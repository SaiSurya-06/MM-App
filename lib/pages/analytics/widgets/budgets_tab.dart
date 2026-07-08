import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/budgets_provider.dart';
import '../../../providers/auth_provider.dart';
import '../trend_analytics_page.dart';

class BudgetsTab extends ConsumerWidget {
  const BudgetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final budgetsState = ref.watch(budgetsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(authProvider).profile?.preferredCurrency ?? 'USD';

    final transactions = derivedValues.filteredTransactions;
    final budgets = budgetsState.budgets;
    final categoryMap = derivedValues.categoryMap;
    final daysInMonth = derivedValues.daysInMonth;

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Calculate category spends for MoM Delta (current vs last month)
    final thisMonthTxs = transactions.where((tx) =>
        tx.date.year == currentYear && tx.date.month == currentMonth).toList();

    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
    
    final prevMonthTxs = transactions.where((tx) =>
        tx.date.year == prevYear && tx.date.month == prevMonth).toList();

    final Map<int, double> thisMonthCatSpend = {};
    for (var tx in thisMonthTxs) {
      if (tx.type == 'expense') {
        thisMonthCatSpend[tx.categoryId] = (thisMonthCatSpend[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }

    final Map<int, double> prevMonthCatSpend = {};
    for (var tx in prevMonthTxs) {
      if (tx.type == 'expense') {
        prevMonthCatSpend[tx.categoryId] = (prevMonthCatSpend[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }

    // Set of all category IDs touched
    final allTouchedCats = {...thisMonthCatSpend.keys, ...prevMonthCatSpend.keys};

    final List<Map<String, dynamic>> deltas = [];
    for (var catId in allTouchedCats) {
      final catName = categoryMap[catId]?.name ?? 'Other';
      final currentSpend = thisMonthCatSpend[catId] ?? 0.0;
      final prevSpend = prevMonthCatSpend[catId] ?? 0.0;
      final diffVal = currentSpend - prevSpend;
      double pct = 0.0;
      if (prevSpend > 0) {
        pct = (diffVal / prevSpend) * 100.0;
      }
      deltas.add({
        'name': catName,
        'current': currentSpend,
        'prev': prevSpend,
        'diff': diffVal,
        'pct': pct,
      });
    }
    // Sort highest increase/decrease first
    deltas.sort((a, b) => (b['diff'] as double).abs().compareTo((a['diff'] as double).abs()));

    // Cumulative budget burn-down lines data preparation
    // Relative to category budgets instead of absolute numbers
    final List<FlSpot> actualSpots = [];
    final List<FlSpot> onTrackSpots = [];
    final List<FlSpot> projectedSpots = [];

    final categoriesWithBudgets = budgets.where((b) => b.limitAmount > 0).toList();
    final int todayDay = now.day;
    final int numCats = categoriesWithBudgets.length;

    // Calculate category-specific daily burn rates
    final Map<int, double> catDailyBurn = {};
    for (var b in categoriesWithBudgets) {
      final catTxs = thisMonthTxs.where((tx) => tx.categoryId == b.categoryId && tx.type == 'expense');
      final totalSpent = catTxs.fold(0.0, (sum, tx) => sum + tx.amount);
      catDailyBurn[b.categoryId] = todayDay > 0 ? (totalSpent / todayDay) : 0.0;
    }

    for (int day = 1; day <= daysInMonth; day++) {
      // 1. Linear "On Track" line: 0% to 100%
      onTrackSpots.add(FlSpot(day.toDouble(), (day / daysInMonth) * 100.0));

      // 2. Actual percentage cumulative spend (only up to today)
      if (day <= todayDay) {
        double totalPctSpent = 0.0;
        for (var b in categoriesWithBudgets) {
          final catTxsToDay = thisMonthTxs.where((tx) => 
              tx.categoryId == b.categoryId && 
              tx.type == 'expense' && 
              tx.date.day <= day
          );
          final spentToDay = catTxsToDay.fold(0.0, (sum, tx) => sum + tx.amount);
          totalPctSpent += (spentToDay / b.limitAmount) * 100.0;
        }
        final double avgPctSpent = numCats > 0 ? (totalPctSpent / numCats) : 0.0;
        actualSpots.add(FlSpot(day.toDouble(), avgPctSpent));
      }

      // 3. Projected cumulative pace line
      double totalProjPctSpent = 0.0;
      for (var b in categoriesWithBudgets) {
        final dailyBurn = catDailyBurn[b.categoryId] ?? 0.0;
        final projSpent = dailyBurn * day;
        totalProjPctSpent += (projSpent / b.limitAmount) * 100.0;
      }
      final double avgProjPctSpent = numCats > 0 ? (totalProjPctSpent / numCats) : 0.0;
      projectedSpots.add(FlSpot(day.toDouble(), avgProjPctSpent));
    }

    double runningActualPct = 0.0;
    if (actualSpots.isNotEmpty) {
      runningActualPct = actualSpots.last.y;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Month-over-Month Delta Card
        Text(
          'Category Month-Over-Month Shifts',
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white38 : Colors.black38, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.0
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (deltas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Not enough data to show shifts.', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(deltas.length, 5),
                  itemBuilder: (context, index) {
                    final item = deltas[index];
                    final diff = item['diff'] as double;
                    final pct = item['pct'] as double;
                    final isUp = diff > 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.format(item['prev'], currency)} → ${CurrencyFormatter.format(item['current'], currency)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                isUp ? Icons.arrow_upward : (diff == 0 ? Icons.remove : Icons.arrow_downward),
                                color: diff == 0 ? Colors.grey : (isUp ? const Color(0xFFE53935) : Colors.green),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${diff == 0 ? '0.0%' : '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%'}' 
                                ' (${CurrencyFormatter.format(diff.abs(), currency)})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: diff == 0 ? Colors.grey : (isUp ? const Color(0xFFE53935) : Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Budget Burn-Down Line Chart
        Text(
          'Budget Burn-Down Cumulative Pace',
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white38 : Colors.black38, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.0
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cumulative Budget Usage (Relative % Scale)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tracks average category spending percentage relative to individual budget limits.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%', style: const TextStyle(fontSize: 9, color: Colors.grey));
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx > 0 && idx <= daysInMonth && idx % 5 == 0) {
                              return Text('Day $idx', style: const TextStyle(fontSize: 9, color: Colors.grey));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // 1. Target linear trajectory
                      LineChartBarData(
                        spots: onTrackSpots,
                        isCurved: false,
                        color: Colors.grey.withValues(alpha: 0.4),
                        barWidth: 1.5,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                      // 2. Projected pace trajectory
                      LineChartBarData(
                        spots: projectedSpots,
                        isCurved: false,
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        barWidth: 1.5,
                        dashArray: [3, 3],
                        dotData: const FlDotData(show: false),
                      ),
                      // 3. Actual spending trajectory (only up to today)
                      LineChartBarData(
                        spots: actualSpots,
                        isCurved: true,
                        color: runningActualPct > 100.0 ? const Color(0xFFE53935) : Colors.green,
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: (runningActualPct > 100.0 ? const Color(0xFFE53935) : Colors.green).withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChartLegendItem('Budget Target', Colors.grey, isDashed: true),
                  _buildChartLegendItem('Projected Pace', Colors.blueAccent, isDashed: true),
                  _buildChartLegendItem('Actual Spend', runningActualPct > 100.0 ? const Color(0xFFE53935) : Colors.green),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        if (isDashed)
          Row(
            children: [
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
            ],
          )
        else
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: color,
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

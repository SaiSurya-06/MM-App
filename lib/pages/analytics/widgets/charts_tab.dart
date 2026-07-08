import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/auth_provider.dart';
import '../trend_analytics_page.dart';

class ChartsTab extends ConsumerWidget {
  const ChartsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final authState = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    final transactions = derivedValues.thisMonthTxs;
    final categoryMap = derivedValues.categoryMap;
    final totalBalance = derivedValues.totalBalance;
    final monthlyIncome = derivedValues.monthlyIncome;
    final monthlyExpense = derivedValues.monthlyExpense;

    // 1. Group spends by weekday
    final weekdayTotals = List<double>.filled(7, 0.0);
    final weekdayCounts = List<int>.filled(7, 0);
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        final day = tx.date.weekday - 1; // 0 (Mon) to 6 (Sun)
        weekdayTotals[day] += tx.amount;
        weekdayCounts[day]++;
      }
    }
    final weekdayAverages = List<double>.generate(7, (i) => weekdayCounts[i] > 0 ? weekdayTotals[i] / weekdayCounts[i] : 0.0);

    // 2. Group spends by week & weekday for the 4x7 heatmap grid
    final heatmapGrid = List.generate(4, (_) => List<double>.filled(7, 0.0));
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        final dayOfM = tx.date.day;
        int week = (dayOfM - 1) ~/ 7;
        if (week > 3) week = 3;
        final wday = tx.date.weekday - 1;
        heatmapGrid[week][wday] += tx.amount;
      }
    }

    // Max val in heatmap for scaling opacity
    double maxHeat = heatmapGrid.expand((w) => w).fold(1.0, (m, v) => v > m ? v : m);

    // 3. Cash Flow Waterfall Data Setup
    final startingBalance = totalBalance - monthlyIncome + monthlyExpense;
    final Map<String, double> categorySpends = {};
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        final name = categoryMap[tx.categoryId]?.name ?? 'Other';
        categorySpends[name] = (categorySpends[name] ?? 0.0) + tx.amount;
      }
    }
    final sortedCats = categorySpends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Construct waterfall steps list
    final List<Map<String, dynamic>> waterfallSteps = [];
    waterfallSteps.add({
      'label': 'Start Bal.',
      'amount': startingBalance,
      'runningBalance': startingBalance,
      'isTotal': true,
      'color': isDark ? Colors.white70 : Colors.black87,
    });
    waterfallSteps.add({
      'label': 'Income (+)',
      'amount': monthlyIncome,
      'runningBalance': startingBalance + monthlyIncome,
      'isTotal': false,
      'color': Colors.green,
    });

    double currentBal = startingBalance + monthlyIncome;
    if (sortedCats.isNotEmpty) {
      for (int i = 0; i < math.min(sortedCats.length, 4); i++) {
        final amt = sortedCats[i].value;
        currentBal -= amt;
        waterfallSteps.add({
          'label': sortedCats[i].key,
          'amount': -amt,
          'runningBalance': currentBal,
          'isTotal': false,
          'color': const Color(0xFFE53935),
        });
      }
    }
    waterfallSteps.add({
      'label': 'Ending Bal.',
      'amount': totalBalance,
      'runningBalance': totalBalance,
      'isTotal': true,
      'color': Colors.blueAccent,
    });

    // Calculate scaling limits for waterfall bars
    double minLimit = 0.0;
    double maxLimit = 0.0;
    for (var step in waterfallSteps) {
      final isTot = step['isTotal'] as bool;
      final bal = step['runningBalance'] as double;
      final amt = step['amount'] as double;
      final start = isTot ? 0.0 : (bal - amt);
      minLimit = math.min(minLimit, math.min(start, bal));
      maxLimit = math.max(maxLimit, math.max(start, bal));
    }
    final double range = (maxLimit - minLimit) > 0 ? (maxLimit - minLimit) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cash Flow Waterfall Step-Graph
        Text(
          'Cash Flow Waterfall',
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
                'Monthly Net Wealth Waterfall',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Starting with previous month-end, adding income, subtracting expenses by category.',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 24),

              // Render waterfall bars list
              ...waterfallSteps.map((step) {
                final isTot = step['isTotal'] as bool;
                final amt = step['amount'] as double;
                final bal = step['runningBalance'] as double;
                
                final double startVal = isTot ? 0.0 : (bal - amt);
                final double endVal = bal;
                
                final double minVal = math.min(startVal, endVal);
                final double maxVal = math.max(startVal, endVal);
                
                final double leftOffsetPct = (minVal - minLimit) / range;
                final double widthPct = (maxVal - minVal) / range;

                return _buildWaterfallBar(
                  label: step['label'] as String,
                  amount: amt,
                  runningBalance: bal,
                  isTotal: isTot,
                  color: step['color'] as Color,
                  leftOffsetPct: leftOffsetPct,
                  widthPct: widthPct,
                  currency: currency,
                  isDark: isDark,
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Heatmap Calendar Grid Card
        Text(
          'Daily Spending Heatmap',
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
                'Activity Calendar (4 Weeks)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Table(
                children: [
                  TableRow(
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            day,
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  for (int w = 0; w < 4; w++)
                    TableRow(
                      children: List.generate(7, (d) {
                        final val = heatmapGrid[w][d];
                        final double opacity = val > 0 ? (val / maxHeat).clamp(0.15, 0.95) : 0.0;
                        return Tooltip(
                          message: val > 0 ? 'Spend: ${CurrencyFormatter.format(val, currency)}' : 'No spending',
                          child: Container(
                            height: 28,
                            margin: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: val > 0 
                                  ? const Color(0xFFE53935).withOpacity(opacity)
                                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${(w * 7) + d + 1}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: val > 0 ? Colors.white : Colors.grey,
                                  fontWeight: val > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Weekday Averages Chart Card
        Text(
          'Average Spend by Weekday',
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
                'Weekly Spend Distributions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildWeekdayAverageRow('Mon', weekdayAverages[0], currency, isDark),
              _buildWeekdayAverageRow('Tue', weekdayAverages[1], currency, isDark),
              _buildWeekdayAverageRow('Wed', weekdayAverages[2], currency, isDark),
              _buildWeekdayAverageRow('Thu', weekdayAverages[3], currency, isDark),
              _buildWeekdayAverageRow('Fri', weekdayAverages[4], currency, isDark),
              _buildWeekdayAverageRow('Sat', weekdayAverages[5], currency, isDark),
              _buildWeekdayAverageRow('Sun', weekdayAverages[6], currency, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayAverageRow(String label, double amount, String currency, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(
            child: Container(
              height: 14,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(4),
              ),
              child: amount > 0 
                  ? FractionallySizedBox(
                      widthFactor: (amount / 200.0).clamp(0.05, 1.0), // Scale maxing at $200
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              CurrencyFormatter.format(amount, currency),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallBar({
    required String label,
    required double amount,
    required double runningBalance,
    required bool isTotal,
    required Color color,
    required double leftOffsetPct,
    required double widthPct,
    required String currency,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - 150; // subtract label and values width
        final left = leftOffsetPct * totalWidth;
        final width = (widthPct * totalWidth).clamp(2.0, totalWidth); // ensure at least a sliver is visible
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 70, 
                child: Text(
                  label, 
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 16,
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Positioned(
                        left: left,
                        width: width,
                        child: Tooltip(
                          message: 'Change: ${amount >= 0 ? '+' : ''}${CurrencyFormatter.format(amount, currency)}\nBalance: ${CurrencyFormatter.format(runningBalance, currency)}',
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(
                  CurrencyFormatter.format(runningBalance, currency),
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

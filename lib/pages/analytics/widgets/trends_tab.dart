import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/auth_provider.dart';
import '../trend_analytics_page.dart';

class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab> {
  int? _selectedTrendsCategoryId;

  Color _parseCategoryColor(String colorStr) {
    final hex = '0xFF${colorStr.replaceAll("#", "")}';
    return Color(int.tryParse(hex) ?? 0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(authProvider).profile?.preferredCurrency ?? 'USD';
    final categories = ref.watch(categoriesProvider).categories;
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final transactions = derivedValues.filteredTransactions;

    final expenseCategories = categories.where((c) => c.type == 'expense' || c.type == 'both').toList();
    if (expenseCategories.isEmpty) {
      return const Center(child: Text('No expense categories found.'));
    }

    _selectedTrendsCategoryId ??= expenseCategories.first.id;

    final selectedCategory = expenseCategories.firstWhere(
      (c) => c.id == _selectedTrendsCategoryId,
      orElse: () => expenseCategories.first,
    );

    final now = DateTime.now();
    final List<MapEntry<String, double>> last6MonthsSpend = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy-MM').format(date);
      final label = DateFormat('MMM').format(date);

      final monthSpend = transactions.where((tx) =>
          tx.type == 'expense' &&
          tx.categoryId == selectedCategory.id &&
          DateFormat('yyyy-MM').format(tx.date) == monthStr
      ).fold(0.0, (sum, tx) => sum + tx.amount);

      last6MonthsSpend.add(MapEntry(label, monthSpend));
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < last6MonthsSpend.length; i++) {
      spots.add(FlSpot(i.toDouble(), last6MonthsSpend[i].value));
    }

    final maxSpend = last6MonthsSpend.fold(1.0, (m, entry) => entry.value > m ? entry.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT CATEGORY FOR TRENDS',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: (expenseCategories.any((cat) => cat.id == _selectedTrendsCategoryId))
                  ? _selectedTrendsCategoryId
                  : (expenseCategories.isNotEmpty ? expenseCategories.first.id : null),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF161625) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white70 : Colors.black54),
              items: expenseCategories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.id,
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTrendsCategoryId = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          '6-MONTH SPENDING TIMELINE',
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Trend: ${selectedCategory.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Long-term monthly trend lines over the last 6 months.',
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
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < last6MonthsSpend.length) {
                              return Text(last6MonthsSpend[index].key, style: const TextStyle(fontSize: 9, color: Colors.grey));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: _parseCategoryColor(selectedCategory.color),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _parseCategoryColor(selectedCategory.color).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('6-Month Peak', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(maxSpend, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Recent Month', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(last6MonthsSpend.last.value, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

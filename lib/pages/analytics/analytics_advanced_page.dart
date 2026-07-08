import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../core/database/database.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/analytics/ai_analyst.dart';
import '../../core/notifications/notification_service.dart';

class AnalyticsAdvancedPage extends ConsumerStatefulWidget {
  const AnalyticsAdvancedPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsAdvancedPage> createState() => _AnalyticsAdvancedPageState();
}

class _AnalyticsAdvancedPageState extends ConsumerState<AnalyticsAdvancedPage> {
  DateTimeRange? _customRange;
  bool _showComparison = false;
  int _selectedTab = 0;
  bool _showGuide = true;

  Future<List<Map<String, dynamic>>> _fetchCategoryTimeline() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final startStr = sixMonthsAgo.toIso8601String().substring(0, 7);
    final endStr = now.toIso8601String().substring(0, 7);

    final results = await db.rawQuery('''
      SELECT c.id, c.name, c.color, strftime('%Y-%m', t.date) as month, SUM(t.amount) as total
      FROM transaction_log t
      INNER JOIN category c ON t.category_id = c.id
      WHERE t.type = 'expense' AND strftime('%Y-%m', t.date) >= ? AND strftime('%Y-%m', t.date) <= ? AND c.type != 'person'
      GROUP BY c.id, month
      ORDER BY month ASC
    ''', [startStr, endStr]);

    return results;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchPeriodComparison(String month1, String month2) async {
    final db = await AppDatabase.instance.database;

    Future<List<Map<String, dynamic>>> fetchMonth(String month) async {
      return await db.rawQuery('''
        SELECT c.name, c.color, SUM(t.amount) as total
        FROM transaction_log t
        INNER JOIN category c ON t.category_id = c.id
        WHERE t.type = 'expense' AND strftime('%Y-%m', t.date) = ? AND c.type != 'person'
        GROUP BY t.category_id
        ORDER BY total DESC
      ''', [month]);
    }

    return {
      'period1': await fetchMonth(month1),
      'period2': await fetchMonth(month2),
    };
  }

  Future<List<Map<String, dynamic>>> _fetchYoYComparison() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final currentMonth = '${now.month.toString().padLeft(2, '0')}';
    final currentMonthFull = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> yoyData = [];

    for (int yearOffset = 0; yearOffset < 3; yearOffset++) {
      final year = now.year - yearOffset;
      final monthStr = '$year-${now.month.toString().padLeft(2, '0')}';

      final result = await db.rawQuery('''
        SELECT
          SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) as income,
          SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) as expenses
        FROM transaction_log t
        INNER JOIN category c ON t.category_id = c.id
        WHERE strftime('%Y-%m', t.date) = ? AND c.type != 'person'
      ''', [monthStr]);

      final income = (result.isNotEmpty ? (result.first['income'] as num?)?.toDouble() ?? 0.0 : 0.0);
      final expenses = (result.isNotEmpty ? (result.first['expenses'] as num?)?.toDouble() ?? 0.0 : 0.0);

      yoyData.add({
        'year': year.toString(),
        'month': DateFormat('MMM').format(DateTime(year, now.month)),
        'income': income,
        'expenses': expenses,
        'net': income - expenses,
      });
    }

    return yoyData;
  }

  void _showAnalyticsInsights() {
    final analyticsState = ref.read(analyticsProvider);
    if (analyticsState.aiRecommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No analytics insights available yet.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          title: const Text('Analytics Insights'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: analyticsState.aiRecommendations.length,
              itemBuilder: (context, index) {
                final rec = analyticsState.aiRecommendations[index];
                final color = rec.type == 'warning' ? const Color(0xFFFF9800)
                    : rec.type == 'saving' ? const Color(0xFF4CAF50)
                    : const Color(0xFF1E88E5);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            rec.type == 'warning' ? Icons.warning_amber_rounded
                                : rec.type == 'saving' ? Icons.savings
                                : Icons.info_outline,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(rec.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(rec.description, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final rec = analyticsState.aiRecommendations.first;
                  await NotificationService.instance.showBudgetAlert(rec.title, 0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alert saved! You will be notified.')),
                    );
                  }
                } catch (_) {}
              },
              icon: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
              label: const Text('Set Alert', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final authState = ref.watch(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final currentMonth = DateFormat('yyyy-MM').format(now);
    final previousMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1));

    final tabs = ['Trends', 'Compare', 'YoY', 'Category Timeline'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Analytics Insights & Alerts',
            onPressed: _showAnalyticsInsights,
          ),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // Date range picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _customRange,
                        );
                        if (picked != null) {
                          setState(() => _customRange = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _customRange != null
                              ? '${DateFormat('MMM dd, yyyy').format(_customRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_customRange!.end)}'
                              : 'Select Date Range',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_customRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _customRange = null),
                    ),
                ],
              ),
            ),

            // Layman Guide Card
            _buildGuideCard(isDark),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final isSelected = _selectedTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE53935) : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black38),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildTrendsTab(analyticsState, currency, isDark)
                  : _selectedTab == 1
                      ? _buildCompareTab(currentMonth, previousMonth, currency, isDark)
                      : _selectedTab == 2
                          ? _buildYoYTab(currency, isDark)
                          : _buildCategoryTimelineTab(currency, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(AnalyticsState state, String currency, bool isDark) {
    if (state.categoryTrends.isEmpty) {
      return const Center(child: Text('No trend data available.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.categoryTrends.length,
      itemBuilder: (context, index) {
        final trend = state.categoryTrends[index];
        if (trend.monthlyAverage <= 0 && trend.currentMonthSpend <= 0) return const SizedBox.shrink();

        final diff = trend.currentMonthSpend - trend.monthlyAverage;
        final diffPct = trend.monthlyAverage > 0 ? (diff / trend.monthlyAverage * 100) : 0.0;
        final isOver = diff > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trend.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOver ? const Color(0xFFE53935) : const Color(0xFF4CAF50)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isOver ? '+' : ''}${diffPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOver ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _trendMetric('6-Mo Avg', CurrencyFormatter.format(trend.monthlyAverage, currency), isDark),
                    _trendMetric('Current', CurrencyFormatter.format(trend.currentMonthSpend, currency), isDark),
                    _trendMetric('3-Mo Rolling', CurrencyFormatter.format(trend.threeMonthRollingAverage, currency), isDark),
                    _trendMetric('Projected', CurrencyFormatter.format(trend.projectedMonthEnd, currency), isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trendMetric(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.black26)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildCompareTab(String currentMonth, String previousMonth, String currency, bool isDark) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchPeriodComparison(currentMonth, previousMonth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final period1 = data['period1']!;
        final period2 = data['period2']!;

        // Merge categories
        final Map<String, Map<String, double>> merged = {};
        for (var row in period1) {
          final name = row['name'] as String;
          merged.putIfAbsent(name, () => {'current': 0, 'previous': 0});
          merged[name]!['current'] = (row['total'] as num?)?.toDouble() ?? 0.0;
          merged[name]!['color'] = 0;
          merged[name]!['color'] = 0;
        }
        for (var row in period2) {
          final name = row['name'] as String;
          merged.putIfAbsent(name, () => {'current': 0, 'previous': 0});
          merged[name]!['previous'] = (row['total'] as num?)?.toDouble() ?? 0.0;
        }

        final entries = merged.entries.toList()..sort((a, b) => b.value['current']!.compareTo(a.value['current']!));


        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _legendDot(const Color(0xFF1E88E5), 'Current Month', isDark),
                const SizedBox(width: 16),
                _legendDot(Colors.grey, 'Previous Month', isDark),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Center(child: Text('No data for comparison.', style: TextStyle(color: Colors.grey)))
            else
              ...entries.map((e) {
                final cur = e.value['current']!;
                final prev = e.value['previous']!;
                final diff = cur - prev;
                final maxVal = [cur, prev].reduce((a, b) => a > b ? a : b);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphismCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current', style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black26)),
                                  Text(CurrencyFormatter.format(cur, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (diff > 0 ? const Color(0xFFE53935) : const Color(0xFF4CAF50)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${diff > 0 ? '+' : ''}${CurrencyFormatter.format(diff, currency)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: diff > 0 ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Previous', style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black26)),
                                  Text(CurrencyFormatter.format(prev, currency), style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black38)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildYoYTab(String currency, bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchYoYComparison(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final yoyData = snapshot.data!;

        if (yoyData.every((d) => (d['income'] as double) == 0 && (d['expenses'] as double) == 0)) {
          return const Center(child: Text('No YoY data available.', style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bar chart for YoY
            GlassmorphismCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: yoyData.asMap().entries.map((e) {
                      final idx = e.key;
                      final data = e.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(toY: data['income'] as double, color: const Color(0xFF4CAF50), width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                          BarChartRodData(toY: data['expenses'] as double, color: const Color(0xFFE53935), width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < yoyData.length) {
                              return Text(yoyData[idx]['month'] as String, style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFF4CAF50), 'Income', isDark),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFFE53935), 'Expenses', isDark),
              ],
            ),
            const SizedBox(height: 20),

            // Detail cards
            ...yoyData.map((data) {
              final income = data['income'] as double;
              final expenses = data['expenses'] as double;
              final net = data['net'] as double;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['month']} ${data['year']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _yoyMetric('Income', CurrencyFormatter.format(income, currency), const Color(0xFF4CAF50)),
                          _yoyMetric('Expenses', CurrencyFormatter.format(expenses, currency), const Color(0xFFE53935)),
                          _yoyMetric('Net', CurrencyFormatter.format(net, currency), net >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _yoyMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),
      ],
    );
  }

  Widget _buildCategoryTimelineTab(String currency, bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchCategoryTimeline(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final rawData = snapshot.data!;

        if (rawData.isEmpty) return const Center(child: Text('No category timeline data.', style: TextStyle(color: Colors.grey)));

        // Group by category
        final Map<String, List<Map<String, dynamic>>> byCategory = {};
        for (var row in rawData) {
          final name = row['name'] as String;
          byCategory.putIfAbsent(name, () => []).add(row);
        }

        // Get all months
        final months = rawData.map((r) => r['month'] as String).toSet().toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...byCategory.entries.map((entry) {
              final catName = entry.key;
              final catData = entry.value;
              final colorHex = catData.first['color'] as String;
              final hex = '0xFF$colorHex';
              final catColor = Color(int.tryParse(hex) ?? 0xFF757575);

              // Map month -> amount
              final Map<String, double> monthAmounts = {};
              for (var row in catData) {
                monthAmounts[row['month'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
              }

              final spots = <FlSpot>[];
              for (int i = 0; i < months.length; i++) {
                spots.add(FlSpot(i.toDouble(), monthAmounts[months[i]] ?? 0.0));
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 18, decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: spots.length >= 2
                            ? LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final idx = val.toInt();
                                          if (idx < months.length) {
                                            final m = DateTime.parse('${months[idx]}-01');
                                            return Text(DateFormat('MMM').format(m), style: const TextStyle(fontSize: 8));
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: catColor,
                                      barWidth: 2,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) =>
                                            FlDotCirclePainter(radius: 3, color: catColor),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [catColor.withOpacity(0.15), catColor.withOpacity(0.0)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Center(child: Text('Need at least 2 data points')),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black38)),
      ],
    );
  }

  Widget _buildGuideCard(bool isDark) {
    if (!_showGuide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
        child: InkWell(
          onTap: () => setState(() => _showGuide = true),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, size: 16, color: Color(0xFFE53935)),
                const SizedBox(width: 6),
                Text(
                  "Show Layman's Guide & Explanations",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "📚 Advanced Analytics Layman's Guide",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _showGuide = false),
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              title: "📈 Trends Tab",
              description: "Compares your current monthly spending against your historical average. A green percentage means you spent less than usual, and red means you spent more.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "⚖️ Compare Tab",
              description: "Shows a side-by-side comparison of current vs. previous month expenses for each category. It highlights the exact increase/decrease.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "📅 YoY (Year-over-Year) Tab",
              description: "Compares income and expenses for this specific month across the current year and past years. Helps you see seasonal patterns (like higher utility bills in summer).",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "⏳ Category Timeline Tab",
              description: "Displays a simple line graph of your spending in each category over the last 6 months, showing if your expenses are rising or falling over time.",
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({required String title, required String description, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : const Color(0xFF555566),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../widgets/common/skeleton_loader.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class ChartSection extends ConsumerStatefulWidget {
  final List<MonthlyComparison> monthlyData;
  final List<CategorySpending> categoryData;
  final List<CategorySpending> incomeCategoryData;
  final List<CategorySpending> personCategoryData;
  final List<CategorySpending> personIncomeCategoryData;
  final List<NetWorthPoint> netWorthData;
  final bool isLoading;

  const ChartSection({
    Key? key,
    required this.monthlyData,
    required this.categoryData,
    required this.incomeCategoryData,
    required this.personCategoryData,
    required this.personIncomeCategoryData,
    required this.netWorthData,
    required this.isLoading,
  }) : super(key: key);

  @override
  ConsumerState<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends ConsumerState<ChartSection> {
  int _activeTab = 0; // 0: Net Worth, 1: Income vs Exp, 2: Categories
  bool _isIncomePie = false;
  bool _showDataList = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const GlassmorphismCard(
        child: SkeletonLoader(height: 220, borderRadius: 16),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Tabs selector and Accessibility view toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTabSelector(0, 'Net Worth'),
                    _buildTabSelector(1, 'Monthly'),
                    _buildTabSelector(2, 'Categories'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showDataList ? Icons.show_chart : Icons.accessibility_new,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                onPressed: () => setState(() => _showDataList = !_showDataList),
                tooltip: _showDataList ? 'Show Chart' : 'Show Data Table (Accessible)',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart / Data Table Container
          AspectRatio(
            aspectRatio: 1.5,
            child: _showDataList ? _buildAccessibleDataList() : _buildActiveChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(int index, String label) {
    final active = _activeTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active 
              ? const Color(0xFFE53935) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active 
                ? const Color(0xFFE53935) 
                : (isDark ? Colors.white10 : Colors.black12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active 
                ? Colors.white 
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChart() {
    switch (_activeTab) {
      case 0:
        return _buildLineChart();
      case 1:
        return _buildBarChart();
      case 2:
        return _buildPieChart();
      default:
        return const SizedBox();
    }
  }

  // 1. Net Worth Trend (Line Chart)
  Widget _buildLineChart() {
    if (widget.netWorthData.isEmpty) {
      return const Center(child: Text('No transaction history available.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.read(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    
    // Map data points
    final List<FlSpot> spots = [];
    for (int i = 0; i < widget.netWorthData.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.netWorthData[i].amount));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white10 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: mathMax(1.0, (spots.length / 5).floorToDouble()),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= widget.netWorthData.length) {
                  return const SizedBox();
                }
                final date = widget.netWorthData[idx].date;
                if (idx == 0 || idx == (spots.length / 2).floor() || idx == spots.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 9,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFE53935),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53935).withOpacity(0.2),
                  const Color(0xFFE53935).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF1E1E2E) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final amount = spot.y;
                final date = widget.netWorthData[spot.x.toInt()].date;
                final dateStr = '${date.day}/${date.month}/${date.year}';
                return LineTooltipItem(
                  'Net Worth\n$dateStr\n${CurrencyFormatter.format(amount, currency)}',
                  TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A26),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // 2. Monthly Income vs Expenses (Bar Chart)
  Widget _buildBarChart() {
    if (widget.monthlyData.isEmpty) {
      return const Center(child: Text('No comparison data.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.read(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    final barGroups = List.generate(widget.monthlyData.length, (i) {
      final data = widget.monthlyData[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data.income,
            color: Colors.green,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: data.expense,
            color: const Color(0xFFE53935),
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= widget.monthlyData.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    widget.monthlyData[idx].month,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF1E1E2E) : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final valType = rodIndex == 0 ? 'Income' : 'Expense';
              final color = rodIndex == 0 ? Colors.green : const Color(0xFFE53935);
              return BarTooltipItem(
                '$valType\n${CurrencyFormatter.format(rod.toY, currency)}',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 3. Category Spending (Donut Chart)
  Widget _buildPieChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCategories = _isIncomePie ? widget.incomeCategoryData : widget.categoryData;
    final activePersons = _isIncomePie ? widget.personIncomeCategoryData : widget.personCategoryData;

    return Column(
      children: [
        // Income vs Expense Segmented Control for Categories
        Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isIncomePie = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                     alignment: Alignment.center,
                     decoration: BoxDecoration(
                       color: !_isIncomePie ? const Color(0xFFE53935) : Colors.transparent,
                       borderRadius: BorderRadius.circular(10),
                     ),
                     child: Text(
                       'Expenses',
                       style: TextStyle(
                         fontSize: 11,
                         fontWeight: FontWeight.bold,
                         color: !_isIncomePie ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                         fontFamily: 'Inter',
                       ),
                     ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isIncomePie = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isIncomePie ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isIncomePie ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // The two pie charts side by side
        Expanded(
          child: Row(
            children: [
              // 1. Categories Pie Chart
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: activeCategories.isEmpty
                          ? Center(
                              child: Text(
                                'No data',
                                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                              ),
                            )
                          : _buildSinglePie(activeCategories, isDark),
                    ),
                  ],
                ),
              ),
              
              // Vertical Divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              
              // 2. Persons Pie Chart
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Persons',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: activePersons.isEmpty
                          ? Center(
                              child: Text(
                                'No P2P data',
                                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                              ),
                            )
                          : _buildSinglePie(activePersons, isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePie(List<CategorySpending> data, bool isDark) {
    return Row(
      children: [
        // Pie Chart Circle
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sections: List.generate(data.length, (i) {
                final item = data[i];
                final showTitle = item.percentage > 15.0;
                final hex = '0xFF${item.colorHex.replaceAll("#", "")}';
                final color = Color(int.tryParse(hex) ?? 0xFF757575);
                return PieChartSectionData(
                  color: color,
                  value: item.amount,
                  title: showTitle ? '${item.percentage.toStringAsFixed(0)}%' : '',
                  radius: 24,
                  titleStyle: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 20,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Legends with a scroll view to prevent overflow
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                mathMin(4, data.length),
                (i) {
                  final item = data[i];
                  final hex = '0xFF${item.colorHex.replaceAll("#", "")}';
                  final color = Color(int.tryParse(hex) ?? 0xFF757575);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.categoryName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibleDataList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A26);
    final authState = ref.read(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    if (_activeTab == 0) {
      if (widget.netWorthData.isEmpty) {
        return const Center(child: Text('No net worth history available.'));
      }
      return ListView.builder(
        itemCount: widget.netWorthData.length,
        itemBuilder: (context, idx) {
          final point = widget.netWorthData[idx];
          final dateStr = '${point.date.day}/${point.date.month}/${point.date.year}';
          return ListTile(
            dense: true,
            title: Text('Date: $dateStr', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
            trailing: Text(CurrencyFormatter.format(point.amount, currency), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          );
        },
      );
    } else if (_activeTab == 1) {
      if (widget.monthlyData.isEmpty) {
        return const Center(child: Text('No comparison data.'));
      }
      return ListView.builder(
        itemCount: widget.monthlyData.length,
        itemBuilder: (context, idx) {
          final data = widget.monthlyData[idx];
          return ListTile(
            dense: true,
            title: Text(data.month, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            subtitle: Text('Income: ${CurrencyFormatter.format(data.income, currency)}', style: const TextStyle(color: Colors.green, fontFamily: 'Inter')),
            trailing: Text('Expense: ${CurrencyFormatter.format(data.expense, currency)}', style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          );
        },
      );
    } else {
      final activeCategories = _isIncomePie ? widget.incomeCategoryData : widget.categoryData;
      final activePersons = _isIncomePie ? widget.personIncomeCategoryData : widget.personCategoryData;
      
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                Expanded(
                  child: activeCategories.isEmpty
                      ? const Center(child: Text('No data', style: TextStyle(fontSize: 10, fontFamily: 'Inter')))
                      : ListView.builder(
                          itemCount: activeCategories.length,
                          itemBuilder: (context, idx) {
                            final item = activeCategories[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(item.categoryName, style: TextStyle(fontSize: 10, color: textColor, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                                  Text('${item.percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Inter')),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: isDark ? Colors.white10 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            child: Column(
              children: [
                Text('Persons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                Expanded(
                  child: activePersons.isEmpty
                      ? const Center(child: Text('No data', style: TextStyle(fontSize: 10, fontFamily: 'Inter')))
                      : ListView.builder(
                          itemCount: activePersons.length,
                          itemBuilder: (context, idx) {
                            final item = activePersons[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(item.categoryName, style: TextStyle(fontSize: 10, color: textColor, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                                  Text('${item.percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Inter')),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Math utils
  double mathMax(double a, double b) => a > b ? a : b;
  int mathMin(int a, int b) => a < b ? a : b;
}

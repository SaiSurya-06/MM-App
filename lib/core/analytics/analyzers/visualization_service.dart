import 'package:intl/intl.dart';
import '../../../models/category.dart';
import '../capability.dart';
import '../models/visualization_models.dart';

class VisualizationService implements Capability<VisualizationModels> {
  @override
  String get id => 'visualization_service';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Visualization Service';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<VisualizationModels> execute(OrchestratorContext context) async {
    final now = context.snapshot.selectedDate;
    final currentMonth = context.snapshot.selectedMonth;

    // 1. Forecast points
    final List<LineChartDataPoint> forecastPoints = [];
    final forecast = context.forecast;
    if (forecast != null) {
      forecast.cashFlowTrend.forEach((dateStr, val) {
        final date = DateTime.tryParse(dateStr) ?? now;
        forecastPoints.add(LineChartDataPoint(date, val));
      });
    }

    // 2. Daily Spends (Heatmap)
    final Map<String, double> spendsByDate = {};
    final thisMonthTxs = context.snapshot.transactions.where((tx) {
      final txMonth = tx.date.toIso8601String().substring(0, 7);
      return txMonth == currentMonth && tx.type == 'expense' && tx.parentId == null;
    }).toList();

    for (var tx in thisMonthTxs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
      spendsByDate[dateKey] = (spendsByDate[dateKey] ?? 0.0) + tx.amount;
    }

    final List<HeatmapDataPoint> dailySpends = [];
    spendsByDate.forEach((dateStr, val) {
      final date = DateTime.tryParse(dateStr) ?? now;
      dailySpends.add(HeatmapDataPoint(date, val));
    });

    // 3. Flow Bars (Segmented block percentages relative to Income)
    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double essentials = context.expenseAnalysis?.spendByFlowGroup['Essentials'] ?? 0.0;
    final double lifestyle = context.expenseAnalysis?.spendByFlowGroup['Lifestyle'] ?? 0.0;
    final double savings = context.expenseAnalysis?.spendByFlowGroup['Savings'] ?? 0.0;
    final double investments = context.expenseAnalysis?.spendByFlowGroup['Investments'] ?? 0.0;
    
    final double remaining = income - (essentials + lifestyle + savings + investments);
    final double moneyLeft = remaining > 0 ? remaining : 0.0;

    final double denominator = income > 0 ? income : 1.0;

    final List<FlowBarItem> flowBars = [
      FlowBarItem(
        label: 'Needs (Essentials)',
        amount: essentials,
        percentage: (essentials / denominator * 100.0).clamp(0.0, 100.0),
        colorHex: '1E88E5', // Blue Accent
      ),
      FlowBarItem(
        label: 'Wants (Lifestyle)',
        amount: lifestyle,
        percentage: (lifestyle / denominator * 100.0).clamp(0.0, 100.0),
        colorHex: 'FFB300', // Yellow Amber
      ),
      FlowBarItem(
        label: 'Savings',
        amount: savings,
        percentage: (savings / denominator * 100.0).clamp(0.0, 100.0),
        colorHex: '4CAF50', // Green
      ),
      FlowBarItem(
        label: 'Investments',
        amount: investments,
        percentage: (investments / denominator * 100.0).clamp(0.0, 100.0),
        colorHex: '8E24AA', // Purple
      ),
      FlowBarItem(
        label: 'Left to Spend',
        amount: moneyLeft,
        percentage: (moneyLeft / denominator * 100.0).clamp(0.0, 100.0),
        colorHex: '00ACC1', // Cyan
      ),
    ];

    // 4. Timeline Events (Chronological flow)
    final List<TimelineItem> timelineEvents = [];
    
    // Sort transactions chronologically
    final chronoTxs = context.snapshot.transactions.where((tx) {
      final txMonth = tx.date.toIso8601String().substring(0, 7);
      return txMonth == currentMonth && tx.parentId == null;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    for (var tx in chronoTxs) {
      final cat = context.snapshot.categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => Category(id: tx.categoryId, name: 'Other', icon: '', color: '', isDefault: true),
      );

      timelineEvents.add(TimelineItem(
        date: tx.date,
        title: tx.title,
        amount: tx.amount,
        type: tx.type,
        categoryName: cat.name,
      ));
    }

    final vis = VisualizationModels(
      forecastPoints: forecastPoints,
      dailySpends: dailySpends,
      flowBars: flowBars,
      timelineEvents: timelineEvents,
    );

    context.visualizations = vis; // Cache in context
    return vis;
  }
}

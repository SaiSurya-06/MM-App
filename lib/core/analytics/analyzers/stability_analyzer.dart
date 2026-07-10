import 'dart:math' as math;
import '../capability.dart';

class StabilityAnalysis {
  final String incomeType; // Stable, Freelance, Seasonal
  final double stabilityScore; // 0.0 to 100.0
  final double baseExpectedMonthlyIncome;
  final String description;
  final String algorithmVersion;

  const StabilityAnalysis({
    required this.incomeType,
    required this.stabilityScore,
    required this.baseExpectedMonthlyIncome,
    required this.description,
    this.algorithmVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'incomeType': incomeType,
        'stabilityScore': stabilityScore,
        'baseExpectedMonthlyIncome': baseExpectedMonthlyIncome,
        'description': description,
        'algorithmVersion': algorithmVersion,
      };
}

class StabilityAnalyzer implements Capability<StabilityAnalysis> {
  @override
  String get id => 'stability_analyzer';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Stability Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<StabilityAnalysis> execute(OrchestratorContext context) async {
    final snapshot = context.snapshot;
    final Map<String, double> incomeByMonth = {};

    // Group all income transactions by month
    for (var tx in snapshot.transactions) {
      if (tx.type == 'income' && tx.parentId == null) {
        final monthStr = tx.date.toIso8601String().substring(0, 7);
        incomeByMonth[monthStr] = (incomeByMonth[monthStr] ?? 0.0) + tx.amount;
      }
    }

    if (incomeByMonth.isEmpty) {
      return const StabilityAnalysis(
        incomeType: 'Freelance',
        stabilityScore: 0.0,
        baseExpectedMonthlyIncome: 0.0,
        description: 'No historical income transactions detected to calculate stability.',
      );
    }

    final incomeValues = incomeByMonth.values.toList();
    final double mean = incomeValues.reduce((a, b) => a + b) / incomeValues.length;

    double variance = 0.0;
    for (var val in incomeValues) {
      variance += math.pow(val - mean, 2);
    }
    final double stdDev = math.sqrt(variance / incomeValues.length);

    double stabilityScore = 100.0;
    if (mean > 0) {
      final cv = stdDev / mean;
      stabilityScore = ((1.0 - cv) * 100.0).clamp(0.0, 100.0);
    }

    String type = 'Stable';
    String desc = 'Your income is highly stable. You receive a consistent monthly salary.';
    if (stabilityScore < 50) {
      type = 'Seasonal';
      desc = 'Your income exhibits high seasonality or volatility. Plan cash flow carefully.';
    } else if (stabilityScore < 85) {
      type = 'Freelance';
      desc = 'Your income fluctuates slightly, typical of freelance or business models.';
    }

    return StabilityAnalysis(
      incomeType: type,
      stabilityScore: stabilityScore,
      baseExpectedMonthlyIncome: mean,
      description: desc,
    );
  }
}

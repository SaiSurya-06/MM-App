import '../capability.dart';
import '../models/spending_velocity.dart';

class SpendingPredictor implements Capability<SpendingVelocity> {
  @override
  String get id => 'spending_predictor';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Spending Predictor';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<SpendingVelocity> execute(OrchestratorContext context) async {
    final now = context.snapshot.selectedDate;
    final expenseAnalysis = context.expenseAnalysis;
    final totalLimits = context.totalBudgetLimits ?? 0.0;

    final double spentSoFar = expenseAnalysis?.totalExpense ?? 0.0;

    final int totalDays = DateTime(now.year, now.month + 1, 0).day;
    final int elapsedDays = now.day > 0 ? now.day : 1;

    final double dailyBurnRate = spentSoFar / elapsedDays;
    final double weeklyBurnRate = dailyBurnRate * 7.0;

    // Expected daily speed based on budget caps
    final double expectedDailyPace = totalLimits > 0 ? totalLimits / totalDays : 2000.0; // Fallback ₹2,000/day

    final bool isAhead = dailyBurnRate > expectedDailyPace;
    final double drift = expectedDailyPace > 0
        ? ((dailyBurnRate - expectedDailyPace) / expectedDailyPace * 100.0)
        : 0.0;

    String status = 'On Pace';
    if (drift > 10.0) {
      status = 'Ahead of Pace ⚠';
    } else if (drift < -10.0) {
      status = 'Behind Pace ✔';
    }

    final velocity = SpendingVelocity(
      dailyBurnRate: dailyBurnRate,
      weeklyBurnRate: weeklyBurnRate,
      expectedDailyPace: expectedDailyPace,
      isAheadOfPace: isAhead,
      paceDriftPercentage: drift,
      statusDescription: status,
    );

    context.velocity = velocity; // Cache in context
    return velocity;
  }
}

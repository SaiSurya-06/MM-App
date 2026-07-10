import 'package:intl/intl.dart';
import '../capability.dart';
import '../explainable_value.dart';

class GoalPredictor implements Capability<Map<int, ExplainableValue<String>>> {
  @override
  String get id => 'goal_predictor';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Goal Predictor';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<Map<int, ExplainableValue<String>>> execute(OrchestratorContext context) async {
    final Map<int, ExplainableValue<String>> forecasts = {};
    final now = context.snapshot.selectedDate;

    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double expense = context.expenseAnalysis?.totalExpense ?? 0.0;
    
    // Monthly net savings velocity
    double monthlySavings = income - expense;
    if (monthlySavings <= 0) {
      // Fallback to historical stability base expected income minus expense, or 5000/month minimum
      final double histInc = context.stability?.baseExpectedMonthlyIncome ?? 0.0;
      monthlySavings = histInc > expense ? histInc - expense : 5000.0;
    }

    for (var goal in context.snapshot.goals) {
      final goalId = goal.id ?? 0;
      final double remaining = goal.targetAmount - goal.currentAmount;
      if (remaining <= 0) {
        forecasts[goalId] = ExplainableValue<String>(
          value: 'Achieved',
          reason: 'Target already reached!',
          confidence: 1.0,
          dataUsed: 'Target: ₹${goal.targetAmount}, Current: ₹${goal.currentAmount}',
        );
        continue;
      }

      // Amortize net savings: if there are multiple goals, assume savings are split equally or by target date
      final activeGoalsCount = context.snapshot.goals.where((g) => g.currentAmount < g.targetAmount).length;
      final shareOfSavings = monthlySavings / (activeGoalsCount > 0 ? activeGoalsCount : 1);

      final double monthsNeeded = remaining / (shareOfSavings > 0 ? shareOfSavings : 1000.0);
      final int daysNeeded = (monthsNeeded * 30.43).round();

      final projectedDate = now.add(Duration(days: daysNeeded));
      final dateStr = DateFormat('MMM yyyy').format(projectedDate);

      String reason = 'Based on current net savings rate of ₹${shareOfSavings.toStringAsFixed(0)}/month allocated to this goal.';
      double confidence = 0.85;

      if (monthsNeeded > 12) {
        confidence = 0.60;
        reason = '$reason Long-term forecast is subject to income changes.';
      }

      forecasts[goalId] = ExplainableValue<String>(
        value: dateStr,
        reason: reason,
        confidence: confidence,
        dataUsed: 'Remaining: ₹${remaining.toStringAsFixed(0)}, Share: ₹${shareOfSavings.toStringAsFixed(0)}/mo',
      );
    }

    return forecasts;
  }
}

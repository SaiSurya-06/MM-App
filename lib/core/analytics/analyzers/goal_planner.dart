import '../capability.dart';
import '../models/goal_plan.dart';
import '../../utils/currency_formatter.dart';

class GoalPlanner implements Capability<GoalPlan> {
  @override
  String get id => 'goal_planner';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Goal Planner';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<GoalPlan> execute(OrchestratorContext context) async {
    final forecast = context.forecast;
    final List<GoalAllocation> allocations = [];
    String recommendations = '';

    if (forecast == null) {
      const plan = GoalPlan(
        allocations: [],
        recommendations: 'No monthly forecast available to calculate goal plan.',
      );
      context.goals = plan;
      return plan;
    }

    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double expense = context.expenseAnalysis?.totalExpense ?? 0.0;
    double netSavings = income - expense;
    if (netSavings <= 0) {
      final double histInc = context.stability?.baseExpectedMonthlyIncome ?? 0.0;
      netSavings = histInc > expense ? histInc - expense : 5000.0;
    }

    final activeGoals = context.snapshot.goals.where((g) => g.currentAmount < g.targetAmount).toList();
    final Map<int, double> weights = {};
    double totalWeight = 0.0;
    final selectedDate = context.snapshot.selectedDate;

    for (var goal in activeGoals) {
      final goalId = goal.id ?? 0;
      final targetDate = goal.targetDate ?? selectedDate.add(const Duration(days: 365));
      final diffDays = targetDate.difference(selectedDate).inDays;
      double monthsRemaining = diffDays / 30.43;
      if (monthsRemaining <= 0) {
        monthsRemaining = 0.5; // Prevent division by zero
      }
      final gap = goal.targetAmount - goal.currentAmount;
      final neededMonthly = gap / monthsRemaining;
      
      weights[goalId] = neededMonthly;
      totalWeight += neededMonthly;
    }

    for (var goal in context.snapshot.goals) {
      final goalId = goal.id ?? 0;
      final forecastVal = forecast.goalForecasts[goalId];
      
      int delayDays = 0;
      double probability = 100.0;

      if (forecastVal != null && forecastVal.value != 'Achieved') {
        probability = forecastVal.confidence * 100.0;
        // Simple delay mock: if target date is set, check if forecast is after target date
        if (goal.targetDate != null) {
          final targetDT = goal.targetDate ?? DateTime.now();
          final months = forecastVal.dataUsed.contains('Months') 
              ? double.tryParse(forecastVal.dataUsed.split('Months:').last.split(',').first.trim()) ?? 2.0
              : 2.0;
          final forecastDT = DateTime.now().add(Duration(days: (months * 30.43).round()));
          delayDays = forecastDT.difference(targetDT).inDays;
        }
      }

      double shareOfSavings = 0.0;
      if (goal.currentAmount < goal.targetAmount) {
        if (totalWeight > 0.0) {
          final weight = weights[goalId] ?? 0.0;
          shareOfSavings = netSavings * (weight / totalWeight);
        } else {
          shareOfSavings = netSavings / (activeGoals.isNotEmpty ? activeGoals.length : 1);
        }
        
        final gap = goal.targetAmount - goal.currentAmount;
        if (shareOfSavings > gap) {
          shareOfSavings = gap;
        }
      }

      allocations.add(GoalAllocation(
        goalId: goalId,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        delayDays: delayDays,
        accelerationPotential: netSavings * 0.15, // Assume we can optimize lifestyle by 15% to accelerate
        allocatedMonthlyAmount: shareOfSavings,
        achievementProbability: probability,
      ));
    }

    final delayedCount = allocations.where((a) => a.delayDays > 0).length;
    if (delayedCount > 0) {
      recommendations = '$delayedCount of your savings goals are currently delayed. '
          'To accelerate your timelines, try shifting 10% of your Lifestyle budget to Savings, '
          'which could add ${CurrencyFormatter.format(netSavings * 0.1, context.currencyCode)}/month to your goal allocations.';
    } else {
      recommendations = 'All savings goals are on track! Maintain your current net savings rate '
          'of ${CurrencyFormatter.format(netSavings, context.currencyCode)}/month to hit your targets on time.';
    }

    final goalPlan = GoalPlan(
      allocations: allocations,
      recommendations: recommendations,
    );

    context.goals = goalPlan; // Cache in context
    return goalPlan;
  }
}

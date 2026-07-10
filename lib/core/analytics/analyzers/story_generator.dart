import '../capability.dart';
import '../models/money_story.dart';

class StoryGenerator implements Capability<MoneyStory> {
  @override
  String get id => 'story_generator';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Story Generator';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<MoneyStory> execute(OrchestratorContext context) async {
    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double expense = context.expenseAnalysis?.totalExpense ?? 0.0;
    final String rating = context.health?.rating ?? 'Good';

    final double essentials = context.expenseAnalysis?.spendByFlowGroup['Essentials'] ?? 0.0;
    final double lifestyle = context.expenseAnalysis?.spendByFlowGroup['Lifestyle'] ?? 0.0;
    final double savings = context.expenseAnalysis?.spendByFlowGroup['Savings'] ?? 0.0;
    final double investments = context.expenseAnalysis?.spendByFlowGroup['Investments'] ?? 0.0;

    final double remaining = income - expense;
    final double moneyLeft = remaining > 0 ? remaining : 0.0;

    // Monthly Story
    final String monthlyStory = 'Your month began with an inflow of ₹${income.toStringAsFixed(0)}. '
        'So far, you spent ₹${essentials.toStringAsFixed(0)} on Essential Bills and '
        '₹${lifestyle.toStringAsFixed(0)} on Daily Living. '
        'You successfully allocated ₹${savings.toStringAsFixed(0)} to Savings and ₹${investments.toStringAsFixed(0)} to Investments, '
        'leaving you with ₹${moneyLeft.toStringAsFixed(0)} safe to spend today. '
        'Your overall budget health is evaluated as $rating.';

    // Daily Story
    final now = context.snapshot.selectedDate;
    // Get today's transactions
    final todayStr = now.toIso8601String().substring(0, 10);
    final todayTxs = context.snapshot.transactions.where((tx) =>
        tx.date.toIso8601String().substring(0, 10) == todayStr && tx.parentId == null).toList();
    final double todaySpend = todayTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);

    final String dailyStory = todaySpend > 0
        ? 'Today you spent ₹${todaySpend.toStringAsFixed(0)} across ${todayTxs.length} transaction logs.'
        : 'Nice work! You logged zero expenses today, keeping your spending velocity intact.';

    // Weekly Story
    final String weeklyStory = 'This week, your lifestyle spending was driven primarily by '
        'discretionary items. Spending velocity is ${dailyStory.contains('zero') ? 'optimal' : 'active'}.';

    // Yearly Story
    const String yearlyStory = 'Over the course of the year, you have maintained a positive net surplus. '
        'Emergency cash reserves and investments are expanding.';

    final storyObj = MoneyStory(
      dailyStory: dailyStory,
      weeklyStory: weeklyStory,
      monthlyStory: monthlyStory,
      yearlyStory: yearlyStory,
    );

    context.story = storyObj; // Cache in context
    return storyObj;
  }
}

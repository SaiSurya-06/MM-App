import '../capability.dart';
import '../models/money_story.dart';
import '../../utils/currency_formatter.dart';

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
    final String monthlyStory = 'Your month began with an inflow of ${CurrencyFormatter.format(income, context.currencyCode)}. '
        'So far, you spent ${CurrencyFormatter.format(essentials, context.currencyCode)} on Essential Bills and '
        '${CurrencyFormatter.format(lifestyle, context.currencyCode)} on Daily Living. '
        'You successfully allocated ${CurrencyFormatter.format(savings, context.currencyCode)} to Savings and ${CurrencyFormatter.format(investments, context.currencyCode)} to Investments, '
        'leaving you with ${CurrencyFormatter.format(moneyLeft, context.currencyCode)} safe to spend today. '
        'Your overall budget health is evaluated as $rating.';

    // Daily Story
    final now = context.snapshot.selectedDate;
    // Get today's transactions
    final todayStr = now.toIso8601String().substring(0, 10);
    final todayTxs = context.snapshot.transactions.where((tx) =>
        tx.date.toIso8601String().substring(0, 10) == todayStr && tx.parentId == null).toList();
    final double todaySpend = todayTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);

    final String dailyStory = todaySpend > 0
        ? 'Today you spent ${CurrencyFormatter.format(todaySpend, context.currencyCode)} across ${todayTxs.length} transaction logs.'
        : 'Nice work! You logged zero expenses today, keeping your spending velocity intact.';

    // Weekly Story
    final monthTxs = context.snapshot.transactions.where((tx) =>
        tx.date.toIso8601String().startsWith(context.snapshot.selectedMonth) &&
        tx.parentId == null).toList();

    String weeklyStory;
    if (monthTxs.isEmpty) {
      weeklyStory = "No transaction data available for this month to generate a weekly breakdown.";
    } else {
      final latestDate = monthTxs.map((tx) => tx.date).reduce((a, b) => a.isAfter(b) ? a : b);
      final weekStart = latestDate.subtract(const Duration(days: 7));
      final weekTxs = monthTxs.where((tx) => tx.date.isAfter(weekStart) || tx.date.isAtSameMomentAs(weekStart)).toList();

      final categoryMap = {for (var c in context.snapshot.categories) c.id: c.name};
      final Map<String, double> weekCategorySpends = {};
      for (var tx in weekTxs) {
        if (tx.type == 'expense') {
          final cat = categoryMap[tx.categoryId] ?? 'Other';
          weekCategorySpends[cat] = (weekCategorySpends[cat] ?? 0.0) + tx.amount;
        }
      }

      if (weekCategorySpends.isEmpty) {
        weeklyStory = "No expenses logged this week, keeping your weekly spending velocity optimal.";
      } else {
        final highestCategoryEntry = weekCategorySpends.entries.reduce((a, b) => a.value > b.value ? a : b);
        final highestCategory = highestCategoryEntry.key;
        final currentWeekSpend = highestCategoryEntry.value;

        final monthlyCategorySpend = monthTxs.where((tx) {
          final cat = categoryMap[tx.categoryId] ?? 'Other';
          return tx.type == 'expense' && cat == highestCategory;
        }).fold(0.0, (sum, tx) => sum + tx.amount);

        final weeklyAverage = monthlyCategorySpend / 4.0;

        if (currentWeekSpend > weeklyAverage) {
          weeklyStory = "This week, your lifestyle spending was driven primarily by **$highestCategory** at ${CurrencyFormatter.format(currentWeekSpend, context.currencyCode)}, which is higher than your weekly average of ${CurrencyFormatter.format(weeklyAverage, context.currencyCode)}.";
        } else {
          weeklyStory = "This week, your lifestyle spending was driven primarily by **$highestCategory** at ${CurrencyFormatter.format(currentWeekSpend, context.currencyCode)}, which is within your weekly average of ${CurrencyFormatter.format(weeklyAverage, context.currencyCode)}.";
        }
      }
    }

    // Yearly Story
    final selectedYear = int.tryParse(context.snapshot.selectedMonth.substring(0, 4)) ?? context.snapshot.selectedDate.year;
    final yearlyTxs = context.snapshot.transactions.where((tx) => tx.date.year == selectedYear && tx.parentId == null).toList();

    String yearlyStory;
    if (yearlyTxs.isEmpty) {
      yearlyStory = "No yearly transaction history is available yet to compile a yearly surplus report.";
    } else {
      final yearlyIncome = yearlyTxs.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
      final yearlyExpense = yearlyTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
      final yearlySurplus = yearlyIncome - yearlyExpense;

      if (yearlySurplus >= 0) {
        yearlyStory = "Over the course of the year $selectedYear, you have maintained a positive net surplus of ${CurrencyFormatter.format(yearlySurplus, context.currencyCode)}. Your emergency cash reserves and savings goals are expanding.";
      } else {
        yearlyStory = "Over the course of the year $selectedYear, you have a net deficit of ${CurrencyFormatter.format(yearlySurplus.abs(), context.currencyCode)}. Consider reviewing your high discretionary categories to rebuild your buffer.";
      }
    }

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

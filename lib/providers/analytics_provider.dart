import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import '../core/database/database.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../core/analytics/ai_analyst.dart';
import '../core/analytics/health_score_service.dart';
import '../core/analytics/financial_engine.dart';
import 'accounts_provider.dart';
import 'transactions_provider.dart';
import 'auth_provider.dart';

class MonthlyComparison {
  final String month; // 'Jan', 'Feb', etc.
  final double income;
  final double expense;
  MonthlyComparison({required this.month, required this.income, required this.expense});
}

class CategorySpending {
  final String categoryName;
  final double amount;
  final double percentage;
  final String colorHex;
  CategorySpending({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.colorHex,
  });
}

class NetWorthPoint {
  final DateTime date;
  final double amount;
  NetWorthPoint({required this.date, required this.amount});
}

class CategoryTrend {
  final int categoryId;
  final String categoryName;
  final double monthlyAverage; // Historical monthly average (up to 6 months)
  final double threeMonthRollingAverage; // Last 90 days divided by 3
  final double projectedMonthEnd; // Projected total for current month
  final double currentMonthSpend;

  CategoryTrend({
    required this.categoryId,
    required this.categoryName,
    required this.monthlyAverage,
    required this.threeMonthRollingAverage,
    required this.projectedMonthEnd,
    required this.currentMonthSpend,
  });
}

class AnalyticsState {
  final List<MonthlyComparison> monthlyData;
  final List<CategorySpending> categoryData;
  final List<CategorySpending> incomeCategoryData;
  final List<CategorySpending> personCategoryData;
  final List<CategorySpending> personIncomeCategoryData;
  final List<NetWorthPoint> netWorthData;
  final List<CategoryTrend> categoryTrends;
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double netSavings;
  final double todayIncome;
  final double todayExpenses;
  final String todayMajorExpenseCategory;
  final double todayMajorExpenseAmount;
  final String todayMajorIncomeCategory;
  final double todayMajorIncomeAmount;
  final double healthScore;
  final AiSpendingForecast? aiForecast;
  final List<AiAnomaly> aiAnomalies;
  final List<AiGoalProjection> aiGoalProjections;
  final List<AiRecommendation> aiRecommendations;
  final bool isLoading;

  AnalyticsState({
    required this.monthlyData,
    required this.categoryData,
    this.incomeCategoryData = const [],
    this.personCategoryData = const [],
    this.personIncomeCategoryData = const [],
    required this.netWorthData,
    this.categoryTrends = const [],
    this.totalBalance = 0.0,
    this.monthlyIncome = 0.0,
    this.monthlyExpenses = 0.0,
    this.netSavings = 0.0,
    this.todayIncome = 0.0,
    this.todayExpenses = 0.0,
    this.todayMajorExpenseCategory = 'None',
    this.todayMajorExpenseAmount = 0.0,
    this.todayMajorIncomeCategory = 'None',
    this.todayMajorIncomeAmount = 0.0,
    this.healthScore = 100.0,
    this.aiForecast,
    this.aiAnomalies = const [],
    this.aiGoalProjections = const [],
    this.aiRecommendations = const [],
    this.isLoading = false,
  });
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;

  AnalyticsNotifier(this._ref)
      : super(AnalyticsState(
          monthlyData: [],
          categoryData: [],
          incomeCategoryData: [],
          netWorthData: [],
          isLoading: true,
        )) {
    // Reload analytics when accounts or transactions change
    _ref.listen(accountsProvider, (_, __) => refreshAnalytics());
    _ref.listen(transactionsProvider, (_, __) => refreshAnalytics());
    refreshAnalytics();
  }

  Timer? _debounceTimer;

  void refreshAnalytics() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _executeRefresh();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _executeRefresh() async {
    try {
      state = AnalyticsState(
        monthlyData: state.monthlyData,
        categoryData: state.categoryData,
        incomeCategoryData: state.incomeCategoryData,
        netWorthData: state.netWorthData,
        totalBalance: state.totalBalance,
        monthlyIncome: state.monthlyIncome,
        monthlyExpenses: state.monthlyExpenses,
        netSavings: state.netSavings,
        todayIncome: state.todayIncome,
        todayExpenses: state.todayExpenses,
        todayMajorExpenseCategory: state.todayMajorExpenseCategory,
        todayMajorExpenseAmount: state.todayMajorExpenseAmount,
        todayMajorIncomeCategory: state.todayMajorIncomeCategory,
        todayMajorIncomeAmount: state.todayMajorIncomeAmount,
        healthScore: state.healthScore,
        aiForecast: state.aiForecast,
        aiAnomalies: state.aiAnomalies,
        aiGoalProjections: state.aiGoalProjections,
        isLoading: true,
      );

      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final currentMonth = now.toIso8601String().substring(0, 7);
      final todayStr = now.toIso8601String().substring(0, 10);

      // Query all transaction logs from the last 6 months in a single query
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final sixMonthsAgoStr = DateFormat('yyyy-MM-dd').format(sixMonthsAgo);

      final List<Map<String, dynamic>> txRows = await db.rawQuery('''
        SELECT t.id, t.account_id, t.category_id, t.title, t.amount, t.type, t.date, t.note, t.recurrence, t.is_private, t.tags, t.parent_id, t.transfer_to_account_id, t.created_at,
               c.name as category_name, c.color as category_color, c.type as category_type
        FROM transaction_log t
        INNER JOIN category c ON t.category_id = c.id
        WHERE t.date >= ?
      ''', [sixMonthsAgoStr]);

      final List<Map<String, dynamic>> allCategories = await db.query('category');
      final Map<int, String> categoryNamesMap = {
        for (var cat in allCategories) cat['id'] as int: cat['name'] as String
      };

      // 1. Calculate Summary Cards
      // A. Total Balance (excluding Credit Cards for Net Worth)
      final accounts = _ref.read(accountsProvider).accounts;
      double totalBalance = 0.0;
      for (var acc in accounts) {
        if (acc.type != 'Credit Card') {
          totalBalance += acc.balance;
        }
      }

      // B. Monthly Income & Expense & C. Today's Income & Expense & D. Today's Major Spending/Income
      double monthlyIncome = 0.0;
      double monthlyExpenses = 0.0;
      double todayIncome = 0.0;
      double todayExpenses = 0.0;

      final Map<String, double> todayExpByCat = {};
      final Map<String, double> todayIncByCat = {};

      for (var row in txRows) {
        final date = row['date'] as String;
        final type = row['type'] as String;
        final amount = (row['amount'] as num).toDouble();
        final catName = row['category_name'] as String;

        if (date.startsWith(currentMonth)) {
          if (type == 'income') {
            monthlyIncome += amount;
          } else if (type == 'expense') {
            monthlyExpenses += amount;
          }
        }

        if (date.startsWith(todayStr)) {
          if (type == 'income') {
            todayIncome += amount;
            todayIncByCat[catName] = (todayIncByCat[catName] ?? 0.0) + amount;
          } else if (type == 'expense') {
            todayExpenses += amount;
            todayExpByCat[catName] = (todayExpByCat[catName] ?? 0.0) + amount;
          }
        }
      }

      String todayMajorExpenseCategory = 'None';
      double todayMajorExpenseAmount = 0.0;
      if (todayExpByCat.isNotEmpty) {
        final sorted = todayExpByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        todayMajorExpenseCategory = sorted.first.key;
        todayMajorExpenseAmount = sorted.first.value;
      }

      String todayMajorIncomeCategory = 'None';
      double todayMajorIncomeAmount = 0.0;
      if (todayIncByCat.isNotEmpty) {
        final sorted = todayIncByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        todayMajorIncomeCategory = sorted.first.key;
        todayMajorIncomeAmount = sorted.first.value;
      }

      // 2. Fetch Bar Chart (Income vs Expense last 6 months)
      final List<MonthlyComparison> monthlyData = [];
      for (int i = 5; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        final targetMonthStr = DateFormat('yyyy-MM').format(targetMonth);
        final label = DateFormat('MMM').format(targetMonth);

        double inc = 0.0;
        double exp = 0.0;
        for (var row in txRows) {
          final date = row['date'] as String;
          if (date.startsWith(targetMonthStr)) {
            final type = row['type'] as String;
            final amount = (row['amount'] as num).toDouble();
            if (type == 'income') {
              inc += amount;
            } else if (type == 'expense') {
              exp += amount;
            }
          }
        }
        monthlyData.add(MonthlyComparison(month: label, income: inc, expense: exp));
      }

      // 3. Fetch Category Spending for current month
      final Map<int, Map<String, dynamic>> expenseAgg = {};
      final Map<int, Map<String, dynamic>> incomeAgg = {};
      final Map<int, Map<String, dynamic>> personExpenseAgg = {};
      final Map<int, Map<String, dynamic>> personIncomeAgg = {};

      double totalExpenseSum = 0.0;
      double totalIncomeSum = 0.0;
      double totalPersonExpenseSum = 0.0;
      double totalPersonIncomeSum = 0.0;

      for (var row in txRows) {
        final date = row['date'] as String;
        if (date.startsWith(currentMonth)) {
          final type = row['type'] as String;
          final amount = (row['amount'] as num).toDouble();
          final catId = row['category_id'] as int;
          final catName = row['category_name'] as String;
          final catColor = row['category_color'] as String;
          final catType = row['category_type'] as String? ?? 'both';

          if (type == 'expense') {
            if (catType == 'person') {
              personExpenseAgg.putIfAbsent(catId, () => {'name': catName, 'color': catColor, 'total': 0.0});
              personExpenseAgg[catId]!['total'] = (personExpenseAgg[catId]!['total'] as double) + amount;
              totalPersonExpenseSum += amount;
            } else {
              expenseAgg.putIfAbsent(catId, () => {'name': catName, 'color': catColor, 'total': 0.0});
              expenseAgg[catId]!['total'] = (expenseAgg[catId]!['total'] as double) + amount;
              totalExpenseSum += amount;
            }
          } else if (type == 'income') {
            if (catType == 'person') {
              personIncomeAgg.putIfAbsent(catId, () => {'name': catName, 'color': catColor, 'total': 0.0});
              personIncomeAgg[catId]!['total'] = (personIncomeAgg[catId]!['total'] as double) + amount;
              totalPersonIncomeSum += amount;
            } else {
              incomeAgg.putIfAbsent(catId, () => {'name': catName, 'color': catColor, 'total': 0.0});
              incomeAgg[catId]!['total'] = (incomeAgg[catId]!['total'] as double) + amount;
              totalIncomeSum += amount;
            }
          }
        }
      }

      final List<CategorySpending> categoryData = [];
      final sortedExpense = expenseAgg.entries.toList()..sort((a, b) => b.value['total'].compareTo(a.value['total']));
      for (var entry in sortedExpense) {
        final double amount = entry.value['total'] as double;
        final double pct = totalExpenseSum > 0 ? (amount / totalExpenseSum) * 100 : 0.0;
        categoryData.add(CategorySpending(
          categoryName: entry.value['name'] as String,
          amount: amount,
          percentage: pct,
          colorHex: entry.value['color'] as String,
        ));
      }

      final List<CategorySpending> incomeCategoryData = [];
      final sortedIncome = incomeAgg.entries.toList()..sort((a, b) => b.value['total'].compareTo(a.value['total']));
      for (var entry in sortedIncome) {
        final double amount = entry.value['total'] as double;
        final double pct = totalIncomeSum > 0 ? (amount / totalIncomeSum) * 100 : 0.0;
        incomeCategoryData.add(CategorySpending(
          categoryName: entry.value['name'] as String,
          amount: amount,
          percentage: pct,
          colorHex: entry.value['color'] as String,
        ));
      }

      final List<CategorySpending> personCategoryData = [];
      final sortedPersonExpense = personExpenseAgg.entries.toList()..sort((a, b) => b.value['total'].compareTo(a.value['total']));
      for (var entry in sortedPersonExpense) {
        final double amount = entry.value['total'] as double;
        final double pct = totalPersonExpenseSum > 0 ? (amount / totalPersonExpenseSum) * 100 : 0.0;
        personCategoryData.add(CategorySpending(
          categoryName: entry.value['name'] as String,
          amount: amount,
          percentage: pct,
          colorHex: entry.value['color'] as String,
        ));
      }

      final List<CategorySpending> personIncomeCategoryData = [];
      final sortedPersonIncome = personIncomeAgg.entries.toList()..sort((a, b) => b.value['total'].compareTo(a.value['total']));
      for (var entry in sortedPersonIncome) {
        final double amount = entry.value['total'] as double;
        final double pct = totalPersonIncomeSum > 0 ? (amount / totalPersonIncomeSum) * 100 : 0.0;
        personIncomeCategoryData.add(CategorySpending(
          categoryName: entry.value['name'] as String,
          amount: amount,
          percentage: pct,
          colorHex: entry.value['color'] as String,
        ));
      }

      // 4. Fetch Net Worth Trend Line (last 30 days)
      final List<NetWorthPoint> netWorthData = [];
      final transactions = _ref.read(transactionsProvider).transactions;

      final creditCardAccountIds = accounts
          .where((acc) => acc.type == 'Credit Card')
          .map((acc) => acc.id)
          .whereType<int>()
          .toSet();

      double runningNetWorth = totalBalance;
      netWorthData.add(NetWorthPoint(date: now, amount: runningNetWorth));

      final Map<String, List<Transaction>> txsByDate = {};
      for (var tx in transactions) {
        final dateKey = tx.date.toIso8601String().substring(0, 10);
        txsByDate.putIfAbsent(dateKey, () => []).add(tx);
      }

      DateTime walkDate = DateTime.now();
      for (int i = 0; i < 30; i++) {
        walkDate = walkDate.subtract(const Duration(days: 1));
        final dateKey = walkDate.toIso8601String().substring(0, 10);
        
        final daysTxs = txsByDate[dateKey] ?? [];
        for (var tx in daysTxs) {
          if (creditCardAccountIds.contains(tx.accountId)) {
            continue;
          }
          if (tx.type == 'income') {
            runningNetWorth -= tx.amount;
          } else if (tx.type == 'expense') {
            runningNetWorth += tx.amount;
          }
        }
        netWorthData.add(NetWorthPoint(date: walkDate, amount: runningNetWorth));
      }

      final sortedNetWorth = netWorthData.reversed.toList();

      // Update Home Screen Widget
      try {
        final profile = _ref.read(authProvider).profile;
        final currency = profile?.preferredCurrency ?? 'USD';
        final todaySpendStr = CurrencyFormatter.format(todayExpenses, currency);
        final todayIncomeStr = CurrencyFormatter.format(todayIncome, currency);

        await HomeWidget.saveWidgetData<String>('net_worth', '••••••');
        await HomeWidget.saveWidgetData<String>('today_spend', todaySpendStr);
        await HomeWidget.saveWidgetData<String>('today_income', todayIncomeStr);
        await HomeWidget.updateWidget(
          name: 'MoneyWidgetProvider',
          androidName: 'MoneyWidgetProvider',
        );
      } catch (_) {}

      // E. Calculate Category Trends
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));

      final Map<int, double> rollingSpendMap = {};
      final Map<int, Map<String, double>> historyByCatAndMonth = {};

      for (var row in txRows) {
        final dateStr = row['date'] as String;
        final date = DateTime.tryParse(dateStr) ?? now;
        final catId = row['category_id'] as int;
        final amount = (row['amount'] as num).toDouble();
        final type = row['type'] as String;
        final catType = row['category_type'] as String? ?? 'both';

        if (type == 'expense' && catType != 'person') {
          if (date.isAfter(ninetyDaysAgo)) {
            rollingSpendMap[catId] = (rollingSpendMap[catId] ?? 0.0) + amount;
          }

          if (!dateStr.startsWith(currentMonth)) {
            final monthStr = dateStr.substring(0, 7);
            historyByCatAndMonth.putIfAbsent(catId, () => {});
            historyByCatAndMonth[catId]![monthStr] = (historyByCatAndMonth[catId]![monthStr] ?? 0.0) + amount;
          }
        }
      }

      final Map<int, double> categoryHistoricalAverage = {};
      final Map<String, List<double>> categoryMonthlyHistories = {};

      historyByCatAndMonth.forEach((catId, monthMap) {
        if (monthMap.isNotEmpty) {
          final sum = monthMap.values.reduce((a, b) => a + b);
          categoryHistoricalAverage[catId] = sum / monthMap.length;
          
          final catName = categoryNamesMap[catId] ?? 'Category';
          categoryMonthlyHistories[catName] = monthMap.values.toList();
        }
      });

      final Map<int, double> currentMonthSpendMap = {};
      expenseAgg.forEach((catId, map) {
        currentMonthSpendMap[catId] = map['total'] as double;
      });
      personExpenseAgg.forEach((catId, map) {
        currentMonthSpendMap[catId] = map['total'] as double;
      });

      final List<CategoryTrend> categoryTrendsList = [];
      final int elapsedDays = now.day;
      final int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final double elapsedDaysSafe = elapsedDays > 0 ? elapsedDays.toDouble() : 1.0;

      for (var cat in allCategories) {
        final catId = cat['id'] as int;
        final catName = cat['name'] as String;
        final catType = cat['type'] as String? ?? 'both';
        if (catType == 'person') continue;

        final curSpend = currentMonthSpendMap[catId] ?? 0.0;
        final rollingAvg = (rollingSpendMap[catId] ?? 0.0) / 3.0;
        final histAvg = categoryHistoricalAverage[catId] ?? 0.0;
        final projected = (curSpend / elapsedDaysSafe) * totalDaysInMonth;

        categoryTrendsList.add(CategoryTrend(
          categoryId: catId,
          categoryName: catName,
          monthlyAverage: histAvg,
          threeMonthRollingAverage: rollingAvg,
          projectedMonthEnd: projected,
          currentMonthSpend: curSpend,
        ));
      }

      final profile = _ref.read(authProvider).profile;
      final currency = profile?.preferredCurrency ?? 'USD';

      // Compute AI/ML metrics
      final aiForecast = AiAnalyst.calculateForecast(monthlyData, monthlyExpenses, categoryMonthlyHistories);
      final aiAnomalies = AiAnalyst.detectAnomalies(transactions, categoryNamesMap, currency);

      final List<Map<String, dynamic>> goalsData = await db.query('savings_goal');
      final List<SavingsGoal> goalsList = goalsData.map((map) => SavingsGoal.fromMap(map)).toList();

      double averageSavingsVelocity = 0.0;
      if (monthlyData.isNotEmpty) {
        int count = 0;
        double savingsSum = 0.0;
        for (int i = monthlyData.length - 1; i >= 0 && count < 3; i--) {
          savingsSum += (monthlyData[i].income - monthlyData[i].expense);
          count++;
        }
        if (count > 0) {
          averageSavingsVelocity = savingsSum / count;
        }
      }
      
      final List<double> monthlySavingsHistory = monthlyData.map((e) => e.income - e.expense).toList();
      final aiGoalProjections = AiAnalyst.projectSavingsTimeline(goalsList, averageSavingsVelocity, monthlySavingsHistory);

      final aiRecommendations = AiAnalyst.generateRecommendations(
        transactions, 
        aiForecast.categoryForecasts, 
        monthlyIncome > 0 ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100) : 0.0,
        currency
      );

      final anomalyCount = aiAnomalies.length;
      final transactionCount = transactions.length;
      final last6MonthsIncome = monthlyData.map((e) => e.income).toList();
      
      final List<Map<String, dynamic>> debtData = await db.rawQuery("SELECT SUM(monthly_payment) as total FROM debt_loan");
      final debtPayments = debtData.isNotEmpty ? (debtData.first['total'] as num?)?.toDouble() ?? 0.0 : 0.0;

      final List<Map<String, dynamic>> budgetsData = await db.query('budget', where: 'month = ?', whereArgs: [currentMonth]);
      double totalBudgetLimits = 0.0;
      double exceededAmount = 0.0;
      for (var b in budgetsData) {
        final catId = b['category_id'] as int;
        final limit = (b['limit_amount'] as num).toDouble();
        final spend = currentMonthSpendMap[catId] ?? 0.0;
        totalBudgetLimits += limit;
        if (spend > limit) {
          exceededAmount += (spend - limit);
        }
      }
      final budgetCompliance = totalBudgetLimits > 0 
          ? ((totalBudgetLimits - exceededAmount) / totalBudgetLimits * 100).clamp(0.0, 100.0) 
          : 100.0;

      final healthScore = FinancialHealthCalculator.calculate(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpenses,
        budgetCompliance: budgetCompliance,
        debtPayments: debtPayments,
        last6MonthsIncome: last6MonthsIncome,
        anomalyCount: anomalyCount,
        transactionCount: transactionCount,
      );

      await HealthScoreService.instance.recordScore(healthScore);

      state = AnalyticsState(
        monthlyData: monthlyData,
        categoryData: categoryData,
        incomeCategoryData: incomeCategoryData,
        personCategoryData: personCategoryData,
        personIncomeCategoryData: personIncomeCategoryData,
        netWorthData: sortedNetWorth,
        categoryTrends: categoryTrendsList,
        totalBalance: totalBalance,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        netSavings: monthlyIncome - monthlyExpenses,
        todayIncome: todayIncome,
        todayExpenses: todayExpenses,
        todayMajorExpenseCategory: todayMajorExpenseCategory,
        todayMajorExpenseAmount: todayMajorExpenseAmount,
        todayMajorIncomeCategory: todayMajorIncomeCategory,
        todayMajorIncomeAmount: todayMajorIncomeAmount,
        healthScore: healthScore,
        aiForecast: aiForecast,
        aiAnomalies: aiAnomalies,
        aiGoalProjections: aiGoalProjections,
        aiRecommendations: aiRecommendations,
        isLoading: false,
      );
    } catch (e) {
      state = AnalyticsState(
        monthlyData: [],
        categoryData: [],
        incomeCategoryData: [],
        personCategoryData: [],
        personIncomeCategoryData: [],
        netWorthData: [],
        categoryTrends: [],
        healthScore: 100.0,
        aiAnomalies: [],
        aiGoalProjections: [],
        aiRecommendations: [],
        isLoading: false,
      );
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});

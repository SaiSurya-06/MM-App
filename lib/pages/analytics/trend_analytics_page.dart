import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transactions_provider.dart' hide DateTimeRange;
import '../../providers/savings_goals_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/savings_goal.dart';
import '../../models/budget.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../core/analytics/ai_analyst.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'widgets/overview_tab.dart';
import 'widgets/charts_tab.dart';
import 'widgets/budgets_tab.dart';
import 'widgets/projections_tab.dart';
import 'widgets/merchants_tags_tab.dart';
import 'widgets/monthly_reports_tab.dart';
import 'widgets/trends_tab.dart';

class DerivedAnalyticsValues {
  final double healthScore;
  final double dailyBurnRate;
  final double projectedMonthEndBalance;
  final double runwayDays;
  final double safeToSpendToday;
  final double velocity;
  final double acceleration;
  final String velocityTrendText;
  final double budgetCompliance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double spendThisYearMonth;
  final double spendLastYearMonth;
  final double spendTwoYearsAgoMonth;
  final List<Transaction> filteredTransactions;
  final List<Transaction> thisMonthTxs;
  final Map<int, Category> categoryMap;
  final Map<int, String> categoryNames;
  final double totalBalance;
  final int daysElapsed;
  final int daysRemaining;
  final int daysInMonth;
  final Map<int, double> currentCategorySpends;

  DerivedAnalyticsValues({
    required this.healthScore,
    required this.dailyBurnRate,
    required this.projectedMonthEndBalance,
    required this.runwayDays,
    required this.safeToSpendToday,
    required this.velocity,
    required this.acceleration,
    required this.velocityTrendText,
    required this.budgetCompliance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.spendThisYearMonth,
    required this.spendLastYearMonth,
    required this.spendTwoYearsAgoMonth,
    required this.filteredTransactions,
    required this.thisMonthTxs,
    required this.categoryMap,
    required this.categoryNames,
    required this.totalBalance,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.daysInMonth,
    required this.currentCategorySpends,
  });
}

final analyticsDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final derivedAnalyticsProvider = Provider<DerivedAnalyticsValues>((ref) {
  final analyticsState = ref.watch(analyticsProvider);
  final categoriesState = ref.watch(categoriesProvider);
  final budgetsState = ref.watch(budgetsProvider);
  final transactionsState = ref.watch(transactionsProvider);
  final accountsState = ref.watch(accountsProvider);
  final selectedRange = ref.watch(analyticsDateRangeProvider);

  final transactions = transactionsState.transactions;
  final budgets = budgetsState.budgets;
  final categories = categoriesState.categories;
  final totalBalance = accountsState.accounts.fold(0.0, (sum, a) => sum + a.balance);

  final Map<int, Category> categoryMap = {
    for (var cat in categories) cat.id ?? 0: cat
  };
  final Map<int, String> categoryNames = {
    for (var cat in categories) cat.id ?? 0: cat.name
  };

  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;

  // Filter transactions by custom date range if selected
  var displayTransactions = transactions;
  if (selectedRange != null) {
    displayTransactions = transactions.where((tx) =>
        tx.date.isAfter(selectedRange.start.subtract(const Duration(seconds: 1))) &&
        tx.date.isBefore(selectedRange.end.add(const Duration(days: 1)))).toList();
  }

  // Filter transactions for this month
  final thisMonthTxs = displayTransactions.where((tx) =>
      tx.date.year == currentYear && tx.date.month == currentMonth).toList();

  double monthlyIncome = 0.0;
  double monthlyExpense = 0.0;
  for (var tx in thisMonthTxs) {
    if (tx.type == 'income') {
      monthlyIncome += tx.amount;
    } else if (tx.type == 'expense') {
      monthlyExpense += tx.amount;
    }
  }

  // Category spends for the current month
  final Map<int, double> currentCategorySpends = {};
  for (var tx in thisMonthTxs) {
    final cat = categoryMap[tx.categoryId];
    if (cat?.type == 'person') continue;
    if (tx.type == 'expense') {
      currentCategorySpends[tx.categoryId] = (currentCategorySpends[tx.categoryId] ?? 0.0) + tx.amount;
    }
  }

  // Budget compliance percentage
  double budgetCompliance = 100.0;
  if (budgets.isNotEmpty) {
    int metBudgets = 0;
    for (var b in budgets) {
      final spent = currentCategorySpends[b.categoryId] ?? 0.0;
      if (spent <= b.limitAmount) {
        metBudgets++;
      }
    }
    budgetCompliance = (metBudgets / budgets.length) * 100.0;
  }

  // Debt payments
  double debtPayments = 0.0;
  for (var tx in thisMonthTxs) {
    if (tx.type == 'expense') {
      final catName = categoryNames[tx.categoryId]?.toLowerCase() ?? '';
      if (catName.contains('debt') ||
          catName.contains('loan') ||
          catName.contains('emi') ||
          catName.contains('credit card payment')) {
        debtPayments += tx.amount;
      }
    }
  }

  final last6MonthsIncome = analyticsState.monthlyData.map((d) => d.income).toList();
  if (last6MonthsIncome.isEmpty) {
    last6MonthsIncome.add(monthlyIncome);
  }

  final anomalyCount = analyticsState.aiAnomalies.length;
  final transactionCount = transactions.length;

  final healthScore = FinancialHealthCalculator.calculate(
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    budgetCompliance: budgetCompliance,
    debtPayments: debtPayments,
    last6MonthsIncome: last6MonthsIncome,
    anomalyCount: anomalyCount,
    transactionCount: transactionCount,
  );

  final int daysElapsed = now.day;
  final int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
  final int daysRemaining = daysInMonth - daysElapsed;
  final double dailyBurnRate = daysElapsed > 0 ? (monthlyExpense / daysElapsed) : 0.0;
  final double projectedMonthEndBalance = totalBalance - (dailyBurnRate * daysRemaining);
  final double runwayDays = dailyBurnRate > 0 ? (totalBalance / dailyBurnRate) : double.infinity;

  double remainingBudgetTotal = 0.0;
  if (budgets.isNotEmpty) {
    double totalBudgetLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    double totalSpentInBudgets = 0.0;
    for (var b in budgets) {
      totalSpentInBudgets += currentCategorySpends[b.categoryId] ?? 0.0;
    }
    remainingBudgetTotal = totalBudgetLimit - totalSpentInBudgets;
  }
  final double safeToSpendToday = daysRemaining > 0 
      ? (remainingBudgetTotal > 0 ? remainingBudgetTotal / daysRemaining : 0.0) 
      : 0.0;

  double velocity = 0.0;
  double acceleration = 0.0;
  String velocityTrendText = 'Your spending is stable.';
  final mData = analyticsState.monthlyData;
  if (mData.length >= 2) {
    final currentMonthExpense = mData.last.expense;
    final prevMonthExpense = mData[mData.length - 2].expense;
    velocity = currentMonthExpense - prevMonthExpense;

    if (mData.length >= 3) {
      final prev2MonthExpense = mData[mData.length - 3].expense;
      final prevVelocity = prevMonthExpense - prev2MonthExpense;
      acceleration = velocity - prevVelocity;
    }

    if (acceleration > 50) {
      velocityTrendText = 'Your spending is accelerating. Be careful!';
    } else if (acceleration < -50) {
      velocityTrendText = 'Your spending growth is slowing down. Excellent!';
    } else {
      velocityTrendText = 'Your spending momentum is steady.';
    }
  }

  double spendThisYearMonth = 0.0;
  double spendLastYearMonth = 0.0;
  double spendTwoYearsAgoMonth = 0.0;

  for (var tx in transactions) {
    if (tx.type == 'expense' && tx.date.month == now.month) {
      if (tx.date.year == now.year) {
        spendThisYearMonth += tx.amount;
      } else if (tx.date.year == now.year - 1) {
        spendLastYearMonth += tx.amount;
      } else if (tx.date.year == now.year - 2) {
        spendTwoYearsAgoMonth += tx.amount;
      }
    }
  }

  return DerivedAnalyticsValues(
    healthScore: healthScore,
    dailyBurnRate: dailyBurnRate,
    projectedMonthEndBalance: projectedMonthEndBalance,
    runwayDays: runwayDays,
    safeToSpendToday: safeToSpendToday,
    velocity: velocity,
    acceleration: acceleration,
    velocityTrendText: velocityTrendText,
    budgetCompliance: budgetCompliance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    spendThisYearMonth: spendThisYearMonth,
    spendLastYearMonth: spendLastYearMonth,
    spendTwoYearsAgoMonth: spendTwoYearsAgoMonth,
    filteredTransactions: displayTransactions,
    thisMonthTxs: thisMonthTxs,
    categoryMap: categoryMap,
    categoryNames: categoryNames,
    totalBalance: totalBalance,
    daysElapsed: daysElapsed,
    daysRemaining: daysRemaining,
    daysInMonth: daysInMonth,
    currentCategorySpends: currentCategorySpends,
  );
});

class TrendAnalyticsPage extends ConsumerStatefulWidget {
  const TrendAnalyticsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TrendAnalyticsPage> createState() => _TrendAnalyticsPageState();
}

class _TrendAnalyticsPageState extends ConsumerState<TrendAnalyticsPage> {
  int _activeTab = 0; // 0: Overview, 1: Charts, 2: Budgets & Deltas, 3: Projections, 4: Merchants & Tags, 5: Monthly Reports, 6: Trends
  final GlobalKey _repaintKey = GlobalKey();
  DateTimeRange? _selectedRange;

  // Monte Carlo Cache
  Map<int, double>? _cachedMonteCarlo;
  int _lastTxsLength = 0;
  int _lastGoalsLength = 0;

  Future<void> _shareTabAsImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/money_manager_analytics_section.png');
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'My Financial Analytics Card',
        text: 'Sharing my analytics card from Money Manager!',
      );
    } catch (e) {
      debugPrint('[ShareTabAsImage] Error: $e');
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFE53935),
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      ref.read(analyticsDateRangeProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final budgetsState = ref.watch(budgetsProvider);
    final authState = ref.watch(authProvider);
    final transactionsState = ref.watch(transactionsProvider);
    final goalsState = ref.watch(savingsGoalsProvider);
    final accountsState = ref.watch(accountsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    final bool isLoading = analyticsState.isLoading || 
                           categoriesState.isLoading || 
                           transactionsState.isLoading || 
                           goalsState.isLoading;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advanced Analytics')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE53935)),
        ),
      );
    }

    final transactions = transactionsState.transactions;
    final budgets = budgetsState.budgets;
    final categories = categoriesState.categories;
    final goals = goalsState.goals;
    final totalBalance = accountsState.accounts.fold(0.0, (sum, a) => sum + a.balance);

    // ── Precomputations & Lookups ──────────────────────────────────────────
    final Map<int, Category> categoryMap = {
      for (var cat in categories) cat.id ?? 0: cat
    };
    final Map<int, String> categoryNames = {
      for (var cat in categories) cat.id ?? 0: cat.name
    };

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Filter transactions for this month
    final thisMonthTxs = transactions.where((tx) =>
        tx.date.year == currentYear && tx.date.month == currentMonth).toList();

    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;
    for (var tx in thisMonthTxs) {
      if (tx.type == 'income') {
        monthlyIncome += tx.amount;
      } else if (tx.type == 'expense') {
        monthlyExpense += tx.amount;
      }
    }

    // Category spends for the current month
    final Map<int, double> currentCategorySpends = {};
    for (var tx in thisMonthTxs) {
      final cat = categoryMap[tx.categoryId];
      if (cat?.type == 'person') continue;
      if (tx.type == 'expense') {
        currentCategorySpends[tx.categoryId] = (currentCategorySpends[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }

    // Budget compliance percentage
    double budgetCompliance = 100.0;
    if (budgets.isNotEmpty) {
      int metBudgets = 0;
      for (var b in budgets) {
        final spent = currentCategorySpends[b.categoryId] ?? 0.0;
        if (spent <= b.limitAmount) {
          metBudgets++;
        }
      }
      budgetCompliance = (metBudgets / budgets.length) * 100.0;
    }

    // Debt payments: categories containing 'debt', 'loan', 'emi', or 'credit card payment'
    double debtPayments = 0.0;
    for (var tx in thisMonthTxs) {
      if (tx.type == 'expense') {
        final catName = categoryNames[tx.categoryId]?.toLowerCase() ?? '';
        if (catName.contains('debt') ||
            catName.contains('loan') ||
            catName.contains('emi') ||
            catName.contains('credit card payment')) {
          debtPayments += tx.amount;
        }
      }
    }

    // Last 6 months income stability data
    final last6MonthsIncome = analyticsState.monthlyData.map((d) => d.income).toList();
    if (last6MonthsIncome.isEmpty) {
      last6MonthsIncome.add(monthlyIncome);
    }

    // Anomaly count and transaction count
    final anomalyCount = analyticsState.aiAnomalies.length;
    final transactionCount = transactions.length;

    // 1. Calculate Financial Health Score
    final healthScore = FinancialHealthCalculator.calculate(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      budgetCompliance: budgetCompliance,
      debtPayments: debtPayments,
      last6MonthsIncome: last6MonthsIncome,
      anomalyCount: anomalyCount,
      transactionCount: transactionCount,
    );

    // 2. Burn Rate calculations
    final int daysElapsed = now.day;
    final int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final int daysRemaining = daysInMonth - daysElapsed;
    final double dailyBurnRate = daysElapsed > 0 ? (monthlyExpense / daysElapsed) : 0.0;
    final double projectedMonthEndBalance = totalBalance - (dailyBurnRate * daysRemaining);
    final double runwayDays = dailyBurnRate > 0 ? (totalBalance / dailyBurnRate) : double.infinity;

    double remainingBudgetTotal = 0.0;
    if (budgets.isNotEmpty) {
      double totalBudgetLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
      double totalSpentInBudgets = 0.0;
      for (var b in budgets) {
        totalSpentInBudgets += currentCategorySpends[b.categoryId] ?? 0.0;
      }
      remainingBudgetTotal = totalBudgetLimit - totalSpentInBudgets;
    }
    final double safeToSpendToday = daysRemaining > 0 
        ? (remainingBudgetTotal > 0 ? remainingBudgetTotal / daysRemaining : 0.0) 
        : 0.0;

    // 3. Velocity and Acceleration
    double velocity = 0.0;
    double acceleration = 0.0;
    String velocityTrendText = 'Your spending is stable.';
    final mData = analyticsState.monthlyData;
    if (mData.length >= 2) {
      final currentMonthExpense = mData.last.expense;
      final prevMonthExpense = mData[mData.length - 2].expense;
      velocity = currentMonthExpense - prevMonthExpense;

      if (mData.length >= 3) {
        final prev2MonthExpense = mData[mData.length - 3].expense;
        final prevVelocity = prevMonthExpense - prev2MonthExpense;
        acceleration = velocity - prevVelocity;
      }

      if (acceleration > 50) {
        velocityTrendText = 'Your spending is accelerating. Be careful!';
      } else if (acceleration < -50) {
        velocityTrendText = 'Your spending growth is slowing down. Excellent!';
      } else {
        velocityTrendText = 'Your spending momentum is steady.';
      }
    }

    // YoY Spending Comparison (unfiltered transactions)
    final currentYearVal = now.year;
    final currentMonthVal = now.month;

    double spendThisYearMonth = 0.0;
    double spendLastYearMonth = 0.0;
    double spendTwoYearsAgoMonth = 0.0;

    for (var tx in transactionsState.transactions) {
      if (tx.type == 'expense' && tx.date.month == currentMonthVal) {
        if (tx.date.year == currentYearVal) {
          spendThisYearMonth += tx.amount;
        } else if (tx.date.year == currentYearVal - 1) {
          spendLastYearMonth += tx.amount;
        } else if (tx.date.year == currentYearVal - 2) {
          spendTwoYearsAgoMonth += tx.amount;
        }
      }
    }

    // Filter transactions by custom date range if selected
    var displayTransactions = transactions;
    if (_selectedRange != null) {
      displayTransactions = transactions.where((tx) =>
          tx.date.isAfter(_selectedRange!.start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_selectedRange!.end.add(const Duration(days: 1)))).toList();
    }

    // Recalculate thisMonthTxs, monthlyIncome, monthlyExpense based on filtered list for display
    final displayThisMonthTxs = displayTransactions.where((tx) =>
        tx.date.year == currentYear && tx.date.month == currentMonth).toList();

    double displayMonthlyIncome = 0.0;
    double displayMonthlyExpense = 0.0;
    for (var tx in displayThisMonthTxs) {
      if (tx.type == 'income') {
        displayMonthlyIncome += tx.amount;
      } else if (tx.type == 'expense') {
        displayMonthlyExpense += tx.amount;
      }
    }

    // 4. Cached Monte Carlo simulation to avoid lag on sliders/tab switches
    final thisMonthSavings = monthlyIncome - monthlyExpense;
    if (_cachedMonteCarlo == null || 
        transactions.length != _lastTxsLength || 
        goals.length != _lastGoalsLength) {
      _cachedMonteCarlo = _calculateMonteCarlo(goals, mData, thisMonthSavings);
      _lastTxsLength = transactions.length;
      _lastGoalsLength = goals.length;
    }
    final monteCarloChances = _cachedMonteCarlo!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            const Text('Advanced Analytics'),
          ],
        ),
      ),
      body: PremiumBackground(
        child: TweenAnimationBuilder<double>(
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
               // Date Range Selector Banner / Share Action Bar
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     FilterChip(
                       avatar: Icon(Icons.date_range, size: 16, color: _selectedRange != null ? Colors.white : Colors.grey),
                       label: Text(
                         _selectedRange == null 
                             ? "Filter by Date Range" 
                             : "${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}",
                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                       ),
                       onSelected: (_) => _selectCustomDateRange(),
                       selected: _selectedRange != null,
                       selectedColor: const Color(0xFFE53935),
                     ),
                     if (_selectedRange != null)
                       IconButton(
                         icon: const Icon(Icons.clear, size: 18),
                         onPressed: () {
                           setState(() {
                             _selectedRange = null;
                           });
                           ref.read(analyticsDateRangeProvider.notifier).state = null;
                         },
                         tooltip: 'Reset Filter',
                       ),
                     const Spacer(),
                     IconButton(
                       icon: const Icon(Icons.share, size: 18),
                       onPressed: _shareTabAsImage,
                       tooltip: 'Share current view as image',
                     ),
                   ],
                 ),
               ),
               // Pill tabs selector
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTabPill(0, 'Overview', Icons.analytics_outlined),
                    _buildTabPill(1, 'Charts', Icons.bar_chart_outlined),
                    _buildTabPill(2, 'Budgets & MoM', Icons.compare_arrows_outlined),
                    _buildTabPill(3, 'Projections', Icons.timeline_outlined),
                    _buildTabPill(4, 'Merchants & Tags', Icons.tag_outlined),
                    _buildTabPill(5, 'Monthly Reports', Icons.picture_as_pdf_outlined),
                    _buildTabPill(6, 'Trends', Icons.trending_up),
                  ],
                ),
              ),

              // Active Tab View (Wrapped inside solid container and RepaintBoundary for Sharing)
              Expanded(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    color: isDark ? const Color(0xFF0F0F1A) : Colors.grey[100],
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: () {
                        switch (_activeTab) {
                          case 0:
                            return const OverviewTab();
                          case 1:
                            return const ChartsTab();
                          case 2:
                            return const BudgetsTab();
                          case 3:
                            return const ProjectionsTab();
                          case 4:
                            return const MerchantsTagsTab();
                          case 5:
                            return const MonthlyReportsTab();
                          case 6:
                            return const TrendsTab();
                          default:
                            return const SizedBox.shrink();
                        }
                      }(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final active = _activeTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: active,
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeTab = index);
          }
        },
        selectedColor: const Color(0xFFE53935),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.04),
        labelStyle: TextStyle(
          color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Map<int, double> _calculateMonteCarlo(List<SavingsGoal> goals, List<MonthlyComparison> mData, double thisMonthSavings) {
    final Map<int, double> results = {};
    final random = math.Random();
    
    List<double> savingsDist = mData.map((d) => d.income - d.expense).toList();
    if (savingsDist.isEmpty) {
      savingsDist.add(thisMonthSavings);
    }
    if (savingsDist.every((s) => s <= 0)) {
      savingsDist = [thisMonthSavings, thisMonthSavings * 0.8, thisMonthSavings * 1.2];
    }

    final now = DateTime.now();

    for (var goal in goals) {
      if (goal.id == null) continue;
      final remaining = goal.targetAmount - goal.currentAmount;
      if (remaining <= 0) {
        results[goal.id!] = 1.0;
        continue;
      }

      int targetMonths = 12;
      if (goal.targetDate != null) {
        targetMonths = ((goal.targetDate!.year - now.year) * 12) + (goal.targetDate!.month - now.month);
        if (targetMonths <= 0) targetMonths = 1;
      }

      int successes = 0;
      for (int trial = 0; trial < 1000; trial++) {
        double current = goal.currentAmount;
        for (int m = 0; m < targetMonths; m++) {
          double sample = savingsDist[random.nextInt(savingsDist.length)];
          sample *= (0.9 + random.nextDouble() * 0.2);
          current += sample;
        }
        if (current >= goal.targetAmount) {
          successes++;
        }
      }
      results[goal.id!] = successes / 1000.0;
    }
    return results;
  }
}

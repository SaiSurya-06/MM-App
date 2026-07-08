import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/database/daos/budget_dao.dart';
import '../core/notifications/notification_service.dart';
import '../models/budget.dart';

class BudgetsState {
  final List<Budget> budgets;
  final Map<int, double> categorySpendings; // categoryId -> spendAmount
  final Map<int, double> categoryRollovers; // categoryId -> rolloverAmount
  final String selectedMonth; // 'YYYY-MM'
  final bool isLoading;
  final String? errorMessage;

  BudgetsState({
    required this.budgets,
    required this.categorySpendings,
    this.categoryRollovers = const {},
    required this.selectedMonth,
    this.isLoading = false,
    this.errorMessage,
  });

  BudgetsState copyWith({
    List<Budget>? budgets,
    Map<int, double>? categorySpendings,
    Map<int, double>? categoryRollovers,
    String? selectedMonth,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      categorySpendings: categorySpendings ?? this.categorySpendings,
      categoryRollovers: categoryRollovers ?? this.categoryRollovers,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BudgetsNotifier extends StateNotifier<BudgetsState> {
  final BudgetDao _budgetDao = BudgetDao();
  BudgetsNotifier(Ref ref)
      : super(BudgetsState(
          budgets: [],
          categorySpendings: {},
          selectedMonth: DateTime.now().toIso8601String().substring(0, 7),
          isLoading: true,
        )) {
    loadBudgetsForMonth(state.selectedMonth);
  }

  Future<void> loadBudgetsForMonth(String month) async {
    try {
      state = state.copyWith(isLoading: true, selectedMonth: month);
      final budgets = await _budgetDao.getBudgetsForMonth(month);
      
      // Calculate category spendings for this month (default monthly ones)
      final spendings = await _calculateSpendings(month);
      
      // Override or calculate period-specific spending for budgets
      for (var b in budgets) {
        spendings[b.categoryId] = await _calculateSpentForBudget(b, month);
      }

      // Calculate rollovers
      final rollovers = <int, double>{};
      for (var b in budgets) {
        rollovers[b.categoryId] = await _calculateRollover(b.categoryId, month);
      }

      // Overall Budget spending cap logic
      final totalBudgetCatId = await _getOrCreateTotalBudgetCategoryId();
      final overallSpent = await _calculateOverallSpent(month);
      spendings[totalBudgetCatId] = overallSpent;
      
      state = BudgetsState(
        budgets: budgets,
        categorySpendings: spendings,
        categoryRollovers: rollovers,
        selectedMonth: month,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load budgets: $e',
      );
    }
  }

  Future<void> loadBudgetsForCurrentMonth() async {
    await loadBudgetsForMonth(state.selectedMonth);
  }

  void selectMonth(String month) {
    loadBudgetsForMonth(month);
  }

  Future<bool> setBudget(
    int categoryId,
    double limitAmount, {
    String recurrence = 'monthly',
    String? groupName,
  }) async {
    try {
      final month = state.selectedMonth;
      final existing = await _budgetDao.getBudgetForCategoryAndMonth(categoryId, month);

      if (existing != null) {
        final updated = existing.copyWith(
          limitAmount: limitAmount,
          recurrence: recurrence,
          groupName: groupName,
        );
        await _budgetDao.updateBudget(updated);
      } else {
        final budget = Budget(
          categoryId: categoryId,
          month: month,
          limitAmount: limitAmount,
          recurrence: recurrence,
          groupName: groupName,
        );
        await _budgetDao.insertBudget(budget);
      }

      await loadBudgetsForMonth(month);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      await _budgetDao.deleteBudget(id);
      await loadBudgetsForMonth(state.selectedMonth);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete budget: $e');
      return false;
    }
  }

  /// Calculates total expense spending per category for a given month
  Future<Map<int, double>> _calculateSpendings(String month) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND strftime('%Y-%m', date) = ?
      GROUP BY category_id
    ''', [month]);

    final Map<int, double> spendings = {};
    for (var row in results) {
      spendings[row['category_id'] as int] = (row['total'] as num).toDouble();
    }
    return spendings;
  }

  Future<double> _calculateSpentForBudget(Budget budget, String selectedMonth) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final currentMonthStr = now.toIso8601String().substring(0, 7);
    
    if (selectedMonth == currentMonthStr) {
      if (budget.recurrence == 'weekly') {
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final startOfWeekStr = startOfWeek.toIso8601String().substring(0, 10);
        final result = await db.rawQuery('''
          SELECT SUM(amount) as total
          FROM transaction_log
          WHERE type = 'expense' AND category_id = ? AND date >= ?
        ''', [budget.categoryId, startOfWeekStr]);
        return (result.first['total'] as num?)?.toDouble() ?? 0.0;
      } else if (budget.recurrence == 'bi-weekly') {
        final startOfBiWeekly = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14));
        final startOfBiWeeklyStr = startOfBiWeekly.toIso8601String().substring(0, 10);
        final result = await db.rawQuery('''
          SELECT SUM(amount) as total
          FROM transaction_log
          WHERE type = 'expense' AND category_id = ? AND date >= ?
        ''', [budget.categoryId, startOfBiWeeklyStr]);
        return (result.first['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    
    // Default/fallback for monthly or historical weekly/bi-weekly (use whole month)
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND category_id = ? AND strftime('%Y-%m', date) = ?
    ''', [budget.categoryId, selectedMonth]);
    
    double totalMonthSpent = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    if (budget.recurrence == 'weekly') {
      return totalMonthSpent / 4.33;
    } else if (budget.recurrence == 'bi-weekly') {
      return totalMonthSpent / 2.16;
    }
    return totalMonthSpent;
  }

  Future<double> _calculateRollover(int categoryId, String currentMonthStr) async {
    try {
      final db = await AppDatabase.instance.database;
      // Get previous month
      final parts = currentMonthStr.split('-');
      if (parts.length != 2) return 0.0;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final prevMonthDate = DateTime(year, month - 1, 1);
      final prevMonthStr = prevMonthDate.toIso8601String().substring(0, 7);

      // Get previous month budget
      final prevBudgetResult = await db.query(
        'budget',
        where: 'category_id = ? AND month = ?',
        whereArgs: [categoryId, prevMonthStr],
      );
      if (prevBudgetResult.isEmpty) return 0.0;

      final limit = (prevBudgetResult.first['limit_amount'] as num).toDouble();

      // Get previous month spent
      final spentResult = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM transaction_log
        WHERE type = 'expense' AND category_id = ? AND strftime('%Y-%m', date) = ?
      ''', [categoryId, prevMonthStr]);

      final spent = (spentResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      return limit - spent;
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> _getOrCreateTotalBudgetCategoryId() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('category', where: 'name = ?', whereArgs: ['Total Budget']);
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return await db.insert('category', {
      'name': 'Total Budget',
      'icon': 'monetization_on',
      'color': 'E53935',
      'is_default': 1,
      'type': 'expense'
    });
  }

  Future<double> _calculateOverallSpent(String month) async {
    final db = await AppDatabase.instance.database;
    final totalBudgetCatId = await _getOrCreateTotalBudgetCategoryId();
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND category_id != ? AND strftime('%Y-%m', date) = ?
    ''', [totalBudgetCatId, month]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<int, double>> getAutoSuggestedLimits() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final currentMonth = now.toIso8601String().substring(0, 7);

    // Get 3 months average spending per category
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total_sum, COUNT(DISTINCT strftime('%Y-%m', date)) as months_count
      FROM transaction_log
      WHERE type = 'expense' AND strftime('%Y-%m', date) < ?
      GROUP BY category_id
    ''', [currentMonth]);

    final Map<int, double> suggestions = {};
    for (var row in results) {
      final catId = row['category_id'] as int;
      final sum = (row['total_sum'] as num).toDouble();
      final count = (row['months_count'] as num).toInt();
      if (count > 0) {
        suggestions[catId] = (sum / count).roundToDouble();
      }
    }
    return suggestions;
  }

  /// Checks if adding a new transaction triggers a budget threshold alert (80% or 100%).
  /// This fires immediately when a transaction is added.
  Future<void> checkBudgetThreshold({
    required int categoryId,
    required double txAmount,
    required DateTime txDate,
    required String txType,
  }) async {
    if (txType != 'expense') return; // Only expenses impact budget

    final month = txDate.toIso8601String().substring(0, 7);
    final budget = await _budgetDao.getBudgetForCategoryAndMonth(categoryId, month);
    if (budget == null) return;

    final db = await AppDatabase.instance.database;
    
    // Calculate total spend in this category *before* adding this transaction
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND category_id = ? AND strftime('%Y-%m', date) = ?
    ''', [categoryId, month]);

    final double currentSpend = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // We assume the new transaction has already been added to the DB before calling this,
    // or we are running it immediately after adding.
    // If it's already added, currentSpend is the *new* spend.
    // Let's assume currentSpend contains the transaction amount (i.e. it was already inserted)
    final double previousSpend = currentSpend - txAmount;
    final double limit = budget.limitAmount;

    final double previousPercent = (previousSpend / limit) * 100;
    final double currentPercent = (currentSpend / limit) * 100;

    // Get category name
    final List<Map<String, dynamic>> catResult = await db.query(
      'category',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    final categoryName = catResult.isNotEmpty ? catResult.first['name'] as String : 'Category';

    // Fire alert if crossing 80% threshold
    if (previousPercent < 80.0 && currentPercent >= 80.0 && currentPercent < 100.0) {
      await NotificationService.instance.showBudgetAlert(categoryName, 80.0);
    }
    // Fire alert if crossing 100% threshold
    else if (previousPercent < 100.0 && currentPercent >= 100.0) {
      await NotificationService.instance.showBudgetAlert(categoryName, 100.0);
    }

    // Refresh budgets state to update UI
    await loadBudgetsForCurrentMonth();
  }

  Future<void> applyOptimizations(List<dynamic> suggestions) async {
    try {
      final month = state.selectedMonth;
      for (var s in suggestions) {
        final db = await AppDatabase.instance.database;
        final catResult = await db.query(
          'category',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [s.categoryName],
        );
        if (catResult.isEmpty) continue;
        final categoryId = catResult.first['id'] as int;

        final existing = await _budgetDao.getBudgetForCategoryAndMonth(categoryId, month);
        if (existing != null) {
          final newLimit = (existing.limitAmount - s.reductionAmount).clamp(0.0, double.infinity);
          final updated = existing.copyWith(limitAmount: newLimit);
          await _budgetDao.updateBudget(updated);
        }
      }
      await loadBudgetsForMonth(month);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to apply optimizations: $e');
    }
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, BudgetsState>((ref) {
  return BudgetsNotifier(ref);
});

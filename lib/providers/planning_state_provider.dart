import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../core/database/database.dart';
import '../core/database/daos/weekly_checkin_dao.dart';
import 'budgets_provider.dart';
import 'categories_provider.dart';
import '../models/category.dart';

class PlanningState {
  final int currentStep; // 0: income, 1: strategy, 2: group slider percentages, 3: category drill-down, 4: summary & confirm
  final double salary;
  final double otherIncome;
  final String strategy; // '50/30/20', 'zero_based', 'envelope', 'custom', 'ai'
  
  // Percentages (Needs, Wants, Savings, Investments, Emergency)
  final double needsPct;
  final double wantsPct;
  final double savingsPct;
  final double investmentsPct;
  final double emergencyPct;

  // Category Budgets: Category Name -> budget amount
  final Map<String, double> categoryBudgets;
  
  // Custom Category Groups: Category Name -> Group Name ('Needs', 'Wants', 'Savings', 'Investments')
  final Map<String, String> customCategoryGroups;
  
  final List<WeeklyCheckin> checkins;
  final bool isCompleted; // whether month plan exists
  final bool isLoading;
  final String? errorMessage;
  final String selectedMonth;

  PlanningState({
    this.currentStep = 0,
    this.salary = 0.0,
    this.otherIncome = 0.0,
    this.strategy = '50/30/20',
    this.needsPct = 50.0,
    this.wantsPct = 30.0,
    this.savingsPct = 20.0,
    this.investmentsPct = 0.0,
    this.emergencyPct = 0.0,
    this.categoryBudgets = const {},
    this.customCategoryGroups = const {},
    this.checkins = const [],
    this.isCompleted = false,
    this.isLoading = false,
    this.errorMessage,
    required this.selectedMonth,
  });

  PlanningState copyWith({
    int? currentStep,
    double? salary,
    double? otherIncome,
    String? strategy,
    double? needsPct,
    double? wantsPct,
    double? savingsPct,
    double? investmentsPct,
    double? emergencyPct,
    Map<String, double>? categoryBudgets,
    Map<String, String>? customCategoryGroups,
    List<WeeklyCheckin>? checkins,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
    String? selectedMonth,
  }) {
    return PlanningState(
      currentStep: currentStep ?? this.currentStep,
      salary: salary ?? this.salary,
      otherIncome: otherIncome ?? this.otherIncome,
      strategy: strategy ?? this.strategy,
      needsPct: needsPct ?? this.needsPct,
      wantsPct: wantsPct ?? this.wantsPct,
      savingsPct: savingsPct ?? this.savingsPct,
      investmentsPct: investmentsPct ?? this.investmentsPct,
      emergencyPct: emergencyPct ?? this.emergencyPct,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      customCategoryGroups: customCategoryGroups ?? this.customCategoryGroups,
      checkins: checkins ?? this.checkins,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class PlanningStateNotifier extends StateNotifier<PlanningState> {
  final Ref _ref;
  final WeeklyCheckinDao _checkinDao = WeeklyCheckinDao();

  PlanningStateNotifier(this._ref)
      : super(PlanningState(
          selectedMonth: DateTime.now().toIso8601String().substring(0, 7),
        )) {
    loadPlanningMeta();
    loadWeeklyCheckins();
  }

  Future<void> changeMonth(String month) async {
    state = state.copyWith(
      selectedMonth: month,
      isCompleted: false,
    );
    await loadPlanningMeta();
  }

  Future<void> loadPlanningMeta() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        'planning_meta',
        where: 'month = ?',
        whereArgs: [state.selectedMonth],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        
        // Also load planned category budgets for this month
        final budgets = _ref.read(budgetsProvider).budgets;
        final categories = _ref.read(categoriesProvider).categories;
        
        final Map<String, double> categoryBudgets = {};
        final Map<String, String> customCategoryGroups = {};
        for (var b in budgets) {
          final cat = categories.firstWhere((c) => c.id == b.categoryId, orElse: () => const Category(id: -99, name: 'Unknown', icon: '', color: '', isDefault: false));
          if (cat.id != -99) {
            categoryBudgets[cat.name] = b.limitAmount;
            if (b.groupName != null) {
              customCategoryGroups[cat.name] = b.groupName!;
            }
          }
        }

        state = state.copyWith(
          salary: (row['estimated_income'] as num).toDouble(),
          strategy: row['strategy'] as String,
          needsPct: (row['needs_pct'] as num).toDouble(),
          wantsPct: (row['wants_pct'] as num).toDouble(),
          savingsPct: (row['savings_pct'] as num).toDouble(),
          investmentsPct: (row['investments_pct'] as num).toDouble(),
          emergencyPct: (row['emergency_pct'] as num).toDouble(),
          categoryBudgets: categoryBudgets,
          customCategoryGroups: customCategoryGroups,
          isCompleted: row['is_completed'] == 1,
          isLoading: false,
        );
      } else {
        // Fallback: Check if budgets exist in existing budget table for this month, if so mark isCompleted
        final budgets = _ref.read(budgetsProvider).budgets;
        if (budgets.isNotEmpty) {
          state = state.copyWith(isCompleted: true, isLoading: false);
        } else {
          state = state.copyWith(isCompleted: false, isLoading: false);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load planning data: $e');
    }
  }

  Future<void> loadWeeklyCheckins() async {
    try {
      final list = await _checkinDao.getAllCheckins();
      state = state.copyWith(checkins: list);
    } catch (e, stackTrace) {
      debugPrint('Silent error loading weekly checkins in PlanningNotifier.loadWeeklyCheckins: $e\n$stackTrace');
    }
  }

  void updateSalary(double amount) => state = state.copyWith(salary: amount);
  void updateOtherIncome(double amount) => state = state.copyWith(otherIncome: amount);
  
  void selectStrategy(String strategy) {
    double n = 50.0, w = 30.0, s = 20.0, inv = 0.0, em = 0.0;
    if (strategy == '50/30/20') {
      n = 50.0; w = 30.0; s = 20.0; inv = 0.0; em = 0.0;
    } else if (strategy == 'zero_based') {
      n = 60.0; w = 20.0; s = 10.0; inv = 10.0; em = 0.0;
    } else if (strategy == 'envelope') {
      n = 45.0; w = 25.0; s = 15.0; inv = 10.0; em = 5.0;
    }
    state = state.copyWith(
      strategy: strategy,
      needsPct: n,
      wantsPct: w,
      savingsPct: s,
      investmentsPct: inv,
      emergencyPct: em,
    );
  }

  void updatePercentages({
    double? needs,
    double? wants,
    double? savings,
    double? investments,
    double? emergency,
  }) {
    state = state.copyWith(
      needsPct: needs ?? state.needsPct,
      wantsPct: wants ?? state.wantsPct,
      savingsPct: savings ?? state.savingsPct,
      investmentsPct: investments ?? state.investmentsPct,
      emergencyPct: emergency ?? state.emergencyPct,
    );
  }

  void updateCategoryBudget(String name, double amount) {
    final Map<String, double> updated = Map.from(state.categoryBudgets);
    updated[name] = amount;
    state = state.copyWith(categoryBudgets: updated);
  }

  void removeCategoryBudget(String name) {
    final Map<String, double> updated = Map.from(state.categoryBudgets);
    updated.remove(name);
    final Map<String, String> updatedGroups = Map.from(state.customCategoryGroups);
    updatedGroups.remove(name);
    state = state.copyWith(categoryBudgets: updated, customCategoryGroups: updatedGroups);
  }

  void renameCategoryBudget(String oldName, String newName) {
    final Map<String, double> updated = Map.from(state.categoryBudgets);
    if (updated.containsKey(oldName)) {
      final val = updated.remove(oldName)!;
      updated[newName] = val;
    }
    final Map<String, String> updatedGroups = Map.from(state.customCategoryGroups);
    if (updatedGroups.containsKey(oldName)) {
      final grp = updatedGroups.remove(oldName)!;
      updatedGroups[newName] = grp;
    }
    state = state.copyWith(categoryBudgets: updated, customCategoryGroups: updatedGroups);
  }

  void setCustomCategoryGroup(String name, String groupName) {
    final Map<String, String> updatedGroups = Map.from(state.customCategoryGroups);
    updatedGroups[name] = groupName;
    state = state.copyWith(customCategoryGroups: updatedGroups);
  }

  void setStep(int step) => state = state.copyWith(currentStep: step);

  Future<void> commitPlanToDatabase() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = await AppDatabase.instance.database;
      
      // 1. Commit planning meta
      await db.insert(
        'planning_meta',
        {
          'month': state.selectedMonth,
          'estimated_income': state.salary + state.otherIncome,
          'strategy': state.strategy,
          'needs_pct': state.needsPct,
          'wants_pct': state.wantsPct,
          'savings_pct': state.savingsPct,
          'investments_pct': state.investmentsPct,
          'emergency_pct': state.emergencyPct,
          'is_completed': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Commit category budget limits
      final budgetsNotifier = _ref.read(budgetsProvider.notifier);

      for (var entry in state.categoryBudgets.entries) {
        final catName = entry.key;
        final amount = entry.value;

        // Try to find category ID
        final currentCategories = _ref.read(categoriesProvider).categories;
        var cat = currentCategories.firstWhere(
          (c) => c.name.toLowerCase() == catName.toLowerCase(),
          orElse: () => const Category(id: -99, name: '', icon: '', color: '', isDefault: false),
        );

        int? catId;
        if (cat.id == -99) {
          // Fallback: query database directly by name to prevent duplicates due to asynchronous latency
          final dbResult = await db.query('category', where: 'LOWER(name) = ?', whereArgs: [catName.toLowerCase()]);
          if (dbResult.isNotEmpty) {
            catId = dbResult.first['id'] as int;
          } else {
            // Only add if it does not exist anywhere in the database
            final newCat = Category(
              name: catName,
              icon: 'account_balance_wallet',
              color: '607D8B',
              isDefault: false,
              type: 'expense',
            );
            catId = await _ref.read(categoriesProvider.notifier).addCategory(newCat);
          }
        } else {
          catId = cat.id;
        }

        if (catId != null) {
          final group = state.customCategoryGroups[catName] ?? _classifyToGroup(catName);
          await budgetsNotifier.setBudget(
            catId,
            amount,
            recurrence: 'monthly',
            groupName: group,
          );
        }
      }

      state = state.copyWith(isCompleted: true, isLoading: false, currentStep: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save your money plan: $e');
    }
  }

  String _classifyToGroup(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('rent') || name.contains('bill') || name.contains('utility') || name.contains('utilities') || name.contains('electricity') || name.contains('internet') || name.contains('water') || name.contains('insurance')) {
      return 'Needs';
    }
    if (name.contains('food') || name.contains('shopping') || name.contains('entertainment') || name.contains('dining') || name.contains('movie') || name.contains('travel')) {
      return 'Wants';
    }
    if (name.contains('saving') || name.contains('emergency')) {
      return 'Savings';
    }
    if (name.contains('invest') || name.contains('stock') || name.contains('mutual')) {
      return 'Investments';
    }
    return 'Wants';
  }

  Future<void> submitWeeklyCheckin(String mood, String? tags, String? notes) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Calculate current Sunday date
      final now = DateTime.now();
      final sunday = now.add(Duration(days: 7 - now.weekday));
      final sundayStr = sunday.toIso8601String().substring(0, 10);

      final checkin = WeeklyCheckin(
        weekEndDate: sundayStr,
        mood: mood,
        reasonTags: tags,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _checkinDao.insertCheckin(checkin);
      await loadWeeklyCheckins();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to submit checkin: $e');
    }
  }

  void resetPlan() {
    state = state.copyWith(
      isCompleted: false,
      currentStep: 0,
      salary: 0.0,
      otherIncome: 0.0,
      strategy: '50/30/20',
      needsPct: 50.0,
      wantsPct: 30.0,
      savingsPct: 20.0,
      investmentsPct: 0.0,
      emergencyPct: 0.0,
      categoryBudgets: {},
    );
  }
}

final planningStateProvider = StateNotifierProvider<PlanningStateNotifier, PlanningState>((ref) {
  return PlanningStateNotifier(ref);
});

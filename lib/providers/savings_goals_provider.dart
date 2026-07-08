import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/database/daos/savings_goal_dao.dart';
import '../models/savings_goal.dart';
import 'accounts_provider.dart';
import 'transactions_provider.dart';

class SavingsGoalsState {
  final List<SavingsGoal> goals;
  final bool isLoading;
  final String? errorMessage;

  SavingsGoalsState({
    required this.goals,
    this.isLoading = false,
    this.errorMessage,
  });

  SavingsGoalsState copyWith({
    List<SavingsGoal>? goals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SavingsGoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SavingsGoalsNotifier extends StateNotifier<SavingsGoalsState> {
  final SavingsGoalDao _savingsGoalDao = SavingsGoalDao();
  final Ref _ref;

  SavingsGoalsNotifier(this._ref) : super(SavingsGoalsState(goals: [], isLoading: true)) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      state = state.copyWith(isLoading: true);
      final goals = await _savingsGoalDao.getAllSavingsGoals();
      state = SavingsGoalsState(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load savings goals: $e');
    }
  }

  Future<bool> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    required String color,
    required String icon,
  }) async {
    try {
      final sg = SavingsGoal(
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
        color: color,
        icon: icon,
        createdAt: DateTime.now(),
      );
      await _savingsGoalDao.insertSavingsGoal(sg);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add savings goal: $e');
      return false;
    }
  }

  Future<bool> updateGoal(SavingsGoal goal) async {
    try {
      await _savingsGoalDao.updateSavingsGoal(goal);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update savings goal: $e');
      return false;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await _savingsGoalDao.deleteSavingsGoal(id);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete savings goal: $e');
      return false;
    }
  }

  Future<bool> addContribution({
    required int goalId,
    required int fromAccountId,
    required double amount,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final goal = state.goals.firstWhere((g) => g.id == goalId);

      await db.transaction((txn) async {
        // 1. Subtract balance from account
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [amount, fromAccountId],
        );
        // 2. Add current_amount to goal
        await txn.rawUpdate(
          'UPDATE savings_goal SET current_amount = current_amount + ? WHERE id = ?',
          [amount, goalId],
        );
        // 3. Insert transaction log
        await txn.insert('transaction_log', {
          'account_id': fromAccountId,
          'category_id': 8, // Category 'Other'
          'title': 'Savings: ${goal.name}',
          'amount': amount,
          'type': 'expense',
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'note': 'Contribution to savings goal "${goal.name}".',
          'recurrence': 'none',
          'is_private': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      // Reload databases and refresh states
      await loadGoals();
      _ref.read(accountsProvider.notifier).loadAccounts();
      _ref.read(transactionsProvider.notifier).loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to record contribution: $e');
      return false;
    }
  }

  Future<bool> withdrawFunds({
    required int goalId,
    required int toAccountId,
    required double amount,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final goal = state.goals.firstWhere((g) => g.id == goalId);

      await db.transaction((txn) async {
        // 1. Add balance to account
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [amount, toAccountId],
        );
        // 2. Subtract current_amount from goal
        await txn.rawUpdate(
          'UPDATE savings_goal SET current_amount = current_amount - ? WHERE id = ?',
          [amount, goalId],
        );
        // 3. Insert transaction log
        await txn.insert('transaction_log', {
          'account_id': toAccountId,
          'category_id': 8, // Category 'Other'
          'title': 'Withdrawal: ${goal.name}',
          'amount': amount,
          'type': 'income',
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'note': 'Withdrawal from savings goal "${goal.name}".',
          'recurrence': 'none',
          'is_private': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      // Reload databases and refresh states
      await loadGoals();
      _ref.read(accountsProvider.notifier).loadAccounts();
      _ref.read(transactionsProvider.notifier).loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to record withdrawal: $e');
      return false;
    }
  }
}

final savingsGoalsProvider = StateNotifierProvider<SavingsGoalsNotifier, SavingsGoalsState>((ref) {
  return SavingsGoalsNotifier(ref);
});

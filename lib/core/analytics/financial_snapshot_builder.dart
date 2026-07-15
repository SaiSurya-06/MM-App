import '../database/daos/transaction_dao.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/budget_dao.dart';
import '../database/daos/savings_goal_dao.dart';
import '../database/daos/debt_loan_dao.dart';
import '../database/daos/account_dao.dart';
import '../database/database.dart';
import 'financial_snapshot.dart';
import 'package:flutter/foundation.dart';

class FinancialSnapshotBuilder {
  final TransactionDao _transactionDao = TransactionDao();
  final CategoryDao _categoryDao = CategoryDao();
  final BudgetDao _budgetDao = BudgetDao();
  final SavingsGoalDao _savingsGoalDao = SavingsGoalDao();
  final DebtLoanDao _debtLoanDao = DebtLoanDao();
  final AccountDao _accountDao = AccountDao();

  Future<FinancialSnapshot> build(String month) async {
    final transactions = await _transactionDao.getAllTransactions();
    final categories = await _categoryDao.getAllCategories();
    final budgets = await _budgetDao.getBudgetsForMonth(month);
    final goals = await _savingsGoalDao.getAllSavingsGoals();
    final debts = await _debtLoanDao.getAllDebtLoans();
    final accounts = await _accountDao.getAllAccounts();

    double estimatedIncome = 0.0;
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        'planning_meta',
        where: 'month = ?',
        whereArgs: [month],
      );
      if (results.isNotEmpty) {
        estimatedIncome = (results.first['estimated_income'] as num).toDouble();
      }
    } catch (e, stack) {
      debugPrint('[FinancialSnapshotBuilder] Error querying planning_meta for estimatedIncome: $e\n$stack');
    }

    return FinancialSnapshot(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      goals: goals,
      debts: debts,
      accounts: accounts,
      selectedMonth: month,
      selectedDate: DateTime.now(),
      estimatedIncome: estimatedIncome,
    );
  }
}

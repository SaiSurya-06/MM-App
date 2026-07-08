import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/database/daos/debt_loan_dao.dart';
import '../models/debt_loan.dart';
import 'accounts_provider.dart';
import 'transactions_provider.dart';

class DebtsState {
  final List<DebtLoan> debts;
  final bool isLoading;
  final String? errorMessage;

  DebtsState({
    required this.debts,
    this.isLoading = false,
    this.errorMessage,
  });

  DebtsState copyWith({
    List<DebtLoan>? debts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DebtsState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DebtsNotifier extends StateNotifier<DebtsState> {
  final DebtLoanDao _debtLoanDao = DebtLoanDao();
  final Ref _ref;

  DebtsNotifier(this._ref) : super(DebtsState(debts: [], isLoading: true)) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    try {
      state = state.copyWith(isLoading: true);
      final debts = await _debtLoanDao.getAllDebtLoans();
      state = DebtsState(debts: debts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load debts: $e');
    }
  }

  Future<bool> addDebt({
    required String name,
    required String type,
    required double balance,
    required double originalAmount,
    required double interestRate,
    required double monthlyPayment,
    required DateTime startDate,
  }) async {
    try {
      final dl = DebtLoan(
        name: name,
        type: type,
        balance: balance,
        originalAmount: originalAmount,
        interestRate: interestRate,
        monthlyPayment: monthlyPayment,
        startDate: startDate,
        createdAt: DateTime.now(),
      );
      await _debtLoanDao.insertDebtLoan(dl);
      await loadDebts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add debt: $e');
      return false;
    }
  }

  Future<bool> updateDebt(DebtLoan debt) async {
    try {
      await _debtLoanDao.updateDebtLoan(debt);
      await loadDebts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update debt: $e');
      return false;
    }
  }

  Future<bool> deleteDebt(int id) async {
    try {
      await _debtLoanDao.deleteDebtLoan(id);
      await loadDebts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete debt: $e');
      return false;
    }
  }

  Future<bool> recordPayment(int id, double amount, int accountId) async {
    try {
      final db = await AppDatabase.instance.database;
      final debt = state.debts.firstWhere((d) => d.id == id);
      
      await db.transaction((txn) async {
        // 1. Subtract balance from funding account
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [amount, accountId],
        );
        // 2. Update debt balance
        final double newBalance = (debt.balance - amount).clamp(0.0, double.infinity);
        await txn.rawUpdate(
          'UPDATE debt_loan SET balance = ? WHERE id = ?',
          [newBalance, id],
        );
        // 3. Insert transaction log
        await txn.insert('transaction_log', {
          'account_id': accountId,
          'category_id': 8, // Category 'Other'
          'title': 'Debt Payment: ${debt.name}',
          'amount': amount,
          'type': 'expense',
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'note': 'Payment towards debt/loan "${debt.name}".',
          'recurrence': 'none',
          'is_private': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      await loadDebts();
      _ref.read(accountsProvider.notifier).loadAccounts();
      _ref.read(transactionsProvider.notifier).loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to record payment: $e');
      return false;
    }
  }
}

final debtsProvider = StateNotifierProvider<DebtsNotifier, DebtsState>((ref) {
  return DebtsNotifier(ref);
});

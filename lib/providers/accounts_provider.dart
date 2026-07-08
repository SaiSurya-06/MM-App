import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/daos/account_dao.dart';
import '../models/account.dart';
import '../core/database/database.dart';

class AccountsState {
  final List<Account> accounts;
  final bool isLoading;
  final String? errorMessage;

  AccountsState({
    required this.accounts,
    this.isLoading = false,
    this.errorMessage,
  });

  AccountsState copyWith({
    List<Account>? accounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  final AccountDao _accountDao = AccountDao();

  AccountsNotifier() : super(AccountsState(accounts: [], isLoading: true)) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      state = state.copyWith(isLoading: true);
      final accounts = await _accountDao.getAllAccounts();
      state = AccountsState(accounts: accounts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load accounts: $e');
    }
  }

  Future<int?> addAccount(String name, String type, double balance, String icon, String color, bool isShared, [double? limitAmount]) async {
    try {
      final newAccount = Account(
        name: name,
        type: type,
        balance: balance,
        icon: icon,
        color: color,
        isShared: isShared,
        createdAt: DateTime.now(),
        limitAmount: limitAmount,
      );
      final id = await _accountDao.insertAccount(newAccount);
      await loadAccounts();
      await AppDatabase.queueSyncAction('insert', 'account', id, newAccount.copyWith(id: id).toMap());
      return id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add account: $e');
      return null;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await _accountDao.updateAccount(account);
      await loadAccounts();
      await AppDatabase.queueSyncAction('update', 'account', account.id!, account.toMap());
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update account: $e');
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      await _accountDao.deleteAccount(id);
      await loadAccounts();
      await AppDatabase.queueSyncAction('delete', 'account', id, {'id': id});
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete account: $e');
      return false;
    }
  }

  Future<bool> restoreAccount(Account account) async {
    try {
      final id = await _accountDao.insertAccount(account);
      await loadAccounts();
      await AppDatabase.queueSyncAction('insert', 'account', id, account.copyWith(id: id).toMap());
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to restore account: $e');
      return false;
    }
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  return AccountsNotifier();
});

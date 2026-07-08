import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/database/database.dart';
import '../widgets/common/toast_notification.dart';
import '../core/database/daos/transaction_dao.dart';
import '../models/transaction.dart';
import '../core/utils/excel_export_helper.dart';
import 'accounts_provider.dart';
import 'budgets_provider.dart';
import '../core/notifications/notification_service.dart';
import '../core/analytics/recurrence_engine.dart';

class TransactionsState {
  final List<Transaction> transactions;
  final List<Transaction> projectedTransactions; // Includes future instances
  final bool isLoading;
  final String? errorMessage;
  final bool sortAscending;
  
  // Filter settings
  final String? filterType; // 'income', 'expense', 'transfer'
  final int? filterAccountId;
  final int? filterCategoryId;
  final int? filterSubcategoryId;
  final DateTimeRange? filterDateRange;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final List<String> selectedTags;
  final List<Map<String, dynamic>> presets;

  TransactionsState({
    required this.transactions,
    required this.projectedTransactions,
    this.isLoading = false,
    this.errorMessage,
    this.sortAscending = false,
    this.filterType,
    this.filterAccountId,
    this.filterCategoryId,
    this.filterSubcategoryId,
    this.filterDateRange,
    this.searchQuery = '',
    this.minAmount,
    this.maxAmount,
    this.selectedTags = const [],
    this.presets = const [],
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    List<Transaction>? projectedTransactions,
    bool? isLoading,
    String? errorMessage,
    bool? sortAscending,
    String? filterType,
    int? filterAccountId,
    int? filterCategoryId,
    int? filterSubcategoryId,
    DateTimeRange? filterDateRange,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    List<String>? selectedTags,
    List<Map<String, dynamic>>? presets,
    bool clearType = false,
    bool clearAccount = false,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      projectedTransactions: projectedTransactions ?? this.projectedTransactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      sortAscending: sortAscending ?? this.sortAscending,
      filterType: clearType ? null : (filterType ?? this.filterType),
      filterAccountId: clearAccount ? null : (filterAccountId ?? this.filterAccountId),
      filterCategoryId: clearCategory ? null : (filterCategoryId ?? this.filterCategoryId),
      filterSubcategoryId: clearSubcategory ? null : (filterSubcategoryId ?? this.filterSubcategoryId),
      filterDateRange: clearDateRange ? null : (filterDateRange ?? this.filterDateRange),
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      selectedTags: selectedTags ?? this.selectedTags,
      presets: presets ?? this.presets,
    );
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionDao _transactionDao = TransactionDao();
  final Ref _ref;

  TransactionsNotifier(this._ref)
      : super(TransactionsState(
          transactions: [],
          projectedTransactions: [],
          isLoading: true,
          selectedTags: [],
          presets: [],
        )) {
    loadTransactions();
    loadPresets();
  }

  Future<void> autoPostDueRecurrences() async {
    try {
      final txs = await _transactionDao.getAllTransactions();
      final recurringTemplates = txs.where((tx) => tx.recurrence != 'none').toList();
      if (recurringTemplates.isEmpty) return;

      final now = DateTime.now();
      bool balanceChanged = false;

      for (var tx in recurringTemplates) {
        DateTime occurrenceDate = tx.date;

        while (true) {
          switch (tx.recurrence) {
            case 'daily':
              occurrenceDate = occurrenceDate.add(const Duration(days: 1));
              break;
            case 'weekly':
              occurrenceDate = occurrenceDate.add(const Duration(days: 7));
              break;
            case 'monthly':
              occurrenceDate = DateTime(occurrenceDate.year, occurrenceDate.month + 1, occurrenceDate.day);
              break;
            case 'yearly':
              occurrenceDate = DateTime(occurrenceDate.year + 1, occurrenceDate.month, occurrenceDate.day);
              break;
            default:
              occurrenceDate = now.add(const Duration(days: 1));
          }

          final adjustedDate = RecurrenceEngine.adjustForWeekendsAndHolidays(occurrenceDate);
          if (adjustedDate.isAfter(now)) break;
          if (tx.recurrenceEndDate != null && adjustedDate.isAfter(tx.recurrenceEndDate!)) break;

          final dateStr = adjustedDate.toIso8601String().substring(0, 10);
          final exists = txs.any((existingTx) =>
              existingTx.accountId == tx.accountId &&
              existingTx.categoryId == tx.categoryId &&
              existingTx.amount == tx.amount &&
              existingTx.date.toIso8601String().substring(0, 10) == dateStr);

          if (!exists) {
            final newInstance = Transaction(
              accountId: tx.accountId,
              categoryId: tx.categoryId,
              title: tx.title,
              amount: tx.amount,
              type: tx.type,
              date: adjustedDate,
              note: 'Auto-posted recurring instance of "${tx.title}".',
              recurrence: 'none',
              isPrivate: tx.isPrivate,
              tags: tx.tags,
              createdAt: DateTime.now(),
            );
            await _transactionDao.insertTransaction(newInstance);
            balanceChanged = true;
          }
        }
      }

      if (balanceChanged) {
        _ref.read(accountsProvider.notifier).loadAccounts();
      }
    } catch (e, stack) {
      // Auto-posting is a background task; surface it as a debug log
      // so production issues are diagnosable without crashing the app.
      debugPrint('[autoPostDueRecurrences] Error: $e\n$stack');
    }
  }

  Future<void> loadTransactions() async {
    try {
      state = state.copyWith(isLoading: true);
      await autoPostDueRecurrences();
      final txs = await _transactionDao.getAllTransactions();
      final projected = RecurrenceEngine.projectFutureInstances(txs);
      state = state.copyWith(
        transactions: txs,
        projectedTransactions: projected,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load transactions: $e',
      );
    }
  }

  Future<bool> addTransaction({
    required int accountId,
    required int categoryId,
    required String title,
    required double amount,
    required String type,
    required DateTime date,
    String? note,
    required String recurrence,
    DateTime? recurrenceEndDate,
    required bool isPrivate,
    String tags = '',
    int? transferToAccountId,
  }) async {
    // ── Input validation ──────────────────────────────────────────────────
    if (title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Transaction title cannot be empty.');
      return false;
    }
    if (amount <= 0) {
      state = state.copyWith(errorMessage: 'Transaction amount must be greater than zero.');
      return false;
    }
    if (!['income', 'expense', 'transfer'].contains(type)) {
      state = state.copyWith(errorMessage: 'Invalid transaction type: $type.');
      return false;
    }
    // ─────────────────────────────────────────────────────────────────────
    try {
      final isDuplicate = await checkForDuplicate(accountId, categoryId, title.trim(), amount, type);
      if (isDuplicate) {
        await NotificationService.instance.showDuplicateAlert(title.trim(), amount);
      }

      final tx = Transaction(
        accountId: accountId,
        categoryId: categoryId,
        title: title.trim(),
        amount: amount,
        type: type,
        date: date,
        note: note,
        recurrence: recurrence,
        recurrenceEndDate: recurrenceEndDate,
        isPrivate: isPrivate,
        tags: tags,
        transferToAccountId: transferToAccountId,
        createdAt: DateTime.now(),
      );

      final id = await _transactionDao.insertTransaction(tx);
      await loadTransactions();
      await AppDatabase.queueSyncAction('insert', 'transaction_log', id, tx.copyWith(id: id).toMap());

      // Check category spending limit alert
      if (type == 'expense') {
        try {
          final db = await AppDatabase.instance.database;
          final List<Map<String, dynamic>> catResult = await db.query(
            'category',
            columns: ['name', 'spending_limit'],
            where: 'id = ?',
            whereArgs: [categoryId],
          );
          if (catResult.isNotEmpty) {
            final catName = catResult.first['name'] as String;
            final limit = (catResult.first['spending_limit'] as num?)?.toDouble();
            if (limit != null && limit > 0) {
              final monthStr = date.toIso8601String().substring(0, 7);
              final List<Map<String, dynamic>> spendResult = await db.rawQuery('''
                SELECT SUM(amount) as total
                FROM transaction_log
                WHERE type = 'expense' AND category_id = ? AND strftime('%Y-%m', date) = ?
              ''', [categoryId, monthStr]);
              final double currentSpend = (spendResult.first['total'] as num?)?.toDouble() ?? 0.0;
              if (currentSpend >= limit) {
                await NotificationService.instance.showCategoryLimitAlert(catName, limit);
              }
            }
          }
        } catch (_) {}
      }

      // Check budget threshold alerts immediately
      await _ref.read(budgetsProvider.notifier).checkBudgetThreshold(
        categoryId: categoryId,
        txAmount: amount,
        txDate: date,
        txType: type,
      );

      // Refresh accounts provider as balances changed!
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add transaction: $e');
      return false;
    }
  }

  Future<int?> addTransactionAndReturnId({
    required int accountId,
    required int categoryId,
    required String title,
    required double amount,
    required String type,
    required DateTime date,
    String? note,
    required String recurrence,
    DateTime? recurrenceEndDate,
    required bool isPrivate,
    String tags = '',
    int? transferToAccountId,
    int? subcategoryId,
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Transaction title cannot be empty.');
      return null;
    }
    if (amount <= 0) {
      state = state.copyWith(errorMessage: 'Transaction amount must be greater than zero.');
      return null;
    }
    if (!['income', 'expense', 'transfer'].contains(type)) {
      state = state.copyWith(errorMessage: 'Invalid transaction type: $type.');
      return null;
    }
    try {
      final isDuplicate = await checkForDuplicate(accountId, categoryId, title.trim(), amount, type);
      if (isDuplicate) {
        await NotificationService.instance.showDuplicateAlert(title.trim(), amount);
      }

      final tx = Transaction(
        accountId: accountId,
        categoryId: categoryId,
        title: title.trim(),
        amount: amount,
        type: type,
        date: date,
        note: note,
        recurrence: recurrence,
        recurrenceEndDate: recurrenceEndDate,
        isPrivate: isPrivate,
        tags: tags,
        transferToAccountId: transferToAccountId,
        createdAt: DateTime.now(),
        subcategoryId: subcategoryId,
      );

      final id = await _transactionDao.insertTransaction(tx);
      await loadTransactions();
      await AppDatabase.queueSyncAction('insert', 'transaction_log', id, tx.copyWith(id: id).toMap());

      if (type == 'expense') {
        try {
          final db = await AppDatabase.instance.database;
          final List<Map<String, dynamic>> catResult = await db.query(
            'category',
            columns: ['name', 'spending_limit'],
            where: 'id = ?',
            whereArgs: [categoryId],
          );
          if (catResult.isNotEmpty) {
            final catName = catResult.first['name'] as String;
            final limit = (catResult.first['spending_limit'] as num?)?.toDouble();
            if (limit != null && limit > 0) {
              final monthStr = date.toIso8601String().substring(0, 7);
              final List<Map<String, dynamic>> spendResult = await db.rawQuery('''
                SELECT SUM(amount) as total
                FROM transaction_log
                WHERE type = 'expense' AND category_id = ? AND strftime('%Y-%m', date) = ?
              ''', [categoryId, monthStr]);
              final double currentSpend = (spendResult.first['total'] as num?)?.toDouble() ?? 0.0;
              if (currentSpend >= limit) {
                await NotificationService.instance.showCategoryLimitAlert(catName, limit);
              }
            }
          }
        } catch (_) {}
      }

      await _ref.read(budgetsProvider.notifier).checkBudgetThreshold(
        categoryId: categoryId,
        txAmount: amount,
        txDate: date,
        txType: type,
      );

      _ref.read(accountsProvider.notifier).loadAccounts();
      return id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add transaction: $e');
      return null;
    }
  }

  Future<List<Transaction>> getSplitsForParent(int parentId) async {
    try {
      final db = await AppDatabase.instance.database;
      final result = await db.query(
        'transaction_log',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'id ASC',
      );
      return result.map<Transaction>((json) => Transaction.fromMap(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> checkForDuplicate(int accountId, int categoryId, String title, double amount, String type) async {
    try {
      final db = await AppDatabase.instance.database;
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: NotificationService.duplicateCheckWindowMinutes)).toIso8601String();
      
      final results = await db.rawQuery('''
        SELECT * FROM transaction_log
        WHERE account_id = ? AND category_id = ? AND amount = ? AND type = ? AND created_at >= ?
      ''', [accountId, categoryId, amount, type, tenMinutesAgo]);
      
      for (var row in results) {
        final existingTitle = row['title'] as String;
        if (existingTitle.toLowerCase().trim() == title.toLowerCase().trim()) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> bulkDeleteTransactions(List<Transaction> txs) async {
    try {
      final List<Transaction> allChildren = [];
      for (var tx in txs) {
        if (tx.id != null) {
          final children = await getSplitsForParent(tx.id!);
          allChildren.addAll(children);
        }
      }

      await _transactionDao.bulkDeleteTransactions(txs);
      await loadTransactions();
      for (var tx in txs) {
        if (tx.id != null) {
          await AppDatabase.queueSyncAction('delete', 'transaction_log', tx.id!, {'id': tx.id});
        }
      }
      for (var child in allChildren) {
        if (child.id != null) {
          await AppDatabase.queueSyncAction('delete', 'transaction_log', child.id!, {'id': child.id});
        }
      }
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to bulk delete transactions: $e');
      return false;
    }
  }

  Future<bool> bulkEditCategory(List<Transaction> txs, int categoryId) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.transaction((txn) async {
        for (var tx in txs) {
          if (tx.id != null) {
            await txn.update(
              'transaction_log',
              {'category_id': categoryId},
              where: 'id = ?',
              whereArgs: [tx.id],
            );
          }
        }
      });
      for (var tx in txs) {
        if (tx.id != null) {
          await AppDatabase.queueSyncAction('update', 'transaction_log', tx.id!, tx.copyWith(categoryId: categoryId).toMap());
        }
      }
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to bulk edit transactions category: $e');
      return false;
    }
  }

  Future<bool> splitTransaction({
    required int parentTransactionId,
    required List<Map<String, dynamic>> splits, // each map has categoryId, amount, note/tags
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      final parentResult = await db.query(
        'transaction_log',
        where: 'id = ?',
        whereArgs: [parentTransactionId],
      );
      if (parentResult.isEmpty) return false;
      
      final parentTx = Transaction.fromMap(parentResult.first);
      final List<MapEntry<int, Transaction>> queuedSplits = [];
      
      await db.transaction((txn) async {
        for (var s in splits) {
          final child = Transaction(
            accountId: parentTx.accountId,
            categoryId: s['categoryId'] as int,
            title: '${parentTx.title} (Split)',
            amount: s['amount'] as double,
            type: parentTx.type,
            date: parentTx.date,
            note: s['note'] as String? ?? 'Split from "${parentTx.title}".',
            recurrence: 'none',
            isPrivate: parentTx.isPrivate,
            tags: s['tags'] as String? ?? parentTx.tags,
            parentId: parentTransactionId,
            createdAt: DateTime.now(),
          );
          final childId = await txn.insert('transaction_log', child.toMap());
          queuedSplits.add(MapEntry(childId, child));
        }
      });
      
      for (var entry in queuedSplits) {
        await AppDatabase.queueSyncAction('insert', 'transaction_log', entry.key, entry.value.copyWith(id: entry.key).toMap());
      }
      
      await loadTransactions();
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to split transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction newTx, Transaction oldTx) async {
    // ── Input validation ──────────────────────────────────────────────────
    if (newTx.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Transaction title cannot be empty.');
      return false;
    }
    if (newTx.amount <= 0) {
      state = state.copyWith(errorMessage: 'Transaction amount must be greater than zero.');
      return false;
    }
    if (!['income', 'expense', 'transfer'].contains(newTx.type)) {
      state = state.copyWith(errorMessage: 'Invalid transaction type: ${newTx.type}.');
      return false;
    }
    // ─────────────────────────────────────────────────────────────────────
    try {
      await _transactionDao.updateTransaction(newTx, oldTx);
      await loadTransactions();
      await AppDatabase.queueSyncAction('update', 'transaction_log', newTx.id!, newTx.toMap());

      // Refresh accounts provider
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(Transaction tx) async {
    try {
      List<Transaction> children = [];
      if (tx.id != null) {
        children = await getSplitsForParent(tx.id!);
      }

      await _transactionDao.deleteTransaction(tx);
      await loadTransactions();
      
      if (tx.id != null) {
        await AppDatabase.queueSyncAction('delete', 'transaction_log', tx.id!, {'id': tx.id});
        for (var child in children) {
          if (child.id != null) {
            await AppDatabase.queueSyncAction('delete', 'transaction_log', child.id!, {'id': child.id});
          }
        }
      }

      // Refresh accounts provider
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete transaction: $e');
      return false;
    }
  }

  Future<bool> restoreTransaction(Transaction tx) async {
    try {
      final id = await _transactionDao.insertTransaction(tx);
      await loadTransactions();
      await AppDatabase.queueSyncAction('insert', 'transaction_log', id, tx.copyWith(id: id).toMap());
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to restore transaction: $e');
      return false;
    }
  }


  // Filters updates
  void setFilterType(String? type) {
    if (type == null) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(filterType: type);
    }
  }

  void setFilterAccount(int? accountId) {
    if (accountId == null) {
      state = state.copyWith(clearAccount: true);
    } else {
      state = state.copyWith(filterAccountId: accountId);
    }
  }

  void setFilterCategory(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true, clearSubcategory: true);
    } else {
      state = state.copyWith(filterCategoryId: categoryId, clearSubcategory: true);
    }
  }

  void setFilterSubcategory(int? subcategoryId) {
    if (subcategoryId == null) {
      state = state.copyWith(clearSubcategory: true);
    } else {
      state = state.copyWith(filterSubcategoryId: subcategoryId);
    }
  }

  void setFilterDateRange(DateTimeRange? range) {
    if (range == null) {
      state = state.copyWith(clearDateRange: true);
    } else {
      state = state.copyWith(filterDateRange: range);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setMinAmount(double? amt) {
    if (amt == null) {
      state = state.copyWith(clearMinAmount: true);
    } else {
      state = state.copyWith(minAmount: amt);
    }
  }

  void setMaxAmount(double? amt) {
    if (amt == null) {
      state = state.copyWith(clearMaxAmount: true);
    } else {
      state = state.copyWith(maxAmount: amt);
    }
  }

  void setSelectedTags(List<String> tags) {
    state = state.copyWith(selectedTags: tags);
  }

  Future<void> loadPresets() async {
    try {
      final db = await AppDatabase.instance.database;
      final list = await db.query('filter_preset', orderBy: 'name ASC');
      state = state.copyWith(presets: list);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load filter presets: $e');
    }
  }

  Future<void> savePreset(String name) async {
    try {
      final db = await AppDatabase.instance.database;
      final filtersMap = {
        'filterType': state.filterType,
        'filterAccountId': state.filterAccountId,
        'filterCategoryId': state.filterCategoryId,
        'filterSubcategoryId': state.filterSubcategoryId,
        'minAmount': state.minAmount,
        'maxAmount': state.maxAmount,
        'selectedTags': state.selectedTags,
      };
      final jsonStr = jsonEncode(filtersMap);
      await db.insert('filter_preset', {
        'name': name,
        'filters_json': jsonStr,
      });
      await loadPresets();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save filter preset: $e');
    }
  }

  Future<void> deletePreset(int id) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('filter_preset', where: 'id = ?', whereArgs: [id]);
      await loadPresets();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete filter preset: $e');
    }
  }

  void applyPreset(Map<String, dynamic> filters) {
    state = state.copyWith(
      filterType: filters['filterType'] as String?,
      filterAccountId: filters['filterAccountId'] as int?,
      filterCategoryId: filters['filterCategoryId'] as int?,
      filterSubcategoryId: filters['filterSubcategoryId'] as int?,
      minAmount: (filters['minAmount'] as num?)?.toDouble(),
      maxAmount: (filters['maxAmount'] as num?)?.toDouble(),
      selectedTags: List<String>.from(filters['selectedTags'] ?? []),
      clearType: filters['filterType'] == null,
      clearAccount: filters['filterAccountId'] == null,
      clearCategory: filters['filterCategoryId'] == null,
      clearSubcategory: filters['filterSubcategoryId'] == null,
      clearMinAmount: filters['minAmount'] == null,
      clearMaxAmount: filters['maxAmount'] == null,
    );
  }

  void resetFilters() {
    state = state.copyWith(
      clearType: true,
      clearAccount: true,
      clearCategory: true,
      clearSubcategory: true,
      clearDateRange: true,
      clearMinAmount: true,
      clearMaxAmount: true,
      selectedTags: [],
      searchQuery: '',
    );
  }

  void toggleSortOrder() {
    state = state.copyWith(sortAscending: !state.sortAscending);
  }

  List<String> _extractTags(Transaction tx) {
    final List<String> tags = [];
    final RegExp regex = RegExp(r'#(\w+)');
    final String text = '${tx.title} ${tx.note ?? ""}';
    for (var match in regex.allMatches(text)) {
      final tag = match.group(1)?.toLowerCase();
      if (tag != null && !tags.contains(tag)) {
        tags.add(tag);
      }
    }
    return tags;
  }

  List<Transaction> getFilteredTransactions({bool includeProjected = false}) {
    final list = includeProjected ? state.projectedTransactions : state.transactions;
    
    final filtered = list.where((tx) {
      if (tx.parentId != null) {
        return false;
      }
      if (state.filterType != null && tx.type != state.filterType) {
        return false;
      }
      if (state.filterAccountId != null && tx.accountId != state.filterAccountId) {
        return false;
      }
      if (state.filterCategoryId != null && tx.categoryId != state.filterCategoryId) {
        return false;
      }
      if (state.filterSubcategoryId != null && tx.subcategoryId != state.filterSubcategoryId) {
        return false;
      }
      if (state.filterDateRange != null) {
        if (tx.date.isBefore(state.filterDateRange!.start) ||
            tx.date.isAfter(state.filterDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesNote = tx.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesNote) {
          return false;
        }
      }
      if (state.minAmount != null && tx.amount < state.minAmount!) {
        return false;
      }
      if (state.maxAmount != null && tx.amount > state.maxAmount!) {
        return false;
      }
      if (state.selectedTags.isNotEmpty) {
        final txTags = _extractTags(tx);
        final matchesAny = state.selectedTags.any((t) => txTags.contains(t.toLowerCase()));
        if (!matchesAny) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final cmp = state.sortAscending 
          ? a.date.compareTo(b.date) 
          : b.date.compareTo(a.date);
      if (cmp != 0) return cmp;
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return state.sortAscending 
          ? idA.compareTo(idB) 
          : idB.compareTo(idA);
    });

    return filtered;
  }

  Future<void> exportTransactionsToCsv(
    BuildContext context, {
    DateTimeRange? dateRange,
    String? dateRangeStr,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final filterAccountId = state.filterAccountId;

      final db = await AppDatabase.instance.database;
      
      // Load accounts list
      final accountsList = await db.query('account');
      final Map<int, String> accountMap = {
        for (var row in accountsList) row['id'] as int: row['name'] as String
      };
      final Map<int, double> accountBalances = {
        for (var row in accountsList) row['id'] as int: (row['balance'] as num).toDouble()
      };

      // Load categories list
      final categoriesList = await db.query('category');
      final Map<int, String> categoryMap = {
        for (var row in categoriesList) row['id'] as int: row['name'] as String
      };

      // Determine current balance based on account filter
      double currentBalance = 0.0;
      if (filterAccountId != null) {
        currentBalance = accountBalances[filterAccountId] ?? 0.0;
      } else {
        currentBalance = accountBalances.values.fold(0.0, (sum, val) => sum + val);
      }

      // Get all transactions
      final allTxs = await _transactionDao.getAllTransactions();
      
      // Filter transactions to export by account
      List<Transaction> exportTxs = allTxs;
      if (filterAccountId != null) {
        exportTxs = exportTxs.where((tx) => tx.accountId == filterAccountId).toList();
      }

      // Compute balances
      double openingBalance = currentBalance;
      double closingBalance = currentBalance;

      if (dateRange != null) {
        final startOfDay = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        final endOfDay = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59, 999);

        // Group A: net change during range (startOfDay <= date <= endOfDay)
        double netChangeDuringRange = 0.0;
        // Group B: net change after range (date > endOfDay)
        double netChangeAfterRange = 0.0;

        for (var tx in exportTxs) {
          double txNet = 0.0;
          if (tx.type == 'income') {
            txNet = tx.amount;
          } else if (tx.type == 'expense') {
            txNet = -tx.amount;
          } else if (tx.type == 'transfer') {
            if (filterAccountId != null) {
              if (tx.accountId == filterAccountId) {
                txNet = -tx.amount;
              } else {
                final regExp = RegExp(r'Transfer to target account ID: (\d+)');
                final match = regExp.firstMatch(tx.note ?? '');
                if (match != null) {
                  final destId = int.tryParse(match.group(1) ?? '');
                  if (destId == filterAccountId) {
                    txNet = tx.amount;
                  }
                }
              }
            } else {
              txNet = 0.0; // Overall transfers sum to 0
            }
          }

          if (tx.date.isBefore(startOfDay)) {
            // Before range
          } else if (tx.date.isAfter(endOfDay)) {
            netChangeAfterRange += txNet;
          } else {
            netChangeDuringRange += txNet;
          }
        }

        openingBalance = currentBalance - netChangeDuringRange - netChangeAfterRange;
        closingBalance = currentBalance - netChangeAfterRange;

        // Filter list to range
        exportTxs = exportTxs.where((tx) {
          return (tx.date.isAfter(startOfDay) || tx.date.isAtSameMomentAs(startOfDay)) &&
                 (tx.date.isBefore(endOfDay) || tx.date.isAtSameMomentAs(endOfDay));
        }).toList();
      }

      // Format balances
      final opBalStr = openingBalance.toStringAsFixed(2);
      final clBalStr = closingBalance.toStringAsFixed(2);

      final List<List<dynamic>> csvData = [];
      
      // Metadata headers
      csvData.add(['Report:', 'Transactions Export']);
      csvData.add(['Date Range:', dateRangeStr ?? 'All-Time']);
      csvData.add(['Opening Balance:', opBalStr]);
      csvData.add(['Closing Balance:', clBalStr]);
      csvData.add([]); // Blank line
      
      // Column Headers
      csvData.add(['Date', 'Title', 'Amount', 'Type', 'Category', 'Account', 'Note', 'Recurrence', 'Recurrence End Date', 'Is Private']);

      // Sort descending by date
      exportTxs.sort((a, b) => b.date.compareTo(a.date));

      for (var tx in exportTxs) {
        final categoryName = categoryMap[tx.categoryId] ?? 'Other';
        final accountName = accountMap[tx.accountId] ?? 'Account';
        csvData.add([
          tx.date.toIso8601String().substring(0, 10),
          tx.title,
          tx.amount,
          tx.type,
          categoryName,
          accountName,
          tx.note ?? '',
          tx.recurrence,
          tx.recurrenceEndDate?.toIso8601String().substring(0, 10) ?? '',
          tx.isPrivate ? 'yes' : 'no',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/money_manager_transactions.csv');
      await file.writeAsString(csvString);

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Transactions Export',
        );
        if (context.mounted) {
          ToastNotification.show(context, 'Transactions exported successfully.');
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Export failed: $e');
      if (context.mounted) {
        ToastNotification.show(context, 'Export failed: $e', isError: true);
      }
    }
  }

  Future<void> exportTransactionsToJson(
    BuildContext context, {
    DateTimeRange? dateRange,
    String? dateRangeStr,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final db = await AppDatabase.instance.database;

      List<Transaction> exportTxs = state.transactions;
      if (dateRange != null) {
        final start = dateRange.start;
        final end = dateRange.end;
        final startOfDay = DateTime(start.year, start.month, start.day);
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
        exportTxs = state.transactions.where((tx) {
          return (tx.date.isAfter(startOfDay) || tx.date.isAtSameMomentAs(startOfDay)) &&
                 (tx.date.isBefore(endOfDay) || tx.date.isAtSameMomentAs(endOfDay));
        }).toList();
      }

      final categoryList = await db.query('category');
      final Map<int, String> categoryMap = {
        for (var row in categoryList) row['id'] as int: row['name'] as String
      };

      final accountList = await db.query('account');
      final Map<int, String> accountMap = {
        for (var row in accountList) row['id'] as int: row['name'] as String
      };

      final List<Map<String, dynamic>> jsonData = [];
      for (var tx in exportTxs) {
        jsonData.add({
          'date': tx.date.toIso8601String().substring(0, 10),
          'title': tx.title,
          'amount': tx.amount,
          'type': tx.type,
          'category': categoryMap[tx.categoryId] ?? 'Other',
          'account': accountMap[tx.accountId] ?? 'Account',
          'note': tx.note ?? '',
          'recurrence': tx.recurrence,
          'recurrence_end_date': tx.recurrenceEndDate?.toIso8601String().substring(0, 10) ?? '',
          'is_private': tx.isPrivate,
        });
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/money_manager_transactions.json');
      await file.writeAsString(jsonString);

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/json')],
          subject: 'Transactions JSON Export',
        );
        if (context.mounted) {
          ToastNotification.show(context, 'Transactions exported to JSON successfully.');
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'JSON Export failed: $e');
      if (context.mounted) {
        ToastNotification.show(context, 'JSON Export failed: $e', isError: true);
      }
    }
  }

  Future<void> exportTransactionsToExcel(
    BuildContext context, {
    DateTimeRange? dateRange,
    String? dateRangeStr,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final db = await AppDatabase.instance.database;

      final categoryList = await db.query('category');
      final Map<int, String> categoryNames = {
        for (var row in categoryList) row['id'] as int: row['name'] as String
      };
      final accountList = await db.query('account');
      final Map<int, String> accountNames = {
        for (var row in accountList) row['id'] as int: row['name'] as String
      };

      List<Transaction> exportTxs = state.transactions;
      if (dateRange != null) {
        final startOfDay = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        final endOfDay = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59, 999);
        exportTxs = state.transactions.where((tx) {
          return (tx.date.isAfter(startOfDay) || tx.date.isAtSameMomentAs(startOfDay)) &&
                 (tx.date.isBefore(endOfDay) || tx.date.isAtSameMomentAs(endOfDay));
        }).toList();
      }

      exportTxs.sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(isLoading: false);

      await ExcelExportHelper.exportTransactionsToExcel(
        transactions: exportTxs,
        categoryNames: categoryNames,
        accountNames: accountNames,
        currency: 'USD',
        dateRangeStr: dateRangeStr ?? 'All-Time',
      );

      if (context.mounted) {
        ToastNotification.show(context, 'Transactions exported to Excel successfully.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Excel export failed: $e');
      if (context.mounted) {
        ToastNotification.show(context, 'Excel export failed: $e', isError: true);
      }
    }
  }

  Future<void> importTransactionsFromCsv(BuildContext context) async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (pickerResult == null || pickerResult.files.single.path == null) {
        return;
      }

      state = state.copyWith(isLoading: true);

      final file = File(pickerResult.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Dynamically scan to find the header row index (matches Date, Title)
      int headerRowIndex = -1;
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 6) {
          final firstCol = row[0].toString().toLowerCase().trim();
          final secondCol = row[1].toString().toLowerCase().trim();
          if (firstCol == 'date' && secondCol == 'title') {
            headerRowIndex = i;
            break;
          }
        }
      }

      if (headerRowIndex == -1) {
        throw Exception('Could not locate transaction header row (Date, Title, ...) in CSV file');
      }

      if (rows.length <= headerRowIndex + 1) {
        throw Exception('CSV file contains no transaction data rows');
      }

      final db = await AppDatabase.instance.database;

      // Fetch existing transactions to prevent duplicates
      final existingTxs = await db.query('transaction_log');
      final Set<String> existingTxKeys = existingTxs.map((tx) {
        final dateVal = tx['date'].toString().substring(0, 10);
        final titleVal = tx['title'].toString().toLowerCase().trim();
        final amountVal = (tx['amount'] as num).toDouble().toStringAsFixed(2);
        final typeVal = tx['type'].toString().toLowerCase().trim();
        final accIdVal = tx['account_id'].toString();
        final noteVal = tx['note']?.toString().toLowerCase().trim() ?? '';
        return "${dateVal}_${titleVal}_${amountVal}_${typeVal}_${accIdVal}_$noteVal";
      }).toSet();

      // Read category mappings
      final categoryList = await db.query('category');
      final Map<String, int> categoryNameToId = {
        for (var row in categoryList) (row['name'] as String).toLowerCase().trim(): row['id'] as int
      };
      
      int otherCategoryId = categoryNameToId['other'] ?? 8;

      // Read account mappings
      final accountList = await db.query('account');
      final Map<String, int> accountNameToId = {
        for (var row in accountList) (row['name'] as String).toLowerCase().trim(): row['id'] as int
      };

      int importedCount = 0;

      // Use a database transaction for batch insert
      await db.transaction((txn) async {
        for (int i = headerRowIndex + 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 6) continue; // Skip incomplete rows

          final dateStr = row[0].toString().trim();
          final title = row[1].toString().trim();
          final amount = double.tryParse(row[2].toString()) ?? 0.0;
          final type = row[3].toString().trim().toLowerCase();
          final categoryName = row[4].toString().trim();
          final accountName = row[5].toString().trim();
          final note = row.length > 6 ? row[6].toString().trim() : '';
          final recurrence = row.length > 7 ? row[7].toString().trim().toLowerCase() : 'none';
          final recEndStr = row.length > 8 ? row[8].toString().trim() : '';
          final isPrivateStr = row.length > 9 ? row[9].toString().trim().toLowerCase() : 'no';

          if (title.isEmpty || amount <= 0 || !['income', 'expense', 'transfer'].contains(type)) {
            continue; // Skip invalid entries
          }

          // Parse date
          DateTime date;
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }

          // Resolve category ID
          int categoryId = categoryNameToId[categoryName.toLowerCase()] ?? otherCategoryId;

          // Resolve account ID
          int? accountId = accountNameToId[accountName.toLowerCase()];
          if (accountId == null) {
            // Automatically create missing account!
            accountId = await txn.insert('account', {
              'name': accountName,
              'type': 'Bank',
              'balance': 0.0,
              'icon': 'account_balance',
              'color': '1E88E5',
              'is_shared': 1,
              'created_at': DateTime.now().toIso8601String(),
            });
            accountNameToId[accountName.toLowerCase()] = accountId;
          }

          // Check for duplicate transaction
          final dateVal = date.toIso8601String().substring(0, 10);
          final titleVal = title.toLowerCase().trim();
          final amountVal = amount.toStringAsFixed(2);
          final typeVal = type.toLowerCase().trim();
          final accIdVal = accountId.toString();
          final noteVal = note.toLowerCase().trim();
          final key = "${dateVal}_${titleVal}_${amountVal}_${typeVal}_${accIdVal}_$noteVal";
          if (existingTxKeys.contains(key)) {
            continue; // Skip duplicate transaction!
          }

          DateTime? recurrenceEndDate;
          if (recurrence != 'none' && recEndStr.isNotEmpty) {
            try {
              recurrenceEndDate = DateTime.parse(recEndStr);
            } catch (_) {}
          }

          final isPrivate = isPrivateStr == 'yes' || isPrivateStr == 'true' || isPrivateStr == '1';

          // Insert the transaction log row
          final txMap = {
            'account_id': accountId,
            'category_id': categoryId,
            'title': title,
            'amount': amount,
            'type': type,
            'date': dateVal,
            'note': note.isEmpty ? null : note,
            'recurrence': recurrence,
            'recurrence_end_date': recurrenceEndDate?.toIso8601String().substring(0, 10),
            'is_private': isPrivate ? 1 : 0,
            'created_at': DateTime.now().toIso8601String(),
          };

          await txn.insert('transaction_log', txMap);
          existingTxKeys.add(key); // Avoid duplicates within the same CSV

          // Update account balance
          if (type == 'income') {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance + ? WHERE id = ?',
              [amount, accountId],
            );
          } else if (type == 'expense') {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance - ? WHERE id = ?',
              [amount, accountId],
            );
          } else if (type == 'transfer') {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance - ? WHERE id = ?',
              [amount, accountId],
            );
            final destRegExp = RegExp(r'Transfer to target account ID: (\d+)');
            final match = destRegExp.firstMatch(note);
            if (match != null) {
              final destId = int.tryParse(match.group(1) ?? '');
              if (destId != null) {
                await txn.rawUpdate(
                  'UPDATE account SET balance = balance + ? WHERE id = ?',
                  [amount, destId],
                );
              }
            }
          }

          importedCount++;
        }
      });

      await loadTransactions();
      _ref.read(accountsProvider.notifier).loadAccounts();

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        ToastNotification.show(context, 'Imported $importedCount transactions successfully.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Import failed: $e');
      if (context.mounted) {
        ToastNotification.show(context, 'Import failed: $e', isError: true);
      }
    }
  }


  Future<List<ReconciliationItem>?> parseStatementCsv(int accountId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      if (fields.isEmpty) return null;

      // 1. Find Header Row
      int headerRowIndex = 0;
      for (int i = 0; i < fields.length; i++) {
        final row = fields[i];
        final rowStr = row.map((e) => e.toString().toLowerCase()).toList();
        if (rowStr.any((s) => s.contains('date')) &&
            (rowStr.any((s) => s.contains('desc')) || rowStr.any((s) => s.contains('memo')) || rowStr.any((s) => s.contains('payee')) || rowStr.any((s) => s.contains('title')))) {
          headerRowIndex = i;
          break;
        }
      }

      final header = fields[headerRowIndex].map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Index mapping
      int dateIdx = header.indexWhere((s) => s.contains('date'));
      int descIdx = header.indexWhere((s) => s.contains('desc') || s.contains('memo') || s.contains('payee') || s.contains('title') || s.contains('description'));
      int amountIdx = header.indexWhere((s) => s.contains('amount') || s.contains('value') || s.contains('charge'));
      int debitIdx = header.indexWhere((s) => s.contains('debit') || s.contains('withdrawal') || s.contains('spent'));
      int creditIdx = header.indexWhere((s) => s.contains('credit') || s.contains('deposit') || s.contains('received'));

      if (dateIdx == -1 || descIdx == -1) {
        dateIdx = 0;
        descIdx = 1;
        amountIdx = 2;
      }

      final db = await AppDatabase.instance.database;
      
      // Get all existing transactions for this account to match
      final existingMaps = await db.query(
        'transaction_log',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
      final existingTxs = existingMaps.map((m) => Transaction.fromMap(m)).toList();

      final List<ReconciliationItem> items = [];

      for (int i = headerRowIndex + 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length <= (dateIdx > descIdx ? dateIdx : descIdx)) continue;

        final dateStr = row[dateIdx].toString().trim();
        final description = row[descIdx].toString().trim();
        if (dateStr.isEmpty || description.isEmpty) continue;

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          try {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              int year = int.parse(parts[2]);
              if (year < 100) year += 2000;
              int month = int.parse(parts[0]);
              int day = int.parse(parts[1]);
              date = DateTime(year, month, day);
            } else {
              date = DateTime.now();
            }
          } catch (_) {
            date = DateTime.now();
          }
        }

        double amount = 0.0;
        String type = 'expense';

        if (amountIdx != -1 && row.length > amountIdx) {
          final amtVal = double.tryParse(row[amountIdx].toString().replaceAll(RegExp(r'[^\d\.\-]'), '')) ?? 0.0;
          amount = amtVal.abs();
          type = amtVal >= 0 ? 'income' : 'expense';
        } else if (debitIdx != -1 && creditIdx != -1 && row.length > (debitIdx > creditIdx ? debitIdx : creditIdx)) {
          final debitVal = double.tryParse(row[debitIdx].toString().replaceAll(RegExp(r'[^\d\.]'), '')) ?? 0.0;
          final creditVal = double.tryParse(row[creditIdx].toString().replaceAll(RegExp(r'[^\d\.]'), '')) ?? 0.0;
          if (debitVal > 0) {
            amount = debitVal;
            type = 'expense';
          } else if (creditVal > 0) {
            amount = creditVal;
            type = 'income';
          }
        } else if (row.length > 2) {
          final amtVal = double.tryParse(row[2].toString().replaceAll(RegExp(r'[^\d\.\-]'), '')) ?? 0.0;
          amount = amtVal.abs();
          type = amtVal >= 0 ? 'income' : 'expense';
        }

        if (amount <= 0) continue;

        Transaction? matchedTx;
        for (var tx in existingTxs) {
          final dateDiff = tx.date.difference(date).inDays.abs();
          final amountMatch = (tx.amount - amount).abs() < 0.01;
          if (amountMatch && dateDiff <= 3 && tx.type == type) {
            matchedTx = tx;
            break;
          }
        }

        items.add(ReconciliationItem(
          date: date,
          description: description,
          amount: amount,
          type: type,
          isMatched: matchedTx != null,
          matchedTransaction: matchedTx,
        ));
      }

      return items;
    } catch (e) {
      debugPrint('[parseStatementCsv] Error: $e');
      return null;
    }
  }

  Future<bool> importReconciledTransactions({
    required int accountId,
    required List<ReconciliationItem> items,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      final categoryList = await db.query('category');
      int otherCategoryId = 8;
      for (var cat in categoryList) {
        if ((cat['name'] as String).toLowerCase() == 'other') {
          otherCategoryId = cat['id'] as int;
          break;
        }
      }
      await db.transaction((txn) async {
        for (var item in items) {
          if (item.isMatched) continue;

          final dateStr = item.date.toIso8601String().substring(0, 10);
          final txMap = {
            'account_id': accountId,
            'category_id': otherCategoryId,
            'title': item.description,
            'amount': item.amount,
            'type': item.type,
            'date': dateStr,
            'note': 'Imported from reconciled bank statement.',
            'recurrence': 'none',
            'is_private': 0,
            'created_at': DateTime.now().toIso8601String(),
          };

          await txn.insert('transaction_log', txMap);

          if (item.type == 'income') {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance + ? WHERE id = ?',
              [item.amount, accountId],
            );
          } else {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance - ? WHERE id = ?',
              [item.amount, accountId],
            );
          }
        }
      });

      await loadTransactions();
      _ref.read(accountsProvider.notifier).loadAccounts();
      return true;
    } catch (e) {
      debugPrint('[importReconciledTransactions] Error: $e');
      return false;
    }
  }
}

class ReconciliationItem {
  final DateTime date;
  final String description;
  final double amount;
  final String type;
  final bool isMatched;
  final Transaction? matchedTransaction;

  ReconciliationItem({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.isMatched,
    this.matchedTransaction,
  });
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(ref);
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/transaction_dao.dart';
import '../database/database.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/partner_sync_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/planning_state_provider.dart';

class SyncClient {
  final Ref ref;
  final TransactionDao _transactionDao = TransactionDao();

  SyncClient(this.ref);

  Future<void> reconcile({
    required List<Account> newPartnerAccounts,
    required List<PartnerTransaction> newPartnerTransactions,
    required List<PartnerTransaction> oldPartnerTransactions,
    List<Map<String, dynamic>>? partnerBudgets,
    List<Map<String, dynamic>>? partnerPlanningMeta,
  }) async {
    try {
      final localAccounts = ref.read(accountsProvider).accounts;
      final categories = ref.read(categoriesProvider).categories;

      // 1. Identify which accounts are joint/shared accounts
      // A joint account is one that exists locally, has the same name as a partner account,
      // and is marked as isShared = true locally.
      final jointAccountNames = <String>{};
      final localAccountMap = <String, Account>{};
      
      for (var acc in localAccounts) {
        if (acc.isShared) {
          localAccountMap[acc.name.toLowerCase().trim()] = acc;
        }
      }

      for (var pAcc in newPartnerAccounts) {
        final nameKey = pAcc.name.toLowerCase().trim();
        if (localAccountMap.containsKey(nameKey)) {
          jointAccountNames.add(nameKey);
        }
      }

      // 2. We only reconcile transactions that belong to joint accounts!
      final newJointPartnerTxs = newPartnerTransactions.where((t) =>
        jointAccountNames.contains(t.accountName.toLowerCase().trim())
      ).toList();

      final oldJointPartnerTxs = oldPartnerTransactions.where((t) =>
        jointAccountNames.contains(t.accountName.toLowerCase().trim())
      ).toList();

      // Helper to find local account ID by name (only for joint accounts)
      int? getAccountIdByName(String name) {
        final nameKey = name.toLowerCase().trim();
        return localAccountMap[nameKey]?.id;
      }

      // Helper to find local category ID by name
      int? getCategoryIdByName(String name) {
        final cat = categories.cast<dynamic>().firstWhere(
          (c) => c.name.toLowerCase().trim() == name.toLowerCase().trim(),
          orElse: () => categories.isNotEmpty ? categories.first : null,
        );
        return cat?.id;
      }

      // Reload accounts provider so we have updated account mappings
      final updatedLocalAccounts = ref.read(accountsProvider).accounts;
      final localTxs = ref.read(transactionsProvider).transactions;

      // Define unique key helper for partner transactions
      String ptxKey(PartnerTransaction t) =>
          "${t.title.toLowerCase().trim()}_${t.amount.toStringAsFixed(2)}_${t.type}_${t.date.toIso8601String().substring(0, 10)}_${t.accountName.toLowerCase().trim()}";

      // Define unique key helper for local transactions
      String txKey(Transaction t) {
        final acc = updatedLocalAccounts.cast<Account?>().firstWhere(
          (a) => a != null && a.id == t.accountId,
          orElse: () => null,
        );
        final accName = acc?.name ?? 'Unknown';
        return "${t.title.toLowerCase().trim()}_${t.amount.toStringAsFixed(2)}_${t.type}_${t.date.toIso8601String().substring(0, 10)}_${accName.toLowerCase().trim()}";
      }

      final Map<String, Transaction> localTxMap = {
        for (var tx in localTxs) txKey(tx): tx
      };

      // A. Detect deletions of joint transactions by partner:
      final Set<String> newPartnerKeys = newJointPartnerTxs.map(ptxKey).toSet();
      for (var oldPtx in oldJointPartnerTxs) {
        final key = ptxKey(oldPtx);
        if (!newPartnerKeys.contains(key)) {
          final localMatch = localTxMap[key];
          if (localMatch != null && localMatch.id != null) {
            await _transactionDao.deleteTransaction(localMatch);
          }
        }
      }

      // B. Detect additions of joint transactions by partner:
      for (var ptx in newJointPartnerTxs) {
        final key = ptxKey(ptx);
        if (!localTxMap.containsKey(key)) {
          final accId = getAccountIdByName(ptx.accountName);
          if (accId != null) {
            final catId = getCategoryIdByName(ptx.categoryName) ?? 1;
            final newTx = Transaction(
              accountId: accId,
              categoryId: catId,
              title: ptx.title,
              amount: ptx.amount,
              type: ptx.type,
              date: ptx.date,
              note: ptx.note,
              recurrence: ptx.recurrence,
              isPrivate: false,
              createdAt: DateTime.now(),
            );
            await _transactionDao.insertTransaction(newTx);
          }
        }
      }

      final db = await AppDatabase.instance.database;

      // C. Reconcile Budgets
      if (partnerBudgets != null) {
        for (var pb in partnerBudgets) {
          final catName = pb['c'] as String? ?? 'Other';
          final limit = (pb['l'] as num?)?.toDouble() ?? 0.0;
          final month = pb['m'] as String? ?? '';
          final recurrence = pb['r'] as String? ?? 'monthly';
          final groupName = pb['g'] as String? ?? 'General';
          
          if (month.isEmpty) continue;
          
          final catId = getCategoryIdByName(catName);
          if (catId != null) {
            final existing = await db.query(
              'budget',
              where: 'category_id = ? AND month = ?',
              whereArgs: [catId, month],
            );
            if (existing.isNotEmpty) {
              final existingLimit = (existing.first['limit_amount'] as num).toDouble();
              if ((existingLimit - limit).abs() > 0.01) {
                await db.update(
                  'budget',
                  {
                    'limit_amount': limit,
                    'recurrence': recurrence,
                    'group_name': groupName,
                  },
                  where: 'category_id = ? AND month = ?',
                  whereArgs: [catId, month],
                );
              }
            } else {
              await db.insert(
                'budget',
                {
                  'category_id': catId,
                  'month': month,
                  'limit_amount': limit,
                  'recurrence': recurrence,
                  'group_name': groupName,
                },
              );
            }
          }
        }
      }

      // D. Reconcile Planning Meta (Splits & Strategies)
      if (partnerPlanningMeta != null) {
        for (var pm in partnerPlanningMeta) {
          final month = pm['m'] as String? ?? '';
          final estIncome = (pm['ei'] as num?)?.toDouble() ?? 0.0;
          final strategy = pm['s'] as String? ?? '50/30/20';
          final needs = (pm['n'] as num?)?.toDouble() ?? 0.0;
          final wants = (pm['w'] as num?)?.toDouble() ?? 0.0;
          final savings = (pm['sa'] as num?)?.toDouble() ?? 0.0;
          final investments = (pm['i'] as num?)?.toDouble() ?? 0.0;
          final emergency = (pm['em'] as num?)?.toDouble() ?? 0.0;
          final isCompleted = pm['ic'] as int? ?? 1;
          
          if (month.isEmpty) continue;
          
          final existing = await db.query(
            'planning_meta',
            where: 'month = ?',
            whereArgs: [month],
          );
          if (existing.isNotEmpty) {
            await db.update(
              'planning_meta',
              {
                'estimated_income': estIncome,
                'strategy': strategy,
                'needs_pct': needs,
                'wants_pct': wants,
                'savings_pct': savings,
                'investments_pct': investments,
                'emergency_pct': emergency,
                'is_completed': isCompleted,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'month = ?',
              whereArgs: [month],
            );
          } else {
            await db.insert(
              'planning_meta',
              {
                'month': month,
                'estimated_income': estIncome,
                'strategy': strategy,
                'needs_pct': needs,
                'wants_pct': wants,
                'savings_pct': savings,
                'investments_pct': investments,
                'emergency_pct': emergency,
                'is_completed': isCompleted,
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // 3. Refresh providers
      await ref.read(accountsProvider.notifier).loadAccounts();
      await ref.read(transactionsProvider.notifier).loadTransactions();
      await ref.read(budgetsProvider.notifier).loadBudgetsForCurrentMonth();
      await ref.read(planningStateProvider.notifier).loadPlanningMeta();
    } catch (e, stack) {
      debugPrint('[SyncClient] Reconciliation error: $e\n$stack');
    }
  }
}

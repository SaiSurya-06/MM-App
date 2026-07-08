import '../database.dart';
import '../../../models/transaction.dart';

class TransactionDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertTransaction(Transaction tx) async {
    final db = await _dbProvider.database;
    
    return await db.transaction((txn) async {
      // 1. Insert the transaction
      final id = await txn.insert('transaction_log', tx.toMap());

      // 2. Adjust account balance
      if (tx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        final ccTargetId = tx.transferToAccountId ?? _parseCreditCardTargetAccountId(tx.note);
        if (ccTargetId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [tx.amount, ccTargetId],
          );
        }
      } else if (tx.type == 'transfer') {
        // For transfer, we treat the source account as being debited
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        // If a destination account is specified
        final destAccountId = tx.transferToAccountId ?? _parseDestAccountId(tx.note);
        if (destAccountId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [tx.amount, destAccountId],
          );
        }
      }

      return id;
    });
  }

  Future<int> updateTransaction(Transaction newTx, Transaction oldTx) async {
    final db = await _dbProvider.database;

    return await db.transaction((txn) async {
      // 1. Revert old transaction's balance adjustments
      if (oldTx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [oldTx.amount, oldTx.accountId],
        );
      } else if (oldTx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [oldTx.amount, oldTx.accountId],
        );
        final oldCcTargetId = oldTx.transferToAccountId ?? _parseCreditCardTargetAccountId(oldTx.note);
        if (oldCcTargetId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance - ? WHERE id = ?',
            [oldTx.amount, oldCcTargetId],
          );
        }
      } else if (oldTx.type == 'transfer') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [oldTx.amount, oldTx.accountId],
        );
        final destAccountId = oldTx.transferToAccountId ?? _parseDestAccountId(oldTx.note);
        if (destAccountId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance - ? WHERE id = ?',
            [oldTx.amount, destAccountId],
          );
        }
      }

      // 2. Apply new transaction's balance adjustments
      if (newTx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [newTx.amount, newTx.accountId],
        );
      } else if (newTx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [newTx.amount, newTx.accountId],
        );
        final newCcTargetId = newTx.transferToAccountId ?? _parseCreditCardTargetAccountId(newTx.note);
        if (newCcTargetId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [newTx.amount, newCcTargetId],
          );
        }
      } else if (newTx.type == 'transfer') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [newTx.amount, newTx.accountId],
        );
        final destAccountId = newTx.transferToAccountId ?? _parseDestAccountId(newTx.note);
        if (destAccountId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [newTx.amount, destAccountId],
          );
        }
      }

      // 3. Update the transaction row
      return await txn.update(
        'transaction_log',
        newTx.toMap(),
        where: 'id = ?',
        whereArgs: [newTx.id],
      );
    });
  }

  Future<int> deleteTransaction(Transaction tx) async {
    final db = await _dbProvider.database;

    return await db.transaction((txn) async {
      // 1. Revert balance adjustments
      if (tx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        final ccTargetId = tx.transferToAccountId ?? _parseCreditCardTargetAccountId(tx.note);
        if (ccTargetId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance - ? WHERE id = ?',
            [tx.amount, ccTargetId],
          );
        }
      } else if (tx.type == 'transfer') {
        await txn.rawUpdate(
          'UPDATE account SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        final destAccountId = tx.transferToAccountId ?? _parseDestAccountId(tx.note);
        if (destAccountId != null) {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance - ? WHERE id = ?',
            [tx.amount, destAccountId],
          );
        }
      }

      // 2. Delete child transactions
      await txn.delete(
        'transaction_log',
        where: 'parent_id = ?',
        whereArgs: [tx.id],
      );

      // 3. Delete transaction row
      return await txn.delete(
        'transaction_log',
        where: 'id = ?',
        whereArgs: [tx.id],
      );
    });
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'transaction_log',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await _dbProvider.database;
    final result = await db.query('transaction_log', orderBy: 'date DESC, id DESC');
    return result.map<Transaction>((json) => Transaction.fromMap(json)).toList();
  }

  Future<List<Transaction>> getTransactionsForAccount(int accountId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'transaction_log',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return result.map<Transaction>((json) => Transaction.fromMap(json)).toList();
  }

  Future<List<Transaction>> getTransactionsForCategory(int categoryId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'transaction_log',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC, id DESC',
    );
    return result.map<Transaction>((json) => Transaction.fromMap(json)).toList();
  }

  Future<List<Transaction>> getTransactionsForMonth(String monthStr) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'transaction_log',
      where: "strftime('%Y-%m', date) = ?",
      whereArgs: [monthStr],
      orderBy: 'date DESC, id DESC',
    );
    return result.map<Transaction>((json) => Transaction.fromMap(json)).toList();
  }

  Future<void> bulkDeleteTransactions(List<Transaction> txs) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      for (var tx in txs) {
        if (tx.type == 'income') {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance - ? WHERE id = ?',
            [tx.amount, tx.accountId],
          );
        } else if (tx.type == 'expense') {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [tx.amount, tx.accountId],
          );
          final ccTargetId = tx.transferToAccountId ?? _parseCreditCardTargetAccountId(tx.note);
          if (ccTargetId != null) {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance - ? WHERE id = ?',
              [tx.amount, ccTargetId],
            );
          }
        } else if (tx.type == 'transfer') {
          await txn.rawUpdate(
            'UPDATE account SET balance = balance + ? WHERE id = ?',
            [tx.amount, tx.accountId],
          );
          final destAccountId = tx.transferToAccountId ?? _parseDestAccountId(tx.note);
          if (destAccountId != null) {
            await txn.rawUpdate(
              'UPDATE account SET balance = balance - ? WHERE id = ?',
              [tx.amount, destAccountId],
            );
          }
        }
        await txn.delete(
          'transaction_log',
          where: 'parent_id = ?',
          whereArgs: [tx.id],
        );
        await txn.delete(
          'transaction_log',
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      }
    });
  }

  int? _parseDestAccountId(String? note) {
    if (note == null) return null;
    final regExp = RegExp(r'Transfer to target account ID: (\d+)');
    final match = regExp.firstMatch(note);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  int? _parseCreditCardTargetAccountId(String? note) {
    if (note == null) return null;
    final regExp = RegExp(r'Credit Card Payment to target account ID: (\d+)');
    final match = regExp.firstMatch(note);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

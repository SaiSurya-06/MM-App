import '../database.dart';
import '../../../models/account.dart';

class AccountDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertAccount(Account account) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('account', account.toMap());
    } catch (e) {
      throw Exception('AccountDao.insertAccount failed: $e');
    }
  }

  Future<int> updateAccount(Account account) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'account',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
    } catch (e) {
      throw Exception('AccountDao.updateAccount failed: $e');
    }
  }

  Future<int> deleteAccount(int id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        'account',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('AccountDao.deleteAccount failed: $e');
    }
  }

  Future<Account?> getAccount(int id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'account',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Account.fromMap(maps.first);
    } catch (e) {
      throw Exception('AccountDao.getAccount failed: $e');
    }
  }

  Future<List<Account>> getAllAccounts() async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query(
        'account',
        orderBy: 'id ASC',
      );
      return result.map((json) => Account.fromMap(json)).toList();
    } catch (e) {
      throw Exception('AccountDao.getAllAccounts failed: $e');
    }
  }

  Future<void> recalculateAllBalances() async {
    try {
      final db = await _dbProvider.database;
      await _dbProvider.recalculateAllBalances(db);
    } catch (e) {
      throw Exception('AccountDao.recalculateAllBalances failed: $e');
    }
  }

  Future<int> updateBalance(int accountId, double newBalance) async {
    try {
      final db = await _dbProvider.database;
      return await db.rawUpdate(
        'UPDATE account SET balance = ? WHERE id = ?',
        [newBalance, accountId],
      );
    } catch (e) {
      throw Exception('AccountDao.updateBalance failed: $e');
    }
  }
}

import '../database.dart';
import '../../../../models/debt_loan.dart';

class DebtLoanDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertDebtLoan(DebtLoan dl) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('debt_loan', dl.toMap());
    } catch (e) {
      throw Exception('DebtLoanDao.insertDebtLoan failed: $e');
    }
  }

  Future<int> updateDebtLoan(DebtLoan dl) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'debt_loan',
        dl.toMap(),
        where: 'id = ?',
        whereArgs: [dl.id],
      );
    } catch (e) {
      throw Exception('DebtLoanDao.updateDebtLoan failed: $e');
    }
  }

  Future<int> deleteDebtLoan(int id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        'debt_loan',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('DebtLoanDao.deleteDebtLoan failed: $e');
    }
  }

  Future<DebtLoan?> getDebtLoan(int id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'debt_loan',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return DebtLoan.fromMap(maps.first);
    } catch (e) {
      throw Exception('DebtLoanDao.getDebtLoan failed: $e');
    }
  }

  Future<List<DebtLoan>> getAllDebtLoans() async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query('debt_loan', orderBy: 'created_at DESC');
      return result.map<DebtLoan>((json) => DebtLoan.fromMap(json)).toList();
    } catch (e) {
      throw Exception('DebtLoanDao.getAllDebtLoans failed: $e');
    }
  }
}

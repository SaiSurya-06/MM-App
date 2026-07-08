import '../database.dart';
import '../../../../models/savings_goal.dart';

class SavingsGoalDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertSavingsGoal(SavingsGoal sg) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('savings_goal', sg.toMap());
    } catch (e) {
      throw Exception('SavingsGoalDao.insertSavingsGoal failed: $e');
    }
  }

  Future<int> updateSavingsGoal(SavingsGoal sg) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'savings_goal',
        sg.toMap(),
        where: 'id = ?',
        whereArgs: [sg.id],
      );
    } catch (e) {
      throw Exception('SavingsGoalDao.updateSavingsGoal failed: $e');
    }
  }

  Future<int> deleteSavingsGoal(int id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        'savings_goal',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('SavingsGoalDao.deleteSavingsGoal failed: $e');
    }
  }

  Future<SavingsGoal?> getSavingsGoal(int id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'savings_goal',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return SavingsGoal.fromMap(maps.first);
    } catch (e) {
      throw Exception('SavingsGoalDao.getSavingsGoal failed: $e');
    }
  }

  Future<List<SavingsGoal>> getAllSavingsGoals() async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query('savings_goal', orderBy: 'created_at DESC');
      return result.map<SavingsGoal>((json) => SavingsGoal.fromMap(json)).toList();
    } catch (e) {
      throw Exception('SavingsGoalDao.getAllSavingsGoals failed: $e');
    }
  }
}

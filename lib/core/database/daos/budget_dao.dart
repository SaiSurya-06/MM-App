import '../database.dart';
import '../../../models/budget.dart';

class BudgetDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertBudget(Budget budget) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('budget', budget.toMap());
    } catch (e) {
      throw Exception('BudgetDao.insertBudget failed: $e');
    }
  }

  Future<int> updateBudget(Budget budget) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'budget',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    } catch (e) {
      throw Exception('BudgetDao.updateBudget failed: $e');
    }
  }

  Future<int> deleteBudget(int id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        'budget',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('BudgetDao.deleteBudget failed: $e');
    }
  }

  Future<Budget?> getBudgetForCategoryAndMonth(int categoryId, String month) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'budget',
        where: 'category_id = ? AND month = ?',
        whereArgs: [categoryId, month],
      );
      if (maps.isEmpty) return null;
      return Budget.fromMap(maps.first);
    } catch (e) {
      throw Exception('BudgetDao.getBudgetForCategoryAndMonth failed: $e');
    }
  }

  Future<List<Budget>> getBudgetsForMonth(String month) async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query(
        'budget',
        where: 'month = ?',
        whereArgs: [month],
      );
      final budgets = result.map((json) => Budget.fromMap(json)).toList();
      final seenCategoryIds = <int>{};
      return budgets.where((b) => seenCategoryIds.add(b.categoryId)).toList();
    } catch (e) {
      throw Exception('BudgetDao.getBudgetsForMonth failed: $e');
    }
  }
}

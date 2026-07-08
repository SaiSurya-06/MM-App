import '../database.dart';
import '../../../models/category.dart';

class CategoryDao {
  static const int otherCategoryId = 8;
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertCategory(Category category) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('category', category.toMap());
    } catch (e) {
      throw Exception('CategoryDao.insertCategory failed: $e');
    }
  }

  Future<int> updateCategory(Category category) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'category',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      throw Exception('CategoryDao.updateCategory failed: $e');
    }
  }

  Future<int> deleteCategory(int id) async {
    try {
      final db = await _dbProvider.database;
      return await db.delete(
        'category',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('CategoryDao.deleteCategory failed: $e');
    }
  }

  Future<Category?> getCategory(int id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'category',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return Category.fromMap(maps.first);
    } catch (e) {
      throw Exception('CategoryDao.getCategory failed: $e');
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query('category', orderBy: 'id ASC');
      return result.map((json) => Category.fromMap(json)).toList();
    } catch (e) {
      throw Exception('CategoryDao.getAllCategories failed: $e');
    }
  }
}

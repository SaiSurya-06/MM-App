import '../database.dart';
import '../../../models/user_profile.dart';

class UserProfileDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertProfile(UserProfile profile) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert('user_profile', profile.toMap());
    } catch (e) {
      throw Exception('UserProfileDao.insertProfile failed: $e');
    }
  }

  Future<int> updateProfile(UserProfile profile) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        'user_profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    } catch (e) {
      throw Exception('UserProfileDao.updateProfile failed: $e');
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'user_profile',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return UserProfile.fromMap(maps.first);
    } catch (e) {
      throw Exception('UserProfileDao.getProfile failed: $e');
    }
  }

  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query('user_profile', orderBy: 'id ASC');
      return maps.map((m) => UserProfile.fromMap(m)).toList();
    } catch (e) {
      throw Exception('UserProfileDao.getAllProfiles failed: $e');
    }
  }

  Future<UserProfile?> getProfileById(int id) async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return UserProfile.fromMap(maps.first);
    } catch (e) {
      throw Exception('UserProfileDao.getProfileById failed: $e');
    }
  }
}

import '../database/database.dart';

class HealthScoreService {
  static final HealthScoreService instance = HealthScoreService._internal();
  HealthScoreService._internal();

  static const int maxHistoryDays = 60;

  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final db = await _dbProvider.database;
      return await db.query('health_score_history', orderBy: 'date ASC');
    } catch (e) {
      return [];
    }
  }

  Future<void> recordScore(double score) async {
    try {
      final db = await _dbProvider.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Check if a score is already recorded for today
      final existing = await db.query(
        'health_score_history',
        where: 'date = ?',
        whereArgs: [todayStr],
      );

      if (existing.isNotEmpty) {
        // Update today's score
        await db.update(
          'health_score_history',
          {'score': score},
          where: 'date = ?',
          whereArgs: [todayStr],
        );
      } else {
        // Insert new score
        await db.insert('health_score_history', {
          'date': todayStr,
          'score': score,
        });
      }

      // Keep only last maxHistoryDays days of history to prevent bloating
      final allHistory = await db.query('health_score_history', orderBy: 'date DESC');
      if (allHistory.length > maxHistoryDays) {
        final cutOffId = allHistory[maxHistoryDays - 1]['id'] as int;
        await db.delete(
          'health_score_history',
          where: 'id < ?',
          whereArgs: [cutOffId],
        );
      }
    } catch (_) {
      // Ignore DB errors during background health recording
    }
  }
}

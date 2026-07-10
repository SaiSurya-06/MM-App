import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../database.dart';

class WeeklyCheckin {
  final int? id;
  final String weekEndDate; // e.g., '2026-07-12' (the Sunday date)
  final String mood; // 'great', 'good', 'okay', 'bad'
  final String? reasonTags; // comma-separated e.g. 'Medical,Travel'
  final String? notes;
  final DateTime createdAt;

  WeeklyCheckin({
    this.id,
    required this.weekEndDate,
    required this.mood,
    this.reasonTags,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_end_date': weekEndDate,
      'mood': mood,
      'reason_tags': reasonTags,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyCheckin.fromMap(Map<String, dynamic> map) {
    return WeeklyCheckin(
      id: map['id'] as int?,
      weekEndDate: map['week_end_date'] as String,
      mood: map['mood'] as String,
      reasonTags: map['reason_tags'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class WeeklyCheckinDao {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<int> insertCheckin(WeeklyCheckin checkin) async {
    try {
      final db = await _dbProvider.database;
      return await db.insert(
        'weekly_checkins',
        checkin.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('WeeklyCheckinDao.insertCheckin failed: $e');
    }
  }

  Future<List<WeeklyCheckin>> getAllCheckins() async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query('weekly_checkins', orderBy: 'week_end_date DESC');
      return result.map((json) => WeeklyCheckin.fromMap(json)).toList();
    } catch (e) {
      throw Exception('WeeklyCheckinDao.getAllCheckins failed: $e');
    }
  }

  Future<WeeklyCheckin?> getCheckinForWeek(String weekEndDate) async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query(
        'weekly_checkins',
        where: 'week_end_date = ?',
        whereArgs: [weekEndDate],
      );
      if (result.isEmpty) return null;
      return WeeklyCheckin.fromMap(result.first);
    } catch (e) {
      throw Exception('WeeklyCheckinDao.getCheckinForWeek failed: $e');
    }
  }
}

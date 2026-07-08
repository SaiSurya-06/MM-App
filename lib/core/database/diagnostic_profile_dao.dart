import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database.dart';
import '../../models/diagnostic_profile.dart';

class DiagnosticProfileRecord {
  final int? id;
  final int userProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentAct;
  final int currentSection;
  final bool completed;
  final DiagnosticProfile profile;

  DiagnosticProfileRecord({
    this.id,
    required this.userProfileId,
    required this.createdAt,
    required this.updatedAt,
    required this.currentAct,
    required this.currentSection,
    required this.completed,
    required this.profile,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_profile_id': userProfileId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'current_act': currentAct,
      'current_section': currentSection,
      'completed': completed ? 1 : 0,
      'profile_json': jsonEncode(profile.toJson()),
    };
  }

  factory DiagnosticProfileRecord.fromMap(Map<String, dynamic> map) {
    return DiagnosticProfileRecord(
      id: map['id'] as int?,
      userProfileId: map['user_profile_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      currentAct: map['current_act'] as int,
      currentSection: map['current_section'] as int,
      completed: (map['completed'] as int) == 1,
      profile: DiagnosticProfile.fromJson(
        jsonDecode(map['profile_json'] as String) as Map<String, dynamic>,
      ),
    );
  }

  DiagnosticProfileRecord copyWith({
    int? id,
    int? userProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentAct,
    int? currentSection,
    bool? completed,
    DiagnosticProfile? profile,
  }) {
    return DiagnosticProfileRecord(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentAct: currentAct ?? this.currentAct,
      currentSection: currentSection ?? this.currentSection,
      completed: completed ?? this.completed,
      profile: profile ?? this.profile,
    );
  }
}

class DiagnosticProfileDao {
  final AppDatabase _dbProvider = AppDatabase.instance;
  final Database? _mockDb;

  DiagnosticProfileDao([this._mockDb]);

  Future<Database> get _db async => _mockDb ?? await _dbProvider.database;

  Future<DiagnosticProfileRecord?> getActiveProfile(int userProfileId) async {
    try {
      final db = await _db;
      final maps = await db.query(
        'diagnostic_profile',
        where: 'user_profile_id = ?',
        whereArgs: [userProfileId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return DiagnosticProfileRecord.fromMap(maps.first);
    } catch (e) {
      throw Exception('DiagnosticProfileDao.getActiveProfile failed: $e');
    }
  }

  Future<int> upsertProfile(DiagnosticProfileRecord record) async {
    try {
      final db = await _db;
      final existing = await getActiveProfile(record.userProfileId);
      if (existing != null) {
        final updatedRecord = record.copyWith(
          id: existing.id,
          createdAt: existing.createdAt, // Keep original creation time
          updatedAt: DateTime.now(),
        );
        await db.update(
          'diagnostic_profile',
          updatedRecord.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return existing.id!;
      } else {
        final newRecord = record.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return await db.insert('diagnostic_profile', newRecord.toMap());
      }
    } catch (e) {
      throw Exception('DiagnosticProfileDao.upsertProfile failed: $e');
    }
  }

  Future<void> markCompleted(int id) async {
    try {
      final db = await _db;
      await db.update(
        'diagnostic_profile',
        {
          'completed': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('DiagnosticProfileDao.markCompleted failed: $e');
    }
  }

  Future<void> deleteProfile(int userProfileId) async {
    try {
      final db = await _db;
      await db.delete(
        'diagnostic_profile',
        where: 'user_profile_id = ?',
        whereArgs: [userProfileId],
      );
    } catch (e) {
      throw Exception('DiagnosticProfileDao.deleteProfile failed: $e');
    }
  }
}

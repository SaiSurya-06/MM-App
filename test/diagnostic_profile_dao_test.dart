import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:money_manager/core/database/diagnostic_profile_dao.dart';
import 'package:money_manager/models/diagnostic_profile.dart';

class MockDatabase implements Database {
  final List<Map<String, dynamic>> tables = [];
  int idCounter = 1;

  @override
  Future<int> insert(String table, Map<String, dynamic> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final map = Map<String, dynamic>.from(values);
    if (!map.containsKey('id')) {
      map['id'] = idCounter++;
    }
    tables.add(map);
    return map['id'] as int;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    if (where != null && whereArgs != null) {
      final userId = whereArgs.first as int;
      return tables.where((m) => m['user_profile_id'] == userId).toList();
    }
    return tables;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) async {
    if (whereArgs != null) {
      final id = whereArgs.first as int;
      final idx = tables.indexWhere((m) => m['id'] == id);
      if (idx != -1) {
        tables[idx] = Map<String, dynamic>.from(tables[idx])..addAll(values);
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    if (whereArgs != null) {
      final userId = whereArgs.first as int;
      tables.removeWhere((m) => m['user_profile_id'] == userId);
      return 1;
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DiagnosticProfileDao Mock Tests', () {
    late MockDatabase mockDb;
    late DiagnosticProfileDao dao;

    setUp(() {
      mockDb = MockDatabase();
      dao = DiagnosticProfileDao(mockDb);
    });

    test('getActiveProfile returns null for new user', () async {
      final profile = await dao.getActiveProfile(999);
      expect(profile, isNull);
    });

    test('upsertProfile creates new record, second upsert updates existing', () async {
      final record1 = DiagnosticProfileRecord(
        userProfileId: 101,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentAct: 1,
        currentSection: 2,
        completed: false,
        profile: DiagnosticProfile.empty().copyWith(
          you: YouSection.empty().copyWith(name: 'Alice'),
        ),
      );

      final id1 = await dao.upsertProfile(record1);
      expect(id1, 1);

      // Verify created
      final fetched1 = await dao.getActiveProfile(101);
      expect(fetched1, isNotNull);
      expect(fetched1!.profile.you.name, 'Alice');
      expect(fetched1.currentSection, 2);

      // Update same user
      final record2 = record1.copyWith(
        currentSection: 3,
        profile: DiagnosticProfile.empty().copyWith(
          you: YouSection.empty().copyWith(name: 'Alice Cooper'),
        ),
      );

      final id2 = await dao.upsertProfile(record2);
      expect(id2, 1); // should update existing id 1

      // Verify updated
      final fetched2 = await dao.getActiveProfile(101);
      expect(fetched2, isNotNull);
      expect(fetched2!.profile.you.name, 'Alice Cooper');
      expect(fetched2.currentSection, 3);
      expect(mockDb.tables.length, 1); // Still only 1 row in the table
    });
  });
}

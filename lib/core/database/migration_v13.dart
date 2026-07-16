import 'package:sqflite/sqflite.dart';

/// Migration class for database version 13.
/// This migration:
/// 1. Adds 'pin_salt' column to the 'user_profile' table.
/// 2. Creates the 'chatbot_message' table with a foreign key reference to 'user_profile'.
class MigrationV13 {
  static Future<void> run(Database db) async {
    // 1. Add pin_salt to user_profile
    await db.execute("ALTER TABLE user_profile ADD COLUMN pin_salt TEXT");

    // 2. Create chatbot_message table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chatbot_message (
        id TEXT PRIMARY KEY,
        profile_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        chart_type TEXT,
        FOREIGN KEY (profile_id) REFERENCES user_profile(id) ON DELETE CASCADE
      )
    ''');
  }
}

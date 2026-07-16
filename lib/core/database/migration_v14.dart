import 'package:sqflite/sqflite.dart';

/// Migration class for database version 14.
/// This migration adds indexes on 'transaction_log' table columns.
class MigrationV14 {
  static Future<void> run(Database db) async {
    await db.execute("CREATE INDEX IF NOT EXISTS idx_txlog_date ON transaction_log(date)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_txlog_account ON transaction_log(account_id)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_txlog_category ON transaction_log(category_id)");
    await db.execute("CREATE INDEX IF NOT EXISTS idx_txlog_type_date ON transaction_log(type, date)");
  }
}

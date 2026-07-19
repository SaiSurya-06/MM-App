import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart' show deleteDatabase;
import '../database/database.dart';
import '../database/daos/category_dao.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  // Track if we are running in simulated fallback mode
  bool isSimulatedMode = false;

  void enableSimulatedMode() {
    isSimulatedMode = true;
    _currentUser = null;
  }

  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      isSimulatedMode = false;
      return _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    if (isSimulatedMode) {
      isSimulatedMode = false;
      return;
    }
    try {
      _currentUser = await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      debugPrint('Silent error in BackupService.signOut: $e\n$stackTrace');
    }
  }

  // --- General Google Drive File Upload & Download Helpers ---

  Future<bool> backupFileToDrive(File localFile, String driveFileName) async {
    if (!await localFile.exists()) return false;

    if (isSimulatedMode) {
      final dbFolder = await getApplicationDocumentsDirectory();
      final backupPath = p.join(dbFolder.path, 'simulated_$driveFileName');
      await localFile.copy(backupPath);
      return true;
    }

    if (_currentUser == null) throw Exception('Google account is not signed in.');

    final authHeaders = await _currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    // Search for existing file
    final fileList = await driveApi.files.list(
      q: "name = '$driveFileName' and trashed = false",
      spaces: 'appDataFolder',
    );

    final media = drive.Media(localFile.openRead(), await localFile.length());
    final driveFile = drive.File()
      ..name = driveFileName
      ..parents = ['appDataFolder'];

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(
        drive.File()..name = driveFileName,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
    }
    return true;
  }

  Future<bool> restoreFileFromDrive(String driveFileName, File localDestinationFile) async {
    if (isSimulatedMode) {
      final dbFolder = await getApplicationDocumentsDirectory();
      final backupPath = p.join(dbFolder.path, 'simulated_$driveFileName');
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) return false;
      
      await backupFile.copy(localDestinationFile.path);
      return true;
    }

    if (_currentUser == null) throw Exception('Google account is not signed in.');

    final authHeaders = await _currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    final fileList = await driveApi.files.list(
      q: "name = '$driveFileName' and trashed = false",
      spaces: 'appDataFolder',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      throw Exception('No backup file named "$driveFileName" found on Google Drive.');
    }

    final fileId = fileList.files!.first.id!;
    final drive.Media response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataStore = [];
    await response.stream.forEach((data) {
      dataStore.addAll(data);
    });
    await localDestinationFile.writeAsBytes(dataStore);
    return true;
  }

  // --- SQLite Legacy Wrappers ---

  Future<bool> backupDatabase() async {
    return backupToGoogleDrive('sqlite');
  }

  Future<bool> restoreDatabase() async {
    return restoreFromGoogleDrive('sqlite');
  }

  // --- Advanced Backup Formats Serializer & Deserializers ---

  Future<String> exportDataToJson() async {
    final db = await AppDatabase.instance.database;
    final Map<String, dynamic> data = {};
    
    final tables = [
      'user_profile',
      'account',
      'category',
      'transaction_log',
      'budget',
      'savings_goal',
      'debt_loan',
      'filter_preset',
      'diagnostic_profile'
    ];

    for (var table in tables) {
      try {
        final list = await db.query(table);
        data[table] = list;
      } catch (e, stackTrace) {
        debugPrint('Silent error exporting table $table in BackupService.exportDatabaseToJson: $e\n$stackTrace');
      }
    }
    return jsonEncode(data);
  }

  Future<void> importDataFromJson(String jsonStr) async {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final db = await AppDatabase.instance.database;

    await db.transaction((txn) async {
      final tables = [
        'user_profile',
        'account',
        'category',
        'transaction_log',
        'budget',
        'savings_goal',
        'debt_loan',
        'filter_preset',
        'diagnostic_profile'
      ];

      for (var table in tables) {
        if (data.containsKey(table)) {
          await txn.delete(table);
          final List<dynamic> rows = data[table];
          for (var row in rows) {
            if (row is Map<String, dynamic>) {
              await txn.insert(table, row);
            }
          }
        }
      }
    });
  }

  Future<String> exportDataToCsv() async {
    final db = await AppDatabase.instance.database;
    final List<List<dynamic>> csvData = [
      ['Date', 'Title', 'Amount', 'Type', 'Category', 'Account', 'Note', 'Recurrence', 'Recurrence End Date', 'Is Private']
    ];

    final txs = await db.query('transaction_log');
    
    final accounts = await db.query('account');
    final Map<int, String> accountMap = {
      for (var row in accounts) row['id'] as int: row['name'] as String
    };

    final categories = await db.query('category');
    final Map<int, String> categoryMap = {
      for (var row in categories) row['id'] as int: row['name'] as String
    };

    for (var tx in txs) {
      final date = tx['date'] as String;
      final title = tx['title'] as String;
      final amount = (tx['amount'] as num).toDouble();
      final type = tx['type'] as String;
      final categoryName = categoryMap[tx['category_id'] as int] ?? 'Other';
      final accountName = accountMap[tx['account_id'] as int] ?? 'Account';
      final note = tx['note'] as String? ?? '';
      final recurrence = tx['recurrence'] as String? ?? 'none';
      final recEnd = tx['recurrence_end_date'] as String? ?? '';
      final isPrivate = (tx['is_private'] as int? ?? 0) == 1 ? 'yes' : 'no';

      csvData.add([
        date,
        title,
        amount,
        type,
        categoryName,
        accountName,
        note,
        recurrence,
        recEnd,
        isPrivate
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  Future<void> importDataFromCsv(String csvStr) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvStr);
    if (rows.isEmpty) return;

    int headerRowIndex = -1;
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 6) {
        final firstCol = row[0].toString().toLowerCase().trim();
        final secondCol = row[1].toString().toLowerCase().trim();
        if (firstCol == 'date' && secondCol == 'title') {
          headerRowIndex = i;
          break;
        }
      }
    }

    if (headerRowIndex == -1) {
      throw Exception('Invalid CSV file: missing transaction headers');
    }

    final db = await AppDatabase.instance.database;

    final categoryList = await db.query('category');
    final Map<String, int> categoryNameToId = {
      for (var row in categoryList) (row['name'] as String).toLowerCase().trim(): row['id'] as int
    };
    int otherCategoryId = categoryNameToId['other'] ?? CategoryDao.otherCategoryId;

    final accountList = await db.query('account');
    final Map<String, int> accountNameToId = {
      for (var row in accountList) (row['name'] as String).toLowerCase().trim(): row['id'] as int
    };

    await db.transaction((txn) async {
      await txn.delete('transaction_log');
      await txn.rawUpdate('UPDATE account SET balance = 0.0');

      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;

        final dateStr = row[0].toString().trim();
        final title = row[1].toString().trim();
        final amount = double.tryParse(row[2].toString()) ?? 0.0;
        final type = row[3].toString().trim().toLowerCase();
        final categoryName = row[4].toString().trim();
        final accountName = row[5].toString().trim();
        final note = row.length > 6 ? row[6].toString().trim() : '';
        final recurrence = row.length > 7 ? row[7].toString().trim().toLowerCase() : 'none';
        final recEndStr = row.length > 8 ? row[8].toString().trim() : '';
        final isPrivateStr = row.length > 9 ? row[9].toString().trim().toLowerCase() : 'no';

        if (title.isEmpty || amount <= 0 || !['income', 'expense', 'transfer'].contains(type)) {
          continue;
        }

        int categoryId = categoryNameToId[categoryName.toLowerCase()] ?? otherCategoryId;

        int? accountId = accountNameToId[accountName.toLowerCase()];
        if (accountId == null) {
          accountId = await txn.insert('account', {
            'name': accountName,
            'type': 'Bank',
            'balance': 0.0,
            'icon': 'account_balance',
            'color': '1E88E5',
            'is_shared': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
          accountNameToId[accountName.toLowerCase()] = accountId;
        }

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }

        DateTime? recurrenceEndDate;
        if (recurrence != 'none' && recEndStr.isNotEmpty) {
          try {
            recurrenceEndDate = DateTime.parse(recEndStr);
          } catch (e, stackTrace) {
            debugPrint('Silent error parsing recurrenceEndDate in BackupService.importDataFromJson: $e\n$stackTrace');
          }
        }

        final isPrivate = isPrivateStr == 'yes' || isPrivateStr == 'true' || isPrivateStr == '1';

        await txn.insert('transaction_log', {
          'account_id': accountId,
          'category_id': categoryId,
          'title': title,
          'amount': amount,
          'type': type,
          'date': date.toIso8601String().substring(0, 10),
          'note': note.isEmpty ? null : note,
          'recurrence': recurrence,
          'recurrence_end_date': recurrenceEndDate?.toIso8601String().substring(0, 10),
          'is_private': isPrivate ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (type == 'income') {
          await txn.rawUpdate('UPDATE account SET balance = balance + ? WHERE id = ?', [amount, accountId]);
        } else if (type == 'expense') {
          await txn.rawUpdate('UPDATE account SET balance = balance - ? WHERE id = ?', [amount, accountId]);
        } else if (type == 'transfer') {
          await txn.rawUpdate('UPDATE account SET balance = balance - ? WHERE id = ?', [amount, accountId]);
          final destRegExp = RegExp(r'Transfer to target account ID: (\d+)');
          final match = destRegExp.firstMatch(note);
          if (match != null) {
            final destId = int.tryParse(match.group(1) ?? '');
            if (destId != null) {
              await txn.rawUpdate('UPDATE account SET balance = balance + ? WHERE id = ?', [amount, destId]);
            }
          }
        }
      }
    });
  }

  // --- High-Level Local Backup & Restore Entry Points ---

  Future<bool> backupToLocal(String format) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      
      File fileToShare;
      String fileName;

      if (format == 'sqlite') {
        await AppDatabase.instance.close();
        final localDbPath = p.join(dbFolder.path, 'money_manager.db');
        final dbFile = File(localDbPath);
        if (!await dbFile.exists()) return false;
        
        fileName = 'money_manager_backup.db';
        final tempFile = File(p.join(tempDir.path, fileName));
        await dbFile.copy(tempFile.path);
        fileToShare = tempFile;
      } else if (format == 'json') {
        final jsonStr = await exportDataToJson();
        fileName = 'money_manager_backup.json';
        final tempFile = File(p.join(tempDir.path, fileName));
        await tempFile.writeAsString(jsonStr);
        fileToShare = tempFile;
      } else if (format == 'csv') {
        final csvStr = await exportDataToCsv();
        fileName = 'money_manager_backup.csv';
        final tempFile = File(p.join(tempDir.path, fileName));
        await tempFile.writeAsString(csvStr);
        fileToShare = tempFile;
      } else {
        return false;
      }

      await Share.shareXFiles(
        [XFile(fileToShare.path, mimeType: format == 'sqlite' ? 'application/octet-stream' : 'text/$format')],
        subject: 'Money Manager Backup (${format.toUpperCase()})',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearDatabaseFiles(String localDbPath) async {
    try {
      await deleteDatabase(localDbPath);
    } catch (e, stackTrace) {
      debugPrint('Failed to delete database via sqflite deleteDatabase: $e\n$stackTrace');
    }

    final walFile = File('$localDbPath-wal');
    final shmFile = File('$localDbPath-shm');
    final dbFile = File(localDbPath);

    if (await walFile.exists()) {
      try {
        await walFile.delete();
      } catch (e, stackTrace) {
        debugPrint('Failed to delete WAL file manually: $e\n$stackTrace');
      }
    }
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
      } catch (e, stackTrace) {
        debugPrint('Failed to delete SHM file manually: $e\n$stackTrace');
      }
    }
    if (await dbFile.exists()) {
      try {
        await dbFile.delete();
      } catch (e, stackTrace) {
        debugPrint('Failed to delete main DB file manually: $e\n$stackTrace');
      }
    }
  }

  Future<bool> restoreFromLocal(String format) async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        return false;
      }

      final file = pickerResult.files.single;

      if (format == 'sqlite') {
        AppDatabase.isRestoring = true;
        try {
          final dbFolder = await getApplicationDocumentsDirectory();
          final localDbPath = p.join(dbFolder.path, 'money_manager.db');
          await AppDatabase.instance.close();
          await _clearDatabaseFiles(localDbPath);
          if (file.path != null) {
            await File(file.path!).copy(localDbPath);
            return true;
          } else if (file.bytes != null) {
            await File(localDbPath).writeAsBytes(file.bytes!);
            return true;
          }
          return false;
        } finally {
          AppDatabase.isRestoring = false;
        }
      }

      // Get the file content as String (for JSON/CSV)
      String? fileContent;
      if (file.bytes != null) {
        fileContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        final pickedFile = File(file.path!);
        fileContent = await pickedFile.readAsString();
      }

      if (format == 'json') {
        if (fileContent == null) return false;
        await importDataFromJson(fileContent);
        return true;
      } else if (format == 'csv') {
        if (fileContent == null) return false;
        await importDataFromCsv(fileContent);
        return true;
      }
      return false;
    } catch (e, stack) {
      print('Error in restoreFromLocal: $e');
      print(stack);
      return false;
    }
  }

  // --- High-Level Google Drive Backup & Restore Entry Points ---

  Future<bool> backupToGoogleDrive(String format) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      File localFile;
      String driveFileName;

      if (format == 'sqlite') {
        await AppDatabase.instance.close();
        final localDbPath = p.join(dbFolder.path, 'money_manager.db');
        localFile = File(localDbPath);
        driveFileName = 'money_manager_backup.db';
      } else if (format == 'json') {
        final jsonStr = await exportDataToJson();
        driveFileName = 'money_manager_backup.json';
        localFile = File(p.join(tempDir.path, driveFileName));
        await localFile.writeAsString(jsonStr);
      } else if (format == 'csv') {
        final csvStr = await exportDataToCsv();
        driveFileName = 'money_manager_backup.csv';
        localFile = File(p.join(tempDir.path, driveFileName));
        await localFile.writeAsString(csvStr);
      } else {
        return false;
      }

      return await backupFileToDrive(localFile, driveFileName);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreFromGoogleDrive(String format) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      
      if (format == 'sqlite') {
        AppDatabase.isRestoring = true;
        try {
          final localDbPath = p.join(dbFolder.path, 'money_manager.db');
          await AppDatabase.instance.close();
          await _clearDatabaseFiles(localDbPath);
          final success = await restoreFileFromDrive('money_manager_backup.db', File(localDbPath));
          return success;
        } finally {
          AppDatabase.isRestoring = false;
        }
      } else if (format == 'json') {
        final tempFile = File(p.join(tempDir.path, 'money_manager_backup.json'));
        final success = await restoreFileFromDrive('money_manager_backup.json', tempFile);
        if (!success) return false;
        
        final jsonStr = await tempFile.readAsString();
        await importDataFromJson(jsonStr);
        return true;
      } else if (format == 'csv') {
        final tempFile = File(p.join(tempDir.path, 'money_manager_backup.csv'));
        final success = await restoreFileFromDrive('money_manager_backup.csv', tempFile);
        if (!success) return false;

        final csvStr = await tempFile.readAsString();
        await importDataFromCsv(csvStr);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}


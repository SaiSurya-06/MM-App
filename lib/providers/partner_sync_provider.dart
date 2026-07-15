import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../core/utils/share_code_encoder.dart';
import '../core/utils/encryption_service.dart';
import '../core/database/database.dart';
import 'accounts_provider.dart';
import 'transactions_provider.dart';
import 'categories_provider.dart';
import 'auth_provider.dart';
import '../core/sync/sync_client.dart';
import '../core/database/daos/account_dao.dart';
import '../core/database/daos/transaction_dao.dart';

class PartnerTransaction {
  final String title;
  final double amount;
  final String type;
  final DateTime date;
  final String? note;
  final String recurrence;
  final String accountName;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;

  PartnerTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.recurrence,
    required this.accountName,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
      'recurrence': recurrence,
      'accountName': accountName,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
    };
  }

  factory PartnerTransaction.fromMap(Map<String, dynamic> map) {
    String txType = map['type'] as String? ?? 'expense';
    if (map['y'] != null) {
      final y = map['y'] as String;
      txType = y == 'i' ? 'income' : (y == 'e' ? 'expense' : 'transfer');
    }
    
    String rec = map['recurrence'] as String? ?? 'none';
    if (map['r'] != null) {
      final r = map['r'] as String;
      rec = r == 'n' ? 'none' : (r == 'd' ? 'daily' : (r == 'w' ? 'weekly' : (r == 'm' ? 'monthly' : (r == 'y' ? 'yearly' : 'none'))));
    }

    return PartnerTransaction(
      title: map['t'] as String? ?? map['title'] as String? ?? '',
      amount: (map['a'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: txType,
      date: DateTime.parse(map['d'] as String? ?? map['date'] as String? ?? DateTime.now().toIso8601String()),
      note: map['n'] as String? ?? map['note'] as String?,
      recurrence: rec,
      accountName: map['ac'] as String? ?? map['accountName'] as String? ?? 'Account',
      categoryName: map['c'] as String? ?? map['categoryName'] as String? ?? 'Other',
      categoryIcon: map['categoryIcon'] as String? ?? 'category',
      categoryColor: map['categoryColor'] as String? ?? '757575',
    );
  }
}

class ConflictRecord {
  final String type; // 'account' or 'transaction'
  final String name;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> partnerData;

  ConflictRecord({
    required this.type,
    required this.name,
    required this.localData,
    required this.partnerData,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'localData': localData,
      'partnerData': partnerData,
    };
  }

  factory ConflictRecord.fromMap(Map<String, dynamic> map) {
    return ConflictRecord(
      type: map['type'] as String,
      name: map['name'] as String,
      localData: Map<String, dynamic>.from(map['localData'] as Map),
      partnerData: Map<String, dynamic>.from(map['partnerData'] as Map),
    );
  }
}

class PartnerSyncState {
  final bool isConnected;
  final String roomCode;
  final String mySlot; // 'A' or 'B'
  final String webAppUrl;
  final String partnerName;
  final String partnerCurrency;
  final String partnerTheme;
  final List<Account> partnerAccounts;
  final List<PartnerTransaction> partnerTransactions;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final String? syncPassword;
  final String? syncSalt;
  final List<ConflictRecord> conflicts;
  final int partnerVersion; // For incremental sync
  final double syncProgress; // 0.0 to 1.0
  final String? syncStatusMessage;

  PartnerSyncState({
    required this.isConnected,
    required this.roomCode,
    required this.mySlot,
    required this.webAppUrl,
    required this.partnerName,
    required this.partnerCurrency,
    this.partnerTheme = 'dark',
    required this.partnerAccounts,
    required this.partnerTransactions,
    this.isSyncing = false,
    this.lastSyncTime,
    this.errorMessage,
    this.syncPassword,
    this.syncSalt,
    this.conflicts = const [],
    this.partnerVersion = 0,
    this.syncProgress = 0.0,
    this.syncStatusMessage,
  });

  PartnerSyncState copyWith({
    bool? isConnected,
    String? roomCode,
    String? mySlot,
    String? webAppUrl,
    String? partnerName,
    String? partnerCurrency,
    String? partnerTheme,
    List<Account>? partnerAccounts,
    List<PartnerTransaction>? partnerTransactions,
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? errorMessage,
    String? syncPassword,
    String? syncSalt,
    List<ConflictRecord>? conflicts,
    int? partnerVersion,
    double? syncProgress,
    String? syncStatusMessage,
  }) {
    return PartnerSyncState(
      isConnected: isConnected ?? this.isConnected,
      roomCode: roomCode ?? this.roomCode,
      mySlot: mySlot ?? this.mySlot,
      webAppUrl: webAppUrl ?? this.webAppUrl,
      partnerName: partnerName ?? this.partnerName,
      partnerCurrency: partnerCurrency ?? this.partnerCurrency,
      partnerTheme: partnerTheme ?? this.partnerTheme,
      partnerAccounts: partnerAccounts ?? this.partnerAccounts,
      partnerTransactions: partnerTransactions ?? this.partnerTransactions,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
      syncPassword: syncPassword ?? this.syncPassword,
      syncSalt: syncSalt ?? this.syncSalt,
      conflicts: conflicts ?? this.conflicts,
      partnerVersion: partnerVersion ?? this.partnerVersion,
      syncProgress: syncProgress ?? this.syncProgress,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
    );
  }
}

class PartnerSyncNotifier extends StateNotifier<PartnerSyncState> {
  final Ref _ref;
  Timer? _syncTimer;

  String _cleanExceptionMessage(dynamic error) {
    final msg = error.toString();
    return msg.replaceFirst(RegExp(r'^([a-zA-Z]*Exception|[a-zA-Z]*Error):\s*'), '');
  }

  PartnerSyncNotifier(this._ref)
      : super(PartnerSyncState(
          isConnected: false,
          roomCode: '',
          mySlot: '',
          webAppUrl: '',
          partnerName: '',
          partnerCurrency: 'USD',
          partnerAccounts: [],
          partnerTransactions: [],
        )) {
    _loadStateLocally();
  }

  Future<File> get _stateFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/partner_sync_state.json');
  }

  Future<void> _saveStateLocally() async {
    try {
      final file = await _stateFile;
      final jsonStr = jsonEncode({
        'isConnected': state.isConnected,
        'roomCode': state.roomCode,
        'mySlot': state.mySlot,
        'webAppUrl': state.webAppUrl,
        'partnerName': state.partnerName,
        'partnerCurrency': state.partnerCurrency,
        'partnerTheme': state.partnerTheme,
        'partnerAccounts': state.partnerAccounts.map((a) => a.toMap()..['pending_payment'] = a.pendingPayment).toList(),
        'partnerTransactions': state.partnerTransactions.map((t) => t.toMap()).toList(),
        'lastSyncTime': state.lastSyncTime?.toIso8601String(),
        'syncPassword': state.syncPassword,
        'syncSalt': state.syncSalt,
        'conflicts': state.conflicts.map((c) => c.toMap()).toList(),
        'partnerVersion': state.partnerVersion,
      });
      await file.writeAsString(jsonStr);
    } catch (e) {
      debugPrint('Error saving partner sync state: $e');
    }
  }

  Future<void> _loadStateLocally() async {
    try {
      final file = await _stateFile;
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;

        final accountsList = (data['partnerAccounts'] as List? ?? [])
            .map((a) => Account.fromMap(a as Map<String, dynamic>))
            .toList();

        final txList = (data['partnerTransactions'] as List? ?? [])
            .map((t) => PartnerTransaction.fromMap(t as Map<String, dynamic>))
            .toList();

        final conflictsList = (data['conflicts'] as List? ?? [])
            .map((c) => ConflictRecord.fromMap(c as Map<String, dynamic>))
            .toList();

        state = PartnerSyncState(
          isConnected: data['isConnected'] as bool? ?? false,
          roomCode: data['roomCode'] as String? ?? '',
          mySlot: data['mySlot'] as String? ?? '',
          webAppUrl: data['webAppUrl'] as String? ?? '',
          partnerName: data['partnerName'] as String? ?? '',
          partnerCurrency: data['partnerCurrency'] as String? ?? 'USD',
          partnerTheme: data['partnerTheme'] as String? ?? 'dark',
          partnerAccounts: accountsList,
          partnerTransactions: txList,
          lastSyncTime: data['lastSyncTime'] != null
              ? DateTime.tryParse(data['lastSyncTime'] as String)
              : null,
          syncPassword: data['syncPassword'] as String?,
          syncSalt: data['syncSalt'] as String?,
          conflicts: conflictsList,
          partnerVersion: data['partnerVersion'] as int? ?? 0,
        );

        if (state.isConnected) {
          _startSyncTimer();
          Future.microtask(() => cleanupPartnerDataFromLocalDB());
        }
      }
    } catch (e) {
      debugPrint('Error loading partner sync state: $e');
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    if (state.isConnected && state.mySlot == 'A' && state.partnerName == 'Waiting...') {
      // Start a slow periodic background timer only while the host is waiting for a partner.
      // Once the partner joins, this timer is stopped immediately.
      _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (state.isConnected && state.mySlot == 'A' && state.partnerName == 'Waiting...') {
          syncNow();
        } else {
          _stopSyncTimer();
        }
      });
    }
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<bool> testConnection(String url) async {
    final client = HttpClient();
    try {
      final cleanedUrl = url.trim();
      if (cleanedUrl.isEmpty) return false;

      final baseUri = Uri.parse(cleanedUrl);
      final queryParams = Map<String, dynamic>.from(baseUri.queryParameters);
      queryParams['action'] = 'test';
      final uri = baseUri.replace(queryParameters: queryParams);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        return responseBody.trim() == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Test connection error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  String _generateRandomKey(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<String?> generateInviteCode(String url) async {
    final isValid = await testConnection(url);
    if (!isValid) {
      state = state.copyWith(errorMessage: 'Connection verification failed. Please check your Web App URL.');
      return null;
    }

    final code = _generateRoomCode();
    final secretPassword = _generateRandomKey(16);
    final secretSalt = _generateRandomKey(16);

    final invitePayload = {
      'url': url.trim(),
      'room': code,
      'slot': 'A',
      'password': secretPassword,
      'salt': secretSalt,
    };

    final inviteCode = ShareCodeEncoder.encode(invitePayload);

    state = PartnerSyncState(
      isConnected: true,
      roomCode: code,
      mySlot: 'A',
      webAppUrl: url.trim(),
      partnerName: 'Waiting...',
      partnerCurrency: 'USD',
      partnerAccounts: [],
      partnerTransactions: [],
      lastSyncTime: DateTime.now(),
      syncPassword: secretPassword,
      syncSalt: secretSalt,
    );

    await _saveStateLocally();
    _startSyncTimer();
    
    // Perform initial upload
    syncNow();

    return inviteCode;
  }

  Future<bool> joinWithInviteCode(String inviteCode) async {
    try {
      state = state.copyWith(isSyncing: true, errorMessage: null);

      final invitePayload = ShareCodeEncoder.decode(inviteCode);
      final url = invitePayload['url'] as String? ?? '';
      final room = invitePayload['room'] as String? ?? '';
      final parentSlot = invitePayload['slot'] as String? ?? 'A';
      final syncPassword = invitePayload['password'] as String? ?? '';
      final syncSalt = invitePayload['salt'] as String? ?? '';

      if (url.isEmpty || room.isEmpty) {
        throw Exception('Invalid invite code parameters.');
      }

      // Guest joins as the opposite of the host's slot (e.g. if host is 'A', guest is 'B')
      final mySlot = parentSlot == 'A' ? 'B' : 'A';

      final isValid = await testConnection(url);
      if (!isValid) {
        throw Exception('Could not connect to the host spreadsheet script.');
      }

      state = PartnerSyncState(
        isConnected: true,
        roomCode: room,
        mySlot: mySlot,
        webAppUrl: url,
        partnerName: 'Connecting...',
        partnerCurrency: 'USD',
        partnerAccounts: [],
        partnerTransactions: [],
        syncPassword: syncPassword,
        syncSalt: syncSalt,
      );

      _startSyncTimer();
      final success = await syncNow();
      if (!success) {
        throw Exception('Connected but failed to sync initial data.');
      }

      return true;
    } catch (e) {
      final errorMsg = _cleanExceptionMessage(e);
      state = state.copyWith(
        isSyncing: false,
        isConnected: false,
        errorMessage: errorMsg,
      );
      _stopSyncTimer();
      return false;
    }
  }

  Future<bool> syncNow() async {
    if (!state.isConnected) return false;
    if (state.isSyncing) {
      debugPrint('[PartnerSync] Already syncing, skipping duplicate syncNow execution.');
      return false;
    }

    try {
      state = state.copyWith(
        isSyncing: true,
        errorMessage: null,
        syncProgress: 0.0,
        syncStatusMessage: 'Preparing sync payload...',
      );

      // 1. Export local data ONLY if there are local changes, or if it's the first sync
      // Always generate and upload local payload to ensure data integrity and send any local updates
      final localPayload = await _generateLocalPayload();
      await _uploadData(localPayload);
      await AppDatabase.clearSyncQueue();

      // 2. Import partner data (supports incremental sync)
      final partnerDataStr = await _downloadData();
      if (partnerDataStr != null) {
        state = state.copyWith(
          syncProgress: 0.75,
          syncStatusMessage: 'Processing partner payload...',
        );
        var decoded = ShareCodeEncoder.decode(partnerDataStr);

        // Handle incremental sync response
        if (decoded.containsKey('changes') && decoded.containsKey('isIncremental')) {
          final changes = decoded['changes'] as Map<String, dynamic>;
          final version = decoded['version'] as int? ?? 0;
          decoded = changes;
          state = state.copyWith(partnerVersion: version);
        }
        if (decoded.containsKey('encrypted') && state.syncPassword != null && state.syncPassword!.isNotEmpty) {
          try {
            final ciphertext = decoded['encrypted'] as String;
            final decryptedJson = EncryptionService.instance.decrypt(
              ciphertext,
              state.syncPassword!,
              state.syncSalt ?? 'default_salt',
            );
            decoded = jsonDecode(decryptedJson) as Map<String, dynamic>;
          } catch (e) {
            throw Exception('Decryption failed: check link keys. $e');
          }
        }

        final profile = decoded['profile'] as Map<String, dynamic>? ?? {};
        final name = profile['name'] as String? ?? 'Partner';
        final currency = profile['currency'] as String? ?? 'USD';
        final partnerThemePref = profile['theme_preference'] as String? ?? 'dark';

        final accountsList = (decoded['accounts'] as List? ?? [])
            .map((a) => Account.fromMap(a as Map<String, dynamic>))
            .toList();

        final txList = (decoded['transactions'] as List? ?? [])
            .map((t) => PartnerTransaction.fromMap(t as Map<String, dynamic>))
            .toList();

        final partnerBudgets = (decoded['budgets'] as List?)
            ?.map((b) => Map<String, dynamic>.from(b as Map))
            .toList();

        final partnerPlanningMeta = (decoded['planning_meta'] as List?)
            ?.map((pm) => Map<String, dynamic>.from(pm as Map))
            .toList();

        state = state.copyWith(
          syncProgress: 0.85,
          syncStatusMessage: 'Reconciling shared transactions...',
        );

        // 3. Reconcile partner data into local database
        final oldPartnerTxs = state.partnerTransactions;
        final syncClient = SyncClient(_ref);
        await syncClient.reconcile(
          newPartnerAccounts: accountsList,
          newPartnerTransactions: txList,
          oldPartnerTransactions: oldPartnerTxs,
          partnerBudgets: partnerBudgets,
          partnerPlanningMeta: partnerPlanningMeta,
        );

        // 4. Bidirectional conflict detection for accounts with matching names
        final List<ConflictRecord> detectedConflicts = [];
        final localAccounts = _ref.read(accountsProvider).accounts;
        for (var partnerAccount in accountsList) {
          final matchingLocal = localAccounts.cast<Account?>().firstWhere(
            (a) => a != null && a.name.toLowerCase().trim() == partnerAccount.name.toLowerCase().trim(),
            orElse: () => null,
          );
          if (matchingLocal != null) {
            final hasDiff = (matchingLocal.balance - partnerAccount.balance).abs() > 0.01 ||
                matchingLocal.limitAmount != partnerAccount.limitAmount;
            if (hasDiff) {
              detectedConflicts.add(
                ConflictRecord(
                  type: 'account',
                  name: matchingLocal.name,
                  localData: matchingLocal.toMap(),
                  partnerData: partnerAccount.toMap(),
                ),
              );
            }
          }
        }

        state = state.copyWith(
          partnerName: name,
          partnerCurrency: currency,
          partnerTheme: partnerThemePref,
          partnerAccounts: accountsList,
          partnerTransactions: txList,
          isSyncing: false,
          lastSyncTime: DateTime.now(),
          conflicts: detectedConflicts,
          partnerVersion: state.partnerVersion + 1,
          syncProgress: 1.0,
          syncStatusMessage: 'Sync completed successfully!',
        );
        if (state.partnerName != 'Waiting...') {
          _stopSyncTimer();
        }
      } else {
        // Partner hasn't uploaded yet
        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: DateTime.now(),
          syncProgress: 1.0,
          syncStatusMessage: 'Sync completed!',
        );
      }

      await _saveStateLocally();
      return true;
    } catch (e) {
      final errorMsg = _cleanExceptionMessage(e);
      state = state.copyWith(
        isSyncing: false,
        syncProgress: 0.0,
        syncStatusMessage: null,
        errorMessage: 'Sync failed: $errorMsg',
      );
      return false;
    }
  }

  Future<void> resolveConflict(ConflictRecord conflict, bool keepLocal) async {
    final updatedConflicts = List<ConflictRecord>.from(state.conflicts)
      ..removeWhere((c) => c.name == conflict.name && c.type == conflict.type);

    state = state.copyWith(conflicts: updatedConflicts);
    await _saveStateLocally();

    if (!keepLocal) {
      if (conflict.type == 'account') {
        final partnerAccount = Account.fromMap(conflict.partnerData);
        final localAccounts = _ref.read(accountsProvider).accounts;
        final matchingLocal = localAccounts.firstWhere((a) => a.name == conflict.name);
        final updatedAccount = partnerAccount.copyWith(id: matchingLocal.id);
        await _ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
      }
    }
    // Perform manual sync to push the resolved state
    await syncNow();
  }

  Future<String> _generateLocalPayload() async {
    final profile = _ref.read(authProvider).profile;
    final accounts = _ref.read(accountsProvider).accounts;
    final transactions = _ref.read(transactionsProvider).transactions;
    final categories = _ref.read(categoriesProvider).categories;

    final name = profile?.name ?? 'Partner';
    final currency = profile?.preferredCurrency ?? 'USD';
    final themePref = profile?.themePreference ?? 'dark';

    // Filter shared accounts
    final sharedAccounts = accounts.where((a) => a.isShared).toList();
    final sharedAccountIds = sharedAccounts.map((a) => a.id).toSet();

    // Map categories for details
    final categoryMap = {for (var c in categories) c.id: c};

    // Filter transactions: must be non-private and belong to shared accounts
    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final sharedTxs = sortedTxs
        .where((tx) => !tx.isPrivate && sharedAccountIds.contains(tx.accountId))
        .toList();

    // Find account names
    final accountNames = {for (var a in accounts) a.id: a.name};

    final transactionsPayload = sharedTxs.map((tx) {
      final cat = categoryMap[tx.categoryId];
      return {
        't': tx.title,
        'a': tx.amount,
        'y': tx.type == 'income' ? 'i' : (tx.type == 'expense' ? 'e' : 'f'),
        'd': tx.date.toIso8601String().substring(0, 10),
        'n': tx.note,
        'r': tx.recurrence == 'none' ? 'n' : (tx.recurrence == 'daily' ? 'd' : (tx.recurrence == 'weekly' ? 'w' : (tx.recurrence == 'monthly' ? 'm' : 'y'))),
        'ac': accountNames[tx.accountId] ?? 'Account',
        'c': cat?.name ?? 'Other',
      };
    }).toList();

    // Export budgets & planning meta
    List<Map<String, dynamic>> budgetsPayload = [];
    List<Map<String, dynamic>> planningMetaPayload = [];
    try {
      final db = await AppDatabase.instance.database;
      final budgetsQuery = await db.query('budget');
      final planningMetaQuery = await db.query('planning_meta');

      budgetsPayload = budgetsQuery.map((b) {
        final catId = b['category_id'] as int?;
        final cat = categoryMap[catId];
        return {
          'c': cat?.name ?? 'Other',
          'l': (b['limit_amount'] as num?)?.toDouble() ?? 0.0,
          'm': b['month'] as String? ?? '',
          'r': b['recurrence'] as String? ?? 'monthly',
          'g': b['group_name'] as String? ?? 'General',
        };
      }).toList();

      planningMetaPayload = planningMetaQuery.map((pm) {
        return {
          'm': pm['month'] as String? ?? '',
          'ei': (pm['estimated_income'] as num?)?.toDouble() ?? 0.0,
          's': pm['strategy'] as String? ?? '50/30/20',
          'n': (pm['needs_pct'] as num?)?.toDouble() ?? 0.0,
          'w': (pm['wants_pct'] as num?)?.toDouble() ?? 0.0,
          'sa': (pm['savings_pct'] as num?)?.toDouble() ?? 0.0,
          'i': (pm['investments_pct'] as num?)?.toDouble() ?? 0.0,
          'em': (pm['emergency_pct'] as num?)?.toDouble() ?? 0.0,
          'ic': pm['is_completed'] as int? ?? 1,
        };
      }).toList();
    } catch (e) {
      debugPrint('[PartnerSyncProvider] Error querying budgets/planning_meta for sync: $e');
    }

    final payloadMap = {
      'profile': {
        'name': name,
        'currency': currency,
        'theme_preference': themePref,
      },
      'accounts': sharedAccounts.map((a) => a.toMap()..['pending_payment'] = a.pendingPayment).toList(),
      'transactions': transactionsPayload,
      'budgets': budgetsPayload,
      'planning_meta': planningMetaPayload,
    };

    final rawJson = jsonEncode(payloadMap);
    if (state.syncPassword != null && state.syncPassword!.isNotEmpty) {
      final encrypted = EncryptionService.instance.encrypt(
        rawJson,
        state.syncPassword!,
        state.syncSalt ?? 'default_salt',
      );
      return ShareCodeEncoder.encode({'encrypted': encrypted});
    }

    return ShareCodeEncoder.encode(payloadMap);
  }

  bool _isLetter(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  List<String> _splitIntoChunks(String text, int chunkSize) {
    final List<String> chunks = [];
    int i = 0;
    while (i < text.length) {
      int end = i + chunkSize;
      if (end >= text.length) {
        end = text.length;
      } else {
        while (end > i + 1 && !_isLetter(text[end])) {
          end--;
        }
      }
      chunks.add(text.substring(i, end));
      i = end;
    }
    return chunks;
  }

  Future<void> _uploadData(String payload) async {
    final key = '${state.roomCode}__${state.mySlot}_data';
    final chunks = _splitIntoChunks(payload, 4000);
    final total = chunks.length;

    final client = HttpClient();
    try {
      for (int i = 0; i < total; i++) {
        final chunk = chunks[i];
        final baseUri = Uri.parse(state.webAppUrl);
        final queryParams = Map<String, dynamic>.from(baseUri.queryParameters);
        queryParams['action'] = 'set_chunk';
        queryParams['key'] = key;
        queryParams['index'] = '$i';
        queryParams['total'] = '$total';
        queryParams['val'] = chunk;
        final uri = baseUri.replace(queryParameters: queryParams);
        
        state = state.copyWith(
          syncProgress: (i / total) * 0.5, // Upload takes 0% to 50%
          syncStatusMessage: 'Uploading: Chunk ${i + 1} of $total...',
        );

        bool success = false;
        int attempts = 0;
        String lastError = '';
        while (!success && attempts < 3) {
          try {
            attempts++;
            final request = await client.getUrl(uri);
            final response = await request.close();
            if (response.statusCode == 200) {
              final responseBody = await response.transform(utf8.decoder).join();
              if (responseBody.contains('chunk_received') || responseBody.contains('assembled')) {
                success = true;
                break;
              } else {
                lastError = 'Server did not acknowledge chunk: $responseBody';
              }
            } else {
              lastError = 'HTTP status ${response.statusCode}';
            }
          } catch (e) {
            lastError = e.toString();
          }
          if (!success && attempts < 3) {
            await Future.delayed(Duration(seconds: attempts * 2));
          }
        }
        if (!success) {
          throw Exception('Upload chunk $i failed after $attempts attempts. Error: $lastError');
        }
      }
    } finally {
      client.close();
    }
  }

  Future<String?> _downloadData() async {
    final partnerSlot = state.mySlot == 'A' ? 'B' : 'A';
    final key = '${state.roomCode}__${partnerSlot}_data';
    final baseUri = Uri.parse(state.webAppUrl);
    final queryParams = Map<String, dynamic>.from(baseUri.queryParameters);
    queryParams['action'] = 'get';
    queryParams['key'] = key;
    if (state.partnerVersion > 0) {
      queryParams['since_version'] = '${state.partnerVersion}';
    }
    final uri = baseUri.replace(queryParameters: queryParams);

    state = state.copyWith(
      syncProgress: 0.6, // Download takes 60%
      syncStatusMessage: 'Downloading partner changes...',
    );

    final client = HttpClient();
    try {
      bool success = false;
      int attempts = 0;
      String lastError = '';
      String responseBody = '';

      while (!success && attempts < 3) {
        try {
          attempts++;
          final request = await client.getUrl(uri);
          final response = await request.close();
          if (response.statusCode == 200) {
            responseBody = await response.transform(utf8.decoder).join();
            success = true;
            break;
          } else {
            lastError = 'HTTP status ${response.statusCode}';
          }
        } catch (e) {
          lastError = e.toString();
        }
        if (!success && attempts < 3) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }

      if (!success) {
        throw Exception('Download failed after $attempts attempts. Error: $lastError');
      }

      if (responseBody.trim() == '404') {
        return null;
      }

      // Check if incremental response
      if (responseBody.startsWith('{"changes":')) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        final isIncremental = decoded['isIncremental'] as bool? ?? false;
        if (isIncremental && (decoded['changes'] as List).isEmpty) {
          return null; // No changes since last sync
        }
        // Return the full data for processing
        return responseBody;
      }

      return responseBody;
    } finally {
      client.close();
    }
  }

  Future<void> cleanupPartnerDataFromLocalDB() async {
    try {
      final partnerTxs = state.partnerTransactions;
      final partnerAccounts = state.partnerAccounts;
      if (partnerTxs.isEmpty && partnerAccounts.isEmpty) return;

      final accountDao = AccountDao();
      final transactionDao = TransactionDao();

      // 1. Get all local accounts and transactions
      final localAccounts = _ref.read(accountsProvider).accounts;
      final localTxs = _ref.read(transactionsProvider).transactions;

      // Identify joint account names
      final jointAccountNames = <String>{};
      final localAccountMap = <String, Account>{};
      
      for (var acc in localAccounts) {
        if (acc.isShared) {
          localAccountMap[acc.name.toLowerCase().trim()] = acc;
        }
      }

      for (var pAcc in partnerAccounts) {
        final nameKey = pAcc.name.toLowerCase().trim();
        if (localAccountMap.containsKey(nameKey)) {
          jointAccountNames.add(nameKey);
        }
      }

      // 2. Identify partner transactions to delete
      // We ONLY delete transactions that belong to partner accounts that are NOT joint accounts!
      final nonJointPartnerTxs = partnerTxs.where((ptx) =>
        !jointAccountNames.contains(ptx.accountName.toLowerCase().trim())
      ).toList();

      if (nonJointPartnerTxs.isEmpty && partnerAccounts.isEmpty) return;

      final partnerTxKeys = nonJointPartnerTxs.map((ptx) =>
        "${ptx.title.toLowerCase().trim()}_${ptx.amount.toStringAsFixed(2)}_${ptx.type}_${ptx.date.toIso8601String().substring(0, 10)}_${ptx.accountName.toLowerCase().trim()}"
      ).toSet();

      // Map local accounts by ID for fast lookup
      final localAccountIdMap = {for (var a in localAccounts) a.id: a};

      final List<Transaction> txsToDelete = [];
      for (var tx in localTxs) {
        final acc = localAccountIdMap[tx.accountId];
        if (acc == null) continue;
        final key = "${tx.title.toLowerCase().trim()}_${tx.amount.toStringAsFixed(2)}_${tx.type}_${tx.date.toIso8601String().substring(0, 10)}_${acc.name.toLowerCase().trim()}";
        if (partnerTxKeys.contains(key)) {
          txsToDelete.add(tx);
        }
      }

      // Delete transactions from SQLite
      for (var tx in txsToDelete) {
        await transactionDao.deleteTransaction(tx);
      }

      // 3. Reload transactions provider
      await _ref.read(transactionsProvider.notifier).loadTransactions();
      final updatedLocalTxs = _ref.read(transactionsProvider).transactions;

      // 4. Identify partner accounts to delete
      // We delete any account in SQLite whose name matches a partner account name,
      // provided it is NOT a joint account (i.e. it was imported by the sync client).
      final partnerAccountNames = partnerAccounts.map((pa) => pa.name.toLowerCase().trim()).toSet();
      
      final txCounts = <int, int>{};
      for (var tx in updatedLocalTxs) {
        txCounts[tx.accountId] = (txCounts[tx.accountId] ?? 0) + 1;
      }

      for (var acc in localAccounts) {
        if (acc.id == null) continue;
        final nameKey = acc.name.toLowerCase().trim();
        // If it matches a partner account and is NOT a joint account
        if (partnerAccountNames.contains(nameKey) && !jointAccountNames.contains(nameKey)) {
          final count = txCounts[acc.id] ?? 0;
          if (count == 0) {
            await accountDao.deleteAccount(acc.id!);
          }
        }
      }

      // 5. Reload accounts and transactions providers to refresh UI
      await _ref.read(accountsProvider.notifier).loadAccounts();
      await _ref.read(transactionsProvider.notifier).loadTransactions();

      debugPrint('[PartnerSync] Cleanup of database completed successfully.');
    } catch (e, stack) {
      debugPrint('[PartnerSync] Error during database cleanup: $e\n$stack');
    }
  }

  Future<void> disconnect() async {
    _stopSyncTimer();
    await cleanupPartnerDataFromLocalDB();
    
    state = PartnerSyncState(
      isConnected: false,
      roomCode: '',
      mySlot: '',
      webAppUrl: '',
      partnerName: '',
      partnerCurrency: 'USD',
      partnerAccounts: [],
      partnerTransactions: [],
    );

    try {
      final file = await _stateFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopSyncTimer();
    super.dispose();
  }
}

final partnerSyncProvider = StateNotifierProvider<PartnerSyncNotifier, PartnerSyncState>((ref) {
  return PartnerSyncNotifier(ref);
});

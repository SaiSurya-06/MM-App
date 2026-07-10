import '../database/database.dart';
import 'execution_plan.dart';

class RetrievedData {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> balances;
  final double netWorth;

  RetrievedData({
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.balances,
    required this.netWorth,
  });

  factory RetrievedData.empty() {
    return RetrievedData(
      transactions: [],
      budgets: [],
      goals: [],
      balances: [],
      netWorth: 0.0,
    );
  }
}

class DatabaseRetriever {
  static Future<RetrievedData> retrieve(ExecutionPlan plan) async {
    final db = await AppDatabase.instance.database;

    List<Map<String, dynamic>> txs = [];
    List<Map<String, dynamic>> budgets = [];
    List<Map<String, dynamic>> goals = [];
    List<Map<String, dynamic>> balances = [];
    double netWorth = 0.0;

    final req = plan.requiredTools;

    // 1. Transaction Tool Fetch
    if (req.contains('transaction') || plan.intent == 'search' || plan.intent == 'compare') {
      String sql = '''
        SELECT t.title, t.amount, t.type, t.date, c.name as category, a.name as account, t.note, t.tags, t.category_id
        FROM transaction_log t
        LEFT JOIN category c ON t.category_id = c.id
        LEFT JOIN account a ON t.account_id = a.id
      ''';

      List<dynamic> args = [];
      List<String> conditions = [];

      if (plan.targetMonth != null) {
        final monthStr = "${plan.targetYear ?? DateTime.now().year}-${plan.targetMonth!.toString().padLeft(2, '0')}";
        conditions.add("strftime('%Y-%m', t.date) = ?");
        args.add(monthStr);
      } else if (plan.targetYear != null) {
        conditions.add("strftime('%Y', t.date) = ?");
        args.add(plan.targetYear!.toString());
      }

      if (plan.minAmount != null) {
        conditions.add("t.amount >= ?");
        args.add(plan.minAmount);
      }
      if (plan.maxAmount != null) {
        conditions.add("t.amount <= ?");
        args.add(plan.maxAmount);
      }

      if (plan.targetType != null) {
        conditions.add("t.type = ?");
        args.add(plan.targetType);
      }

      if (plan.timeFilter != null) {
        final tf = plan.timeFilter!.toLowerCase();
        if (tf == 'weekend') {
          conditions.add("strftime('%w', t.date) IN ('0', '6')");
        } else if (tf == 'night') {
          conditions.add("cast(strftime('%H', t.date) as integer) >= 20");
        } else if (tf == 'evening') {
          conditions.add("cast(strftime('%H', t.date) as integer) >= 17");
        }
      }

      if (conditions.isNotEmpty) {
        sql += " WHERE ${conditions.join(" AND ")}";
      }

      sql += " ORDER BY t.date DESC, t.id DESC";

      final rawRows = await db.rawQuery(sql, args);

      // Perform matching in Dart
      List<Map<String, dynamic>> filtered = rawRows;
      if (plan.category != null) {
        filtered = filtered.where((tx) =>
            _fuzzyMatch(tx['category']?.toString() ?? '', plan.category!)).toList();
      }

      if (plan.merchant != null) {
        filtered = filtered.where((tx) =>
            _fuzzyMatch(tx['title']?.toString() ?? '', plan.merchant!) ||
            _fuzzyMatch(tx['note']?.toString() ?? '', plan.merchant!) ||
            _fuzzyMatch(tx['category']?.toString() ?? '', plan.merchant!)).toList();
      }

      if (plan.paymentMethod != null) {
        final pm = plan.paymentMethod!.toLowerCase();
        filtered = filtered.where((tx) {
          final note = (tx['note']?.toString() ?? '').toLowerCase();
          final acc = (tx['account']?.toString() ?? '').toLowerCase();
          final tags = (tx['tags']?.toString() ?? '').toLowerCase();
          final title = (tx['title']?.toString() ?? '').toLowerCase();

          if (pm == 'upi') {
            return note.contains('upi') || tags.contains('upi') || title.contains('upi') || acc.contains('upi');
          }
          return note.contains(pm) || acc.contains(pm) || title.contains(pm);
        }).toList();
      }

      txs = filtered;
    }

    // 2. Budget Tool Fetch
    if (req.contains('budget') || plan.intent == 'budget') {
      final now = DateTime.now();
      final monthStr = "${plan.targetYear ?? now.year}-${(plan.targetMonth ?? now.month).toString().padLeft(2, '0')}";
      budgets = await db.rawQuery('''
        SELECT b.limit_amount, c.name, b.category_id
        FROM budget b
        JOIN category c ON b.category_id = c.id
        WHERE b.month = ?
      ''', [monthStr]);
    }

    // 3. Goal Tool Fetch
    if (req.contains('goal') || plan.intent == 'budget') {
      goals = await db.rawQuery('''
        SELECT name, target_amount, current_amount, target_date FROM savings_goal
      ''');
    }

    // 4. Account Balance & Net Worth Tool Fetch
    if (req.contains('account') || plan.intent == 'balance') {
      balances = await db.rawQuery('''
        SELECT name, type, balance FROM account ORDER BY balance DESC
      ''');
      final totalRow = await db.rawQuery('SELECT SUM(balance) as total FROM account');
      netWorth = totalRow.isNotEmpty ? (totalRow.first['total'] as num? ?? 0.0).toDouble() : 0.0;
    }

    return RetrievedData(
      transactions: txs,
      budgets: budgets,
      goals: goals,
      balances: balances,
      netWorth: netWorth,
    );
  }

  static String _soundex(String s) {
    if (s.isEmpty) return s;
    final clean = s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (clean.isEmpty) return s;

    final first = clean[0];
    final buffer = StringBuffer(first);

    final map = {
      'b': '1', 'f': '1', 'p': '1', 'v': '1',
      'c': '2', 'g': '2', 'j': '2', 'k': '2', 'q': '2', 's': '2', 'x': '2', 'z': '2',
      'd': '3', 't': '3',
      'l': '4',
      'm': '5', 'n': '5',
      'r': '6'
    };

    String prevCode = map[first] ?? '';
    for (int i = 1; i < clean.length; i++) {
      final code = map[clean[i]] ?? '';
      if (code.isNotEmpty && code != prevCode) {
        buffer.write(code);
        prevCode = code;
      }
    }
    return buffer.toString();
  }

  static bool _fuzzyMatch(String text, String keyword) {
    final cleanText = text.toLowerCase();
    final cleanKeyword = keyword.toLowerCase();

    if (cleanText.contains(cleanKeyword)) return true;

    final textWords = cleanText.replaceAll(RegExp(r'[^a-z\s]'), '').split(RegExp(r'\s+'));
    final kwWords = cleanKeyword.replaceAll(RegExp(r'[^a-z\s]'), '').split(RegExp(r'\s+'));

    for (final kw in kwWords) {
      if (kw.length < 3) continue;
      final kwSoundex = _soundex(kw);

      bool wordMatched = false;
      for (final tw in textWords) {
        if (tw.length < 3) continue;
        if (tw.contains(kw) || kw.contains(tw)) {
          wordMatched = true;
          break;
        }
        if (_soundex(tw) == kwSoundex) {
          wordMatched = true;
          break;
        }
      }
      if (wordMatched) return true;
    }

    return false;
  }
}

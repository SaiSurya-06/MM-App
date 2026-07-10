import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/database/database.dart';
import '../../core/agent/agent_service.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';

class ChatSessionContext {
  String? merchant;
  String? category;
  int? targetMonth;
  int? targetYear;
  double? minAmount;
  double? maxAmount;
  String? paymentMethod;
  String? targetType;

  // Comparison context
  int? comparisonMonth;
  int? comparisonYear;

  void clear() {
    merchant = null;
    category = null;
    targetMonth = null;
    targetYear = null;
    minAmount = null;
    maxAmount = null;
    paymentMethod = null;
    targetType = null;
    comparisonMonth = null;
    comparisonYear = null;
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isSystemError;
  final Widget? chartWidget;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isSystemError = false,
    this.chartWidget,
  });
}

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSessionContext _sessionContext = ChatSessionContext();
  bool _isTyping = false;
  bool _useOnlineAI = true;

  @override
  void initState() {
    super.initState();
    _loadWelcomeDashboard();
  }

  Future<void> _saveMessageToDb(String text, bool isMe, String? chartType) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.insert('chatbot_message', {
        'text': text,
        'is_me': isMe ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'chart_type': chartType,
      });
    } catch (e) {
      debugPrint("Error saving chatbot message: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadWelcomeDashboard() async {
    final db = await AppDatabase.instance.database;
    
    // Ensure SQLite storage table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chatbot_message (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_me INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        chart_type TEXT
      )
    ''');

    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    // Load existing messages
    final List<Map<String, dynamic>> rows = await db.query('chatbot_message', orderBy: 'id ASC');
    
    if (rows.isNotEmpty) {
      final List<ChatMessage> loaded = [];
      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final text = r['text'] as String;
        final isMe = (r['is_me'] as int) == 1;
        final timestamp = DateTime.parse(r['timestamp'] as String);
        final chartType = r['chart_type'] as String?;

        Widget? chartWidget;
        try {
          if (chartType == 'pie' && i > 0) {
            final userQuery = rows[i - 1]['text'] as String;
            final tempCtx = ChatSessionContext();
            _parseQuery(userQuery, tempCtx);
            final txs = await _runQuery(tempCtx, userQuery);
            final shares = <String, double>{};
            for (var tx in txs) {
              final cat = tx['category']?.toString() ?? 'Other';
              shares[cat] = (shares[cat] ?? 0.0) + (tx['amount'] as num).toDouble();
            }
            if (shares.isNotEmpty) {
              chartWidget = ChatPieChart(categoryShares: shares, currencySymbol: currencySymbol);
            }
          } else if (chartType == 'bar' && i > 0) {
            final userQuery = rows[i - 1]['text'] as String;
            final tempCtx = ChatSessionContext();
            _parseQuery(userQuery, tempCtx);
            final txs = await _runQuery(tempCtx, userQuery);
            double totalAmount = 0.0;
            for (var tx in txs) {
              totalAmount += (tx['amount'] as num).toDouble();
            }
            double comparisonTotal = 0.0;
            if (tempCtx.comparisonMonth != null) {
              final compContext = ChatSessionContext()
                ..merchant = tempCtx.merchant
                ..category = tempCtx.category
                ..targetMonth = tempCtx.comparisonMonth
                ..targetYear = tempCtx.comparisonYear
                ..minAmount = tempCtx.minAmount
                ..maxAmount = tempCtx.maxAmount
                ..paymentMethod = tempCtx.paymentMethod
                ..targetType = tempCtx.targetType;
              final compRows = await _runQuery(compContext, userQuery);
              for (var tx in compRows) {
                comparisonTotal += (tx['amount'] as num).toDouble();
              }
            }
            chartWidget = ChatBarChart(
              val1: totalAmount,
              val2: comparisonTotal,
              label1: _getMonthName(tempCtx.targetMonth ?? DateTime.now().month),
              label2: _getMonthName(tempCtx.comparisonMonth ?? (DateTime.now().month - 1)),
              currencySymbol: currencySymbol,
            );
          }
        } catch (_) {}

        loaded.add(ChatMessage(
          text: text,
          isMe: isMe,
          timestamp: timestamp,
          chartWidget: chartWidget,
        ));
      }

      setState(() {
        _messages.clear();
        _messages.addAll(loaded);
      });
      _scrollToBottom();
      return;
    }

    // Otherwise, generate initial proactive dashboard and save it
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    try {
      // Calculate Net Worth (Step 7)
      final List<Map<String, dynamic>> accounts = await db.rawQuery('SELECT SUM(balance) as total FROM account');
      final double netWorth = accounts.isNotEmpty ? (accounts.first['total'] as num? ?? 0.0).toDouble() : 0.0;

      // Calculate Income vs Expenses for current month
      final List<Map<String, dynamic>> txs = await db.rawQuery('''
        SELECT amount, type, title, date
        FROM transaction_log
        WHERE strftime('%Y-%m', date) = ?
      ''', [currentMonth]);

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      double foodSpent = 0.0;
      double largestExpense = 0.0;
      String largestExpenseTitle = "";

      for (var tx in txs) {
        final amt = (tx['amount'] as num).toDouble();
        final type = tx['type'] as String;
        final title = tx['title'] as String;
        
        if (type == 'income') {
          totalIncome += amt;
        } else if (type == 'expense') {
          totalExpense += amt;
          if (title.toLowerCase().contains('swiggy') || title.toLowerCase().contains('zomato') || title.toLowerCase().contains('food') || title.toLowerCase().contains('restaurant')) {
            foodSpent += amt;
          }
          if (amt > largestExpense) {
            largestExpense = amt;
            largestExpenseTitle = title;
          }
        }
      }

      final double savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0.0;

      final buffer = StringBuffer();
      buffer.writeln("Hi! I am your AI Financial Advisor. I've compiled your **Proactive Insights Dashboard** for this month:\n");
      buffer.writeln("📊 **Financial Health Summary**:");
      buffer.writeln("- **Net Worth**: **$currencySymbol${netWorth.toStringAsFixed(2)}**");
      buffer.writeln("- **Savings Rate**: ${savingsRate.toStringAsFixed(1)}%");
      buffer.writeln("- **Cash Flow**: Income $currencySymbol${totalIncome.toStringAsFixed(0)} / Expenses $currencySymbol${totalExpense.toStringAsFixed(0)}");
      
      buffer.writeln("\n💡 **Impulse Habits & Proactive Alerts (Step 9)**:");
      if (foodSpent > 0) {
        buffer.writeln("- **Food Delivery**: You spent **$currencySymbol${foodSpent.toStringAsFixed(0)}** on food delivery. Reducing this by 30% could save you **$currencySymbol${(foodSpent * 0.3).toStringAsFixed(0)}**.");
      }
      if (largestExpense > 0) {
        buffer.writeln("- **Largest expense**: '$largestExpenseTitle' ($currencySymbol${largestExpense.toStringAsFixed(0)}).");
      }
      if (savingsRate < 20 && totalIncome > 0) {
        buffer.writeln("- ⚠️ **Savings Alert**: Your savings rate is below the recommended 20%. Try cutting back on discretionary spending.");
      } else if (savingsRate >= 20) {
        buffer.writeln("- 🎉 **Great Job!**: Your savings rate is healthy (${savingsRate.toStringAsFixed(1)}%).");
      }

      buffer.writeln("\nAsk me anything! You can ask: *'how much did I spend on food?'*, *'UPI payments above 500'*, *'compare June vs May'*.");

      final welcomeText = buffer.toString();
      await _saveMessageToDb(welcomeText, false, null);

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage(
            text: welcomeText,
            isMe: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      const welcomeText = "Hi! I am your AI Financial Assistant. Ask me anything about your spending, accounts, budgets, and savings.";
      await _saveMessageToDb(welcomeText, false, null);
      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage(
            text: welcomeText,
            isMe: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void _parseQuery(String query, ChatSessionContext context) {
    final clean = query.toLowerCase();

    // Check if the query is a follow-up or relative addition (Step 6)
    final isFollowUp = clean.contains("only") ||
        clean.contains("compare") ||
        clean.contains("vs") ||
        (clean.split(RegExp(r'\s+')).length <= 3 &&
            (clean.contains("month") ||
                clean.contains("above") ||
                clean.contains("below") ||
                clean.contains("june") ||
                clean.contains("may") ||
                clean.contains("july")));

    if (!isFollowUp) {
      context.clear(); // Reset filters for a brand new topic
    }

    final now = DateTime.now();

    // 1. Detect target month
    final monthsMap = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };

    for (var entry in monthsMap.entries) {
      if (clean.contains(entry.key)) {
        if (clean.contains("compare") || clean.contains("vs")) {
          if (context.targetMonth != null) {
            context.comparisonMonth = entry.value;
            context.comparisonYear = now.year;
          } else {
            context.targetMonth = entry.value;
            context.targetYear = now.year;
          }
        } else {
          context.targetMonth = entry.value;
          context.targetYear = now.year;
        }
      }
    }

    if (clean.contains("this month")) {
      context.targetMonth = now.month;
      context.targetYear = now.year;
    } else if (clean.contains("last month")) {
      final prev = DateTime(now.year, now.month - 1);
      context.targetMonth = prev.month;
      context.targetYear = prev.year;
    } else if (clean.contains("last year")) {
      context.targetYear = now.year - 1;
      context.targetMonth = null;
    } else if (clean.contains("this year")) {
      context.targetYear = now.year;
      context.targetMonth = null;
    }

    // Default to current month if no dates are detected at all
    if (context.targetMonth == null && context.targetYear == null) {
      context.targetMonth = now.month;
      context.targetYear = now.year;
    }

    // 2. Detect Comparison intent
    if (clean.contains("compare") || clean.contains("vs")) {
      if (context.comparisonMonth == null && context.targetMonth != null) {
        // Compare target month with previous month
        final compDate = DateTime(context.targetYear ?? now.year, context.targetMonth! - 1);
        context.comparisonMonth = compDate.month;
        context.comparisonYear = compDate.year;
      }
    }

    // 3. Detect Amount bounds
    final amountReg = RegExp(
        r'(above|below|more than|less than|greater than|over|under|>|<|>=|<=)\s*(?:rs\.?|rs|rupees|inr|₹)?\s*(\d+)');
    final match = amountReg.firstMatch(clean);
    if (match != null) {
      final op = match.group(1)!;
      final val = double.tryParse(match.group(2)!) ?? 0.0;
      if (op.contains("above") || op.contains("more") || op.contains("greater") || op.contains("over") || op.contains(">")) {
        context.minAmount = val;
        context.maxAmount = null;
      } else {
        context.maxAmount = val;
        context.minAmount = null;
      }
    }

    // 4. Detect transaction type
    if (clean.contains("spend") || clean.contains("spent") || clean.contains("expense") || clean.contains("paid") || clean.contains("bought") || clean.contains("cost") || clean.contains("waste")) {
      context.targetType = 'expense';
    } else if (clean.contains("got") || clean.contains("received") || clean.contains("earned") || clean.contains("income") || clean.contains("salary") || clean.contains("interest") || clean.contains("dividend")) {
      context.targetType = 'income';
    }

    // 5. Detect payment method
    if (clean.contains("upi")) {
      context.paymentMethod = 'upi';
    } else if (clean.contains("cash")) {
      context.paymentMethod = 'cash';
    } else if (clean.contains("card")) {
      context.paymentMethod = 'card';
    }

    // 6. Semantic Synonyms Mapper (Step 10)
    final semanticSynonyms = {
      'Transport': ['goa', 'vacation', 'holiday', 'trip', 'fuel', 'flight', 'hotel', 'train', 'bus', 'uber', 'ola', 'travel', 'transport'],
      'Food': ['coffee', 'cafe', 'latte', 'starbucks', 'ccd', 'barista', 'swiggy', 'zomato', 'pizza', 'kfc', 'mcdonalds', 'burger', 'dining', 'restaurant', 'food', 'delivery'],
      'Utilities': ['electricity', 'water', 'gas', 'power', 'internet', 'wifi', 'recharge', 'bill', 'utilities'],
      'Entertainment': ['netflix', 'spotify', 'movie', 'cinema', 'youtube', 'prime', 'game', 'playstation', 'entertainment']
    };

    String? matchedCategory;
    for (var entry in semanticSynonyms.entries) {
      for (var syn in entry.value) {
        if (clean.contains(syn)) {
          matchedCategory = entry.key;
          break;
        }
      }
      if (matchedCategory != null) break;
    }

    if (matchedCategory != null) {
      context.category = matchedCategory;
      context.merchant = null;
    } else {
      // Extract candidate merchant
      final words = clean.split(RegExp(r'\s+'));
      final stopWords = {
        'how', 'much', 'did', 'i', 'get', 'got', 'in', 'the', 'month', 'of', 'on', 'at',
        'for', 'show', 'list', 'my', 'me', 'what', 'was', 'were', 'spend', 'spent',
        'salary', 'income', 'expense', 'expenses', 'balance', 'balances', 'account', 'accounts',
        'this', 'last', 'interest', 'money', 'transaction', 'transactions', 'to', 'from',
        'where', 'which', 'who', 'why', 'when', 'most', 'highest', 'least', 'lowest', 'total',
        'sum', 'all', 'any', 'average', 'avg', 'many', 'more', 'less', 'category', 'catagoy',
        'catagory', 'recent', 'save', 'saving', 'savings', 'tip', 'tips', 'blueprint',
        'only', 'compare', 'vs', 'comparison', 'above', 'below', 'waste', 'wasted', 'purchase',
        'payment', 'payments', 'method',
        ...monthsMap.keys
      };

      final candidates = words.where((w) => !stopWords.contains(w) && w.length > 2).toList();
      if (candidates.isNotEmpty) {
        final name = candidates.first;
        final knownCategories = ['food', 'rent', 'salary', 'transport', 'entertainment', 'health', 'utilities', 'credit card payment', 'other'];
        if (knownCategories.contains(name)) {
          context.category = name;
          context.merchant = null;
        } else {
          context.merchant = name;
          context.category = null;
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _runQuery(ChatSessionContext context, String originalQuery) async {
    final db = await AppDatabase.instance.database;

    String sql = '''
      SELECT t.title, t.amount, t.type, t.date, c.name as category, a.name as account, t.note, t.tags
      FROM transaction_log t
      LEFT JOIN category c ON t.category_id = c.id
      LEFT JOIN account a ON t.account_id = a.id
    ''';

    List<dynamic> args = [];
    List<String> conditions = [];

    if (context.targetMonth != null) {
      final monthStr = "${context.targetYear ?? DateTime.now().year}-${context.targetMonth!.toString().padLeft(2, '0')}";
      conditions.add("strftime('%Y-%m', t.date) = ?");
      args.add(monthStr);
    } else if (context.targetYear != null) {
      conditions.add("strftime('%Y', t.date) = ?");
      args.add(context.targetYear!.toString());
    }

    if (context.minAmount != null) {
      conditions.add("t.amount >= ?");
      args.add(context.minAmount);
    }
    if (context.maxAmount != null) {
      conditions.add("t.amount <= ?");
      args.add(context.maxAmount);
    }
    if (context.targetType != null) {
      conditions.add("t.type = ?");
      args.add(context.targetType);
    }

    // Time-based checks (Step 11 - SQL Agent capabilities)
    final queryLower = originalQuery.toLowerCase();
    if (queryLower.contains("weekend")) {
      conditions.add("strftime('%w', t.date) IN ('0', '6')");
    }
    if (queryLower.contains("after 8 pm") || queryLower.contains("after 20") || queryLower.contains("night")) {
      conditions.add("cast(strftime('%H', t.date) as integer) >= 20");
    } else if (queryLower.contains("evening")) {
      conditions.add("cast(strftime('%H', t.date) as integer) >= 17");
    }

    if (conditions.isNotEmpty) {
      sql += " WHERE ${conditions.join(" AND ")}";
    }

    sql += " ORDER BY t.date DESC, t.id DESC";

    final List<Map<String, dynamic>> rawRows = await db.rawQuery(sql, args);

    // Apply Soundex & Fuzzy matching in Dart (Step 4)
    List<Map<String, dynamic>> filtered = rawRows;

    if (context.category != null) {
      filtered = filtered.where((tx) =>
          _fuzzyMatch(tx['category']?.toString() ?? '', context.category!)).toList();
    }

    if (context.merchant != null) {
      filtered = filtered.where((tx) =>
          _fuzzyMatch(tx['title']?.toString() ?? '', context.merchant!) ||
          _fuzzyMatch(tx['note']?.toString() ?? '', context.merchant!) ||
          _fuzzyMatch(tx['category']?.toString() ?? '', context.merchant!)).toList();
    }

    if (context.paymentMethod != null) {
      filtered = filtered.where((tx) {
        final note = (tx['note']?.toString() ?? '').toLowerCase();
        final acc = (tx['account']?.toString() ?? '').toLowerCase();
        final tags = (tx['tags']?.toString() ?? '').toLowerCase();
        final title = (tx['title']?.toString() ?? '').toLowerCase();

        if (context.paymentMethod == 'upi') {
          return note.contains('upi') || tags.contains('upi') || title.contains('upi') || acc.contains('upi');
        }
        return note.contains(context.paymentMethod!) || acc.contains(context.paymentMethod!) || title.contains(context.paymentMethod!);
      }).toList();
    }

    return filtered;
  }

  String _getBaseMerchant(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('netflix')) return 'Netflix';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('starbucks')) return 'Starbucks';
    return title;
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final userMessage = ChatMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    // Persist user input (Conversation Storage)
    await _saveMessageToDb(text, true, null);

    // 1. Context parsing
    _parseQuery(text, _sessionContext);
    final cleanQuery = text.toLowerCase();

    String responseText = "";
    bool isFallback = false;
    Widget? chartWidget;

    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    if (_useOnlineAI) {
      // 2. Query execution
      final retrievedRows = await _runQuery(_sessionContext, text);
      
      // Calculate growth and analytics for LLM prompt grounding (Step 7)
      double totalAmount = 0.0;
      for (var r in retrievedRows) {
        totalAmount += (r['amount'] as num).toDouble();
      }
      final averageAmount = retrievedRows.isNotEmpty ? totalAmount / retrievedRows.length : 0.0;
      
      double weekendSum = 0.0;
      double nightSum = 0.0;
      double impulseSum = 0.0;
      final recurringMap = <String, int>{};
      for (var r in retrievedRows) {
        final amt = (r['amount'] as num).toDouble();
        final dateStr = r['date']?.toString() ?? '';
        final title = r['title']?.toString() ?? '';
        final cat = r['category']?.toString() ?? '';
        try {
          final dt = DateTime.parse(dateStr);
          if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
            weekendSum += amt;
          }
          if (dt.hour >= 20) {
            nightSum += amt;
          }
        } catch (_) {}
        if (amt >= 1000 && (cat == 'Food' || cat == 'Entertainment')) {
          impulseSum += amt;
        }
        final key = "$title|${amt.toStringAsFixed(0)}";
        recurringMap[key] = (recurringMap[key] ?? 0) + 1;
      }
      final detectedSubscriptions = recurringMap.entries
          .where((e) => e.value >= 2)
          .map((e) => "- **${e.key.split('|')[0]}**: Recurring same-amount charges (${e.key.split('|')[1]})")
          .toList();

      // Top merchant & Category shares (Step 7)
      final categoryShares = <String, double>{};
      for (var r in retrievedRows) {
        final cat = r['category']?.toString() ?? 'Other';
        categoryShares[cat] = (categoryShares[cat] ?? 0.0) + (r['amount'] as num).toDouble();
      }
      final topCategory = categoryShares.entries.isNotEmpty
          ? categoryShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : "N/A";

      final merchantShares = <String, double>{};
      for (var r in retrievedRows) {
        final merch = _getBaseMerchant(r['title']?.toString() ?? 'Other');
        merchantShares[merch] = (merchantShares[merch] ?? 0.0) + (r['amount'] as num).toDouble();
      }
      final topMerchant = merchantShares.entries.isNotEmpty
          ? merchantShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : "N/A";

      double comparisonTotal = 0.0;
      String percentageChangeStr = "N/A";
      if (_sessionContext.comparisonMonth != null) {
        final compContext = ChatSessionContext()
          ..merchant = _sessionContext.merchant
          ..category = _sessionContext.category
          ..targetMonth = _sessionContext.comparisonMonth
          ..targetYear = _sessionContext.comparisonYear
          ..minAmount = _sessionContext.minAmount
          ..maxAmount = _sessionContext.maxAmount
          ..paymentMethod = _sessionContext.paymentMethod
          ..targetType = _sessionContext.targetType;
        final compRows = await _runQuery(compContext, text);
        for (var r in compRows) {
          comparisonTotal += (r['amount'] as num).toDouble();
        }
        final diff = totalAmount - comparisonTotal;
        final percentageChange = comparisonTotal > 0 ? (diff / comparisonTotal * 100) : 0.0;
        percentageChangeStr = "${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%";
      }

      final prompt = '''
User Question: "$text"

Retrieved Local Transaction Data:
${retrievedRows.take(15).map((r) => "- ${r['date']}: ${r['title']} (${r['category']}) -> $currencySymbol${r['amount']} (${r['type']})").join('\n')}

Calculated Analytics Context:
- Scanned Transactions: ${retrievedRows.length}
- Total Sum: $currencySymbol${totalAmount.toStringAsFixed(2)}
- Average Order: $currencySymbol${averageAmount.toStringAsFixed(2)}
- Top Category: $topCategory
- Top Merchant: $topMerchant
- Weekend Spending: $currencySymbol${weekendSum.toStringAsFixed(2)}
- Nighttime (after 8PM) Orders: $currencySymbol${nightSum.toStringAsFixed(2)}
- Impulse Discretionary Purchases: $currencySymbol${impulseSum.toStringAsFixed(2)}
- Growth (vs comparison period): $percentageChangeStr
- Subscriptions Detected:
${detectedSubscriptions.isEmpty ? '- None' : detectedSubscriptions.join('\n')}

Instructions:
1. Answer the user's question using ONLY the retrieved local transaction data and calculated metrics above.
2. If no data matches, clearly state that no transactions were found in the database. Do not hallucinate or guess any numbers.
3. Offer professional, actionable financial coaching (e.g. "Swiggy accounts for X% of your food budget", "Reducing food delivery by 30% could save you Y").
''';

      try {
        final rawResponse = await AgentService.sendMessage(prompt);
        if (rawResponse.startsWith("Error from agent:") ||
            rawResponse.contains("mock-key-for-local-testing") ||
            rawResponse.contains("Unexpected error:") ||
            rawResponse.trim().isEmpty) {
          responseText = await _processQueryLocally(text);
          isFallback = true;
        } else {
          responseText = rawResponse;
        }
      } catch (e) {
        responseText = await _processQueryLocally(text);
        isFallback = true;
      }
    } else {
      responseText = await _processQueryLocally(text);
      isFallback = true;
    }

    // Chart generation for display in UI bubble
    final retrievedRowsForChart = await _runQuery(_sessionContext, text);
    double totalAmountForChart = 0.0;
    for (var r in retrievedRowsForChart) {
      totalAmountForChart += (r['amount'] as num).toDouble();
    }
    final categoryShares = <String, double>{};
    for (var r in retrievedRowsForChart) {
      final cat = r['category']?.toString() ?? 'Other';
      categoryShares[cat] = (categoryShares[cat] ?? 0.0) + (r['amount'] as num).toDouble();
    }
    double comparisonTotalForChart = 0.0;
    if (_sessionContext.comparisonMonth != null) {
      final compContext = ChatSessionContext()
        ..merchant = _sessionContext.merchant
        ..category = _sessionContext.category
        ..targetMonth = _sessionContext.comparisonMonth
        ..targetYear = _sessionContext.comparisonYear
        ..minAmount = _sessionContext.minAmount
        ..maxAmount = _sessionContext.maxAmount
        ..paymentMethod = _sessionContext.paymentMethod
        ..targetType = _sessionContext.targetType;
      final compRows = await _runQuery(compContext, text);
      for (var r in compRows) {
        comparisonTotalForChart += (r['amount'] as num).toDouble();
      }
    }

    String? chartType;
    if (cleanQuery.contains("category") || cleanQuery.contains("breakdown") || cleanQuery.contains("most") || cleanQuery.contains("where did")) {
      if (categoryShares.isNotEmpty) {
        chartWidget = ChatPieChart(categoryShares: categoryShares, currencySymbol: currencySymbol);
        chartType = 'pie';
      }
    } else if (_sessionContext.comparisonMonth != null) {
      chartWidget = ChatBarChart(
        val1: totalAmountForChart,
        val2: comparisonTotalForChart,
        label1: _getMonthName(_sessionContext.targetMonth ?? DateTime.now().month),
        label2: _getMonthName(_sessionContext.comparisonMonth!),
        currencySymbol: currencySymbol,
      );
      chartType = 'bar';
    }

    // Append explainability block (Step 13)
    final explainability = "\n\n***\n📊 *Data Grounding Source: Local SQLite Ledger | Scanned: ${retrievedRowsForChart.length} transactions | Period: ${_sessionContext.targetMonth != null ? _getMonthName(_sessionContext.targetMonth!) : 'all time'} | Confidence: 100%*";
    responseText += explainability;

    // Persist assistant reply
    await _saveMessageToDb(responseText, false, chartType);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: responseText,
            isMe: false,
            timestamp: DateTime.now(),
            isSystemError: isFallback && !_useOnlineAI,
            chartWidget: chartWidget,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String _generateDetailedNlgResponse(
    List<Map<String, dynamic>> rows,
    double totalAmount,
    double averageAmount,
    Map<String, dynamic>? largestTransaction,
    double comparisonTotal,
    double percentageChange,
    double weekendSum,
    double nightSum,
    double impulseSum,
    List<String> subscriptions,
    String currencySymbol,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("Based on your local transaction ledger, here is what I found:\n");

    if (_sessionContext.merchant != null) {
      buffer.writeln("🔍 **Merchant search**: matches '${_sessionContext.merchant}'");
    }
    if (_sessionContext.category != null) {
      buffer.writeln("📁 **Category filter**: matches '${_sessionContext.category}'");
    }
    if (_sessionContext.targetMonth != null) {
      buffer.writeln("📅 **Period**: ${_getMonthName(_sessionContext.targetMonth!)} ${_sessionContext.targetYear ?? DateTime.now().year}");
    }
    if (_sessionContext.minAmount != null) {
      buffer.writeln("💰 **Amount range**: above $currencySymbol${_sessionContext.minAmount}");
    }
    if (_sessionContext.paymentMethod != null) {
      buffer.writeln("💳 **Payment Method**: ${_sessionContext.paymentMethod!.toUpperCase()}");
    }

    buffer.writeln("\n---");
    buffer.writeln("### Summary Metrics");
    buffer.writeln("- **Total Transactions**: ${rows.length}");
    buffer.writeln("- **Total Sum**: **$currencySymbol${totalAmount.toStringAsFixed(2)}**");
    buffer.writeln("- **Average Transaction**: $currencySymbol${averageAmount.toStringAsFixed(2)}");
    if (largestTransaction != null) {
      buffer.writeln("- **Largest Transaction**: $currencySymbol${(largestTransaction['amount'] as num).toDouble().toStringAsFixed(2)} ('${largestTransaction['title']}')");
    }

    buffer.writeln("\n### Financial Intelligence & Habits (Step 8)");
    buffer.writeln("- **Weekend Spending**: $currencySymbol${weekendSum.toStringAsFixed(2)}");
    buffer.writeln("- **Nighttime Spending (after 8 PM)**: $currencySymbol${nightSum.toStringAsFixed(2)}");
    buffer.writeln("- **Impulse Purchases**: $currencySymbol${impulseSum.toStringAsFixed(2)}");
    if (subscriptions.isNotEmpty) {
      buffer.writeln("\n**Subscriptions Detected**:");
      for (var sub in subscriptions) {
        buffer.writeln(sub);
      }
    }

    if (_sessionContext.comparisonMonth != null) {
      buffer.writeln("\n### Comparison (${_getMonthName(_sessionContext.targetMonth ?? DateTime.now().month)} vs ${_getMonthName(_sessionContext.comparisonMonth!)})");
      buffer.writeln("- **Previous Period**: $currencySymbol${comparisonTotal.toStringAsFixed(2)}");
      final indicator = percentageChange >= 0 ? "increased by 📈" : "decreased by 📉";
      buffer.writeln("- **Change**: $indicator **${percentageChange.abs().toStringAsFixed(1)}%**");
    }

    buffer.writeln("\n### Transactions Scanned");
    if (rows.isEmpty) {
      buffer.writeln("- *No transactions found matching criteria.*");
    } else {
      for (var tx in rows.take(8)) {
        final title = tx['title'];
        final amt = (tx['amount'] as num).toDouble();
        final date = tx['date'];
        final cat = tx['category'] ?? 'Uncategorized';
        final typeChar = tx['type'] == 'income' ? '+' : '-';
        buffer.writeln("- **$title** ($cat): $typeChar$currencySymbol${amt.toStringAsFixed(2)} on $date");
      }
      if (rows.length > 8) {
        buffer.writeln("- *And ${rows.length - 8} more transactions...*");
      }
    }

    return buffer.toString();
  }

  Future<String> _processQueryLocally(String query) async {
    _parseQuery(query, _sessionContext);

    final cleanQuery = query.toLowerCase();
    final db = await AppDatabase.instance.database;
    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    final isBalanceQuery = cleanQuery.contains("balance") || cleanQuery.contains("net worth") || cleanQuery.contains("my money");
    final isBudgetQuery = cleanQuery.contains("budget") || cleanQuery.contains("save") || cleanQuery.contains("saving");

    if (isBalanceQuery) {
      return _queryBalances(db, currencySymbol);
    } else if (isBudgetQuery) {
      return _queryBudgetsAndSavings(db, _sessionContext.targetMonth ?? DateTime.now().month, _sessionContext.targetYear ?? DateTime.now().year, currencySymbol);
    }

    final rows = await _runQuery(_sessionContext, query);

    double totalAmount = 0.0;
    for (var r in rows) {
      totalAmount += (r['amount'] as num).toDouble();
    }
    final averageAmount = rows.isNotEmpty ? totalAmount / rows.length : 0.0;

    Map<String, dynamic>? largestTransaction;
    if (rows.isNotEmpty) {
      largestTransaction = rows.reduce((a, b) =>
          (a['amount'] as num).toDouble() > (b['amount'] as num).toDouble() ? a : b);
    }

    double comparisonTotal = 0.0;
    double percentageChange = 0.0;
    double weekendSum = 0.0;
    double nightSum = 0.0;
    double impulseSum = 0.0;
    final recurringMap = <String, int>{};

    for (var r in rows) {
      final amt = (r['amount'] as num).toDouble();
      final dateStr = r['date']?.toString() ?? '';
      final title = r['title']?.toString() ?? '';
      final cat = r['category']?.toString() ?? '';

      try {
        final dt = DateTime.parse(dateStr);
        if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
          weekendSum += amt;
        }
        if (dt.hour >= 20) {
          nightSum += amt;
        }
      } catch (_) {}

      if (amt >= 1000 && (cat == 'Food' || cat == 'Entertainment')) {
        impulseSum += amt;
      }

      final key = "$title|${amt.toStringAsFixed(0)}";
      recurringMap[key] = (recurringMap[key] ?? 0) + 1;
    }

    final detectedSubscriptions = recurringMap.entries
        .where((e) => e.value >= 2)
        .map((e) => "- **${e.key.split('|')[0]}**: Recurring same-amount charges (${e.key.split('|')[1]})")
        .toList();

    return _generateDetailedNlgResponse(rows, totalAmount, averageAmount, largestTransaction, comparisonTotal, percentageChange, weekendSum, nightSum, impulseSum, detectedSubscriptions, currencySymbol);
  }

  String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }
    return '';
  }

  Future<String> _queryBalances(dynamic db, String currencySymbol) async {
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT name, type, balance FROM account ORDER BY balance DESC
    ''');

    if (results.isEmpty) {
      return "I couldn't find any accounts in your database. Please set up accounts first!";
    }

    double netWorth = 0.0;
    final buffer = StringBuffer();
    buffer.writeln("Here are your current account balances:\n");
    for (var r in results) {
      final name = r['name'];
      final type = r['type'];
      final bal = (r['balance'] as num).toDouble();
      netWorth += bal;
      buffer.writeln("- **$name** (${type.toString().toUpperCase()}): $currencySymbol${bal.toStringAsFixed(2)}");
    }
    buffer.writeln("\n**Total Net Balance**: $currencySymbol${netWorth.toStringAsFixed(2)}");
    return buffer.toString();
  }

  Future<String> _queryBudgetsAndSavings(dynamic db, int month, int year, String currencySymbol) async {
    final monthStr = "${year.toString()}-${month.toString().padLeft(2, '0')}";
    final List<Map<String, dynamic>> spendings = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND strftime('%Y-%m', date) = ?
      GROUP BY category_id
    ''', [monthStr]);
    final spendMap = {for (var r in spendings) r['category_id'] as int: (r['total'] as num).toDouble()};

    final List<Map<String, dynamic>> budgets = await db.rawQuery('''
      SELECT b.limit_amount, c.name, b.category_id
      FROM budget b
      JOIN category c ON b.category_id = c.id
      WHERE b.month = ?
    ''', [monthStr]);

    final buffer = StringBuffer();
    final monthName = "${_getMonthName(month)} $year";
    if (budgets.isEmpty) {
      buffer.writeln("You don't have any budgets set for **$monthName**.");
      buffer.writeln("To save money effectively, we recommend setting category spending limits. You can do this in the **Budgets** tab or use the new **Budget Blueprint** tool under the More tab to automatically generate limits based on your income!");
    } else {
      buffer.writeln("Here is your budget comparison for **$monthName**:\n");
      bool overspentAny = false;
      for (var b in budgets) {
        final cat = b['name'];
        final limit = (b['limit_amount'] as num).toDouble();
        final spent = spendMap[b['category_id'] as int] ?? 0.0;
        final diff = limit - spent;

        if (diff < 0) {
          overspentAny = true;
          buffer.writeln("- **$cat**: $currencySymbol${spent.toStringAsFixed(2)} of $currencySymbol${limit.toStringAsFixed(2)} (**Overspent by $currencySymbol${(-diff).toStringAsFixed(2)}** ⚠️)");
        } else {
          buffer.writeln("- **$cat**: $currencySymbol${spent.toStringAsFixed(2)} of $currencySymbol${limit.toStringAsFixed(2)} (Remaining: $currencySymbol${diff.toStringAsFixed(2)})");
        }
      }

      if (overspentAny) {
        buffer.writeln("\n💡 **Tip**: You have exceeded budgets in some categories. Try limiting dining out (Food) or leisure items (Entertainment) to stay on track.");
      } else {
        buffer.writeln("\n🎉 **Excellent!** You are currently keeping within all your category budgets. Keep it up!");
      }
    }

    // Add savings goals info
    final List<Map<String, dynamic>> goals = await db.rawQuery('''
      SELECT name, target_amount, current_amount FROM savings_goal
    ''');
    if (goals.isNotEmpty) {
      buffer.writeln("\n**Savings Goals Progress**:");
      for (var g in goals) {
        final name = g['name'];
        final tar = (g['target_amount'] as num).toDouble();
        final cur = (g['current_amount'] as num).toDouble();
        final pct = (cur / tar * 100).toStringAsFixed(0);
        buffer.writeln("- **$name**: $currencySymbol${cur.toStringAsFixed(0)} of $currencySymbol${tar.toStringAsFixed(0)} ($pct% saved)");
      }
    }

    return buffer.toString();
  }

  String _soundex(String s) {
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

  bool _fuzzyMatch(String text, String keyword) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final isOffline = !_useOnlineAI;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Assistant",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOffline ? Colors.orangeAccent : Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOffline ? "Local Insights Engine (Offline)" : "On-Device AI Agent (ADK)",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: "Clear Conversation History",
            onPressed: () async {
              final db = await AppDatabase.instance.database;
              await db.delete('chatbot_message');
              _sessionContext.clear();
              await _loadWelcomeDashboard();
            },
          ),
          Row(
            children: [
              Text(
                "Offline Mode",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Switch(
                value: !_useOnlineAI,
                onChanged: (val) {
                  setState(() {
                    _useOnlineAI = !val;
                  });
                },
                activeColor: const Color(0xFFE53935),
              ),
            ],
          ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildSuggestionsRow(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                child: const Icon(Icons.psychology, size: 18, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GlassmorphismCard(
                borderRadius: 16,
                blur: 10,
                color: msg.isMe
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderColor: msg.isMe
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (msg.chartWidget != null) ...[
                      const SizedBox(height: 12),
                      msg.chartWidget!,
                    ],
                  ],
                ),
              ),
            ),
            if (msg.isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 18, color: Color(0xFF6C63FF)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              child: const Icon(Icons.psychology, size: 18, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text("Assistant is thinking...", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    final chips = [
      "Where did I spend most?",
      "Account balances",
      "How to save more?",
      "Recent transactions",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () => _handleSubmitted(c),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ask about your finances...",
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6C63FF),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPieChart extends StatelessWidget {
  final Map<String, double> categoryShares;
  final String currencySymbol;

  const ChatPieChart({
    super.key,
    required this.categoryShares,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    int colorIdx = 0;
    final sections = categoryShares.entries.map((e) {
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: '${e.key}\n$currencySymbol${e.value.toStringAsFixed(0)}',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 140,
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 25,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class ChatBarChart extends StatelessWidget {
  final double val1;
  final double val2;
  final String label1;
  final String label2;
  final String currencySymbol;

  const ChatBarChart({
    super.key,
    required this.val1,
    required this.val2,
    required this.label1,
    required this.label2,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: (val1 > val2 ? val1 : val2) * 1.2,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: val1,
                  color: Colors.blueAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: val2,
                  color: Colors.orangeAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() == 0) return Text(label1, style: const TextStyle(fontSize: 10, color: Colors.grey));
                  if (value.toInt() == 1) return Text(label2, style: const TextStyle(fontSize: 10, color: Colors.grey));
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

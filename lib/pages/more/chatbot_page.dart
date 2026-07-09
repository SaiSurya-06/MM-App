import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/agent/agent_service.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isSystemError;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isSystemError = false,
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
  bool _isTyping = false;
  bool _useOnlineAI = true; // Attempt to use ADK Agent by default

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hi! I am your AI Financial Assistant. How can I help you today? You can ask me questions about your spending, accounts, budgets, and savings.",
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
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

    String responseText = "";
    bool isFallback = false;

    if (_useOnlineAI) {
      try {
        final rawResponse = await AgentService.sendMessage(text);
        if (rawResponse.startsWith("Error from agent:") ||
            rawResponse.contains("mock-key-for-local-testing") ||
            rawResponse.contains("Unexpected error:") ||
            rawResponse.trim().isEmpty) {
          // If ADK fails or is mocked, use local fallback
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

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: responseText,
            isMe: false,
            timestamp: DateTime.now(),
            isSystemError: isFallback && !_useOnlineAI,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  // Local Dart-side analyzer for offline-first capabilities
  Future<String> _processQueryLocally(String query) async {
    final cleanQuery = query.toLowerCase();
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    
    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    // 1. Detect Month
    int? targetMonthInt;
    int targetYear = now.year;
    
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
      if (cleanQuery.contains(entry.key)) {
        targetMonthInt = entry.value;
        break;
      }
    }
    
    // Detect relative months
    if (cleanQuery.contains("this month")) {
      targetMonthInt = now.month;
    } else if (cleanQuery.contains("last month")) {
      final lastMonthDate = DateTime(now.year, now.month - 1);
      targetMonthInt = lastMonthDate.month;
      targetYear = lastMonthDate.year;
    }
    
    // 2. Detect transaction type
    String? targetType;
    if (cleanQuery.contains("spend") || 
        cleanQuery.contains("spent") || 
        cleanQuery.contains("expense") || 
        cleanQuery.contains("paid") || 
        cleanQuery.contains("bought") ||
        cleanQuery.contains("cost")) {
      targetType = 'expense';
    } else if (cleanQuery.contains("got") || 
               cleanQuery.contains("received") || 
               cleanQuery.contains("earned") || 
               cleanQuery.contains("income") || 
               cleanQuery.contains("salary") || 
               cleanQuery.contains("interest") ||
               cleanQuery.contains("dividend")) {
      targetType = 'income';
    }
    
    // 3. Extract keywords (strip common stop words)
    final words = cleanQuery.split(RegExp(r'\s+'));
    final stopWords = {
      'how', 'much', 'did', 'i', 'get', 'got', 'in', 'the', 'month', 'of', 'on', 'at', 
      'for', 'show', 'list', 'my', 'me', 'what', 'was', 'were', 'spend', 'spent',
      'salary', 'income', 'expense', 'expenses', 'balance', 'balances', 'account', 'accounts',
      'this', 'last', 'interest', 'money', 'transaction', 'transactions', 'to', 'from',
      // month names
      ...monthsMap.keys
    };
    
    final keywords = words.where((w) => !stopWords.contains(w) && w.length > 2).toList();
    
    try {
      // Specific triggers
      if (cleanQuery.contains("balance") || cleanQuery.contains("net worth") || cleanQuery.contains("my money")) {
        return _queryBalances(db, currencySymbol);
      }
      
      if (cleanQuery.contains("budget") || cleanQuery.contains("saving")) {
        return _queryBudgetsAndSavings(db, targetMonthInt ?? now.month, targetYear, currencySymbol);
      }
      
      // General Natural Language Search
      final buffer = StringBuffer();
      
      // Build SQL query
      String sql = '''
        SELECT t.title, t.amount, t.type, t.date, c.name as category, t.note
        FROM transaction_log t
        LEFT JOIN category c ON t.category_id = c.id
      ''';
      
      List<dynamic> args = [];
      List<String> conditions = [];
      
      if (targetMonthInt != null) {
        final monthStr = "${targetYear.toString()}-${targetMonthInt.toString().padLeft(2, '0')}";
        conditions.add("strftime('%Y-%m', t.date) = ?");
        args.add(monthStr);
      }
      
      if (targetType != null) {
        conditions.add("t.type = ?");
        args.add(targetType);
      }
      
      if (conditions.isNotEmpty) {
        sql += " WHERE " + conditions.join(" AND ");
      }
      
      sql += " ORDER BY t.date DESC, t.id DESC";
      
      final List<Map<String, dynamic>> allTransactions = await db.rawQuery(sql, args);
      
      // Filter by keywords in Dart
      List<Map<String, dynamic>> filtered = allTransactions;
      String searchSubject = "transactions";
      
      if (cleanQuery.contains("interest")) {
        filtered = allTransactions.where((tx) => 
          tx['title'].toString().toLowerCase().contains('interest') ||
          (tx['category'] ?? '').toString().toLowerCase().contains('interest') ||
          (tx['note'] ?? '').toString().toLowerCase().contains('interest')
        ).toList();
        searchSubject = "interest";
      } else if (cleanQuery.contains("salary")) {
        filtered = allTransactions.where((tx) => 
          tx['title'].toString().toLowerCase().contains('salary') ||
          (tx['category'] ?? '').toString().toLowerCase().contains('salary')
        ).toList();
        searchSubject = "salary";
      } else if (keywords.isNotEmpty) {
        filtered = allTransactions.where((tx) {
          final title = tx['title'].toString().toLowerCase();
          final note = (tx['note'] ?? '').toString().toLowerCase();
          final cat = (tx['category'] ?? '').toString().toLowerCase();
          return keywords.any((kw) => title.contains(kw) || note.contains(kw) || cat.contains(kw));
        }).toList();
        searchSubject = "'${keywords.join(', ')}'";
      }
      
      final monthLabel = targetMonthInt != null 
          ? _getMonthName(targetMonthInt) + " $targetYear"
          : "this month";
          
      if (filtered.isEmpty) {
        return "I analyzed your database for $monthLabel, but I couldn't find any $searchSubject transactions. Try adjusting your query or keywords!";
      }
      
      double total = 0.0;
      for (var tx in filtered) {
        total += (tx['amount'] as num).toDouble();
      }
      
      final actionWord = targetType == 'expense' ? "spent" : (targetType == 'income' ? "received/earned" : "transacted");
      
      buffer.writeln("In **$monthLabel**, you **$actionWord** a total of **$currencySymbol${total.toStringAsFixed(2)}** matching **$searchSubject**:\n");
      for (var tx in filtered) {
        final title = tx['title'];
        final amt = (tx['amount'] as num).toDouble();
        final date = tx['date'];
        final cat = tx['category'] ?? 'Uncategorized';
        final typeChar = tx['type'] == 'income' ? '+' : '-';
        buffer.writeln("- **$title** ($cat): $typeChar$currencySymbol${amt.toStringAsFixed(2)} on $date");
      }
      
      return buffer.toString();
    } catch (e) {
      return "Sorry, I encountered an error while analyzing your local database: $e";
    }
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
    final monthName = _getMonthName(month) + " $year";
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
                    ? const Color(0xFFE53935).withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderColor: msg.isMe
                    ? const Color(0xFFE53935).withValues(alpha: 0.3)
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
                  ],
                ),
              ),
            ),
            if (msg.isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 18, color: Color(0xFFE53935)),
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
            const GlassmorphismCard(
              borderRadius: 16,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PulsingDot(delay: 0),
                    _PulsingDot(delay: 150),
                    _PulsingDot(delay: 300),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    final suggestions = [
      "Where did I spend most?",
      "Account balances",
      "How to save more?",
      "Recent transactions"
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              label: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.black12,
              ),
              onPressed: () => _handleSubmitted(text),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask about your finances...",
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            radius: 22,
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

class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isDark ? Colors.white70 : Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

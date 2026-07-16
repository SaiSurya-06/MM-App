import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/database/database.dart';
import '../../core/agent/financial_brain.dart';
import '../../core/agent/execution_plan.dart';
import '../../core/agent/planner.dart';
import '../../core/agent/retriever.dart';
import '../../core/agent/metrics_engine.dart';
import '../../core/agent/insight_engine.dart';
import '../../core/agent/score_engine.dart';
import '../../core/agent/investigation_engine.dart';
import '../../core/agent/prediction_engine.dart';
import '../../core/agent/decision_engine.dart';
import '../../core/agent/evaluation_engine.dart';
import '../../core/agent/coaching_engine.dart';
import '../../core/agent/ui_adapter.dart';
import '../../core/agent/analytics_engine.dart';
import '../../core/agent/scenario_engine.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../core/agent/agent_service.dart';

class ChatMessage {
  final String text; // Conversational fallback or user text
  final bool isMe;
  final DateTime timestamp;
  final bool isSystemError;
  final Widget? chartWidget;
  final List<UiComponent>? uiComponents;
  final FinancialScores? scores;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isSystemError = false,
    this.chartWidget,
    this.uiComponents,
    this.scores,
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
  final ConversationMemory _conversationMemory = ConversationMemory();
  bool _isTyping = false;
  bool _useOnlineAI = true;
  late String _sessionId;

  String _generateSessionId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void initState() {
    super.initState();
    _sessionId = _generateSessionId();
    AgentService.activeSessionId = _sessionId;
    _loadWelcomeDashboard();
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

  Future<void> _saveMessageToDb(String text, bool isMe, String? chartType, {Map<String, dynamic>? structuredData}) async {
    try {
      final db = await AppDatabase.instance.database;
      final savedText = structuredData != null ? jsonEncode(structuredData) : text;
      final profileId = ref.read(authProvider).profile?.id;
      if (profileId == null) return;

      final id = _generateSessionId(); // Generate unique message ID
      await db.insert('chatbot_message', {
        'id': id,
        'profile_id': profileId,
        'role': isMe ? 'user' : 'assistant',
        'content': savedText,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'chart_type': chartType,
      });
    } catch (e) {
      debugPrint("Error saving chatbot message: $e");
    }
  }

  Future<void> _loadWelcomeDashboard() async {
    final db = await AppDatabase.instance.database;
    
    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);
    final profileId = ref.read(authProvider).profile?.id;

    if (profileId == null) return;

    final List<Map<String, dynamic>> rows = await db.query(
      'chatbot_message',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp ASC',
    );
    
    if (rows.isNotEmpty) {
      final List<ChatMessage> loaded = [];
      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final rawText = r['content'] as String;
        final isMe = (r['role'] as String) == 'user';
        final timestamp = DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int);
        final chartType = r['chart_type'] as String?;

        List<UiComponent>? uiComponents;
        String displayText = rawText;

        try {
          if (rawText.startsWith('{') && rawText.endsWith('}')) {
            final decoded = jsonDecode(rawText) as Map<String, dynamic>;
            if (decoded['isStructured'] == true) {
              final widgetsArray = decoded['widgets'] as List;
              uiComponents = widgetsArray.map((w) {
                final typeIndex = w['type'] as int;
                return UiComponent(
                  type: UiComponentType.values[typeIndex],
                  data: Map<String, dynamic>.from(w['data'] as Map),
                );
              }).toList();
              final summaryComp = uiComponents.firstWhere(
                (c) => c.type == UiComponentType.summary,
                orElse: () => UiComponent(type: UiComponentType.summary, data: {'text': ''})
              );
              displayText = summaryComp.data['text']?.toString() ?? "";
            }
          }
        } catch (_) {}

        Widget? chartWidget;
        try {
          if (chartType != null && chartType != 'NONE' && chartType != 'none' && i > 0) {
            final userQuery = rows[i - 1]['text'] as String;
            final planner = RulePlanner();
            final plan = await planner.plan(userQuery, _conversationMemory);
            final fetched = await DatabaseRetriever.retrieve(plan);
            if (chartType == 'pie' || chartType == 'PIE') {
              final shares = <String, double>{};
              for (var tx in fetched.transactions) {
                final cat = tx['category']?.toString() ?? 'Other';
                shares[cat] = (shares[cat] ?? 0.0) + (tx['amount'] as num).toDouble();
              }
              if (shares.isNotEmpty) {
                chartWidget = ChatPieChart(categoryShares: shares, currencySymbol: currencySymbol);
              }
            } else if (chartType == 'bar' || chartType == 'BAR') {
              double totalAmount = 0.0;
              for (var tx in fetched.transactions) {
                totalAmount += (tx['amount'] as num).toDouble();
              }
              double comparisonTotal = 0.0;
              if (plan.comparisonMonth != null) {
                final compContext = ExecutionPlan(
                  intent: plan.intent,
                  responseType: plan.responseType,
                  merchant: plan.merchant,
                  category: plan.category,
                  minAmount: plan.minAmount,
                  maxAmount: plan.maxAmount,
                  targetMonth: plan.comparisonMonth,
                  targetYear: plan.comparisonYear,
                  paymentMethod: plan.paymentMethod,
                  timeFilter: plan.timeFilter,
                  targetType: plan.targetType,
                  requiredTools: plan.requiredTools,
                  requiredStrategies: plan.requiredStrategies,
                  needsForecast: plan.needsForecast,
                  needsDecision: plan.needsDecision,
                  needsCoaching: plan.needsCoaching,
                  confidence: plan.confidence,
                );
                final compRows = await DatabaseRetriever.retrieve(compContext);
                for (var tx in compRows.transactions) {
                  comparisonTotal += (tx['amount'] as num).toDouble();
                }
              }
              chartWidget = ChatBarChart(
                val1: totalAmount,
                val2: comparisonTotal,
                label1: _getMonthName(plan.targetMonth ?? DateTime.now().month),
                label2: _getMonthName(plan.comparisonMonth ?? (DateTime.now().month - 1)),
                currencySymbol: currencySymbol,
              );
            }
          }
        } catch (_) {}

        loaded.add(ChatMessage(
          text: displayText,
          isMe: isMe,
          timestamp: timestamp,
          chartWidget: chartWidget,
          uiComponents: uiComponents,
        ));
      }

      setState(() {
        _messages.clear();
        _messages.addAll(loaded);
      });
      _scrollToBottom();
      return;
    }

    final now = DateTime.now();
    final currentMonthPlan = ExecutionPlan(
      intent: 'search',
      responseType: 'financial_review',
      targetMonth: now.month,
      targetYear: now.year,
      requiredTools: ['transaction', 'budget', 'goal', 'account', 'subscription'],
      requiredStrategies: ['comparison', 'anomaly'],
      needsForecast: true,
      needsDecision: false,
      needsCoaching: true,
      confidence: 1.0,
    );

    try {
      final fetched = await DatabaseRetriever.retrieve(currentMonthPlan);
      
      final orchestrator = AgentOrchestrator(
        engines: [
          MetricsEngine(),
          InsightEngine(),
          ScoreEngine(),
        ],
      );
      final initialContext = FinancialContext.initial("dashboard", currentMonthPlan, fetched);
      final finalContext = await orchestrator.orchestrate(initialContext);

      final buffer = StringBuffer();
      final activeMonthName = _getMonthName(fetched.activeMonth ?? now.month);
      final fallbackText = fetched.fallbackMonthUsed 
          ? "No transactions found in this month. Showing your data from **$activeMonthName ${fetched.activeYear}** (your most recent active period):\n"
          : "Hi! I am your AI Financial Advisor. I've compiled your **Proactive Insights Dashboard** for **$activeMonthName**:\n";
      
      buffer.writeln(fallbackText);
      buffer.writeln("📊 **Financial Health Summary**:");
      buffer.writeln("- **Net Worth**: **$currencySymbol${fetched.netWorth.toStringAsFixed(2)}**");
      buffer.writeln("- **Savings Rate**: ${finalContext.scores.savingsScore.toStringAsFixed(1)}%");
      buffer.writeln("- **Cash Flow**: Income $currencySymbol${(finalContext.metrics['totalIncome'] as num).toDouble().toStringAsFixed(0)} / Expenses $currencySymbol${(finalContext.metrics['totalExpense'] as num).toDouble().toStringAsFixed(0)}");
      
      buffer.writeln("\n💡 **Impulse Habits & Proactive Alerts**:");
      final foodSpent = finalContext.metrics['categoryShares']['Food'] ?? 0.0;
      if (foodSpent > 0) {
        buffer.writeln("- **Food Delivery**: You spent **$currencySymbol${foodSpent.toStringAsFixed(0)}** on food delivery. Reducing this by 30% could save you **$currencySymbol${(foodSpent * 0.3).toStringAsFixed(0)}**.");
      }
      if (finalContext.metrics['largestTransaction'] != null) {
        buffer.writeln("- **Largest expense**: '${finalContext.metrics['largestTransaction']!['title']}' ($currencySymbol${(finalContext.metrics['largestTransaction']!['amount'] as num).toDouble().toStringAsFixed(0)}).");
      }
      if (finalContext.scores.savingsScore < 50 && (finalContext.metrics['totalIncome'] as num).toDouble() > 0) {
        buffer.writeln("- ⚠️ **Savings Alert**: Your savings rate is below the recommended 20%. Try cutting back on discretionary spending.");
      } else if (finalContext.scores.savingsScore >= 50) {
        buffer.writeln("- 🎉 **Great Job!**: Your savings rate is healthy (${finalContext.scores.savingsScore.toStringAsFixed(1)}%).");
      }

      buffer.writeln("\nAsk me anything! You can ask: *'why did expenses increase?'*, *'UPI payments above 500'*, *'compare June vs May'*.");

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

    await _saveMessageToDb(text, true, null);

    ExecutionPlan? parsedPlan;
    bool isFallback = false;

    final Planner planner = _useOnlineAI ? GeminiPlanner() : RulePlanner();
    try {
      parsedPlan = await planner.plan(text, _conversationMemory);
    } catch (e) {
      parsedPlan = await RulePlanner().plan(text, _conversationMemory);
      isFallback = true;
    }

    final mergedPlan = _conversationMemory.mergeNewPlan(parsedPlan);

    // 2. safe SQL tool registry data fetch
    final fetched = await DatabaseRetriever.retrieve(mergedPlan);

    // 3. Orchestrated Engine Pipeline (with Scenario Engine added)
    final orchestrator = AgentOrchestrator(
      engines: [
        MetricsEngine(),
        InsightEngine(),
        ScoreEngine(),
        InvestigationEngine(),
        PredictionEngine(),
        DecisionEngine(),
        ScenarioEngine(),
        EvaluationEngine(),
        CoachingEngine(useOnline: _useOnlineAI && !isFallback),
      ],
    );

    final initialContext = FinancialContext.initial(text, mergedPlan, fetched);
    final finalContext = await orchestrator.orchestrate(initialContext);

    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    // 4. Transform to declarative UI Presentation Components (Task 5.2)
    final uiComponents = UIAdapter.adapt(finalContext);

    Widget? chartWidget;
    if (finalContext.coaching.chartType == 'PIE' && finalContext.metrics['categoryShares'] != null) {
      chartWidget = ChatPieChart(categoryShares: Map<String, double>.from(finalContext.metrics['categoryShares'] as Map), currencySymbol: currencySymbol);
    } else if (finalContext.coaching.chartType == 'BAR' && mergedPlan.comparisonMonth != null) {
      chartWidget = ChatBarChart(
        val1: (finalContext.metrics['totalAmount'] as num).toDouble(),
        val2: (finalContext.metrics['totalAmount'] as num).toDouble() - finalContext.investigation.absoluteIncrease,
        label1: _getMonthName(mergedPlan.targetMonth ?? DateTime.now().month),
        label2: _getMonthName(mergedPlan.comparisonMonth!),
        currencySymbol: currencySymbol,
      );
    }

    // Persist structured widget package
    final structuredPacket = {
      'isStructured': true,
      'widgets': uiComponents.map((e) => {
        'type': e.type.index,
        'data': e.data,
      }).toList(),
      'coaching': finalContext.coaching.toJson(),
      'scores': {
        'savingsScore': finalContext.scores.savingsScore,
        'budgetScore': finalContext.scores.budgetScore,
        'spendingScore': finalContext.scores.spendingScore,
        'emergencyScore': finalContext.scores.emergencyScore,
        'overallScore': finalContext.scores.overallScore,
      }
    };

    await _saveMessageToDb('', false, finalContext.coaching.chartType.toLowerCase(), structuredData: structuredPacket);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: finalContext.coaching.summary,
            isMe: false,
            timestamp: DateTime.now(),
            isSystemError: isFallback && !_useOnlineAI,
            chartWidget: chartWidget,
            uiComponents: uiComponents,
            scores: finalContext.scores,
          ),
        );
      });
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2833);
    final isOffline = !_useOnlineAI;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0C10) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Assistant",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOffline ? Colors.orangeAccent : Colors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOffline ? "Investigative OS (Offline)" : "On-Device Financial OS (ADK)",
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
            icon: const Icon(Icons.delete_sweep, color: Colors.grey),
            tooltip: "Clear Conversation History",
            onPressed: () async {
              final db = await AppDatabase.instance.database;
              final profileId = ref.read(authProvider).profile?.id;
              if (profileId != null) {
                await db.delete(
                  'chatbot_message',
                  where: 'profile_id = ?',
                  whereArgs: [profileId],
                );
              }
              _conversationMemory.clear();
              _sessionId = _generateSessionId();
              AgentService.activeSessionId = _sessionId;
              await _loadWelcomeDashboard();
            },
          ),
          Row(
            children: [
              Text(
                "Offline",
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
                activeColor: Colors.tealAccent,
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

    if (msg.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: GlassmorphismCard(
                  borderRadius: 12,
                  blur: 15,
                  color: isDark ? Colors.tealAccent.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.05),
                  borderColor: isDark ? Colors.tealAccent.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? const Color(0xFF1F2833) : Colors.grey[200],
                child: Icon(Icons.person, size: 14, color: isDark ? Colors.tealAccent : Colors.teal),
              ),
            ],
          ),
        ),
      );
    }

    final comps = msg.uiComponents;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? const Color(0xFF1F2833) : Colors.grey[200],
              child: Icon(Icons.psychology, size: 14, color: isDark ? Colors.tealAccent : Colors.teal),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comps != null
                    ? comps.map((c) => _renderUiComponent(c, msg.chartWidget)).toList()
                    : [
                        GlassmorphismCard(
                          borderRadius: 12,
                          blur: 15,
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderUiComponent(UiComponent comp, Widget? chartWidget) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (comp.type) {
      case UiComponentType.accountBalanceCard:
        final total = (comp.data['totalBalance'] as num? ?? 0.0).toDouble();
        final list = comp.data['accounts'] as List? ?? [];
        final buffer = (comp.data['buffer'] as num? ?? 0.0).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassmorphismCard(
            borderRadius: 16,
            blur: 20,
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.015),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "💰 Available Cash",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "₹${total.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.tealAccent : const Color(0xFF008080),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Across ${list.length} accounts",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 14),
                ...list.map((item) {
                  final name = item['name']?.toString() ?? 'Account';
                  final balance = (item['balance'] as num? ?? 0.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          "₹${balance.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available after upcoming bills",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                    Text(
                      "₹${buffer.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: buffer > 10000 ? Colors.tealAccent : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case UiComponentType.recentTransactionsCard:
        final txs = comp.data['transactions'] as List? ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassmorphismCard(
            borderRadius: 16,
            blur: 20,
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.015),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📑 Recent Activity",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (txs.isEmpty)
                  const Text("No recent transactions found.", style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...txs.map((tx) {
                    final title = tx['title']?.toString() ?? 'Transaction';
                    final amount = (tx['amount'] as num? ?? 0.0).toDouble();
                    final date = tx['date']?.toString() ?? '';
                    final category = tx['category']?.toString() ?? 'Other';
                    final type = tx['type']?.toString() ?? 'expense';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: type == 'income' ? Colors.teal.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                            child: Icon(
                              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 14,
                              color: type == 'income' ? Colors.tealAccent : Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$date · $category",
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${type == 'income' ? '+' : '-'}₹${amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: type == 'income' ? Colors.tealAccent : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );

      case UiComponentType.budgetBlueprintCard:
        final income = (comp.data['income'] as num? ?? 0.0).toDouble();
        final expense = (comp.data['expense'] as num? ?? 0.0).toDouble();
        final savings = (comp.data['savings'] as num? ?? 0.0).toDouble();
        final list = comp.data['budgets'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassmorphismCard(
            borderRadius: 16,
            blur: 20,
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.015),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🗺️ Monthly Money Blueprint",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Money In", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("₹${income.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Outflow", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("₹${expense.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Money Saved", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("₹${savings.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                const Text(
                  "Meters of Budget Spent",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Text("No active category budgets found.", style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...list.map((item) {
                    final name = item['name']?.toString() ?? 'Other';
                    final limit = (item['limit'] as num? ?? 0.0).toDouble();
                    final spent = (item['spent'] as num? ?? 0.0).toDouble();
                    final percent = (item['percent'] as num? ?? 0.0).toDouble();

                    String statusText = "Safe";
                    Color statusColor = Colors.tealAccent;
                    if (percent >= 1.0) {
                      statusText = "Over Budget";
                      statusColor = Colors.redAccent;
                    } else if (percent >= 0.8) {
                      statusText = "Almost Full";
                      statusColor = Colors.orangeAccent;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percent.clamp(0.0, 1.0),
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );

      case UiComponentType.aiInsightCard:
        final title = comp.data['title']?.toString() ?? '💡 Best Insight';
        final detail = comp.data['detail']?.toString() ?? '';
        final cardType = comp.data['cardType']?.toString() ?? 'insight';
        
        Color accentColor = Colors.blueAccent;
        if (cardType == 'habit') accentColor = Colors.purpleAccent;
        if (cardType == 'risk') accentColor = Colors.redAccent;
        if (cardType == 'win') accentColor = Colors.tealAccent;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accentColor, width: 4)),
            ),
            child: GlassmorphismCard(
              borderRadius: 12,
              blur: 15,
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case UiComponentType.largestTransactionCard:
        final title = comp.data['title']?.toString() ?? 'Purchase';
        final amount = (comp.data['amount'] as num? ?? 0.0).toDouble();
        final date = comp.data['date']?.toString() ?? '';
        final category = comp.data['category']?.toString() ?? 'Other';
        final pct = (comp.data['pctOfMonthly'] as num? ?? 0.0).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🏆 Largest Transaction", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    Text(
                      "₹${amount.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.tealAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Date: $date", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("Category: $category", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                if (pct > 0) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 4),
                  Text(
                    "This represents ${pct.toStringAsFixed(0)}% of your monthly spending.",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );

      case UiComponentType.comparisonTableCard:
        final abs = (comp.data['absoluteIncrease'] as num? ?? 0.0).toDouble();
        final pct = (comp.data['percentageIncrease'] as num? ?? 0.0).toDouble();
        final causes = List<String>.from(comp.data['causes'] ?? []);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("⚖️ Period Comparison Summary", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  "Expenses increased by +₹${abs.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%) compared to comparison month.",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                if (causes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text("Main Causes of Increase:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 4),
                  ...causes.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text("• $c", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                      )),
                ],
              ],
            ),
          ),
        );

      case UiComponentType.budgetProgressCard:
        final list = comp.data['budgets'] as List? ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📊 Category Budgets Progress", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Text("No active category budgets found.", style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...list.map((item) {
                    final name = item['name']?.toString() ?? 'Other';
                    final limit = (item['limit'] as num? ?? 0.0).toDouble();
                    final spent = (item['spent'] as num? ?? 0.0).toDouble();
                    final percent = (item['percent'] as num? ?? 0.0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              Text("₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(percent >= 1.0 ? Colors.redAccent : Colors.orangeAccent),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );

      case UiComponentType.goalProgressCard:
        final list = comp.data['goals'] as List? ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🎯 Savings Goals Progress", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Text("No active savings goals found.", style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...list.map((item) {
                    final name = item['name']?.toString() ?? 'Goal';
                    final target = (item['target'] as num? ?? 1.0).toDouble();
                    final current = (item['current'] as num? ?? 0.0).toDouble();
                    final percent = (item['percent'] as num? ?? 0.0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              Text("₹${current.toStringAsFixed(0)} / ₹${target.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );

      case UiComponentType.decisionCard:
        final isAffordable = comp.data['isAffordable'] == true;
        final price = (comp.data['price'] as num? ?? 0.0).toDouble();
        final decisionText = comp.data['decisionText']?.toString() ?? '';
        final recommendationText = comp.data['recommendationText']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAffordable ? Icons.check_circle : Icons.warning_rounded,
                      color: isAffordable ? Colors.tealAccent : Colors.orangeAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAffordable ? "Comfortably Affordable (₹${price.toStringAsFixed(0)})" : "Budget Risk Detected (₹${price.toStringAsFixed(0)})",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  decisionText,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                ),
                if (recommendationText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 4),
                  Text(
                    recommendationText,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );

      case UiComponentType.scopeCard:
        final txs = comp.data['transactions'] ?? 0;
        final accs = comp.data['accounts'] ?? 0;
        final dates = comp.data['dateRange'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0, top: 2.0),
          child: Center(
            child: Text(
              "Based on: $txs Transactions | $accs Accounts | $dates",
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case UiComponentType.evidenceCard:
        final checklist = List<String>.from(comp.data['checklist'] ?? []);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 10,
            blur: 10,
            color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.005),
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  "🔍 Reasoning & Calculation Evidence",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                dense: true,
                childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                children: checklist.map((item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        );

      case UiComponentType.healthScore:
        final overall = comp.data['overallScore'] as double? ?? 0.0;
        final savings = comp.data['savingsScore'] as double? ?? 0.0;
        final budget = comp.data['budgetScore'] as double? ?? 0.0;
        final emergency = comp.data['emergencyScore'] as double? ?? 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreCircular(overall, "Health Index", Colors.tealAccent),
                _buildScoreCircular(savings, "Savings", Colors.blueAccent),
                _buildScoreCircular(budget, "Budget", Colors.orangeAccent),
                _buildScoreCircular(emergency, "Emergency", Colors.purpleAccent),
              ],
            ),
          ),
        );
      case UiComponentType.summary:
        final text = comp.data['text']?.toString() ?? "";
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GlassmorphismCard(
            borderRadius: 12,
            blur: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        );
      case UiComponentType.insights:
        final list = List<String>.from(comp.data['list'] ?? []);
        return _buildBulletSection("💡 Insights", list, Colors.blueAccent);
      case UiComponentType.warnings:
        final list = List<String>.from(comp.data['list'] ?? []);
        return _buildBulletSection("⚠️ Alerts", list, Colors.orangeAccent);
      case UiComponentType.recommendations:
        final list = List<String>.from(comp.data['list'] ?? []);
        return _buildBulletSection("🎯 Recommendations", list, Colors.tealAccent);
      case UiComponentType.nextActions:
        final list = List<String>.from(comp.data['list'] ?? []);
        return _buildBulletSection("✅ Actions", list, Colors.purpleAccent);
      case UiComponentType.chart:
        if (chartWidget != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassmorphismCard(
              borderRadius: 12,
              blur: 15,
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
              padding: const EdgeInsets.all(12),
              child: chartWidget,
            ),
          );
        }
        return const SizedBox.shrink();
      case UiComponentType.motivationalMessage:
        final text = comp.data['text']?.toString() ?? "";
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        );
      case UiComponentType.followUps:
        return const SizedBox.shrink(); // follow-up chips are rendered floating at screen bottom instead
    }
  }

  Widget _buildScoreCircular(double score, String label, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 2,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBulletSection(String title, List<String> items, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GlassmorphismCard(
        borderRadius: 12,
        blur: 15,
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, right: 6.0),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          i,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? const Color(0xFF1F2833) : Colors.grey[200],
              child: Icon(Icons.psychology, size: 14, color: isDark ? Colors.tealAccent : Colors.teal),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Investigating...", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    List<String> chips = [
      "Why did expenses increase?",
      "Account balances",
      "How to save more?",
      "Recent transactions",
    ];

    if (_messages.isNotEmpty) {
      final lastMsg = _messages.last;
      if (!lastMsg.isMe && lastMsg.uiComponents != null) {
        final fComp = lastMsg.uiComponents!.firstWhere(
          (c) => c.type == UiComponentType.followUps,
          orElse: () => UiComponent(type: UiComponentType.followUps, data: {'list': []})
        );
        final list = List<String>.from(fComp.data['list'] ?? []);
        if (list.isNotEmpty) {
          chips = list;
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: () => _handleSubmitted(c),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Ask about your finances...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? const Color(0xFF1F2833) : Colors.teal,
            child: IconButton(
              icon: Icon(Icons.send, color: isDark ? Colors.tealAccent : Colors.white, size: 16),
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

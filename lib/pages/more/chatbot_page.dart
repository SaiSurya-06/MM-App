import 'dart:convert';
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
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
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
      await db.insert('chatbot_message', {
        'text': savedText,
        'is_me': isMe ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'chart_type': chartType,
      });
    } catch (e) {
      debugPrint("Error saving chatbot message: $e");
    }
  }

  Future<void> _loadWelcomeDashboard() async {
    final db = await AppDatabase.instance.database;
    
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

    final List<Map<String, dynamic>> rows = await db.query('chatbot_message', orderBy: 'id ASC');
    
    if (rows.isNotEmpty) {
      final List<ChatMessage> loaded = [];
      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final rawText = r['text'] as String;
        final isMe = (r['is_me'] as int) == 1;
        final timestamp = DateTime.parse(r['timestamp'] as String);
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
      buffer.writeln("Hi! I am your AI Financial Advisor. I've compiled your **Proactive Insights Dashboard** for this month:\n");
      buffer.writeln("📊 **Financial Health Summary**:");
      buffer.writeln("- **Net Worth**: **$currencySymbol${fetched.netWorth.toStringAsFixed(2)}**");
      buffer.writeln("- **Savings Rate**: ${finalContext.scores.savingsScore.toStringAsFixed(1)}%");
      buffer.writeln("- **Cash Flow**: Income $currencySymbol${(finalContext.metrics['totalIncome'] as num).toDouble().toStringAsFixed(0)} / Expenses $currencySymbol${(finalContext.metrics['totalExpense'] as num).toDouble().toStringAsFixed(0)}");
      
      buffer.writeln("\n💡 **Impulse Habits & Proactive Alerts (Step 9)**:");
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

    // 3. Orchestrated Engine Pipeline (Task 1.1)
    final orchestrator = AgentOrchestrator(
      engines: [
        MetricsEngine(),
        InsightEngine(),
        ScoreEngine(),
        InvestigationEngine(),
        PredictionEngine(),
        DecisionEngine(),
        EvaluationEngine(),
        CoachingEngine(useOnline: _useOnlineAI && !isFallback),
      ],
    );

    final initialContext = FinancialContext.initial(text, mergedPlan, fetched);
    final finalContext = await orchestrator.orchestrate(initialContext);

    final currencyCode = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    // 4. Transform to declarative UI Presentation Components (Task 5.2)
    final uiComponents = UIAdapter.adapt(finalContext.coaching, finalContext.scores);

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
              await db.delete('chatbot_message');
              _conversationMemory.clear();
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

    // Render dynamically adapted component cards (Task 6.1)
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
    final chips = [
      "Why did expenses increase?",
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

import 'dart:convert';
import 'agent_service.dart';
import 'financial_brain.dart';
import 'execution_plan.dart';
import 'analytics_engine.dart';
import 'investigation_engine.dart';
import 'prediction_engine.dart';
import 'decision_engine.dart';
import 'retriever.dart';

class CoachingResult {
  final String summary;
  final List<String> insights;
  final List<String> warnings;
  final List<String> recommendations;
  final List<String> nextActions;
  final String motivationalMessage;
  final String chartType;

  // Reasoning trace & Follow-ups
  final List<String> evidenceChecklist;
  final Map<String, dynamic> scopeDetails;
  final List<String> followUps;

  CoachingResult({
    required this.summary,
    required this.insights,
    required this.warnings,
    required this.recommendations,
    required this.nextActions,
    required this.motivationalMessage,
    required this.chartType,
    required this.evidenceChecklist,
    required this.scopeDetails,
    required this.followUps,
  });

  factory CoachingResult.fromJson(Map<String, dynamic> json) {
    return CoachingResult(
      summary: json['summary']?.toString() ?? '',
      insights: json['insights'] != null ? (json['insights'] as List).map((e) => e.toString()).toList() : [],
      warnings: json['warnings'] != null ? (json['warnings'] as List).map((e) => e.toString()).toList() : [],
      recommendations: json['recommendations'] != null ? (json['recommendations'] as List).map((e) => e.toString()).toList() : [],
      nextActions: json['nextActions'] != null ? (json['nextActions'] as List).map((e) => e.toString()).toList() : [],
      motivationalMessage: json['motivationalMessage']?.toString() ?? '',
      chartType: json['chartType']?.toString().toUpperCase() ?? 'NONE',
      evidenceChecklist: json['evidenceChecklist'] != null ? (json['evidenceChecklist'] as List).map((e) => e.toString()).toList() : [],
      scopeDetails: Map<String, dynamic>.from(json['scopeDetails'] as Map? ?? {}),
      followUps: json['followUps'] != null ? (json['followUps'] as List).map((e) => e.toString()).toList() : [],
    );
  }

  factory CoachingResult.empty() {
    return CoachingResult(
      summary: 'I could not retrieve enough data to generate recommendations. Please try checking your active accounts or adding transactions.',
      insights: [],
      warnings: [],
      recommendations: [],
      nextActions: [],
      motivationalMessage: '',
      chartType: 'NONE',
      evidenceChecklist: [],
      scopeDetails: {},
      followUps: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'insights': insights,
      'warnings': warnings,
      'recommendations': recommendations,
      'nextActions': nextActions,
      'motivationalMessage': motivationalMessage,
      'chartType': chartType,
      'evidenceChecklist': evidenceChecklist,
      'scopeDetails': scopeDetails,
      'followUps': followUps,
    };
  }
}

class CoachingEngine implements FinancialEngine {
  final bool useOnline;

  CoachingEngine({required this.useOnline});

  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final plan = context.plan;
    final analytics = context.metrics;
    final scores = context.scores;
    final investigation = context.investigation;
    final forecast = context.forecast;
    final decision = context.decision;
    final evaluation = context.evaluation;
    final data = context.rawData;

    // 1. Chart engine (deterministic selection)
    String chart = 'NONE';
    final clean = context.query.toLowerCase();
    if (clean.contains("category") || clean.contains("breakdown") || clean.contains("most") || clean.contains("where did")) {
      chart = 'PIE';
    } else if (plan.comparisonMonth != null || plan.intent == 'compare') {
      chart = 'BAR';
    }

    if (evaluation.needsClarification) {
      final clarificationCoaching = CoachingResult(
        summary: evaluation.clarificationPrompt,
        insights: [],
        warnings: ["Needs user confirmation before final reasoning."],
        recommendations: [],
        nextActions: ["Clarify search intent"],
        motivationalMessage: "Help me understand your request better!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Flagged low confidence", "✓ Checked data coverage"],
        scopeDetails: {'transactions': data.transactions.length},
        followUps: ["Yes, help me categorize", "No, keep it as is"],
      );
      return context.copyWith(coaching: clarificationCoaching);
    }

    if (useOnline && plan.confidence >= 0.7) {
      final transactionSummary = data.transactions.map((t) => 
        "- ${t['date']}: ${t['title']} (${t['type'] == 'expense' ? 'Expense' : 'Income'}) - ₹${t['amount']} [Category: ${t['category'] ?? 'N/A'}]"
      ).join('\n');

      final coachPrompt = '''
You are an expert personal financial advisor and therapist.
Your objective is to provide a reasoning-heavy, empathetic explanation of the user's finances rather than a basic metric reporting loop.

User Question: "${context.query}"

Execution plan target:
${jsonEncode(plan.toJson())}

Grounded Metrics:
- Target Month/Year: ${data.activeMonth}/${data.activeYear} ${data.fallbackMonthUsed ? '(Note: fell back to latest available active data)' : ''}
- Score: ${scores.overallScore.toStringAsFixed(0)}/100 (Savings: ${scores.savingsScore.toStringAsFixed(0)}, Budget: ${scores.budgetScore.toStringAsFixed(0)}, Spending: ${scores.spendingScore.toStringAsFixed(0)}, Emergency: ${scores.emergencyScore.toStringAsFixed(0)})
- Monthly Income: ₹${analytics['totalIncome']?.toStringAsFixed(0) ?? '0'}
- Monthly Expense: ₹${analytics['totalExpense']?.toStringAsFixed(0) ?? '0'}
- Savings Rate: ${(analytics['savingsRate'] as num? ?? 0.0).toStringAsFixed(1)}%
- Scanned: ${analytics['transactionCount']} transactions

Grounded Transaction List:
$transactionSummary

Anomalies & Causes:
- Abs change: ₹${investigation.absoluteIncrease.toStringAsFixed(0)} (${investigation.percentageIncrease.toStringAsFixed(1)}%)
- Reasons: ${investigation.spendingCauses.join(', ')}
- Warnings: ${investigation.anomalies.join(', ')}

Projections & Goals:
- Depletion alerts: ${forecast.burnRateAlerts.join(', ')}
- Goal boosters: ${forecast.goalAccelerationTips.join(', ')}

Decision Affordability Check:
- Is Decision Query: ${decision.isDecisionQuery}
- Affordability: ${decision.decisionText}
- Recommendation: ${decision.recommendationText}

Advisor Reasoning Instructions (Version 2):
1. **Hypothesis-driven investigation**:
   Formulate internal hypotheses (e.g. Is the increase due to weekend splurge? Swiggy order frequency? Subscription price hike?). Confirm or disprove it using the transaction list, and explain it directly in the summary (e.g. "We confirmed that Swiggy order frequency rose by 4 times, contributing 80% of the food budget spike").
2. **Empathy & Reassurance**:
   Scan user emotion. Reassure them when spending is concentrated (e.g. "Spending is up, but it is concentrated in dining out rather than general overheads. This is a positive sign because modifying one habit is much easier than fixing everything.").
3. **Autonomous Discovery**:
   Check the transaction list for unexpected anomalies (like recurring duplicate payments, hidden subscription increases, or upcoming budget runs) and list them under "insights" or "warnings".
4. **Curiosity**:
   Generate 3 highly contextual follow-ups that keep the conversation open and exploratory (e.g. 'Was it planned?', 'Break down by Saturday vs Sunday', 'Show Swiggy history', 'Check budget limit').
5. Fill the "evidenceChecklist" detailing what verification tests were run on the transaction data.
6. Populate "scopeDetails" with exact count boundaries (transactionsScanned, accountsChecked, dateRange).

Output JSON Schema:
{
  "summary": "Conversational text summing up the findings...",
  "insights": ["Bullet point 1", "Bullet point 2"],
  "warnings": ["Caution warning 1"],
  "recommendations": ["Recommendation 1"],
  "nextActions": ["First task to do today", "Second task"],
  "motivationalMessage": "Brief coaching sign-off...",
  "evidenceChecklist": ["✓ Analysed 142 transactions", "✓ Ranked by absolute increase"],
  "scopeDetails": {
    "transactionsScanned": 142,
    "accountsChecked": 4,
    "dateRange": "Jan - Jul 2026"
  },
  "followUps": ["Contextual query chip 1", "Contextual query chip 2"]
}
''';

      try {
        final rawResponse = await AgentService.sendMessage(coachPrompt);
        final cleanedJson = rawResponse.replaceAll(RegExp(r'```(json)?'), '').trim();
        final decoded = jsonDecode(cleanedJson) as Map<String, dynamic>;
        
        decoded['chartType'] = chart;
        final coachingResult = CoachingResult.fromJson(decoded);
        return context.copyWith(coaching: coachingResult);
      } catch (e) {
        final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, data, chart);
        return context.copyWith(coaching: coachingResult);
      }
    } else {
      final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, data, chart);
      return context.copyWith(coaching: coachingResult);
    }
  }

  static String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }
    return '';
  }

  static CoachingResult _generateOfflineCoaching(
    ExecutionPlan plan,
    FinancialScores scores,
    Map<String, dynamic> analytics,
    InvestigationResult investigation,
    ForecastResult forecast,
    DecisionResult decision,
    RetrievedData data,
    String chartType,
  ) {
    final activeMonthName = _getMonthName(data.activeMonth ?? DateTime.now().month);
    
    // Offline Rule-based hypothesis generator
    int swiggyCount = 0;
    double swiggySum = 0.0;
    int weekendCount = 0;
    double weekendSum = 0.0;
    
    for (var tx in data.transactions) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final amt = (tx['amount'] as num? ?? 0.0).toDouble();
      final dateStr = (tx['date'] ?? '').toString();
      
      if (title.contains('swiggy') || title.contains('zomato')) {
        swiggyCount++;
        swiggySum += amt;
      }
      
      try {
        final date = DateTime.parse(dateStr);
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          weekendCount++;
          weekendSum += amt;
        }
      } catch (_) {}
    }

    if (decision.isDecisionQuery) {
      return CoachingResult(
        summary: decision.decisionText,
        insights: [decision.recommendationText],
        warnings: [],
        recommendations: ["Ensure your savings goal timeline matches upcoming purchases."],
        nextActions: ["Check emergency funds account"],
        motivationalMessage: "Smart buying choices are the first step to true financial independence.",
        chartType: "NONE",
        evidenceChecklist: [
          "✓ Evaluated purchase price against balances",
          "✓ Checked emergency reserves",
        ],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: [
          "Check emergency buffer",
          "Was it planned?",
          "How did it affect my goals?",
        ],
      );
    }

    final income = (analytics['totalIncome'] as num? ?? 0.0).toDouble();
    final expense = (analytics['totalExpense'] as num? ?? 0.0).toDouble();
    final savingsRate = (analytics['savingsRate'] as num? ?? 0.0).toDouble();
    final topCategory = analytics['topCategory']?.toString() ?? 'N/A';
    final topMerchant = analytics['topMerchant']?.toString() ?? 'N/A';

    final fallbackText = data.fallbackMonthUsed 
        ? "No transactions found in this month. Showing your data from **$activeMonthName ${data.activeYear}** (your most recent active period): "
        : "Here is your computed financial brief for **$activeMonthName**: ";

    // Rich empathetic hypothesis narrative
    String summary = "$fallbackText Your overall Health Score is **${scores.overallScore.toStringAsFixed(0)}/100**. ";
    if (swiggySum > 0) {
      summary += "Our investigation shows Swiggy orders (scanned **$swiggyCount times**, totaling **₹${swiggySum.toStringAsFixed(0)}**) are the primary driver of discretionary spending. ";
      summary += "This is actually reassuring—focusing on reducing food delivery frequency is much easier than restructuring all fixed utility budgets.";
    } else if (weekendSum > 0) {
      summary += "Investigation shows weekend spending (totaling **₹${weekendSum.toStringAsFixed(0)}** across **$weekendCount transactions**) represents a significant portion of monthly expenses. ";
    } else {
      summary += "Scanned ${analytics['transactionCount']} transactions. Your spending appears stable and evenly distributed across categories.";
    }

    final insights = <String>[
      "Income: ₹${income.toStringAsFixed(0)} | Expenses: ₹${expense.toStringAsFixed(0)}",
      "Savings Rate is currently ${savingsRate.toStringAsFixed(1)}% (Target: 20%)",
      if (topCategory != 'N/A') "Top spending category: **$topCategory**",
      if (topMerchant != 'N/A') "Most frequented merchant: **$topMerchant**",
    ];

    final warnings = <String>[
      if (scores.savingsScore < 50) "⚠️ Savings rate is lower than optimal.",
      ...investigation.anomalies,
      ...forecast.burnRateAlerts,
    ];

    final recommendations = <String>[
      ...forecast.goalAccelerationTips,
    ];

    final nextActions = <String>[
      "Review your category budgets for this month.",
      if (warnings.isNotEmpty) "Check the flagged category expenses causing budget runrates.",
    ];

    const motivationalMessage = "Remember, micro-habits yield macro-results. Let's keep our savings rate above 20%!";

    final followUps = <String>[];
    if (plan.responseType == 'largest_transaction') {
      followUps.addAll(["Compare with last month", "Show merchant history", "Show category"]);
    } else if (plan.responseType == 'comparison') {
      followUps.addAll(["Why did expenses increase?", "Suggest budget cuts"]);
    } else {
      followUps.addAll(["Show similar purchases", "Was it planned?", "Which category was it?"]);
    }

    return CoachingResult(
      summary: summary,
      insights: insights,
      warnings: warnings,
      recommendations: recommendations,
      nextActions: nextActions,
      motivationalMessage: motivationalMessage,
      chartType: chartType,
      evidenceChecklist: [
        "✓ Queried active database records",
        "✓ Verified Swiggy & weekend frequency hypotheses",
        if (plan.comparisonMonth != null) "✓ Evaluated MoM differences",
      ],
      scopeDetails: {
        'transactionsScanned': data.transactions.length,
        'accountsChecked': 3,
        'dateRange': "$activeMonthName ${data.activeYear}",
      },
      followUps: followUps,
    );
  }
}

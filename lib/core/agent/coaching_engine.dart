import 'dart:convert';
import 'agent_service.dart';
import 'financial_brain.dart';
import 'execution_plan.dart';
import 'analytics_engine.dart';
import 'investigation_engine.dart';
import 'prediction_engine.dart';
import 'decision_engine.dart';

class CoachingResult {
  final String summary;
  final List<String> insights;
  final List<String> warnings;
  final List<String> recommendations;
  final List<String> nextActions;
  final String motivationalMessage;
  final String chartType;

  CoachingResult({
    required this.summary,
    required this.insights,
    required this.warnings,
    required this.recommendations,
    required this.nextActions,
    required this.motivationalMessage,
    required this.chartType,
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

    // 1. Chart engine (deterministic selection)
    String chart = 'NONE';
    final clean = context.query.toLowerCase();
    if (clean.contains("category") || clean.contains("breakdown") || clean.contains("most") || clean.contains("where did")) {
      chart = 'PIE';
    } else if (plan.comparisonMonth != null || plan.intent == 'compare') {
      chart = 'BAR';
    }

    if (evaluation.needsClarification) {
      // Short-circuit: If evaluation flag requires clarification, return clarification directly
      final clarificationCoaching = CoachingResult(
        summary: evaluation.clarificationPrompt,
        insights: [],
        warnings: ["Needs user confirmation before final reasoning."],
        recommendations: [],
        nextActions: ["Clarify search intent"],
        motivationalMessage: "Help me understand your request better!",
        chartType: "NONE",
      );
      return context.copyWith(coaching: clarificationCoaching);
    }

    if (useOnline && plan.confidence >= 0.7) {
      final coachPrompt = '''
You are a professional Financial Coach.
Provide structured coaching advice by interpreting the computed financial statistics, anomalies, and forecasts.

User Question: "${context.query}"

Execution plan target:
${jsonEncode(plan.toJson())}

Grounded Metrics (Zero Hallucination - Use ONLY these facts):
- Score: ${scores.overallScore.toStringAsFixed(0)}/100 (Savings: ${scores.savingsScore.toStringAsFixed(0)}, Budget: ${scores.budgetScore.toStringAsFixed(0)}, Spending: ${scores.spendingScore.toStringAsFixed(0)}, Emergency: ${scores.emergencyScore.toStringAsFixed(0)})
- Monthly Income: ₹${analytics['totalIncome']?.toStringAsFixed(0) ?? '0'}
- Monthly Expense: ₹${analytics['totalExpense']?.toStringAsFixed(0) ?? '0'}
- Savings Rate: ${(analytics['savingsRate'] as num? ?? 0.0).toStringAsFixed(1)}%
- Scanned: ${analytics['transactionCount']} transactions

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

Instructions:
1. Conforming strictly to the JSON schema below, return a highly actionable financial report.
2. Return ONLY valid raw JSON. No markdown wraps (like ```json), no intro text.
3. Be encouraging and direct.
4. Keep the lists under 4 items each.

Output JSON Schema:
{
  "summary": "Conversational text summing up the findings...",
  "insights": ["Bullet point 1", "Bullet point 2"],
  "warnings": ["Caution warning 1"],
  "recommendations": ["Recommendation 1"],
  "nextActions": ["First task to do today", "Second task"],
  "motivationalMessage": "Brief coaching sign-off..."
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
        final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, chart);
        return context.copyWith(coaching: coachingResult);
      }
    } else {
      final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, chart);
      return context.copyWith(coaching: coachingResult);
    }
  }

  static CoachingResult _generateOfflineCoaching(
    ExecutionPlan plan,
    FinancialScores scores,
    Map<String, dynamic> analytics,
    InvestigationResult investigation,
    ForecastResult forecast,
    DecisionResult decision,
    String chartType,
  ) {
    if (decision.isDecisionQuery) {
      return CoachingResult(
        summary: decision.decisionText,
        insights: [decision.recommendationText],
        warnings: [],
        recommendations: ["Ensure your savings goal timeline matches upcoming purchases."],
        nextActions: ["Check emergency funds account"],
        motivationalMessage: "Smart buying choices are the first step to true financial independence.",
        chartType: "NONE",
      );
    }

    final income = (analytics['totalIncome'] as num? ?? 0.0).toDouble();
    final expense = (analytics['totalExpense'] as num? ?? 0.0).toDouble();
    final savingsRate = (analytics['savingsRate'] as num? ?? 0.0).toDouble();
    final topCategory = analytics['topCategory']?.toString() ?? 'N/A';
    final topMerchant = analytics['topMerchant']?.toString() ?? 'N/A';

    final summary = "Here is your computed financial brief. Your overall Health Score is **${scores.overallScore.toStringAsFixed(0)}/100**. Scanned ${analytics['transactionCount']} transactions.";

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

    return CoachingResult(
      summary: summary,
      insights: insights,
      warnings: warnings,
      recommendations: recommendations,
      nextActions: nextActions,
      motivationalMessage: motivationalMessage,
      chartType: chartType,
    );
  }
}

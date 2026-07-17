import 'financial_brain.dart';
import 'rule_planner.dart';

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

    final coachingResult = RulePlanner.generateResponse(context);
    
    // Merge chart selection
    final updatedCoaching = CoachingResult(
      summary: coachingResult.summary,
      insights: coachingResult.insights,
      warnings: coachingResult.warnings,
      recommendations: coachingResult.recommendations,
      nextActions: coachingResult.nextActions,
      motivationalMessage: coachingResult.motivationalMessage,
      chartType: chart,
      evidenceChecklist: coachingResult.evidenceChecklist,
      scopeDetails: coachingResult.scopeDetails,
      followUps: coachingResult.followUps,
    );

    return context.copyWith(coaching: updatedCoaching);
  }
}

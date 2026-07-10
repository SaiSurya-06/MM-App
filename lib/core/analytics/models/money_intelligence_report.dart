import 'money_snapshot.dart';
import 'spending_velocity.dart';
import 'budget_health.dart';
import 'monthly_forecast.dart';
import 'financial_risk.dart';
import 'purchase_decision.dart';
import 'goal_plan.dart';
import 'financial_insight.dart';
import 'money_story.dart';
import 'visualization_models.dart';

class ReportMetadata {
  final String reportVersion;
  final DateTime generatedAt;
  final int analysisDurationMs;
  final String snapshotId;

  const ReportMetadata({
    required this.reportVersion,
    required this.generatedAt,
    required this.analysisDurationMs,
    required this.snapshotId,
  });

  Map<String, dynamic> toJson() => {
        'reportVersion': reportVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'analysisDurationMs': analysisDurationMs,
        'snapshotId': snapshotId,
      };
}

class MoneyIntelligenceReport {
  final MoneySnapshot snapshot;
  final SpendingVelocity velocity;
  final BudgetHealth health;
  final MonthlyForecast forecast;
  final FinancialRisk risk;
  final PurchaseDecision purchase;
  final GoalPlan goals;
  final List<FinancialInsight> insights;
  final VisualizationModels visualizations;
  final MoneyStory story;
  final Map<String, dynamic> plugins;
  final ReportMetadata metadata;

  const MoneyIntelligenceReport({
    required this.snapshot,
    required this.velocity,
    required this.health,
    required this.forecast,
    required this.risk,
    required this.purchase,
    required this.goals,
    required this.insights,
    required this.visualizations,
    required this.story,
    required this.plugins,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'snapshot': snapshot.toJson(),
        'velocity': velocity.toJson(),
        'health': health.toJson(),
        'forecast': forecast.toJson(),
        'risk': risk.toJson(),
        'purchase': purchase.toJson(),
        'goals': goals.toJson(),
        'insights': insights.map((e) => e.toJson()).toList(),
        'visualizations': visualizations.toJson(),
        'story': story.toJson(),
        'plugins': plugins,
        'metadata': metadata.toJson(),
      };

  MoneyIntelligenceReport copyWith({
    MoneySnapshot? snapshot,
    SpendingVelocity? velocity,
    BudgetHealth? health,
    MonthlyForecast? forecast,
    FinancialRisk? risk,
    PurchaseDecision? purchase,
    GoalPlan? goals,
    List<FinancialInsight>? insights,
    VisualizationModels? visualizations,
    MoneyStory? story,
    Map<String, dynamic>? plugins,
    ReportMetadata? metadata,
  }) {
    return MoneyIntelligenceReport(
      snapshot: snapshot ?? this.snapshot,
      velocity: velocity ?? this.velocity,
      health: health ?? this.health,
      forecast: forecast ?? this.forecast,
      risk: risk ?? this.risk,
      purchase: purchase ?? this.purchase,
      goals: goals ?? this.goals,
      insights: insights ?? this.insights,
      visualizations: visualizations ?? this.visualizations,
      story: story ?? this.story,
      plugins: plugins ?? this.plugins,
      metadata: metadata ?? this.metadata,
    );
  }
}

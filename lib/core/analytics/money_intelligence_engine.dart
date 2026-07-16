import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'capability.dart';
import 'financial_snapshot.dart';
import 'explainable_value.dart';
import 'analyzers/income_analyzer.dart';
import 'analyzers/expense_analyzer.dart';
import 'analyzers/subscription_analyzer.dart';
import 'analyzers/stability_analyzer.dart';
import 'analyzers/budget_analyzer.dart';
import 'analyzers/health_calculator.dart';
import 'analyzers/risk_analyzer.dart';
import 'analyzers/spending_predictor.dart';
import 'analyzers/forecast_service.dart';
import 'analyzers/purchase_advisor.dart';
import 'analyzers/goal_planner.dart';
import 'analyzers/story_generator.dart';
import 'analyzers/recommendation_service.dart';
import 'analyzers/visualization_service.dart';
import 'models/money_snapshot.dart';
import 'models/spending_velocity.dart';
import 'models/budget_health.dart';
import 'models/monthly_forecast.dart';
import 'models/financial_risk.dart';
import 'models/purchase_decision.dart';
import 'models/goal_plan.dart';
import 'models/money_story.dart';
import 'models/visualization_models.dart';
import 'models/money_intelligence_report.dart';

class MoneyIntelligenceOrchestrator {
  static final MoneyIntelligenceOrchestrator instance = MoneyIntelligenceOrchestrator._internal();
  MoneyIntelligenceOrchestrator._internal();

  // Cached state
  MoneyIntelligenceReport? _cachedReport;
  String? _cachedSnapshotId;

  // Clear cache if needed (e.g. settings change)
  void invalidateCache() {
    _cachedReport = null;
    _cachedSnapshotId = null;
  }

  Future<MoneyIntelligenceReport> orchestrate(FinancialSnapshot snapshot, {double simulatedPurchaseAmount = 0.0}) async {
    final snapshotId = '${snapshot.snapshotId}_sim_$simulatedPurchaseAmount';

    // 1. Caching Check
    if (_cachedReport != null && _cachedSnapshotId == snapshotId) {
      debugPrint('[Orchestrator] Cache hit for snapshot ID: $snapshotId. Returning cached report.');
      return _cachedReport!;
    }

    debugPrint('[Orchestrator] Cache miss. Offloading staged analytics pipeline to Isolate.');

    final snapshotJson = snapshot.toFullJson();
    final args = {
      'snapshot': snapshotJson,
      'simulatedPurchaseAmount': simulatedPurchaseAmount,
    };

    final report = await compute(_runOrchestratorIsolate, args);

    // Cache results (on the main thread)
    _cachedReport = report;
    _cachedSnapshotId = snapshotId;

    return report;
  }

  // Runs the actual pipeline (safe to run inside Isolate)
  Future<MoneyIntelligenceReport> executePipeline(FinancialSnapshot snapshot, {double simulatedPurchaseAmount = 0.0}) async {
    final snapshotId = '${snapshot.snapshotId}_sim_$simulatedPurchaseAmount';
    debugPrint('[Orchestrator] Starting staged analytics pipeline for month: ${snapshot.selectedMonth}');
    final stopwatch = Stopwatch()..start();

    // 2. Initialize Context
    final context = OrchestratorContext(snapshot);
    context.simulatedPurchaseAmount = simulatedPurchaseAmount;

    // 3. Stage 1: Facts & Basic Analyzers
    try {
      context.incomeAnalysis = await IncomeAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in IncomeAnalyzer: $e');
      context.incomeAnalysis = const IncomeAnalysis(totalIncome: 0.0, incomeTransactions: [], incomeBySource: {});
    }

    try {
      context.expenseAnalysis = await ExpenseAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in ExpenseAnalyzer: $e');
      context.expenseAnalysis = const ExpenseAnalysis(totalExpense: 0.0, expenseTransactions: [], spendByFlowGroup: {}, spendByCategory: {});
    }

    try {
      context.stability = await StabilityAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in StabilityAnalyzer: $e');
      context.stability = const StabilityAnalysis(incomeType: 'Freelance', stabilityScore: 50.0, baseExpectedMonthlyIncome: 0.0, description: 'Error running stability analysis.');
    }

    try {
      context.subscription = await SubscriptionAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in SubscriptionAnalyzer: $e');
      context.subscription = const SubscriptionAnalysis(totalSubscriptionSpend: 0.0, activeSubscriptions: [], detectedLeaks: []);
    }

    try {
      await BudgetAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in BudgetAnalyzer: $e');
    }

    // 4. Stage 2: Predictions & Forecasts
    try {
      await SpendingPredictor().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in SpendingPredictor: $e');
      context.velocity = const SpendingVelocity(dailyBurnRate: 0.0, weeklyBurnRate: 0.0, expectedDailyPace: 2000.0, isAheadOfPace: false, paceDriftPercentage: 0.0, statusDescription: 'On Pace');
    }

    try {
      await ForecastService().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in ForecastService: $e');
      context.forecast = const MonthlyForecast(
        predictedMonthEndSpend: ExplainableValue(value: 0.0, reason: 'Error'),
        predictedMonthEndBalance: ExplainableValue(value: 0.0, reason: 'Error'),
        predictedIncomeTotal: ExplainableValue(value: 0.0, reason: 'Error'),
        cashFlowTrend: {},
        goalForecasts: {},
      );
    }

    try {
      context.health = await HealthCalculator().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in HealthCalculator: $e');
      context.health = const BudgetHealth(score: 70.0, rating: 'Good', positiveFactors: [], warningFactors: []);
    }

    try {
      context.risk = await RiskAnalyzer().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in RiskAnalyzer: $e');
      context.risk = const FinancialRisk(cashRunwayMonths: 12.0, debtToIncomeRatio: 0.0, overspendingProbability: 0.0, budgetCollapseProbability: 0.0, riskLevel: 'Low', riskFactors: []);
    }

    // 5. Stage 3 & 4: Decisions, Advisors & Insights
    try {
      await PurchaseAdvisor().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in PurchaseAdvisor: $e');
      context.purchase = const PurchaseDecision(purchaseAmount: 0.0, isApproved: true, postPurchaseEmergencyFund: 0.0, isSavingsGoalAffected: false, budgetRecoveryDays: 0, confidenceScore: 1.0, explanation: 'Error evaluating purchase.');
    }

    try {
      await GoalPlanner().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in GoalPlanner: $e');
      context.goals = const GoalPlan(allocations: [], recommendations: 'Error mapping goals.');
    }

    try {
      await RecommendationService().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in RecommendationService: $e');
    }

    try {
      await StoryGenerator().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in StoryGenerator: $e');
      context.story = const MoneyStory(dailyStory: '', weeklyStory: '', monthlyStory: '', yearlyStory: '');
    }

    // 6. Stage 5: Visualizations
    try {
      await VisualizationService().execute(context);
    } catch (e) {
      debugPrint('[Orchestrator] Error in VisualizationService: $e');
      context.visualizations = const VisualizationModels(forecastPoints: [], dailySpends: [], flowBars: [], timelineEvents: []);
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    debugPrint('[Orchestrator] Staged analytics completed in $elapsedMs ms.');

    // 7. Compile MoneySnapshot flow totals
    final double incomeTotalRaw = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double incomeTotal = incomeTotalRaw > 0.0 ? incomeTotalRaw : snapshot.estimatedIncome;

    final double essentials = context.expenseAnalysis?.spendByFlowGroup['Essentials'] ?? 0.0;
    final double lifestyle = context.expenseAnalysis?.spendByFlowGroup['Lifestyle'] ?? 0.0;
    final double savings = context.expenseAnalysis?.spendByFlowGroup['Savings'] ?? 0.0;
    final double investments = context.expenseAnalysis?.spendByFlowGroup['Investments'] ?? 0.0;
    final double debt = context.expenseAnalysis?.spendByFlowGroup['Debt'] ?? 0.0;
    final double taxes = context.expenseAnalysis?.spendByFlowGroup['Taxes'] ?? 0.0;
    final double transfers = context.expenseAnalysis?.spendByFlowGroup['Transfers'] ?? 0.0;
    final double others = context.expenseAnalysis?.spendByFlowGroup['Others'] ?? 0.0;
    final double expenseTotal = context.expenseAnalysis?.totalExpense ?? 0.0;
    final double remaining = incomeTotal - expenseTotal;

    final snapshotModel = MoneySnapshot(
      salary: incomeTotal,
      essentials: essentials,
      lifestyle: lifestyle,
      savings: savings,
      investments: investments,
      debt: debt,
      taxes: taxes,
      transfers: transfers,
      others: others,
      totalIncome: incomeTotal,
      totalExpense: expenseTotal,
      moneyLeft: remaining > 0 ? remaining : 0.0,
    );

    // 8. Construct Metadata
    final reportMetadata = ReportMetadata(
      reportVersion: '1.0.0',
      generatedAt: DateTime.now(),
      analysisDurationMs: elapsedMs,
      snapshotId: snapshotId,
    );

    // 9. Build final Report
    final report = MoneyIntelligenceReport(
      snapshot: snapshotModel,
      velocity: context.velocity!,
      health: context.health!,
      forecast: context.forecast!,
      risk: context.risk!,
      purchase: context.purchase!,
      goals: context.goals!,
      insights: context.insights,
      visualizations: context.visualizations!,
      story: context.story!,
      plugins: const {},
      metadata: reportMetadata,
    );

    return report;
  }
}

// Top-level function for background isolate execution
Future<MoneyIntelligenceReport> _runOrchestratorIsolate(Map<String, dynamic> args) async {
  final snapshotJson = args['snapshot'] as Map<String, dynamic>;
  final simulatedPurchaseAmount = (args['simulatedPurchaseAmount'] as num).toDouble();
  
  final snapshot = FinancialSnapshot.fromFullJson(snapshotJson);
  final orchestrator = MoneyIntelligenceOrchestrator.instance;
  return await orchestrator.executePipeline(snapshot, simulatedPurchaseAmount: simulatedPurchaseAmount);
}

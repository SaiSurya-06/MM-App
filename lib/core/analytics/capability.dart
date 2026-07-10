import 'financial_snapshot.dart';
import 'analyzers/income_analyzer.dart';
import 'analyzers/expense_analyzer.dart';
import 'analyzers/stability_analyzer.dart';
import 'analyzers/subscription_analyzer.dart';
import 'analyzers/budget_analyzer.dart';
import 'models/spending_velocity.dart';
import 'models/monthly_forecast.dart';
import 'models/budget_health.dart';
import 'models/financial_risk.dart';
import 'models/purchase_decision.dart';
import 'models/goal_plan.dart';
import 'models/financial_insight.dart';
import 'models/money_story.dart';
import 'models/visualization_models.dart';

class OrchestratorContext {
  final FinancialSnapshot snapshot;
  
  // Accumulated facts
  IncomeAnalysis? incomeAnalysis;
  ExpenseAnalysis? expenseAnalysis;
  StabilityAnalysis? stability;
  SubscriptionAnalysis? subscription;
  BudgetAnalysis? budget;
  double? budgetCompliance; // Budget analyzer output
  double? totalBudgetLimits; // Budget analyzer output
  
  // Accumulated domain models
  SpendingVelocity? velocity;
  MonthlyForecast? forecast;
  BudgetHealth? health;
  FinancialRisk? risk;
  PurchaseDecision? purchase;
  GoalPlan? goals;
  List<FinancialInsight> insights = [];
  MoneyStory? story;
  VisualizationModels? visualizations;
  
  double simulatedPurchaseAmount = 0.0;

  OrchestratorContext(this.snapshot);
}

abstract class Intent {
  final String type;
  const Intent(this.type);
}

class QueryIntent extends Intent {
  final String query;
  final Map<String, dynamic> parameters;
  const QueryIntent(this.query, {this.parameters = const {}}) : super('query');
}

abstract class Capability<TOutput> {
  String get id;
  String get version;
  String get name;
  List<Type> get dependencies;
  bool get isEnabled;

  Future<void> initialize();
  bool supports(Intent intent);
  Future<TOutput> execute(OrchestratorContext context);
}

abstract class Analyzer<TOutput> implements Capability<TOutput> {}
abstract class Predictor<TOutput> implements Capability<TOutput> {}
abstract class DecisionMaker<TOutput> implements Capability<TOutput> {}

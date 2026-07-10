import '../capability.dart';
import '../models/financial_insight.dart';
import 'rule_engine.dart';

class RecommendationService implements Capability<List<FinancialInsight>> {
  @override
  String get id => 'recommendation_service';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Recommendation Service';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  final RuleEngine _ruleEngine = RuleEngine();

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<List<FinancialInsight>> execute(OrchestratorContext context) async {
    // 1. Gather all deterministic insights from the RuleEngine
    final List<FinancialInsight> finalInsights = await _ruleEngine.execute(context);

    // 2. Add predictive insights based on Spending Velocity and Forecasts
    final velocity = context.velocity;
    final forecast = context.forecast;
    final double limits = context.totalBudgetLimits ?? 0.0;

    if (velocity != null && forecast != null) {
      if (velocity.isAheadOfPace && limits > 0) {
        final double projectedOver = forecast.predictedMonthEndSpend.value - limits;
        if (projectedOver > 0) {
          finalInsights.add(FinancialInsight(
            type: 'warning',
            priority: 'high',
            title: 'Drift Warning: Monthly Cap Risk',
            description: 'You are spending at a pace of ₹${velocity.dailyBurnRate.toStringAsFixed(0)}/day. '
                'At this rate, you will exceed your overall budget by ₹${projectedOver.toStringAsFixed(0)} at month end.',
            action: 'Slow down daily discretionary spending to ₹${velocity.expectedDailyPace.toStringAsFixed(0)}/day.',
            confidence: forecast.predictedMonthEndSpend.confidence,
            impactAmount: projectedOver,
          ));
        }
      }
    }

    // 3. Add emergency fund acceleration advice
    final goals = context.goals;
    if (goals != null) {
      for (var alloc in goals.allocations) {
        if (alloc.delayDays > 0 && alloc.name.toLowerCase().contains('emergency')) {
          finalInsights.add(FinancialInsight(
            type: 'action',
            priority: 'high',
            title: 'Accelerate Emergency Fund',
            description: 'Your Emergency Fund goal is delayed by ${alloc.delayDays} days due to lower savings rates.',
            action: 'Allocate ₹${alloc.accelerationPotential.toStringAsFixed(0)} from Lifestyle wants to hit this target sooner.',
            confidence: 0.90,
            impactAmount: alloc.accelerationPotential,
          ));
        }
      }
    }

    // Save in context
    context.insights = finalInsights;
    return finalInsights;
  }
}

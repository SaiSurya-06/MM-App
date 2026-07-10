import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/agent/execution_plan.dart';
import 'package:money_manager/core/agent/retriever.dart';
import 'package:money_manager/core/agent/metrics_engine.dart';
import 'package:money_manager/core/agent/score_engine.dart';
import 'package:money_manager/core/agent/prediction_engine.dart';
import 'package:money_manager/core/agent/financial_brain.dart';
import 'package:money_manager/core/agent/insight_engine.dart';
import 'package:money_manager/core/agent/scenario_engine.dart';

void main() {
  group('ExecutionPlan Rich Schema Tests', () {
    test('Serialization and Deserialization matches correctly', () {
      final plan = ExecutionPlan(
        intent: 'compare',
        responseType: 'comparison',
        merchant: 'Swiggy',
        category: 'Food',
        minAmount: 100.0,
        maxAmount: 1000.0,
        targetMonth: 6,
        targetYear: 2026,
        comparisonMonth: 5,
        comparisonYear: 2026,
        paymentMethod: 'upi',
        timeFilter: 'weekend',
        targetType: 'expense',
        requiredTools: ['transaction', 'budget'],
        requiredStrategies: ['comparison'],
        needsForecast: true,
        needsDecision: false,
        needsCoaching: true,
        confidence: 0.95,
      );

      final json = plan.toJson();
      final decoded = ExecutionPlan.fromJson(json);

      expect(decoded.intent, equals('compare'));
      expect(decoded.responseType, equals('comparison'));
      expect(decoded.merchant, equals('Swiggy'));
      expect(decoded.category, equals('Food'));
      expect(decoded.requiredTools, contains('transaction'));
      expect(decoded.requiredTools, contains('budget'));
      expect(decoded.requiredStrategies, contains('comparison'));
      expect(decoded.needsForecast, isTrue);
      expect(decoded.needsCoaching, isTrue);
      expect(decoded.confidence, equals(0.95));
    });
  });

  group('ConversationMemory Levels Tests', () {
    test('Memory correctly merges targetMonth and merchant for relative follow-up queries', () {
      final memory = ConversationMemory();

      final firstPlan = ExecutionPlan(
        intent: 'search',
        responseType: 'financial_review',
        merchant: 'Swiggy',
        targetMonth: 5,
        targetYear: 2026,
        requiredTools: ['transaction'],
        requiredStrategies: [],
        needsForecast: false,
        needsDecision: false,
        needsCoaching: false,
        confidence: 1.0,
      );

      final mergedFirst = memory.mergeNewPlan(firstPlan);
      expect(mergedFirst.merchant, equals('Swiggy'));
      expect(mergedFirst.targetMonth, equals(5));

      final followUpPlan = ExecutionPlan(
        intent: 'search',
        responseType: 'financial_review',
        targetMonth: 6,
        requiredTools: [],
        requiredStrategies: [],
        needsForecast: false,
        needsDecision: false,
        needsCoaching: false,
        confidence: 1.0,
      );

      final mergedSecond = memory.mergeNewPlan(followUpPlan);
      expect(mergedSecond.merchant, equals('Swiggy'));
      expect(mergedSecond.targetMonth, equals(6));
    });
  });

  group('Financial Score Engine Tests', () {
    test('Scores calculate savings, spending, and health overall out of 100', () async {
      final plan = ExecutionPlan.empty();
      final data = RetrievedData(
        transactions: [
          {'title': 'Salary', 'amount': 10000.0, 'type': 'income', 'date': '2026-07-05', 'category': 'Salary'},
          {'title': 'Swiggy', 'amount': 2000.0, 'type': 'expense', 'date': '2026-07-06', 'category': 'Food', 'category_id': 2},
          {'title': 'Rent', 'amount': 4000.0, 'type': 'expense', 'date': '2026-07-10', 'category': 'Rent', 'category_id': 1},
        ],
        budgets: [
          {'limit_amount': 5000.0, 'name': 'Rent', 'category_id': 1},
          {'limit_amount': 3000.0, 'name': 'Food', 'category_id': 2},
        ],
        goals: [],
        balances: [],
        netWorth: 12000.0,
      );

      final initialContext = FinancialContext.initial("compute scores", plan, data);

      final orchestrator = AgentOrchestrator(
        engines: [
          MetricsEngine(),
          InsightEngine(),
          ScoreEngine(),
        ],
      );

      final finalContext = await orchestrator.orchestrate(initialContext);
      
      expect(finalContext.metrics['totalIncome'], equals(10000.0));
      expect(finalContext.metrics['totalExpense'], equals(6000.0));
      expect(finalContext.metrics['savingsRate'], equals(40.0));
      expect(finalContext.scores.savingsScore, equals(100.0));
      expect(finalContext.scores.overallScore, isNotNull);
    });
  });

  group('Investigation and Forecasting Engine Tests', () {
    test('PredictionEngine projects budget depletion and goal acceleration correctly', () async {
      final plan = ExecutionPlan(
        intent: 'forecast',
        responseType: 'goal_progress',
        requiredTools: ['transaction', 'budget', 'goal'],
        requiredStrategies: [],
        needsForecast: true,
        needsDecision: false,
        needsCoaching: true,
        confidence: 1.0,
      );

      final data = RetrievedData(
        transactions: [
          {'title': 'Salary', 'amount': 10000.0, 'type': 'income', 'date': '2026-07-05', 'category': 'Salary'},
          {'title': 'Swiggy', 'amount': 4500.0, 'type': 'expense', 'date': '2026-07-06', 'category': 'Food', 'category_id': 1},
        ],
        budgets: [
          {'limit_amount': 4000.0, 'name': 'Food', 'category_id': 1},
        ],
        goals: [
          {'name': 'Trip', 'target_amount': 50000.0, 'current_amount': 10000.0},
        ],
        balances: [],
        netWorth: 10000.0,
      );

      final initialContext = FinancialContext.initial("predict futures", plan, data);

      final orchestrator = AgentOrchestrator(
        engines: [
          MetricsEngine(),
          InsightEngine(),
          ScoreEngine(),
          PredictionEngine(),
        ],
      );

      final finalContext = await orchestrator.orchestrate(initialContext);

      expect(finalContext.forecast.burnRateAlerts, isNotEmpty);
      expect(finalContext.forecast.burnRateAlerts.first, contains('Food'));
      expect(finalContext.forecast.goalAccelerationTips, isNotEmpty);
      expect(finalContext.forecast.goalAccelerationTips.first, contains('Trip'));
    });
  });

  group('Scenario Simulator Engine Tests', () {
    test('ScenarioEngine runs what-if simulations for food cutting correctly', () async {
      final plan = ExecutionPlan(
        intent: 'forecast',
        responseType: 'financial_review',
        requiredTools: [],
        requiredStrategies: [],
        needsForecast: true,
        needsDecision: false,
        needsCoaching: true,
        confidence: 1.0,
      );

      final data = RetrievedData(
        transactions: [],
        budgets: [],
        goals: [],
        balances: [],
        netWorth: 10000.0,
      );

      final initialContext = FinancialContext.initial("What if I stop ordering food?", plan, data).copyWith(
        metrics: {
          'categoryShares': {'Food': 4000.0},
          'totalIncome': 50000.0,
        },
      );

      final engine = ScenarioEngine();
      final finalContext = await engine.execute(initialContext);

      expect(finalContext.scenario.isScenarioQuery, isTrue);
      expect(finalContext.scenario.scenarioSummary, contains('Food Delivery'));
      expect(finalContext.scenario.projections.length, equals(3));
      expect(finalContext.scenario.projections[0], contains('+₹12000'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/agent/execution_plan.dart';
import 'package:money_manager/core/agent/retriever.dart';
import 'package:money_manager/core/agent/financial_brain.dart';
import 'package:money_manager/core/agent/metrics_engine.dart';
import 'package:money_manager/core/agent/insight_engine.dart';
import 'package:money_manager/core/agent/score_engine.dart';
import 'package:money_manager/core/agent/decision_engine.dart';
import 'package:money_manager/core/agent/evaluation_engine.dart';

void main() {
  group('Enterprise Agent Platform Orchestration Tests', () {
    test('Orchestrator executes metrics, insights, score, decision, and evaluation engines', () async {
      final plan = ExecutionPlan(
        intent: 'decision',
        merchant: null,
        category: null,
        minAmount: 50000.0,
        maxAmount: null,
        targetMonth: 7,
        targetYear: 2026,
        comparisonMonth: null,
        comparisonYear: null,
        paymentMethod: null,
        timeFilter: null,
        targetType: null,
        requiredTools: ['transaction', 'budget', 'goal', 'account'],
        requiredStrategies: [],
        needsForecast: false,
        needsDecision: true,
        needsCoaching: true,
        confidence: 0.95,
      );

      final data = RetrievedData(
        transactions: [
          {'title': 'Salary', 'amount': 100000.0, 'type': 'income', 'date': '2026-07-05', 'category': 'Salary'},
          {'title': 'Rent', 'amount': 15000.0, 'type': 'expense', 'date': '2026-07-06', 'category': 'Rent', 'category_id': 1},
          {'title': 'Groceries', 'amount': 5000.0, 'type': 'expense', 'date': '2026-07-07', 'category': 'Food', 'category_id': 2},
        ],
        budgets: [
          {'limit_amount': 20000.0, 'name': 'Rent', 'category_id': 1},
        ],
        goals: [],
        balances: [],
        netWorth: 80000.0, // Let's check decision threshold
      );

      final initialContext = FinancialContext.initial("Can I buy a 50000 laptop?", plan, data);

      final orchestrator = AgentOrchestrator(
        engines: [
          MetricsEngine(),
          InsightEngine(),
          ScoreEngine(),
          DecisionEngine(),
          EvaluationEngine(),
        ],
      );

      final finalContext = await orchestrator.orchestrate(initialContext);

      // Verify Metrics Engine output
      expect(finalContext.metrics['totalIncome'], equals(100000.0));
      expect(finalContext.metrics['totalExpense'], equals(20000.0));
      expect(finalContext.metrics['transactionCount'], equals(3));

      // Verify Insight Engine output
      expect(finalContext.insights, isNotEmpty);
      expect(finalContext.metrics['savingsRate'], equals(80.0));

      // Verify Score Engine output
      expect(finalContext.scores.overallScore, isNotNull);

      // Verify Decision Engine output
      expect(finalContext.decision.isDecisionQuery, isTrue);
      expect(finalContext.decision.purchaseAmount, equals(50000.0));
      expect(finalContext.decision.decisionText, isNotEmpty);

      // Verify Evaluation Engine output
      expect(finalContext.evaluation.dataCoveragePercentage, equals(100.0)); // All categorized
      expect(finalContext.evaluation.needsClarification, isFalse);

      // Verify Observability log records
      expect(finalContext.observabilityLogs['MetricsEngine'], isNotNull);
      expect(finalContext.observabilityLogs['TotalOrchestrationTime'], isNotNull);
    });
  });
}

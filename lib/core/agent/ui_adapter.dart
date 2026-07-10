import 'financial_brain.dart';

enum UiComponentType {
  healthScore,
  summary,
  insights,
  warnings,
  recommendations,
  nextActions,
  chart,
  motivationalMessage,
  
  // Specialized Adaptive Cards
  largestTransactionCard,
  comparisonTableCard,
  budgetProgressCard,
  goalProgressCard,
  decisionCard,

  // Reasoning traces & Conversation explorers
  evidenceCard,
  scopeCard,
  followUps,
}

class UiComponent {
  final UiComponentType type;
  final Map<String, dynamic> data;

  UiComponent({required this.type, required this.data});
}

class UIAdapter {
  static List<UiComponent> adapt(FinancialContext context) {
    final coaching = context.coaching;
    final scores = context.scores;
    final plan = context.plan;
    final metrics = context.metrics;
    final data = context.rawData;
    final decision = context.decision;

    final List<UiComponent> components = [];

    // 1. Always append tiny scope card at the very top to frame the metrics scope
    if (coaching.scopeDetails.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.scopeCard,
        data: {
          'transactions': coaching.scopeDetails['transactionsScanned'] ?? data.transactions.length,
          'accounts': coaching.scopeDetails['accountsChecked'] ?? 3,
          'dateRange': coaching.scopeDetails['dateRange'] ?? "${data.activeMonth ?? 3}/${data.activeYear ?? 2026}",
          'confidence': plan.confidence,
        },
      ));
    }

    // 2. Add verification evidence tracing checklist
    if (coaching.evidenceChecklist.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.evidenceCard,
        data: {'checklist': coaching.evidenceChecklist},
      ));
    }

    switch (plan.responseType) {
      case 'largest_transaction':
        final largest = metrics['largestTransaction'] as Map<String, dynamic>?;
        if (largest != null) {
          final totalSpent = (metrics['totalExpense'] as num? ?? 1.0).toDouble();
          final amt = (largest['amount'] as num? ?? 0.0).toDouble();
          final pct = totalSpent > 0 ? (amt / totalSpent * 100) : 0.0;
          components.add(UiComponent(
            type: UiComponentType.largestTransactionCard,
            data: {
              'title': largest['title'] ?? 'Purchase',
              'amount': amt,
              'date': largest['date'] ?? '',
              'category': largest['category'] ?? 'Other',
              'pctOfMonthly': pct,
            },
          ));
        }
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        if (coaching.insights.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.insights,
            data: {'list': coaching.insights},
          ));
        }
        break;

      case 'comparison':
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        components.add(UiComponent(
          type: UiComponentType.comparisonTableCard,
          data: {
            'absoluteIncrease': context.investigation.absoluteIncrease,
            'percentageIncrease': context.investigation.percentageIncrease,
            'causes': context.investigation.spendingCauses,
          },
        ));
        if (coaching.chartType != 'NONE') {
          components.add(UiComponent(
            type: UiComponentType.chart,
            data: {'chartType': coaching.chartType},
          ));
        }
        if (coaching.warnings.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.warnings,
            data: {'list': coaching.warnings},
          ));
        }
        if (coaching.recommendations.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.recommendations,
            data: {'list': coaching.recommendations},
          ));
        }
        break;

      case 'budget_status':
        final List<Map<String, dynamic>> budgetList = [];
        final Map<int, double> limits = {};
        for (var b in data.budgets) {
          final catId = b['category_id'] as int;
          limits[catId] = (b['limit_amount'] as num).toDouble();
        }
        final Map<int, double> spends = {};
        for (var tx in data.transactions) {
          if (tx['type'] == 'expense' && tx['category_id'] != null) {
            final catId = tx['category_id'] as int;
            spends[catId] = (spends[catId] ?? 0.0) + (tx['amount'] as num).toDouble();
          }
        }
        for (var b in data.budgets) {
          final catId = b['category_id'] as int;
          final limit = limits[catId] ?? 0.0;
          final spent = spends[catId] ?? 0.0;
          budgetList.add({
            'name': b['name'] ?? 'Other',
            'limit': limit,
            'spent': spent,
            'percent': limit > 0 ? (spent / limit) : 0.0,
          });
        }
        components.add(UiComponent(
          type: UiComponentType.budgetProgressCard,
          data: {'budgets': budgetList},
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        if (coaching.warnings.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.warnings,
            data: {'list': coaching.warnings},
          ));
        }
        if (coaching.nextActions.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.nextActions,
            data: {'list': coaching.nextActions},
          ));
        }
        break;

      case 'goal_progress':
        final List<Map<String, dynamic>> goalList = [];
        for (var g in data.goals) {
          final target = (g['target_amount'] as num? ?? 1.0).toDouble();
          final current = (g['current_amount'] as num? ?? 0.0).toDouble();
          goalList.add({
            'name': g['name'] ?? 'Goal',
            'target': target,
            'current': current,
            'percent': target > 0 ? (current / target) : 0.0,
          });
        }
        components.add(UiComponent(
          type: UiComponentType.goalProgressCard,
          data: {'goals': goalList},
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        if (coaching.recommendations.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.recommendations,
            data: {'list': coaching.recommendations},
          ));
        }
        break;

      case 'affordability':
        components.add(UiComponent(
          type: UiComponentType.decisionCard,
          data: {
            'isAffordable': decision.decisionText.toLowerCase().contains("comfortable") || decision.decisionText.toLowerCase().contains("comfortably"),
            'price': decision.purchaseAmount,
            'decisionText': decision.decisionText,
            'recommendationText': decision.recommendationText,
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        if (coaching.recommendations.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.recommendations,
            data: {'list': coaching.recommendations},
          ));
        }
        break;

      case 'financial_review':
      default:
        // What-if simulated state result highlights
        if (context.scenario.isScenarioQuery) {
          components.add(UiComponent(
            type: UiComponentType.largestTransactionCard, // reuse structured card styles for what-if outcomes
            data: {
              'title': "Simulated Savings Rate: ${(context.forecast.projectedSavingsRate + 15).toStringAsFixed(0)}%",
              'amount': 0.0,
              'date': "12 months forecast",
              'category': "Scenario Analysis",
              'pctOfMonthly': 0.0,
            },
          ));
          components.add(UiComponent(
            type: UiComponentType.summary,
            data: {'text': "${context.scenario.scenarioSummary}\n\n${context.scenario.projections.join('\n')}\n\n${context.scenario.advice}"},
          ));
          break;
        }

        components.add(UiComponent(
          type: UiComponentType.healthScore,
          data: {
            'overallScore': scores.overallScore,
            'savingsScore': scores.savingsScore,
            'budgetScore': scores.budgetScore,
            'emergencyScore': scores.emergencyScore,
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        if (coaching.chartType != 'NONE') {
          components.add(UiComponent(
            type: UiComponentType.chart,
            data: {'chartType': coaching.chartType},
          ));
        }
        if (coaching.insights.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.insights,
            data: {'list': coaching.insights},
          ));
        }
        if (coaching.warnings.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.warnings,
            data: {'list': coaching.warnings},
          ));
        }
        if (coaching.nextActions.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.nextActions,
            data: {'list': coaching.nextActions},
          ));
        }
        if (coaching.motivationalMessage.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.motivationalMessage,
            data: {'text': coaching.motivationalMessage},
          ));
        }
        break;
    }

    // 3. Append dynamic follow-ups if they exist
    if (coaching.followUps.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.followUps,
        data: {'list': coaching.followUps},
      ));
    }

    return components;
  }
}

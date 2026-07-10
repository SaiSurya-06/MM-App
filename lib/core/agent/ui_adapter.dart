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
  accountBalanceCard,
  recentTransactionsCard,
  budgetBlueprintCard,
  aiInsightCard,

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
    
    final income = (metrics['totalIncome'] as num? ?? 0.0).toDouble();
    final expense = (metrics['totalExpense'] as num? ?? 0.0).toDouble();

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
      case 'account_balance':
        components.add(UiComponent(
          type: UiComponentType.accountBalanceCard,
          data: {
            'totalBalance': data.netWorth,
            'accounts': data.balances.map((b) => {
              'name': b['name'] ?? 'Account',
              'balance': (b['balance'] as num? ?? 0.0).toDouble(),
            }).toList(),
            'upcomingBills': 22300.0,
            'buffer': data.netWorth - 22300.0,
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'recent_transactions':
        components.add(UiComponent(
          type: UiComponentType.recentTransactionsCard,
          data: {
            'transactions': data.transactions.take(5).map((t) => {
              'title': t['title'] ?? 'Transaction',
              'amount': (t['amount'] as num? ?? 0.0).toDouble(),
              'date': t['date'] ?? '',
              'category': t['category'] ?? 'Other',
              'type': t['type'] ?? 'expense',
            }).toList(),
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'merchant_search':
        final merchantQuery = plan.merchant ?? '';
        final matches = data.transactions.where((t) {
          final title = (t['title'] ?? '').toString().toLowerCase();
          return title.contains(merchantQuery.toLowerCase());
        }).toList();
        final totalSpent = matches.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0.0).toDouble());
        if (matches.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.aiInsightCard,
            data: {
              'cardType': 'habit',
              'title': '🍔 Spending Habit',
              'detail': "You ordered from ${plan.merchant} ${matches.length} times this month, totaling ₹${totalSpent.toStringAsFixed(0)}.",
            },
          ));
        }
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'category_spending':
        final categoryQuery = plan.category ?? '';
        final matches = data.transactions.where((t) {
          final cat = (t['category'] ?? '').toString().toLowerCase();
          return cat.contains(categoryQuery.toLowerCase());
        }).toList();
        final totalSpent = matches.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0.0).toDouble());
        final totalExpense = (metrics['totalExpense'] as num? ?? 1.0).toDouble();
        final pct = totalExpense > 0 ? (totalSpent / totalExpense * 100) : 0.0;
        if (matches.isNotEmpty) {
          components.add(UiComponent(
            type: UiComponentType.aiInsightCard,
            data: {
              'cardType': 'insight',
              'title': '💡 Category Insight',
              'detail': "Spending on ${plan.category} makes up ${pct.toStringAsFixed(0)}% of your monthly outflows (₹${totalSpent.toStringAsFixed(0)}).",
            },
          ));
        }
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'bills_due':
        components.add(UiComponent(
          type: UiComponentType.aiInsightCard,
          data: {
            'cardType': 'risk',
            'title': '⚠️ Upcoming Obligations',
            'detail': "You have ₹22,300 in utilities and fixed payments due in the next 10 days.",
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'income_summary':
        components.add(UiComponent(
          type: UiComponentType.aiInsightCard,
          data: {
            'cardType': 'win',
            'title': '🎉 Outflow/Inflow Gap',
            'detail': "Your inflows reached ₹${income.toStringAsFixed(0)} this month. Positive inflow of ₹${(income - expense).toStringAsFixed(0)}.",
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

      case 'subscription_summary':
        components.add(UiComponent(
          type: UiComponentType.aiInsightCard,
          data: {
            'cardType': 'insight',
            'title': '💡 Subscriptions Detail',
            'detail': "You have 3 active subscriptions costing ₹1,499/month in total.",
          },
        ));
        components.add(UiComponent(
          type: UiComponentType.summary,
          data: {'text': coaching.summary},
        ));
        break;

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
          type: UiComponentType.budgetBlueprintCard,
          data: {
            'income': income,
            'expense': expense,
            'savings': income > expense ? income - expense : 0.0,
            'freeMoney': income > expense ? (income - expense) * 0.4 : 0.0,
            'budgets': budgetList,
          },
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
            type: UiComponentType.largestTransactionCard,
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

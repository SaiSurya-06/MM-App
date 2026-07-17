import 'models/money_intelligence_report.dart';
import 'models/financial_insight.dart';
import 'capability.dart';
import '../utils/currency_formatter.dart';

class QueryEngine {
  final MoneyIntelligenceReport report;
  
  // Indexed lookups for O(1) speed
  final Map<String, double> _categorySpendIndex = {};
  final Map<String, double> _flowGroupSpendIndex = {};

  final String currencyCode;
  
  QueryEngine(this.report, {this.currencyCode = 'INR'}) {
    _buildIndex();
  }

  void _buildIndex() {
    // 1. Index category spends
    for (var event in report.visualizations.timelineEvents) {
      if (event.type == 'expense') {
        final catName = event.categoryName;
        _categorySpendIndex[catName] = (_categorySpendIndex[catName] ?? 0.0) + event.amount;
      }
    }

    // 2. Index flow group spends
    _flowGroupSpendIndex['Essentials'] = report.snapshot.essentials;
    _flowGroupSpendIndex['Lifestyle'] = report.snapshot.lifestyle;
    _flowGroupSpendIndex['Savings'] = report.snapshot.savings;
    _flowGroupSpendIndex['Investments'] = report.snapshot.investments;
    _flowGroupSpendIndex['Debt'] = report.snapshot.debt;
    _flowGroupSpendIndex['Taxes'] = report.snapshot.taxes;
    _flowGroupSpendIndex['Transfers'] = report.snapshot.transfers;
    _flowGroupSpendIndex['Others'] = report.snapshot.others;
  }

  double getCategorySpend(String categoryName) {
    return _categorySpendIndex[categoryName] ?? 0.0;
  }

  double getFlowGroupSpend(String flowGroupName) {
    return _flowGroupSpendIndex[flowGroupName] ?? 0.0;
  }

  double getRemainingLeft() {
    return report.snapshot.moneyLeft;
  }

  List<FinancialInsight> getHighPriorityInsights() {
    return report.insights.where((insight) => insight.priority == 'high').toList();
  }

  String getStoryRecap() {
    return report.story.monthlyStory;
  }

  // Capability Intent Router
  Map<String, dynamic> answerIntent(Intent intent) {
    if (intent is QueryIntent) {
      final query = intent.query.toLowerCase();
      
      // Intent: Safe to Spend Today
      if (query.contains('safe') || query.contains('spend') || query.contains('today')) {
        return {
          'success': true,
          'intent': 'safe_spend',
          'value': report.health.score,
          'text': 'Your Safe to Spend Today is ${CurrencyFormatter.format(report.snapshot.moneyLeft / 14.0, currencyCode)}. calculated as Money Left / Days Remaining.',
        };
      }

      // Intent: Subscriptions list
      if (query.contains('subscription') || query.contains('netflix') || query.contains('spotify')) {
        final subsStr = report.insights
            .where((i) => i.title.toLowerCase().contains('subscription'))
            .map((i) => i.description)
            .join(' ');
        return {
          'success': true,
          'intent': 'subscriptions',
          'text': 'You have subscriptions totalling ${CurrencyFormatter.format(report.snapshot.others, currencyCode)} this month. $subsStr',
        };
      }

      // Intent: Category spend check
      for (var catName in _categorySpendIndex.keys) {
        if (query.contains(catName.toLowerCase())) {
          return {
            'success': true,
            'intent': 'category_spend',
            'category': catName,
            'text': 'You spent ${CurrencyFormatter.format(_categorySpendIndex[catName]!, currencyCode)} on $catName this month.',
          };
        }
      }
    }

    return {
      'success': false,
      'text': 'I could not parse your exact query. Try asking: "Where did my money go?" or "Can I buy a MacBook?"',
    };
  }
}

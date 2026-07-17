import '../capability.dart';
import '../models/financial_insight.dart';
import '../../utils/currency_formatter.dart';

class RuleEngine implements Capability<List<FinancialInsight>> {
  @override
  String get id => 'rule_engine';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Rule Engine';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<List<FinancialInsight>> execute(OrchestratorContext context) async {
    final List<FinancialInsight> ruleInsights = [];

    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double expense = context.expenseAnalysis?.totalExpense ?? 0.0;

    // Rule 1: Emergency runway check
    final risk = context.risk;
    if (risk != null) {
      if (risk.cashRunwayMonths < 1.0) {
        ruleInsights.add(const FinancialInsight(
          type: 'alert',
          priority: 'high',
          title: 'Emergency Fund Critical',
          description: 'Your cash reserves cover less than 1 month of expenses. An unexpected expense could cause debt collapse.',
          action: 'Create a dedicated Emergency savings goal and save 10% of income.',
          confidence: 0.98,
        ));
      } else if (risk.cashRunwayMonths < 3.0) {
        ruleInsights.add(FinancialInsight(
          type: 'warning',
          priority: 'medium',
          title: 'Low Cash Runway',
          description: 'Your cash reserves cover ${risk.cashRunwayMonths.toStringAsFixed(1)} months of spending. 3-6 months is recommended.',
          action: 'Increase your monthly savings allocation to build cash buffers.',
          confidence: 0.90,
        ));
      }
    }

    // Rule 2: Savings rate threshold check
    if (income > 0) {
      final rate = (income - expense) / income * 100.0;
      if (rate < 10.0) {
        ruleInsights.add(FinancialInsight(
          type: 'warning',
          priority: 'high',
          title: 'Savings Deficit',
          description: 'Your net savings rate is ${(rate).toStringAsFixed(0)}% this month. The target is at least 15%.',
          action: 'Audit your Lifestyle (Wants) categories for immediate cuts.',
          confidence: 0.95,
          impactAmount: income * 0.15 - (income - expense),
        ));
      }
    }

    // Rule 3: Debt repay DTI check
    if (risk != null && risk.debtToIncomeRatio > 0.40) {
      ruleInsights.add(FinancialInsight(
        type: 'alert',
        priority: 'high',
        title: 'Dangerous Debt Ratio',
        description: 'Monthly debt repayments consume ${(risk.debtToIncomeRatio * 100).toStringAsFixed(0)}% of your income. The safe threshold is <30%.',
        action: 'Avoid taking new credit, prioritize paying off high-interest loans.',
        confidence: 0.96,
      ));
    }

    // Rule 4: Subscription leak check
    final subscription = context.subscription;
    if (subscription != null && subscription.detectedLeaks.isNotEmpty) {
      ruleInsights.add(FinancialInsight(
        type: 'tip',
        priority: 'medium',
        title: 'Subscription Leaks Detected',
        description: '${subscription.detectedLeaks.length} unused or expensive subscriptions are draining cash.',
        action: 'Review and cancel active subscriptions under the details list.',
        confidence: 0.95,
        impactAmount: subscription.totalSubscriptionSpend,
      ));
    }

    // Rule 5: Budget overspent check
    final budgetAnalysis = context.budget;
    if (budgetAnalysis != null) {
      for (var status in budgetAnalysis.categoryStatuses) {
        if (status.isOverspent) {
          ruleInsights.add(FinancialInsight(
            type: 'alert',
            priority: 'medium',
            title: 'Budget Overrun: ${status.categoryName}',
            description: 'You exceeded your budget limit for ${status.categoryName} by ${CurrencyFormatter.format(status.spent - status.limit, context.currencyCode)}.',
            action: 'Shift cash from Lifestyle to cover this category deficit.',
            confidence: 0.98,
            categoryName: status.categoryName,
            impactAmount: status.spent - status.limit,
          ));
        }
      }
    }

    return ruleInsights;
  }
}

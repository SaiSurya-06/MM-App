import '../capability.dart';
import '../models/financial_risk.dart';

class RiskAnalyzer implements Capability<FinancialRisk> {
  @override
  String get id => 'risk_analyzer';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Risk Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<FinancialRisk> execute(OrchestratorContext context) async {
    final incomeAnalysis = context.incomeAnalysis;
    final expenseAnalysis = context.expenseAnalysis;

    final double monthlyIncome = incomeAnalysis?.totalIncome ?? 0.0;
    final double monthlyExpense = expenseAnalysis?.totalExpense ?? 0.0;

    // 1. Calculate Total Balance (excluding Credit Card debt)
    final double totalBalance = context.snapshot.accounts
        .where((acc) => acc.type != 'Credit Card')
        .fold(0.0, (sum, acc) => sum + acc.balance);

    // 2. Cash Runway (in months)
    final double runway = monthlyExpense > 0 ? totalBalance / monthlyExpense : 12.0;

    // 3. DTI
    final double debtPayments = context.snapshot.debts.fold(0.0, (sum, d) => sum + d.monthlyPayment);
    final double dti = monthlyIncome > 0 ? debtPayments / monthlyIncome : (debtPayments > 0 ? 1.0 : 0.0);

    // 4. Overspending Probability (using budget limits vs actuals)
    final double limits = context.totalBudgetLimits ?? 0.0;
    double overspendProb = 0.0;
    if (limits > 0) {
      if (monthlyExpense > limits) {
        overspendProb = 1.0;
      } else {
        // Extrapolate daily burn rate to month end
        final now = context.snapshot.selectedDate;
        final totalDays = DateTime(now.year, now.month + 1, 0).day;
        final elapsedDays = now.day > 0 ? now.day : 1;
        final projected = (monthlyExpense / elapsedDays) * totalDays;
        
        if (projected > limits) {
          overspendProb = ((projected - limits) / limits * 2.0).clamp(0.1, 0.95);
        } else {
          overspendProb = (projected / limits * 0.1).clamp(0.0, 0.3);
        }
      }
    }

    // 5. Budget Collapse Probability (exhausting cash)
    double collapseProb = 0.0;
    if (totalBalance <= 0) {
      collapseProb = 1.0;
    } else {
      // Remaining budget to spend vs cash on hand
      final double remainingBudget = limits > monthlyExpense ? limits - monthlyExpense : 0.0;
      if (remainingBudget > totalBalance) {
        collapseProb = ((remainingBudget - totalBalance) / totalBalance).clamp(0.2, 0.95);
      }
    }

    // Risk factors & level
    final List<String> factors = [];
    String level = 'Low';

    if (runway < 1.0) {
      factors.add('Runway: Emergency reserves cover less than 1 month of spending.');
      level = 'High';
    } else if (runway < 3.0) {
      factors.add('Runway: Low emergency reserves (covers ${runway.toStringAsFixed(1)} months).');
      if (level != 'High') level = 'Medium';
    }

    if (dti > 0.40) {
      factors.add('Debt: Debt obligations consume over 40% of income.');
      level = 'High';
    } else if (dti > 0.20) {
      factors.add('Debt: Moderate debt obligations (${(dti * 100).toStringAsFixed(0)}% of income).');
      if (level != 'High') level = 'Medium';
    }

    if (overspendProb > 0.8) {
      factors.add('Budget: Extremely high probability of overspending budget limits.');
      level = 'High';
    }

    if (collapseProb > 0.7) {
      factors.add('Cash Flow: High risk of running out of money before month end.');
      level = 'High';
    }

    if (factors.isEmpty) {
      factors.add('No major financial risk indicators detected.');
    }

    final reason = 'Financial risk is evaluated as $level. '
        'Your cash runway is ${runway.toStringAsFixed(1)} months, '
        'and Debt-To-Income ratio is ${(dti * 100).toStringAsFixed(0)}%.';

    return FinancialRisk(
      cashRunwayMonths: runway,
      debtToIncomeRatio: dti,
      overspendingProbability: overspendProb,
      budgetCollapseProbability: collapseProb,
      riskLevel: level,
      riskFactors: factors,
      reason: reason,
    );
  }
}

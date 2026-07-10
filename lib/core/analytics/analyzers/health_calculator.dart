import '../capability.dart';
import '../models/budget_health.dart';

class HealthCalculator implements Capability<BudgetHealth> {
  @override
  String get id => 'health_calculator';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Health Calculator';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<BudgetHealth> execute(OrchestratorContext context) async {
    final incomeAnalysis = context.incomeAnalysis;
    final expenseAnalysis = context.expenseAnalysis;
    final budgetCompliance = context.budgetCompliance ?? 100.0;
    final stability = context.stability;
    final subscription = context.subscription;

    final double monthlyIncome = incomeAnalysis?.totalIncome ?? 0.0;
    final double monthlyExpense = expenseAnalysis?.totalExpense ?? 0.0;

    // 1. Savings Rate Score (30%)
    double savingsRateScore = 0.0;
    double savingsRate = 0.0;
    if (monthlyIncome > 0) {
      savingsRate = (monthlyIncome - monthlyExpense) / monthlyIncome * 100.0;
      savingsRateScore = savingsRate.clamp(0.0, 100.0);
    }

    // 2. Budget Compliance Score (25%)
    final double budgetComplianceScore = budgetCompliance.clamp(0.0, 100.0);

    // 3. Debt to Income Ratio Score (20%)
    final double debtPayments = context.snapshot.debts.fold(0.0, (sum, d) => sum + d.monthlyPayment);
    double dtiScore = 100.0;
    if (monthlyIncome > 0) {
      final dti = debtPayments / monthlyIncome;
      dtiScore = ((1.0 - (dti / 0.40)) * 100.0).clamp(0.0, 100.0);
    } else if (debtPayments > 0) {
      dtiScore = 0.0;
    }

    // 4. Stability Score (15%)
    final double stabilityScore = stability?.stabilityScore ?? 100.0;

    // 5. Anomaly / Leaks Score (10%)
    final int leakCount = subscription?.detectedLeaks.length ?? 0;
    final double anomalyScore = (100.0 - (leakCount * 15.0)).clamp(0.0, 100.0);

    // Composite Calculation
    final double compositeScore = (savingsRateScore * 0.30) +
        (budgetComplianceScore * 0.25) +
        (dtiScore * 0.20) +
        (stabilityScore * 0.15) +
        (anomalyScore * 0.10);

    String rating = 'Fair';
    if (compositeScore >= 85) {
      rating = 'Excellent';
    } else if (compositeScore >= 70) {
      rating = 'Good';
    } else if (compositeScore >= 50) {
      rating = 'Fair';
    } else {
      rating = 'Needs Attention';
    }

    // Determine Factors
    final List<String> positive = [];
    final List<String> warning = [];

    if (budgetCompliance >= 90) {
      positive.add('✔ Bills Paid: Excellent budget adherence.');
    } else if (budgetCompliance < 70) {
      warning.add('⚠ Over Budget: High budget overrun in some categories.');
    }

    if (savingsRate >= 15) {
      positive.add('✔ Savings Growing: Saving ${savingsRate.toStringAsFixed(0)}% of your income.');
    } else {
      warning.add('⚠ Low Savings Rate: Saving less than 15% this month.');
    }

    if (debtPayments == 0) {
      positive.add('✔ No Debt: Zero monthly loan obligations.');
    } else if (debtPayments > monthlyIncome * 0.3) {
      warning.add('⚠ High Debt Load: Loan repayments exceed 30% of income.');
    }

    if (stabilityScore >= 85) {
      positive.add('✔ Stable Income: Highly reliable salary inflows.');
    }

    if (leakCount > 0) {
      warning.add('⚠ Subscription Leaks: Unused subscription charges identified.');
    }

    // Detailed explanation
    final reason = 'Your Budget Health is $rating (${compositeScore.toStringAsFixed(0)}/100). '
        'Key drivers: Savings Rate is ${savingsRate.toStringAsFixed(0)}% (score: ${savingsRateScore.toStringAsFixed(0)}), '
        'Budget compliance is ${budgetComplianceScore.toStringAsFixed(0)}%, '
        'and Debt payments are ₹${debtPayments.toStringAsFixed(0)}.';

    final dataUsed = 'Transactions: ${context.snapshot.transactions.length}, '
        'Budgets: ${context.snapshot.budgets.length}, '
        'Debts: ${context.snapshot.debts.length}';

    return BudgetHealth(
      score: compositeScore,
      rating: rating,
      positiveFactors: positive,
      warningFactors: warning,
      confidence: 0.95,
      reason: reason,
      dataUsed: dataUsed,
      algorithmVersion: '1.0.0',
    );
  }
}

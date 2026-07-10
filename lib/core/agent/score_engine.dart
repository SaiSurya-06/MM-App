import 'financial_brain.dart';
import 'analytics_engine.dart';

class ScoreEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final metrics = context.metrics;
    final data = context.rawData;

    final double savingsRate = (metrics['savingsRate'] as num? ?? 0.0).toDouble();
    final double expense = (metrics['totalExpense'] as num? ?? 0.0).toDouble();
    final double totalAmount = (metrics['totalAmount'] as num? ?? 0.0).toDouble();
    final double impulseSum = (metrics['impulseSum'] as num? ?? 0.0).toDouble();

    // 1. Savings Score
    double savingsScore = 0.0;
    if (savingsRate > 0) {
      savingsScore = (savingsRate / 20.0 * 100).clamp(0.0, 100.0);
    }

    // 2. Budget Score
    double budgetScore = 100.0;
    if (data.budgets.isNotEmpty) {
      double totalLimit = 0.0;
      double totalSpent = 0.0;
      for (var b in data.budgets) {
        totalLimit += (b['limit_amount'] as num).toDouble();
      }
      for (var s in data.transactions) {
        if (s['type'] == 'expense') {
          totalSpent += (s['amount'] as num).toDouble();
        }
      }
      if (totalLimit > 0) {
        final ratio = totalSpent / totalLimit;
        budgetScore = ((1.0 - ratio) * 100).clamp(0.0, 100.0);
      }
    }

    // 3. Spending Score (impulse buying checks)
    double spendingScore = 100.0;
    if (totalAmount > 0) {
      final impulseRatio = impulseSum / totalAmount;
      spendingScore = ((1.0 - impulseRatio) * 100).clamp(0.0, 100.0);
    }

    // 4. Emergency Score (Liquid cash buffer)
    double emergencyScore = 0.0;
    final avgExpense = expense > 0 ? expense : 2000.0;
    if (data.netWorth > 0) {
      final emergencyMonths = data.netWorth / avgExpense;
      emergencyScore = (emergencyMonths / 6.0 * 100).clamp(0.0, 100.0);
    }

    final overallScore = (savingsScore + budgetScore + spendingScore + emergencyScore) / 4.0;

    final scores = FinancialScores(
      savingsScore: savingsScore,
      budgetScore: budgetScore,
      spendingScore: spendingScore,
      emergencyScore: emergencyScore,
      overallScore: overallScore,
    );

    return context.copyWith(scores: scores);
  }
}

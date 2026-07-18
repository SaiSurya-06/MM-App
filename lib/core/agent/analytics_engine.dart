import 'package:flutter/foundation.dart';
import 'execution_plan.dart';
import 'retriever.dart';

class FinancialScores {
  final double savingsScore;
  final double budgetScore;
  final double spendingScore;
  final double emergencyScore;
  final double overallScore;

  FinancialScores({
    required this.savingsScore,
    required this.budgetScore,
    required this.spendingScore,
    required this.emergencyScore,
    required this.overallScore,
  });

  factory FinancialScores.empty() {
    return FinancialScores(
      savingsScore: 100,
      budgetScore: 100,
      spendingScore: 100,
      emergencyScore: 100,
      overallScore: 100,
    );
  }
}

class AnalyticsResult {
  final double totalAmount;
  final double averageAmount;
  final int transactionCount;
  final Map<String, dynamic>? largestTransaction;
  final Map<String, double> categoryShares;
  final Map<String, double> merchantShares;
  final String topCategory;
  final String topMerchant;
  final double weekendSum;
  final double nightSum;
  final double impulseSum;
  final List<String> subscriptions;
  final double monthlyIncome;
  final double monthlyExpense;
  final double savingsRate;
  final FinancialScores scores;

  AnalyticsResult({
    required this.totalAmount,
    required this.averageAmount,
    required this.transactionCount,
    required this.largestTransaction,
    required this.categoryShares,
    required this.merchantShares,
    required this.topCategory,
    required this.topMerchant,
    required this.weekendSum,
    required this.nightSum,
    required this.impulseSum,
    required this.subscriptions,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.savingsRate,
    required this.scores,
  });
}

class FinancialAnalyticsEngine {
  static String _getBaseMerchant(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('netflix')) return 'Netflix';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('starbucks')) return 'Starbucks';
    return title;
  }

  static AnalyticsResult compute(ExecutionPlan plan, RetrievedData data) {
    final rows = data.transactions;
    
    double totalAmount = 0.0;
    for (var r in rows) {
      totalAmount += (r['amount'] as num).toDouble();
    }
    final averageAmount = rows.isNotEmpty ? totalAmount / rows.length : 0.0;

    Map<String, dynamic>? largestTransaction;
    if (rows.isNotEmpty) {
      largestTransaction = rows.reduce((a, b) =>
          (a['amount'] as num).toDouble() > (b['amount'] as num).toDouble() ? a : b);
    }

    final categoryShares = <String, double>{};
    for (var r in rows) {
      final cat = r['category']?.toString() ?? 'Other';
      categoryShares[cat] = (categoryShares[cat] ?? 0.0) + (r['amount'] as num).toDouble();
    }
    final topCategory = categoryShares.entries.isNotEmpty
        ? categoryShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    final merchantShares = <String, double>{};
    for (var r in rows) {
      final title = r['title']?.toString() ?? 'Other';
      final merch = _getBaseMerchant(title);
      merchantShares[merch] = (merchantShares[merch] ?? 0.0) + (r['amount'] as num).toDouble();
    }
    final topMerchant = merchantShares.entries.isNotEmpty
        ? merchantShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    double weekendSum = 0.0;
    double nightSum = 0.0;
    double impulseSum = 0.0;
    final recurringMap = <String, int>{};

    for (var r in rows) {
      final amt = (r['amount'] as num).toDouble();
      final dateStr = r['date']?.toString() ?? '';
      final title = r['title']?.toString() ?? '';
      final cat = r['category']?.toString() ?? '';

      try {
        final dt = DateTime.parse(dateStr);
        if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
          weekendSum += amt;
        }
        if (dt.hour >= 20) {
          nightSum += amt;
        }
      } catch (e, stackTrace) {
        debugPrint('Silent error in AnalyticsEngine._runHeuristicCalculations: $e\n$stackTrace');
      }

      if (amt >= 1000 && (cat == 'Food' || cat == 'Entertainment')) {
        impulseSum += amt;
      }

      final key = "$title|${amt.toStringAsFixed(0)}";
      recurringMap[key] = (recurringMap[key] ?? 0) + 1;
    }

    final subscriptions = recurringMap.entries
        .where((e) => e.value >= 2)
        .map((e) => "- **${e.key.split('|')[0]}**: Recurring same-amount charges (${e.key.split('|')[1]})")
        .toList();

    // Monthly Income/Expense calculation based on retrieved transactions
    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;
    for (var tx in rows) {
      final amt = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'income') {
        monthlyIncome += amt;
      } else {
        monthlyExpense += amt;
      }
    }
    final double savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlyExpense) / monthlyIncome * 100) : 0.0;

    // Financial Score Calculations
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
      for (var s in rows) {
        if (s['type'] == 'expense') {
          totalSpent += (s['amount'] as num).toDouble();
        }
      }
      if (totalLimit > 0) {
        final ratio = totalSpent / totalLimit;
        budgetScore = ((1.0 - ratio) * 100).clamp(0.0, 100.0);
      }
    }

    // 3. Spending Score (based on discretionary impulse ratio)
    double spendingScore = 100.0;
    if (totalAmount > 0) {
      final impulseRatio = impulseSum / totalAmount;
      spendingScore = ((1.0 - impulseRatio) * 100).clamp(0.0, 100.0);
    }

    // 4. Emergency Score (Emergency fund buffer)
    double emergencyScore = 0.0;
    final avgExpense = monthlyExpense > 0 ? monthlyExpense : 2000.0;
    if (data.netWorth > 0) {
      final emergencyMonths = data.netWorth / avgExpense;
      emergencyScore = (emergencyMonths / 6.0 * 100).clamp(0.0, 100.0);
    }

    final overallScore = (savingsScore + budgetScore + spendingScore + emergencyScore) / 4.0;

    return AnalyticsResult(
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      transactionCount: rows.length,
      largestTransaction: largestTransaction,
      categoryShares: categoryShares,
      merchantShares: merchantShares,
      topCategory: topCategory,
      topMerchant: topMerchant,
      weekendSum: weekendSum,
      nightSum: nightSum,
      impulseSum: impulseSum,
      subscriptions: subscriptions,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      savingsRate: savingsRate,
      scores: FinancialScores(
        savingsScore: savingsScore,
        budgetScore: budgetScore,
        spendingScore: spendingScore,
        emergencyScore: emergencyScore,
        overallScore: overallScore,
      ),
    );
  }
}

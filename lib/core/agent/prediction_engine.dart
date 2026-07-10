import 'financial_brain.dart';

class ForecastResult {
  final List<String> burnRateAlerts;
  final List<String> goalAccelerationTips;
  final double projectedSavingsRate;
  final double projectedEndMonthBalance;

  ForecastResult({
    required this.burnRateAlerts,
    required this.goalAccelerationTips,
    required this.projectedSavingsRate,
    required this.projectedEndMonthBalance,
  });

  factory ForecastResult.empty() {
    return ForecastResult(
      burnRateAlerts: [],
      goalAccelerationTips: [],
      projectedSavingsRate: 0.0,
      projectedEndMonthBalance: 0.0,
    );
  }
}

class PredictionEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final plan = context.plan;
    if (!plan.needsForecast) {
      return context.copyWith(forecast: ForecastResult.empty()); // fallback type compatible or use local type
    }

    final data = context.rawData;
    final now = DateTime.now();
    final currentDay = now.day;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    final burnRateAlerts = <String>[];
    final goalAccelerationTips = <String>[];

    // 1. Budget depletion calculations
    final Map<int, double> budgetLimits = {};
    final Map<int, String> categoryNames = {};
    for (var b in data.budgets) {
      final catId = b['category_id'] as int;
      budgetLimits[catId] = (b['limit_amount'] as num).toDouble();
      categoryNames[catId] = b['name']?.toString() ?? 'Other';
    }

    final categorySpends = <int, double>{};
    for (var tx in data.transactions) {
      if (tx['type'] == 'expense' && tx['category_id'] != null) {
        final catId = tx['category_id'] as int;
        categorySpends[catId] = (categorySpends[catId] ?? 0.0) + (tx['amount'] as num).toDouble();
      }
    }

    categorySpends.forEach((catId, spent) {
      final limit = budgetLimits[catId];
      final name = categoryNames[catId] ?? 'Category';
      if (limit != null && limit > 0) {
        if (spent >= limit) {
          burnRateAlerts.add("🚨 **Limit exceeded**: Your **$name** budget is fully depleted ($spent/$limit).");
        } else {
          final dailyRate = spent / currentDay;
          if (dailyRate > 0) {
            final projectedTotal = dailyRate * totalDays;
            final remainingDays = (limit - spent) / dailyRate;

            if (projectedTotal > limit) {
              burnRateAlerts.add("⚠️ **Overrun warning**: Your **$name** budget will deplete in **${remainingDays.toStringAsFixed(0)} days** if spending continues at current rate.");
            }
          }
        }
      }
    });

    // 2. Goal completion timeline calculations
    final double income = (context.metrics['totalIncome'] as num? ?? 0.0).toDouble();
    final double expense = (context.metrics['totalExpense'] as num? ?? 0.0).toDouble();
    final double netSavings = income - expense;

    for (var goal in data.goals) {
      final name = goal['name']?.toString() ?? 'Goal';
      final target = (goal['target_amount'] as num).toDouble();
      final current = (goal['current_amount'] as num).toDouble();
      final needed = target - current;

      if (needed > 0 && netSavings > 0) {
        final monthsToTarget = needed / netSavings;
        
        const addedSavings = 1500.0;
        final acceleratedMonths = needed / (netSavings + addedSavings);
        final diff = monthsToTarget - acceleratedMonths;

        if (diff > 0.5) {
          goalAccelerationTips.add("🎯 **Goal Accelerate**: Saving an extra **₹${addedSavings.toStringAsFixed(0)}/month** gets you to your **'$name'** goal **${diff.toStringAsFixed(1)} months** earlier!");
        }
      }
    }

    final double projectedSavings = netSavings * (totalDays / currentDay);
    final double endBalance = data.netWorth + projectedSavings;

    final forecastResult = ForecastResult(
      burnRateAlerts: burnRateAlerts,
      goalAccelerationTips: goalAccelerationTips,
      projectedSavingsRate: income > 0 ? (netSavings / income * 100) : 0.0,
      projectedEndMonthBalance: endBalance,
    );

    return context.copyWith(forecast: forecastResult);
  }
}

import 'financial_brain.dart';

class InsightEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final rows = context.rawData.transactions;
    final metrics = context.metrics;
    
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
      } catch (_) {}

      if (amt >= 1000 && (cat == 'Food' || cat == 'Entertainment')) {
        impulseSum += amt;
      }

      final key = "$title|${amt.toStringAsFixed(0)}";
      recurringMap[key] = (recurringMap[key] ?? 0) + 1;
    }

    final subscriptions = recurringMap.entries
        .where((e) => e.value >= 2)
        .map((e) => "- **${e.key.split('|')[0]}**: Recurring charges (${e.key.split('|')[1]})")
        .toList();

    final List<String> insights = [];
    final double income = (metrics['totalIncome'] as num? ?? 0.0).toDouble();
    final double expense = (metrics['totalExpense'] as num? ?? 0.0).toDouble();
    final double savingsRate = income > 0 ? ((income - expense) / income * 100) : 0.0;

    insights.add("Savings Rate is ${savingsRate.toStringAsFixed(1)}% (Target: 20%)");
    if (weekendSum > expense * 0.3) {
      insights.add("Weekend discretionary spending is high (${(weekendSum / expense * 100).toStringAsFixed(0)}% of expenses)");
    }
    if (impulseSum > 0) {
      insights.add("Impulse shopping/eating out makes up ₹${impulseSum.toStringAsFixed(0)} of this period.");
    }
    if (subscriptions.isNotEmpty) {
      insights.add("Found ${subscriptions.length} active recurring subscriptions.");
    }

    // Enrich context with insights
    final updatedMetrics = Map<String, dynamic>.from(metrics)
      ..['weekendSum'] = weekendSum
      ..['nightSum'] = nightSum
      ..['impulseSum'] = impulseSum
      ..['subscriptions'] = subscriptions
      ..['savingsRate'] = savingsRate;

    return context.copyWith(
      insights: insights,
      metrics: updatedMetrics,
    );
  }
}

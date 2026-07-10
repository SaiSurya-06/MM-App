import 'financial_brain.dart';
import 'execution_plan.dart';
import 'retriever.dart';

class InvestigationResult {
  final double absoluteIncrease;
  final double percentageIncrease;
  final List<String> spendingCauses;
  final List<String> anomalies;
  final bool isAnomalyDetected;

  InvestigationResult({
    required this.absoluteIncrease,
    required this.percentageIncrease,
    required this.spendingCauses,
    required this.anomalies,
    required this.isAnomalyDetected,
  });

  factory InvestigationResult.empty() {
    return InvestigationResult(
      absoluteIncrease: 0.0,
      percentageIncrease: 0.0,
      spendingCauses: [],
      anomalies: [],
      isAnomalyDetected: false,
    );
  }
}

class InvestigationEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final plan = context.plan;
    if (plan.comparisonMonth == null) {
      return context.copyWith(investigation: InvestigationResult.empty());
    }

    final compPlan = ExecutionPlan(
      intent: plan.intent,
      merchant: plan.merchant,
      category: plan.category,
      minAmount: plan.minAmount,
      maxAmount: plan.maxAmount,
      targetMonth: plan.comparisonMonth,
      targetYear: plan.comparisonYear,
      paymentMethod: plan.paymentMethod,
      timeFilter: plan.timeFilter,
      targetType: plan.targetType,
      requiredTools: plan.requiredTools,
      requiredStrategies: plan.requiredStrategies,
      needsForecast: plan.needsForecast,
      needsDecision: plan.needsDecision,
      needsCoaching: plan.needsCoaching,
      confidence: plan.confidence,
    );

    final compData = await DatabaseRetriever.retrieve(compPlan);

    double currentTotal = 0.0;
    final currentCatGroup = <String, double>{};
    final currentMerchGroup = <String, double>{};

    for (var r in context.rawData.transactions) {
      final amt = (r['amount'] as num).toDouble();
      currentTotal += amt;
      final cat = r['category']?.toString() ?? 'Other';
      currentCatGroup[cat] = (currentCatGroup[cat] ?? 0.0) + amt;

      final title = r['title']?.toString() ?? '';
      currentMerchGroup[title] = (currentMerchGroup[title] ?? 0.0) + amt;
    }

    double compTotal = 0.0;
    final compCatGroup = <String, double>{};
    final compMerchGroup = <String, double>{};

    for (var r in compData.transactions) {
      final amt = (r['amount'] as num).toDouble();
      compTotal += amt;
      final cat = r['category']?.toString() ?? 'Other';
      compCatGroup[cat] = (compCatGroup[cat] ?? 0.0) + amt;

      final title = r['title']?.toString() ?? '';
      compMerchGroup[title] = (compMerchGroup[title] ?? 0.0) + amt;
    }

    final double absDiff = currentTotal - compTotal;
    final double pctDiff = compTotal > 0 ? (absDiff / compTotal * 100) : 0.0;

    final causes = <String>[];
    final anomalies = <String>[];

    // Category difference tracking
    final catDiffs = <String, double>{};
    currentCatGroup.forEach((cat, amt) {
      final compAmt = compCatGroup[cat] ?? 0.0;
      final diff = amt - compAmt;
      if (diff > 0) {
        catDiffs[cat] = diff;
      }
    });

    final sortedCatDiffs = catDiffs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedCatDiffs) {
      causes.add("${entry.key} spending increased by +₹${entry.value.toStringAsFixed(0)}");
      if (entry.value > 1000) {
        anomalies.add("⚠️ **Anomaly**: Spikes in **${entry.key}** spending (+₹${entry.value.toStringAsFixed(0)}) compared to comparison month.");
      }
    }

    // Merchant difference tracking
    final merchDiffs = <String, double>{};
    currentMerchGroup.forEach((merch, amt) {
      final compAmt = compMerchGroup[merch] ?? 0.0;
      final diff = amt - compAmt;
      if (diff > 150) {
        merchDiffs[merch] = diff;
      }
    });

    final sortedMerchDiffs = merchDiffs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedMerchDiffs.take(3)) {
      if (entry.value > 500) {
        anomalies.add("🚨 **Habit alert**: Spending at **${entry.key}** went up by +₹${entry.value.toStringAsFixed(0)}.");
      }
    }

    final result = InvestigationResult(
      absoluteIncrease: absDiff,
      percentageIncrease: pctDiff,
      spendingCauses: causes,
      anomalies: anomalies,
      isAnomalyDetected: anomalies.isNotEmpty,
    );

    return context.copyWith(investigation: result);
  }
}

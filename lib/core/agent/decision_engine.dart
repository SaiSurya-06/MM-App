import 'financial_brain.dart';

class DecisionResult {
  final bool isDecisionQuery;
  final String decisionText;
  final String recommendationText;
  final double purchaseAmount;

  DecisionResult({
    required this.isDecisionQuery,
    required this.decisionText,
    required this.recommendationText,
    required this.purchaseAmount,
  });

  factory DecisionResult.empty() {
    return DecisionResult(
      isDecisionQuery: false,
      decisionText: '',
      recommendationText: '',
      purchaseAmount: 0.0,
    );
  }
}

class DecisionEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final plan = context.plan;
    if (plan.intent != 'decision') {
      return context.copyWith(decision: DecisionResult.empty());
    }

    final query = context.query.toLowerCase();
    
    // Parse purchase amount from query, e.g. "Can I buy a 50000 laptop" or "afford 30000"
    final amtReg = RegExp(r'(?:buy|afford|purchase|price|cost|laptop|phone|iphone|car|rs\.?|₹)\s*(\d+)');
    final match = amtReg.firstMatch(query);
    double purchaseAmt = 0.0;
    if (match != null) {
      purchaseAmt = double.tryParse(match.group(1)!) ?? 0.0;
    } else {
      purchaseAmt = plan.minAmount ?? plan.maxAmount ?? 0.0;
    }

    if (purchaseAmt <= 0) {
      return context.copyWith(
        decision: DecisionResult(
          isDecisionQuery: true,
          decisionText: "I couldn't identify the price of the item you want to purchase.",
          recommendationText: "Please ask again specifying the amount (e.g. 'Can I buy a ₹50,000 laptop?').",
          purchaseAmount: 0.0,
        ),
      );
    }

    final double balance = context.rawData.netWorth;
    final double expense = (context.metrics['totalExpense'] as num? ?? 2000.0).toDouble();
    final double emergencyReserve = expense * 3.0; // 3 months of expenses

    String decisionText = "";
    String recommendationText = "";

    if (balance >= purchaseAmt + emergencyReserve) {
      decisionText = "Yes, you can comfortably afford this purchase of ₹${purchaseAmt.toStringAsFixed(0)}.";
      recommendationText = "Your emergency reserve of 3 months (₹${emergencyReserve.toStringAsFixed(0)}) remains untouched, leaving a surplus of ₹${(balance - purchaseAmt - emergencyReserve).toStringAsFixed(0)}.";
    } else if (balance >= purchaseAmt) {
      decisionText = "Technically yes, you have the cash, but your emergency fund would fall below the safe 3-month boundary (₹${emergencyReserve.toStringAsFixed(0)}).";
      recommendationText = "Your emergency buffer would drop to ₹${(balance - purchaseAmt).toStringAsFixed(0)}. Recommendation: Wait until you save an additional ₹${(purchaseAmt + emergencyReserve - balance).toStringAsFixed(0)} to maintain financial safety.";
    } else {
      decisionText = "No, you cannot afford this purchase of ₹${purchaseAmt.toStringAsFixed(0)} right now.";
      recommendationText = "This purchase exceeds your current net balances by ₹${(purchaseAmt - balance).toStringAsFixed(0)}. Try saving ₹3,000/month to accumulate the funds in ${((purchaseAmt - balance) / 3000.0).ceil()} months.";
    }

    final result = DecisionResult(
      isDecisionQuery: true,
      decisionText: decisionText,
      recommendationText: recommendationText,
      purchaseAmount: purchaseAmt,
    );

    return context.copyWith(decision: result);
  }
}

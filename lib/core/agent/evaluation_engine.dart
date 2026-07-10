import 'financial_brain.dart';

class EvaluationResult {
  final double dataCoveragePercentage;
  final bool needsClarification;
  final String clarificationPrompt;
  final String reasoningStrength;

  EvaluationResult({
    required this.dataCoveragePercentage,
    required this.needsClarification,
    required this.clarificationPrompt,
    required this.reasoningStrength,
  });

  factory EvaluationResult.empty() {
    return EvaluationResult(
      dataCoveragePercentage: 100.0,
      needsClarification: false,
      clarificationPrompt: '',
      reasoningStrength: 'High',
    );
  }
}

class EvaluationEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final rawData = context.rawData;
    final plan = context.plan;

    // 1. Data Coverage calculation
    double coverage = 100.0;
    if (plan.requiredTools.contains('transaction') && rawData.transactions.isEmpty) {
      coverage = 0.0;
    } else if (rawData.transactions.isNotEmpty) {
      int uncategorizedCount = 0;
      for (var tx in rawData.transactions) {
        final cat = (tx['category']?.toString() ?? 'other').toLowerCase();
        if (cat == 'other' || cat == 'uncategorized') {
          uncategorizedCount++;
        }
      }
      coverage = ((rawData.transactions.length - uncategorizedCount) / rawData.transactions.length) * 100;
    }

    // 2. Determine if clarification is required
    bool needsClarification = false;
    String clarificationPrompt = "";
    String reasoningStrength = "High";

    if (coverage < 50.0 && rawData.transactions.isNotEmpty) {
      needsClarification = true;
      clarificationPrompt = "I found some records, but over 50% of your transactions are uncategorized (e.g. Swiggy or Uber). Should I dynamically categorize Swiggy/Zomato to 'Food' and Uber/Ola to 'Transport' to improve details?";
      reasoningStrength = "Medium";
    }

    if (plan.confidence < 0.7) {
      needsClarification = true;
      clarificationPrompt = "I'm not fully sure of the merchant or category. Did you mean groceries, food delivery, or recent ATM cash withdrawals?";
      reasoningStrength = "Low";
    }

    final result = EvaluationResult(
      dataCoveragePercentage: coverage,
      needsClarification: needsClarification,
      clarificationPrompt: clarificationPrompt,
      reasoningStrength: reasoningStrength,
    );

    return context.copyWith(evaluation: result);
  }
}

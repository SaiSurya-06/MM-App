import 'financial_brain.dart';
import '../utils/currency_formatter.dart';

class ScenarioResult {
  final bool isScenarioQuery;
  final String scenarioSummary;
  final List<String> projections;
  final String advice;

  ScenarioResult({
    required this.isScenarioQuery,
    required this.scenarioSummary,
    required this.projections,
    required this.advice,
  });

  factory ScenarioResult.empty() {
    return ScenarioResult(
      isScenarioQuery: false,
      scenarioSummary: '',
      projections: [],
      advice: '',
    );
  }
}

class ScenarioEngine implements FinancialEngine {
  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final query = context.query.toLowerCase();
    
    // Check if it is a what-if query
    final isWhatIf = query.contains("what if") || query.contains("simulate") || query.contains("suppose");
    if (!isWhatIf) {
      return context.copyWith(scenario: ScenarioResult.empty());
    }

    double monthlyBooster = 0.0;
    double incomePercent = 0.0;
    String cutTarget = "";
    double cutValue = 0.0;

    // 1. Check for discretionary expense cuts, e.g. "stop ordering food", "no swiggy"
    if (query.contains("food") || query.contains("swiggy") || query.contains("dining")) {
      cutTarget = "Food Delivery";
      cutValue = (context.metrics['categoryShares']['Food'] as num? ?? 3000.0).toDouble();
    } else if (query.contains("entertainment") || query.contains("netflix") || query.contains("subscriptions")) {
      cutTarget = "Entertainment & Subscriptions";
      cutValue = (context.metrics['categoryShares']['Entertainment'] as num? ?? 1500.0).toDouble();
    }

    // 2. Check for savings booster, e.g. "save 5000 more"
    final saveReg = RegExp(r'(?:save|invest|add|booster)\s*(?:rs\.?|₹)?\s*(\d+)');
    final saveMatch = saveReg.firstMatch(query);
    if (saveMatch != null) {
      monthlyBooster = double.tryParse(saveMatch.group(1)!) ?? 0.0;
    }

    // 3. Check for salary/income increase, e.g. "salary increases by 15%"
    final salReg = RegExp(r'(?:salary|income)\s*(?:increases|goes up|up|raise)\s*(?:by)?\s*(\d+)\s*%');
    final salMatch = salReg.firstMatch(query);
    if (salMatch != null) {
      incomePercent = double.tryParse(salMatch.group(1)!) ?? 0.0;
    }

    if (cutValue <= 0 && monthlyBooster <= 0 && incomePercent <= 0) {
      return context.copyWith(
        scenario: ScenarioResult(
          isScenarioQuery: true,
          scenarioSummary: "I recognized your simulation request, but couldn't parse the specific parameters.",
          projections: [],
          advice: "Try asking: 'What if I stop ordering food?' or 'What if I save ${CurrencyFormatter.getSymbol(context.currencyCode)}5,000 more monthly?'",
        ),
      );
    }

    double totalMonthlySavings = monthlyBooster;
    String summary = "";

    if (cutValue > 0) {
      totalMonthlySavings += cutValue;
      summary += "Simulating cutting **$cutTarget** expenses (saving **${CurrencyFormatter.format(cutValue, context.currencyCode)}/month**). ";
    }
    if (incomePercent > 0) {
      final currentIncome = (context.metrics['totalIncome'] as num? ?? 50000.0).toDouble();
      final extraIncome = currentIncome * (incomePercent / 100.0);
      totalMonthlySavings += extraIncome;
      summary += "Simulating a **${incomePercent.toStringAsFixed(0)}% salary increase** (+${CurrencyFormatter.format(extraIncome, context.currencyCode)}/month). ";
    }
    if (monthlyBooster > 0 && cutValue == 0 && incomePercent == 0) {
      summary += "Simulating saving an extra **${CurrencyFormatter.format(monthlyBooster, context.currencyCode)}/month**. ";
    }

    final projections = [
      "📈 Cumulative Savings in **3 months**: +${CurrencyFormatter.format(totalMonthlySavings * 3, context.currencyCode)}",
      "📈 Cumulative Savings in **6 months**: +${CurrencyFormatter.format(totalMonthlySavings * 6, context.currencyCode)}",
      "📈 Cumulative Savings in **12 months**: +${CurrencyFormatter.format(totalMonthlySavings * 12, context.currencyCode)}",
    ];

    String advice = "This extra buffer could pay off your credit card balances faster, or secure your emergency fund target earlier.";

    final result = ScenarioResult(
      isScenarioQuery: true,
      scenarioSummary: summary,
      projections: projections,
      advice: advice,
    );

    return context.copyWith(scenario: result);
  }
}

import '../capability.dart';
import '../explainable_value.dart';
import '../../utils/currency_formatter.dart';

class IncomePredictor implements Capability<ExplainableValue<double>> {
  @override
  String get id => 'income_predictor';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Income Predictor';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<ExplainableValue<double>> execute(OrchestratorContext context) async {
    final stability = context.stability;
    final incomeAnalysis = context.incomeAnalysis;

    final double soFar = incomeAnalysis?.totalIncome ?? 0.0;
    final double historicalAverage = stability?.baseExpectedMonthlyIncome ?? 0.0;
    final String type = stability?.incomeType ?? 'Stable';

    double predicted = soFar;
    double confidence = 0.95;
    String reason = 'Based on stable, recurring salary inflow patterns.';
    
    if (type == 'Stable') {
      if (soFar == 0.0) {
        predicted = historicalAverage;
        confidence = 0.90;
        reason = 'Income not yet received this month. Expected baseline salary of ${CurrencyFormatter.format(historicalAverage, context.currencyCode)}.';
      } else {
        predicted = soFar > historicalAverage ? soFar : historicalAverage;
        confidence = 0.98;
        reason = 'Income received matches stable historical salary baseline.';
      }
    } else {
      // Freelance / Seasonal
      predicted = soFar + (historicalAverage * 0.2); // Project slight additional freelance earnings
      confidence = 0.70;
      reason = 'Freelance/Seasonal income is variable. Expected baseline total of ${CurrencyFormatter.format(predicted, context.currencyCode)}.';
    }

    return ExplainableValue<double>(
      value: predicted,
      reason: reason,
      confidence: confidence,
      dataUsed: 'Current Month Inflows: ${CurrencyFormatter.format(soFar, context.currencyCode)}, Historical Avg: ${CurrencyFormatter.format(historicalAverage, context.currencyCode)}',
    );
  }
}

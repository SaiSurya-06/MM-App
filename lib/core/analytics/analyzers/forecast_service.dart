import '../capability.dart';
import '../explainable_value.dart';
import '../models/monthly_forecast.dart';
import 'income_predictor.dart';
import 'cash_flow_predictor.dart';
import 'goal_predictor.dart';
import '../../utils/currency_formatter.dart';

class ForecastService implements Capability<MonthlyForecast> {
  @override
  String get id => 'forecast_service';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Forecast Service';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  final IncomePredictor _incomePredictor = IncomePredictor();
  final CashFlowPredictor _cashFlowPredictor = CashFlowPredictor();
  final GoalPredictor _goalPredictor = GoalPredictor();

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<MonthlyForecast> execute(OrchestratorContext context) async {
    final now = context.snapshot.selectedDate;
    final double spentSoFar = context.expenseAnalysis?.totalExpense ?? 0.0;
    final int totalDays = DateTime(now.year, now.month + 1, 0).day;
    final int elapsedDays = now.day > 0 ? now.day : 1;

    // 1. Spending Forecast
    final double projectedSpend = (spentSoFar / elapsedDays) * totalDays;
    final double spendConfidence = elapsedDays >= 20 ? 0.95 : (elapsedDays >= 10 ? 0.80 : 0.60);
    
    final predictedMonthEndSpend = ExplainableValue<double>(
      value: projectedSpend,
      reason: 'Extrapolated from spending burn rate of ${CurrencyFormatter.format(spentSoFar / elapsedDays, context.currencyCode)}/day over $elapsedDays days.',
      confidence: spendConfidence,
      dataUsed: 'Spent: ${CurrencyFormatter.format(spentSoFar, context.currencyCode)}, Month Days: $totalDays',
    );

    // 2. Income Forecast
    final predictedIncome = await _incomePredictor.execute(context);

    // 3. Month End Balance Forecast
    final double balance = context.snapshot.accounts
        .where((acc) => acc.type != 'Credit Card')
        .fold(0.0, (sum, acc) => sum + acc.balance);
    
    final double projectedEndBalance = balance + (predictedIncome.value - projectedSpend);
    final predictedMonthEndBalance = ExplainableValue<double>(
      value: projectedEndBalance,
      reason: 'Calculated as cash balance plus predicted net monthly savings (${CurrencyFormatter.format(predictedIncome.value - projectedSpend, context.currencyCode)}).',
      confidence: predictedIncome.confidence * spendConfidence,
      dataUsed: 'Cash: ${CurrencyFormatter.format(balance, context.currencyCode)}, Net Savings: ${CurrencyFormatter.format(predictedIncome.value - projectedSpend, context.currencyCode)}',
    );

    // 4. Cash Flow Daily coordinates
    final cashFlowTrend = await _cashFlowPredictor.execute(context);

    // 5. Goal Forecast dates
    final goalForecasts = await _goalPredictor.execute(context);

    final forecast = MonthlyForecast(
      predictedMonthEndSpend: predictedMonthEndSpend,
      predictedMonthEndBalance: predictedMonthEndBalance,
      predictedIncomeTotal: predictedIncome,
      cashFlowTrend: cashFlowTrend,
      goalForecasts: goalForecasts,
    );

    context.forecast = forecast; // Cache in context
    return forecast;
  }
}

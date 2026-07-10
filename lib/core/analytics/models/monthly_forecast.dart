import '../explainable_value.dart';

class MonthlyForecast {
  final ExplainableValue<double> predictedMonthEndSpend;
  final ExplainableValue<double> predictedMonthEndBalance;
  final ExplainableValue<double> predictedIncomeTotal;
  final Map<String, double> cashFlowTrend; // Date -> projected balance
  final Map<int, ExplainableValue<String>> goalForecasts; // Goal ID -> expected date prediction

  const MonthlyForecast({
    required this.predictedMonthEndSpend,
    required this.predictedMonthEndBalance,
    required this.predictedIncomeTotal,
    required this.cashFlowTrend,
    required this.goalForecasts,
  });

  Map<String, dynamic> toJson() => {
        'predictedMonthEndSpend': predictedMonthEndSpend.toJson((v) => v),
        'predictedMonthEndBalance': predictedMonthEndBalance.toJson((v) => v),
        'predictedIncomeTotal': predictedIncomeTotal.toJson((v) => v),
        'cashFlowTrend': cashFlowTrend,
        'goalForecasts': goalForecasts.map((key, val) => MapEntry(key.toString(), val.toJson((v) => v))),
      };

  MonthlyForecast copyWith({
    ExplainableValue<double>? predictedMonthEndSpend,
    ExplainableValue<double>? predictedMonthEndBalance,
    ExplainableValue<double>? predictedIncomeTotal,
    Map<String, double>? cashFlowTrend,
    Map<int, ExplainableValue<String>>? goalForecasts,
  }) {
    return MonthlyForecast(
      predictedMonthEndSpend: predictedMonthEndSpend ?? this.predictedMonthEndSpend,
      predictedMonthEndBalance: predictedMonthEndBalance ?? this.predictedMonthEndBalance,
      predictedIncomeTotal: predictedIncomeTotal ?? this.predictedIncomeTotal,
      cashFlowTrend: cashFlowTrend ?? this.cashFlowTrend,
      goalForecasts: goalForecasts ?? this.goalForecasts,
    );
  }
}

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

  factory MonthlyForecast.fromJson(Map<String, dynamic> json) => MonthlyForecast(
        predictedMonthEndSpend: ExplainableValue.fromJson(
            json['predictedMonthEndSpend'] as Map<String, dynamic>, (v) => (v as num).toDouble()),
        predictedMonthEndBalance: ExplainableValue.fromJson(
            json['predictedMonthEndBalance'] as Map<String, dynamic>, (v) => (v as num).toDouble()),
        predictedIncomeTotal: ExplainableValue.fromJson(
            json['predictedIncomeTotal'] as Map<String, dynamic>, (v) => (v as num).toDouble()),
        cashFlowTrend: Map<String, double>.from(json['cashFlowTrend'] ?? {}),
        goalForecasts: (json['goalForecasts'] as Map?)?.map(
              (key, val) => MapEntry(
                int.parse(key.toString()),
                ExplainableValue.fromJson(val as Map<String, dynamic>, (v) => v as String),
              ),
            ) ??
            {},
      );

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

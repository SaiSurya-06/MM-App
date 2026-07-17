export '../database/database_retriever.dart';

class RetrievedData {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> balances;
  final double netWorth;
  final bool fallbackMonthUsed;
  final int? activeMonth;
  final int? activeYear;

  RetrievedData({
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.balances,
    required this.netWorth,
    this.fallbackMonthUsed = false,
    this.activeMonth,
    this.activeYear,
  });

  factory RetrievedData.empty() {
    return RetrievedData(
      transactions: [],
      budgets: [],
      goals: [],
      balances: [],
      netWorth: 0.0,
    );
  }
}

class MoneySnapshot {
  final double salary;       // Salary / Income
  final double essentials;   // Needs / Essential Bills
  final double lifestyle;    // Wants / Daily Living
  final double savings;      // Savings allocated
  final double investments;  // Investments allocated
  final double debt;         // Debt EMI/payments
  final double taxes;        // Taxes paid
  final double transfers;    // Net transfers out
  final double others;       // Unclassified outflow
  
  final double totalIncome;
  final double totalExpense;
  final double moneyLeft;    // Remaining balance

  const MoneySnapshot({
    required this.salary,
    required this.essentials,
    required this.lifestyle,
    required this.savings,
    required this.investments,
    required this.debt,
    required this.taxes,
    required this.transfers,
    required this.others,
    required this.totalIncome,
    required this.totalExpense,
    required this.moneyLeft,
  });

  Map<String, dynamic> toJson() => {
        'salary': salary,
        'essentials': essentials,
        'lifestyle': lifestyle,
        'savings': savings,
        'investments': investments,
        'debt': debt,
        'taxes': taxes,
        'transfers': transfers,
        'others': others,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'moneyLeft': moneyLeft,
      };

  factory MoneySnapshot.fromJson(Map<String, dynamic> json) => MoneySnapshot(
        salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
        essentials: (json['essentials'] as num?)?.toDouble() ?? 0.0,
        lifestyle: (json['lifestyle'] as num?)?.toDouble() ?? 0.0,
        savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
        investments: (json['investments'] as num?)?.toDouble() ?? 0.0,
        debt: (json['debt'] as num?)?.toDouble() ?? 0.0,
        taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
        transfers: (json['transfers'] as num?)?.toDouble() ?? 0.0,
        others: (json['others'] as num?)?.toDouble() ?? 0.0,
        totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
        totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
        moneyLeft: (json['moneyLeft'] as num?)?.toDouble() ?? 0.0,
      );

  MoneySnapshot copyWith({
    double? salary,
    double? essentials,
    double? lifestyle,
    double? savings,
    double? investments,
    double? debt,
    double? taxes,
    double? transfers,
    double? others,
    double? totalIncome,
    double? totalExpense,
    double? moneyLeft,
  }) {
    return MoneySnapshot(
      salary: salary ?? this.salary,
      essentials: essentials ?? this.essentials,
      lifestyle: lifestyle ?? this.lifestyle,
      savings: savings ?? this.savings,
      investments: investments ?? this.investments,
      debt: debt ?? this.debt,
      taxes: taxes ?? this.taxes,
      transfers: transfers ?? this.transfers,
      others: others ?? this.others,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      moneyLeft: moneyLeft ?? this.moneyLeft,
    );
  }
}

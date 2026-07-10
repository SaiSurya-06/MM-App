class FinancialRisk {
  final double cashRunwayMonths; // Number of months of spending emergency fund covers
  final double debtToIncomeRatio; // DTI ratio
  final double overspendingProbability; // Probability of exceeding overall budget limit (0.0 to 1.0)
  final double budgetCollapseProbability; // Probability of exhausting all remaining cash before month end
  final String riskLevel; // Low, Medium, High
  final List<String> riskFactors;
  final String reason;

  const FinancialRisk({
    required this.cashRunwayMonths,
    required this.debtToIncomeRatio,
    required this.overspendingProbability,
    required this.budgetCollapseProbability,
    required this.riskLevel,
    required this.riskFactors,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'cashRunwayMonths': cashRunwayMonths,
        'debtToIncomeRatio': debtToIncomeRatio,
        'overspendingProbability': overspendingProbability,
        'budgetCollapseProbability': budgetCollapseProbability,
        'riskLevel': riskLevel,
        'riskFactors': riskFactors,
        'reason': reason,
      };

  FinancialRisk copyWith({
    double? cashRunwayMonths,
    double? debtToIncomeRatio,
    double? overspendingProbability,
    double? budgetCollapseProbability,
    String? riskLevel,
    List<String>? riskFactors,
    String? reason,
  }) {
    return FinancialRisk(
      cashRunwayMonths: cashRunwayMonths ?? this.cashRunwayMonths,
      debtToIncomeRatio: debtToIncomeRatio ?? this.debtToIncomeRatio,
      overspendingProbability: overspendingProbability ?? this.overspendingProbability,
      budgetCollapseProbability: budgetCollapseProbability ?? this.budgetCollapseProbability,
      riskLevel: riskLevel ?? this.riskLevel,
      riskFactors: riskFactors ?? this.riskFactors,
      reason: reason ?? this.reason,
    );
  }
}

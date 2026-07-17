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

  factory FinancialRisk.fromJson(Map<String, dynamic> json) => FinancialRisk(
        cashRunwayMonths: (json['cashRunwayMonths'] as num?)?.toDouble() ?? 0.0,
        debtToIncomeRatio: (json['debtToIncomeRatio'] as num?)?.toDouble() ?? 0.0,
        overspendingProbability: (json['overspendingProbability'] as num?)?.toDouble() ?? 0.0,
        budgetCollapseProbability: (json['budgetCollapseProbability'] as num?)?.toDouble() ?? 0.0,
        riskLevel: json['riskLevel'] as String? ?? 'Low',
        riskFactors: List<String>.from(json['riskFactors'] ?? []),
        reason: json['reason'] as String? ?? '',
      );

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

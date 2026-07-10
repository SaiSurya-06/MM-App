class PurchaseDecision {
  final double purchaseAmount;
  final bool isApproved;
  final double postPurchaseEmergencyFund;
  final bool isSavingsGoalAffected;
  final int budgetRecoveryDays;
  final double confidenceScore;
  final String explanation;

  const PurchaseDecision({
    required this.purchaseAmount,
    required this.isApproved,
    required this.postPurchaseEmergencyFund,
    required this.isSavingsGoalAffected,
    required this.budgetRecoveryDays,
    required this.confidenceScore,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'purchaseAmount': purchaseAmount,
        'isApproved': isApproved,
        'postPurchaseEmergencyFund': postPurchaseEmergencyFund,
        'isSavingsGoalAffected': isSavingsGoalAffected,
        'budgetRecoveryDays': budgetRecoveryDays,
        'confidenceScore': confidenceScore,
        'explanation': explanation,
      };

  PurchaseDecision copyWith({
    double? purchaseAmount,
    bool? isApproved,
    double? postPurchaseEmergencyFund,
    bool? isSavingsGoalAffected,
    int? budgetRecoveryDays,
    double? confidenceScore,
    String? explanation,
  }) {
    return PurchaseDecision(
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      isApproved: isApproved ?? this.isApproved,
      postPurchaseEmergencyFund: postPurchaseEmergencyFund ?? this.postPurchaseEmergencyFund,
      isSavingsGoalAffected: isSavingsGoalAffected ?? this.isSavingsGoalAffected,
      budgetRecoveryDays: budgetRecoveryDays ?? this.budgetRecoveryDays,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      explanation: explanation ?? this.explanation,
    );
  }
}

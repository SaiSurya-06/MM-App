class BudgetHealth {
  final double score;
  final String rating; // e.g. Excellent, Good, Fair, Poor
  final List<String> positiveFactors;
  final List<String> warningFactors;
  final double confidence;
  final String reason;
  final String dataUsed;
  final String algorithmVersion;

  const BudgetHealth({
    required this.score,
    required this.rating,
    required this.positiveFactors,
    required this.warningFactors,
    this.confidence = 1.0,
    this.reason = '',
    this.dataUsed = '',
    this.algorithmVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'rating': rating,
        'positiveFactors': positiveFactors,
        'warningFactors': warningFactors,
        'confidence': confidence,
        'reason': reason,
        'dataUsed': dataUsed,
        'algorithmVersion': algorithmVersion,
      };

  factory BudgetHealth.fromJson(Map<String, dynamic> json) => BudgetHealth(
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        rating: json['rating'] as String? ?? 'Fair',
        positiveFactors: List<String>.from(json['positiveFactors'] ?? []),
        warningFactors: List<String>.from(json['warningFactors'] ?? []),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        reason: json['reason'] as String? ?? '',
        dataUsed: json['dataUsed'] as String? ?? '',
        algorithmVersion: json['algorithmVersion'] as String? ?? '1.0.0',
      );

  BudgetHealth copyWith({
    double? score,
    String? rating,
    List<String>? positiveFactors,
    List<String>? warningFactors,
    double? confidence,
    String? reason,
    String? dataUsed,
    String? algorithmVersion,
  }) {
    return BudgetHealth(
      score: score ?? this.score,
      rating: rating ?? this.rating,
      positiveFactors: positiveFactors ?? this.positiveFactors,
      warningFactors: warningFactors ?? this.warningFactors,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      dataUsed: dataUsed ?? this.dataUsed,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    );
  }
}

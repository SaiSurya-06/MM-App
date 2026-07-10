class ExplainableValue<T> {
  final T value;
  final String reason;
  final String dataUsed;
  final double confidence; // 0.0 to 1.0
  final List<String> limitations;

  const ExplainableValue({
    required this.value,
    this.reason = '',
    this.dataUsed = '',
    this.confidence = 1.0,
    this.limitations = const [],
  });

  ExplainableValue<T> copyWith({
    T? value,
    String? reason,
    String? dataUsed,
    double? confidence,
    List<String>? limitations,
  }) {
    return ExplainableValue<T>(
      value: value ?? this.value,
      reason: reason ?? this.reason,
      dataUsed: dataUsed ?? this.dataUsed,
      confidence: confidence ?? this.confidence,
      limitations: limitations ?? this.limitations,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
        'value': toJsonT(value),
        'reason': reason,
        'dataUsed': dataUsed,
        'confidence': confidence,
        'limitations': limitations,
      };
}

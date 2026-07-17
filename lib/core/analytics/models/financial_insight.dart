class FinancialInsight {
  final String type; // alert, warning, tip, action, rule
  final String priority; // high, medium, low
  final String title;
  final String description;
  final String action;
  final double confidence;
  final String? categoryName;
  final double? impactAmount; // Potential savings or overspent amount

  const FinancialInsight({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
    required this.confidence,
    this.categoryName,
    this.impactAmount,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'priority': priority,
        'title': title,
        'description': description,
        'action': action,
        'confidence': confidence,
        'categoryName': categoryName,
        'impactAmount': impactAmount,
      };

  factory FinancialInsight.fromJson(Map<String, dynamic> json) => FinancialInsight(
        type: json['type'] as String? ?? 'tip',
        priority: json['priority'] as String? ?? 'low',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        action: json['action'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        categoryName: json['categoryName'] as String?,
        impactAmount: (json['impactAmount'] as num?)?.toDouble(),
      );

  FinancialInsight copyWith({
    String? type,
    String? priority,
    String? title,
    String? description,
    String? action,
    double? confidence,
    String? categoryName,
    double? impactAmount,
  }) {
    return FinancialInsight(
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      action: action ?? this.action,
      confidence: confidence ?? this.confidence,
      categoryName: categoryName ?? this.categoryName,
      impactAmount: impactAmount ?? this.impactAmount,
    );
  }
}

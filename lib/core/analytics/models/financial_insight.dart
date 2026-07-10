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

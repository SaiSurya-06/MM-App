class TransactionTemplate {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final int categoryId;
  final int accountId;

  TransactionTemplate({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'account_id': accountId,
    };
  }

  factory TransactionTemplate.fromMap(Map<String, dynamic> map) {
    return TransactionTemplate(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      accountId: map['account_id'] as int,
    );
  }

  TransactionTemplate copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    int? accountId,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
    );
  }
}

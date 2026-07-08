import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    int? id,
    @JsonKey(name: 'account_id') required int accountId,
    @JsonKey(name: 'category_id') required int categoryId,
    required String title,
    required double amount,
    required String type,
    required DateTime date,
    String? note,
    @Default('none') String recurrence,
    @JsonKey(name: 'recurrence_end_date') DateTime? recurrenceEndDate,
    @JsonKey(name: 'is_private') required bool isPrivate,
    @Default('') String tags,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'transfer_to_account_id') int? transferToAccountId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  Map<String, dynamic> toMap() {
    final map = toJson();
    map['is_private'] = isPrivate ? 1 : 0;
    map['date'] = date.toIso8601String().substring(0, 10);
    if (recurrenceEndDate != null) {
      map['recurrence_end_date'] = recurrenceEndDate!.toIso8601String().substring(0, 10);
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final adjustedMap = Map<String, dynamic>.from(map);
    adjustedMap['is_private'] = (map['is_private'] as int) == 1;
    adjustedMap['amount'] = ((map['amount'] as num).toDouble() * 100.0).roundToDouble() / 100.0;
    return Transaction.fromJson(adjustedMap);
  }
}

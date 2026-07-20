import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const Account._();

  const factory Account({
    int? id,
    required String name,
    required String type,
    required double balance,
    required String icon,
    required String color,
    @JsonKey(name: 'is_shared') required bool isShared,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'limit_amount') double? limitAmount,
  }) = _Account;

  double get pendingPayment => type == 'Credit Card' ? (balance < 0 ? -balance : 0.0) : 0.0;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

  Map<String, dynamic> toMap() {
    final map = toJson();
    map['is_shared'] = isShared ? 1 : 0;
    return map;
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final adjustedMap = Map<String, dynamic>.from(map);
    adjustedMap['is_shared'] = map['is_shared'] == 1 || map['is_shared'] == true;
    adjustedMap['balance'] = map['balance'] != null 
        ? (((map['balance'] as num).toDouble() * 100.0).roundToDouble() / 100.0)
        : 0.0;
    if (map['limit_amount'] != null) {
      adjustedMap['limit_amount'] = ((map['limit_amount'] as num).toDouble() * 100.0).roundToDouble() / 100.0;
    }
    if (map['created_at'] == null) {
      adjustedMap['created_at'] = DateTime.now().toIso8601String();
    }
    return Account.fromJson(adjustedMap);
  }
}

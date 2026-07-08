import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    int? id,
    @JsonKey(name: 'category_id') required int categoryId,
    required String month,
    @JsonKey(name: 'limit_amount') required double limitAmount,
    @Default('monthly') String recurrence,
    @JsonKey(name: 'group_name') String? groupName,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  Map<String, dynamic> toMap() => toJson();
  factory Budget.fromMap(Map<String, dynamic> map) => Budget.fromJson(map);
}

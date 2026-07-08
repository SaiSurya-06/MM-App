import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    int? id,
    required String name,
    required String icon,
    required String color,
    @JsonKey(name: 'is_default') required bool isDefault,
    @Default('both') String type,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'spending_limit') double? spendingLimit,
    @JsonKey(name: 'dark_color') String? darkColor,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  Map<String, dynamic> toMap() {
    final map = toJson();
    map['is_default'] = isDefault ? 1 : 0;
    return map;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final adjustedMap = Map<String, dynamic>.from(map);
    adjustedMap['is_default'] = (map['is_default'] as int) == 1;
    return Category.fromJson(adjustedMap);
  }
}

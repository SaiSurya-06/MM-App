// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetImpl _$$BudgetImplFromJson(Map<String, dynamic> json) => _$BudgetImpl(
      id: (json['id'] as num?)?.toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      month: json['month'] as String,
      limitAmount: (json['limit_amount'] as num).toDouble(),
      recurrence: json['recurrence'] as String? ?? 'monthly',
      groupName: json['group_name'] as String?,
    );

Map<String, dynamic> _$$BudgetImplToJson(_$BudgetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'month': instance.month,
      'limit_amount': instance.limitAmount,
      'recurrence': instance.recurrence,
      'group_name': instance.groupName,
    };

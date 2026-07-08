// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: (json['id'] as num?)?.toInt(),
      accountId: (json['account_id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      recurrence: json['recurrence'] as String? ?? 'none',
      recurrenceEndDate: json['recurrence_end_date'] == null
          ? null
          : DateTime.parse(json['recurrence_end_date'] as String),
      isPrivate: json['is_private'] as bool,
      tags: json['tags'] as String? ?? '',
      parentId: (json['parent_id'] as num?)?.toInt(),
      transferToAccountId: (json['transfer_to_account_id'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      subcategoryId: (json['subcategory_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'amount': instance.amount,
      'type': instance.type,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'recurrence': instance.recurrence,
      'recurrence_end_date': instance.recurrenceEndDate?.toIso8601String(),
      'is_private': instance.isPrivate,
      'tags': instance.tags,
      'parent_id': instance.parentId,
      'transfer_to_account_id': instance.transferToAccountId,
      'created_at': instance.createdAt.toIso8601String(),
      'subcategory_id': instance.subcategoryId,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDefault: json['is_default'] as bool,
      type: json['type'] as String? ?? 'both',
      parentId: (json['parent_id'] as num?)?.toInt(),
      spendingLimit: (json['spending_limit'] as num?)?.toDouble(),
      darkColor: json['dark_color'] as String?,
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'is_default': instance.isDefault,
      'type': instance.type,
      'parent_id': instance.parentId,
      'spending_limit': instance.spendingLimit,
      'dark_color': instance.darkColor,
    };

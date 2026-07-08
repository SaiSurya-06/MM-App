// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'account_id')
  int get accountId => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  int get categoryId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String get recurrence => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_end_date')
  DateTime? get recurrenceEndDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_private')
  bool get isPrivate => throw _privateConstructorUsedError;
  String get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  int? get parentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'transfer_to_account_id')
  int? get transferToAccountId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'subcategory_id')
  int? get subcategoryId => throw _privateConstructorUsedError;

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
          Transaction value, $Res Function(Transaction) then) =
      _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'account_id') int accountId,
      @JsonKey(name: 'category_id') int categoryId,
      String title,
      double amount,
      String type,
      DateTime date,
      String? note,
      String recurrence,
      @JsonKey(name: 'recurrence_end_date') DateTime? recurrenceEndDate,
      @JsonKey(name: 'is_private') bool isPrivate,
      String tags,
      @JsonKey(name: 'parent_id') int? parentId,
      @JsonKey(name: 'transfer_to_account_id') int? transferToAccountId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'subcategory_id') int? subcategoryId});
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? accountId = null,
    Object? categoryId = null,
    Object? title = null,
    Object? amount = null,
    Object? type = null,
    Object? date = null,
    Object? note = freezed,
    Object? recurrence = null,
    Object? recurrenceEndDate = freezed,
    Object? isPrivate = null,
    Object? tags = null,
    Object? parentId = freezed,
    Object? transferToAccountId = freezed,
    Object? createdAt = null,
    Object? subcategoryId = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as int,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: null == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceEndDate: freezed == recurrenceEndDate
          ? _value.recurrenceEndDate
          : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      transferToAccountId: freezed == transferToAccountId
          ? _value.transferToAccountId
          : transferToAccountId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      subcategoryId: freezed == subcategoryId
          ? _value.subcategoryId
          : subcategoryId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
          _$TransactionImpl value, $Res Function(_$TransactionImpl) then) =
      __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'account_id') int accountId,
      @JsonKey(name: 'category_id') int categoryId,
      String title,
      double amount,
      String type,
      DateTime date,
      String? note,
      String recurrence,
      @JsonKey(name: 'recurrence_end_date') DateTime? recurrenceEndDate,
      @JsonKey(name: 'is_private') bool isPrivate,
      String tags,
      @JsonKey(name: 'parent_id') int? parentId,
      @JsonKey(name: 'transfer_to_account_id') int? transferToAccountId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'subcategory_id') int? subcategoryId});
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
      _$TransactionImpl _value, $Res Function(_$TransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? accountId = null,
    Object? categoryId = null,
    Object? title = null,
    Object? amount = null,
    Object? type = null,
    Object? date = null,
    Object? note = freezed,
    Object? recurrence = null,
    Object? recurrenceEndDate = freezed,
    Object? isPrivate = null,
    Object? tags = null,
    Object? parentId = freezed,
    Object? transferToAccountId = freezed,
    Object? createdAt = null,
    Object? subcategoryId = freezed,
  }) {
    return _then(_$TransactionImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as int,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: null == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceEndDate: freezed == recurrenceEndDate
          ? _value.recurrenceEndDate
          : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      transferToAccountId: freezed == transferToAccountId
          ? _value.transferToAccountId
          : transferToAccountId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      subcategoryId: freezed == subcategoryId
          ? _value.subcategoryId
          : subcategoryId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl extends _Transaction {
  const _$TransactionImpl(
      {this.id,
      @JsonKey(name: 'account_id') required this.accountId,
      @JsonKey(name: 'category_id') required this.categoryId,
      required this.title,
      required this.amount,
      required this.type,
      required this.date,
      this.note,
      this.recurrence = 'none',
      @JsonKey(name: 'recurrence_end_date') this.recurrenceEndDate,
      @JsonKey(name: 'is_private') required this.isPrivate,
      this.tags = '',
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'transfer_to_account_id') this.transferToAccountId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'subcategory_id') this.subcategoryId})
      : super._();

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'account_id')
  final int accountId;
  @override
  @JsonKey(name: 'category_id')
  final int categoryId;
  @override
  final String title;
  @override
  final double amount;
  @override
  final String type;
  @override
  final DateTime date;
  @override
  final String? note;
  @override
  @JsonKey()
  final String recurrence;
  @override
  @JsonKey(name: 'recurrence_end_date')
  final DateTime? recurrenceEndDate;
  @override
  @JsonKey(name: 'is_private')
  final bool isPrivate;
  @override
  @JsonKey()
  final String tags;
  @override
  @JsonKey(name: 'parent_id')
  final int? parentId;
  @override
  @JsonKey(name: 'transfer_to_account_id')
  final int? transferToAccountId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'subcategory_id')
  final int? subcategoryId;

  @override
  String toString() {
    return 'Transaction(id: $id, accountId: $accountId, categoryId: $categoryId, title: $title, amount: $amount, type: $type, date: $date, note: $note, recurrence: $recurrence, recurrenceEndDate: $recurrenceEndDate, isPrivate: $isPrivate, tags: $tags, parentId: $parentId, transferToAccountId: $transferToAccountId, createdAt: $createdAt, subcategoryId: $subcategoryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.recurrence, recurrence) ||
                other.recurrence == recurrence) &&
            (identical(other.recurrenceEndDate, recurrenceEndDate) ||
                other.recurrenceEndDate == recurrenceEndDate) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.tags, tags) || other.tags == tags) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.transferToAccountId, transferToAccountId) ||
                other.transferToAccountId == transferToAccountId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.subcategoryId, subcategoryId) ||
                other.subcategoryId == subcategoryId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      accountId,
      categoryId,
      title,
      amount,
      type,
      date,
      note,
      recurrence,
      recurrenceEndDate,
      isPrivate,
      tags,
      parentId,
      transferToAccountId,
      createdAt,
      subcategoryId);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(
      this,
    );
  }
}

abstract class _Transaction extends Transaction {
  const factory _Transaction(
      {final int? id,
      @JsonKey(name: 'account_id') required final int accountId,
      @JsonKey(name: 'category_id') required final int categoryId,
      required final String title,
      required final double amount,
      required final String type,
      required final DateTime date,
      final String? note,
      final String recurrence,
      @JsonKey(name: 'recurrence_end_date') final DateTime? recurrenceEndDate,
      @JsonKey(name: 'is_private') required final bool isPrivate,
      final String tags,
      @JsonKey(name: 'parent_id') final int? parentId,
      @JsonKey(name: 'transfer_to_account_id') final int? transferToAccountId,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'subcategory_id')
      final int? subcategoryId}) = _$TransactionImpl;
  const _Transaction._() : super._();

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'account_id')
  int get accountId;
  @override
  @JsonKey(name: 'category_id')
  int get categoryId;
  @override
  String get title;
  @override
  double get amount;
  @override
  String get type;
  @override
  DateTime get date;
  @override
  String? get note;
  @override
  String get recurrence;
  @override
  @JsonKey(name: 'recurrence_end_date')
  DateTime? get recurrenceEndDate;
  @override
  @JsonKey(name: 'is_private')
  bool get isPrivate;
  @override
  String get tags;
  @override
  @JsonKey(name: 'parent_id')
  int? get parentId;
  @override
  @JsonKey(name: 'transfer_to_account_id')
  int? get transferToAccountId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'subcategory_id')
  int? get subcategoryId;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

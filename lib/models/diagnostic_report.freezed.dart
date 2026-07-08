// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GoalFundingResult _$GoalFundingResultFromJson(Map<String, dynamic> json) {
  return _GoalFundingResult.fromJson(json);
}

/// @nodoc
mixin _$GoalFundingResult {
  String get name => throw _privateConstructorUsedError;
  double get targetAmount => throw _privateConstructorUsedError;
  int get yearsNeeded => throw _privateConstructorUsedError;
  double get projectedSavings => throw _privateConstructorUsedError;
  double get fundingGap => throw _privateConstructorUsedError;

  /// Serializes this GoalFundingResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalFundingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalFundingResultCopyWith<GoalFundingResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalFundingResultCopyWith<$Res> {
  factory $GoalFundingResultCopyWith(
          GoalFundingResult value, $Res Function(GoalFundingResult) then) =
      _$GoalFundingResultCopyWithImpl<$Res, GoalFundingResult>;
  @useResult
  $Res call(
      {String name,
      double targetAmount,
      int yearsNeeded,
      double projectedSavings,
      double fundingGap});
}

/// @nodoc
class _$GoalFundingResultCopyWithImpl<$Res, $Val extends GoalFundingResult>
    implements $GoalFundingResultCopyWith<$Res> {
  _$GoalFundingResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalFundingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? targetAmount = null,
    Object? yearsNeeded = null,
    Object? projectedSavings = null,
    Object? fundingGap = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double,
      yearsNeeded: null == yearsNeeded
          ? _value.yearsNeeded
          : yearsNeeded // ignore: cast_nullable_to_non_nullable
              as int,
      projectedSavings: null == projectedSavings
          ? _value.projectedSavings
          : projectedSavings // ignore: cast_nullable_to_non_nullable
              as double,
      fundingGap: null == fundingGap
          ? _value.fundingGap
          : fundingGap // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalFundingResultImplCopyWith<$Res>
    implements $GoalFundingResultCopyWith<$Res> {
  factory _$$GoalFundingResultImplCopyWith(_$GoalFundingResultImpl value,
          $Res Function(_$GoalFundingResultImpl) then) =
      __$$GoalFundingResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      double targetAmount,
      int yearsNeeded,
      double projectedSavings,
      double fundingGap});
}

/// @nodoc
class __$$GoalFundingResultImplCopyWithImpl<$Res>
    extends _$GoalFundingResultCopyWithImpl<$Res, _$GoalFundingResultImpl>
    implements _$$GoalFundingResultImplCopyWith<$Res> {
  __$$GoalFundingResultImplCopyWithImpl(_$GoalFundingResultImpl _value,
      $Res Function(_$GoalFundingResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of GoalFundingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? targetAmount = null,
    Object? yearsNeeded = null,
    Object? projectedSavings = null,
    Object? fundingGap = null,
  }) {
    return _then(_$GoalFundingResultImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double,
      yearsNeeded: null == yearsNeeded
          ? _value.yearsNeeded
          : yearsNeeded // ignore: cast_nullable_to_non_nullable
              as int,
      projectedSavings: null == projectedSavings
          ? _value.projectedSavings
          : projectedSavings // ignore: cast_nullable_to_non_nullable
              as double,
      fundingGap: null == fundingGap
          ? _value.fundingGap
          : fundingGap // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalFundingResultImpl implements _GoalFundingResult {
  const _$GoalFundingResultImpl(
      {required this.name,
      required this.targetAmount,
      required this.yearsNeeded,
      required this.projectedSavings,
      required this.fundingGap});

  factory _$GoalFundingResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalFundingResultImplFromJson(json);

  @override
  final String name;
  @override
  final double targetAmount;
  @override
  final int yearsNeeded;
  @override
  final double projectedSavings;
  @override
  final double fundingGap;

  @override
  String toString() {
    return 'GoalFundingResult(name: $name, targetAmount: $targetAmount, yearsNeeded: $yearsNeeded, projectedSavings: $projectedSavings, fundingGap: $fundingGap)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalFundingResultImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.yearsNeeded, yearsNeeded) ||
                other.yearsNeeded == yearsNeeded) &&
            (identical(other.projectedSavings, projectedSavings) ||
                other.projectedSavings == projectedSavings) &&
            (identical(other.fundingGap, fundingGap) ||
                other.fundingGap == fundingGap));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, targetAmount, yearsNeeded,
      projectedSavings, fundingGap);

  /// Create a copy of GoalFundingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalFundingResultImplCopyWith<_$GoalFundingResultImpl> get copyWith =>
      __$$GoalFundingResultImplCopyWithImpl<_$GoalFundingResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalFundingResultImplToJson(
      this,
    );
  }
}

abstract class _GoalFundingResult implements GoalFundingResult {
  const factory _GoalFundingResult(
      {required final String name,
      required final double targetAmount,
      required final int yearsNeeded,
      required final double projectedSavings,
      required final double fundingGap}) = _$GoalFundingResultImpl;

  factory _GoalFundingResult.fromJson(Map<String, dynamic> json) =
      _$GoalFundingResultImpl.fromJson;

  @override
  String get name;
  @override
  double get targetAmount;
  @override
  int get yearsNeeded;
  @override
  double get projectedSavings;
  @override
  double get fundingGap;

  /// Create a copy of GoalFundingResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalFundingResultImplCopyWith<_$GoalFundingResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CashFlowBreakdown _$CashFlowBreakdownFromJson(Map<String, dynamic> json) {
  return _CashFlowBreakdown.fromJson(json);
}

/// @nodoc
mixin _$CashFlowBreakdown {
  String get category => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;

  /// Serializes this CashFlowBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CashFlowBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CashFlowBreakdownCopyWith<CashFlowBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CashFlowBreakdownCopyWith<$Res> {
  factory $CashFlowBreakdownCopyWith(
          CashFlowBreakdown value, $Res Function(CashFlowBreakdown) then) =
      _$CashFlowBreakdownCopyWithImpl<$Res, CashFlowBreakdown>;
  @useResult
  $Res call({String category, double amount, double percentage});
}

/// @nodoc
class _$CashFlowBreakdownCopyWithImpl<$Res, $Val extends CashFlowBreakdown>
    implements $CashFlowBreakdownCopyWith<$Res> {
  _$CashFlowBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CashFlowBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? amount = null,
    Object? percentage = null,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CashFlowBreakdownImplCopyWith<$Res>
    implements $CashFlowBreakdownCopyWith<$Res> {
  factory _$$CashFlowBreakdownImplCopyWith(_$CashFlowBreakdownImpl value,
          $Res Function(_$CashFlowBreakdownImpl) then) =
      __$$CashFlowBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String category, double amount, double percentage});
}

/// @nodoc
class __$$CashFlowBreakdownImplCopyWithImpl<$Res>
    extends _$CashFlowBreakdownCopyWithImpl<$Res, _$CashFlowBreakdownImpl>
    implements _$$CashFlowBreakdownImplCopyWith<$Res> {
  __$$CashFlowBreakdownImplCopyWithImpl(_$CashFlowBreakdownImpl _value,
      $Res Function(_$CashFlowBreakdownImpl) _then)
      : super(_value, _then);

  /// Create a copy of CashFlowBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? amount = null,
    Object? percentage = null,
  }) {
    return _then(_$CashFlowBreakdownImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CashFlowBreakdownImpl implements _CashFlowBreakdown {
  const _$CashFlowBreakdownImpl(
      {required this.category, required this.amount, required this.percentage});

  factory _$CashFlowBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$CashFlowBreakdownImplFromJson(json);

  @override
  final String category;
  @override
  final double amount;
  @override
  final double percentage;

  @override
  String toString() {
    return 'CashFlowBreakdown(category: $category, amount: $amount, percentage: $percentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CashFlowBreakdownImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, category, amount, percentage);

  /// Create a copy of CashFlowBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CashFlowBreakdownImplCopyWith<_$CashFlowBreakdownImpl> get copyWith =>
      __$$CashFlowBreakdownImplCopyWithImpl<_$CashFlowBreakdownImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CashFlowBreakdownImplToJson(
      this,
    );
  }
}

abstract class _CashFlowBreakdown implements CashFlowBreakdown {
  const factory _CashFlowBreakdown(
      {required final String category,
      required final double amount,
      required final double percentage}) = _$CashFlowBreakdownImpl;

  factory _CashFlowBreakdown.fromJson(Map<String, dynamic> json) =
      _$CashFlowBreakdownImpl.fromJson;

  @override
  String get category;
  @override
  double get amount;
  @override
  double get percentage;

  /// Create a copy of CashFlowBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CashFlowBreakdownImplCopyWith<_$CashFlowBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActionItem _$ActionItemFromJson(Map<String, dynamic> json) {
  return _ActionItem.fromJson(json);
}

/// @nodoc
mixin _$ActionItem {
  int get priority => throw _privateConstructorUsedError; // 1 = most urgent
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  ActionCategory get category =>
      throw _privateConstructorUsedError; // protection, debt, savings, emergency, goal
  double? get monetaryTarget => throw _privateConstructorUsedError;
  int? get timelineMonths => throw _privateConstructorUsedError;

  /// Serializes this ActionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionItemCopyWith<ActionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionItemCopyWith<$Res> {
  factory $ActionItemCopyWith(
          ActionItem value, $Res Function(ActionItem) then) =
      _$ActionItemCopyWithImpl<$Res, ActionItem>;
  @useResult
  $Res call(
      {int priority,
      String title,
      String description,
      ActionCategory category,
      double? monetaryTarget,
      int? timelineMonths});
}

/// @nodoc
class _$ActionItemCopyWithImpl<$Res, $Val extends ActionItem>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? priority = null,
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? monetaryTarget = freezed,
    Object? timelineMonths = freezed,
  }) {
    return _then(_value.copyWith(
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ActionCategory,
      monetaryTarget: freezed == monetaryTarget
          ? _value.monetaryTarget
          : monetaryTarget // ignore: cast_nullable_to_non_nullable
              as double?,
      timelineMonths: freezed == timelineMonths
          ? _value.timelineMonths
          : timelineMonths // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActionItemImplCopyWith<$Res>
    implements $ActionItemCopyWith<$Res> {
  factory _$$ActionItemImplCopyWith(
          _$ActionItemImpl value, $Res Function(_$ActionItemImpl) then) =
      __$$ActionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int priority,
      String title,
      String description,
      ActionCategory category,
      double? monetaryTarget,
      int? timelineMonths});
}

/// @nodoc
class __$$ActionItemImplCopyWithImpl<$Res>
    extends _$ActionItemCopyWithImpl<$Res, _$ActionItemImpl>
    implements _$$ActionItemImplCopyWith<$Res> {
  __$$ActionItemImplCopyWithImpl(
      _$ActionItemImpl _value, $Res Function(_$ActionItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? priority = null,
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? monetaryTarget = freezed,
    Object? timelineMonths = freezed,
  }) {
    return _then(_$ActionItemImpl(
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ActionCategory,
      monetaryTarget: freezed == monetaryTarget
          ? _value.monetaryTarget
          : monetaryTarget // ignore: cast_nullable_to_non_nullable
              as double?,
      timelineMonths: freezed == timelineMonths
          ? _value.timelineMonths
          : timelineMonths // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActionItemImpl implements _ActionItem {
  const _$ActionItemImpl(
      {required this.priority,
      required this.title,
      required this.description,
      required this.category,
      this.monetaryTarget,
      this.timelineMonths});

  factory _$ActionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActionItemImplFromJson(json);

  @override
  final int priority;
// 1 = most urgent
  @override
  final String title;
  @override
  final String description;
  @override
  final ActionCategory category;
// protection, debt, savings, emergency, goal
  @override
  final double? monetaryTarget;
  @override
  final int? timelineMonths;

  @override
  String toString() {
    return 'ActionItem(priority: $priority, title: $title, description: $description, category: $category, monetaryTarget: $monetaryTarget, timelineMonths: $timelineMonths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionItemImpl &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.monetaryTarget, monetaryTarget) ||
                other.monetaryTarget == monetaryTarget) &&
            (identical(other.timelineMonths, timelineMonths) ||
                other.timelineMonths == timelineMonths));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, priority, title, description,
      category, monetaryTarget, timelineMonths);

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      __$$ActionItemImplCopyWithImpl<_$ActionItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActionItemImplToJson(
      this,
    );
  }
}

abstract class _ActionItem implements ActionItem {
  const factory _ActionItem(
      {required final int priority,
      required final String title,
      required final String description,
      required final ActionCategory category,
      final double? monetaryTarget,
      final int? timelineMonths}) = _$ActionItemImpl;

  factory _ActionItem.fromJson(Map<String, dynamic> json) =
      _$ActionItemImpl.fromJson;

  @override
  int get priority; // 1 = most urgent
  @override
  String get title;
  @override
  String get description;
  @override
  ActionCategory get category; // protection, debt, savings, emergency, goal
  @override
  double? get monetaryTarget;
  @override
  int? get timelineMonths;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiagnosticReport _$DiagnosticReportFromJson(Map<String, dynamic> json) {
  return _DiagnosticReport.fromJson(json);
}

/// @nodoc
mixin _$DiagnosticReport {
  DiagnosticVerdict get verdict =>
      throw _privateConstructorUsedError; // overall health category
  double get monthlySurplus => throw _privateConstructorUsedError;
  double get netWorth => throw _privateConstructorUsedError;
  int get emergencyFundTargetMonths => throw _privateConstructorUsedError;
  double get emergencyFundTarget =>
      throw _privateConstructorUsedError; // in currency units
  double get emergencyFundGap => throw _privateConstructorUsedError;
  double get termCoverGap => throw _privateConstructorUsedError;
  double get healthCoverGap => throw _privateConstructorUsedError;
  @DebtPayoffResultConverter()
  DebtPayoffResult get debtPayoff => throw _privateConstructorUsedError;
  List<GoalFundingResult> get goalFunding => throw _privateConstructorUsedError;
  List<CashFlowBreakdown> get cashFlowBreakdown =>
      throw _privateConstructorUsedError; // for donut chart
  List<ActionItem> get checklist => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Serializes this DiagnosticReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiagnosticReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagnosticReportCopyWith<DiagnosticReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticReportCopyWith<$Res> {
  factory $DiagnosticReportCopyWith(
          DiagnosticReport value, $Res Function(DiagnosticReport) then) =
      _$DiagnosticReportCopyWithImpl<$Res, DiagnosticReport>;
  @useResult
  $Res call(
      {DiagnosticVerdict verdict,
      double monthlySurplus,
      double netWorth,
      int emergencyFundTargetMonths,
      double emergencyFundTarget,
      double emergencyFundGap,
      double termCoverGap,
      double healthCoverGap,
      @DebtPayoffResultConverter() DebtPayoffResult debtPayoff,
      List<GoalFundingResult> goalFunding,
      List<CashFlowBreakdown> cashFlowBreakdown,
      List<ActionItem> checklist,
      DateTime generatedAt});
}

/// @nodoc
class _$DiagnosticReportCopyWithImpl<$Res, $Val extends DiagnosticReport>
    implements $DiagnosticReportCopyWith<$Res> {
  _$DiagnosticReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagnosticReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? verdict = null,
    Object? monthlySurplus = null,
    Object? netWorth = null,
    Object? emergencyFundTargetMonths = null,
    Object? emergencyFundTarget = null,
    Object? emergencyFundGap = null,
    Object? termCoverGap = null,
    Object? healthCoverGap = null,
    Object? debtPayoff = null,
    Object? goalFunding = null,
    Object? cashFlowBreakdown = null,
    Object? checklist = null,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      verdict: null == verdict
          ? _value.verdict
          : verdict // ignore: cast_nullable_to_non_nullable
              as DiagnosticVerdict,
      monthlySurplus: null == monthlySurplus
          ? _value.monthlySurplus
          : monthlySurplus // ignore: cast_nullable_to_non_nullable
              as double,
      netWorth: null == netWorth
          ? _value.netWorth
          : netWorth // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundTargetMonths: null == emergencyFundTargetMonths
          ? _value.emergencyFundTargetMonths
          : emergencyFundTargetMonths // ignore: cast_nullable_to_non_nullable
              as int,
      emergencyFundTarget: null == emergencyFundTarget
          ? _value.emergencyFundTarget
          : emergencyFundTarget // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundGap: null == emergencyFundGap
          ? _value.emergencyFundGap
          : emergencyFundGap // ignore: cast_nullable_to_non_nullable
              as double,
      termCoverGap: null == termCoverGap
          ? _value.termCoverGap
          : termCoverGap // ignore: cast_nullable_to_non_nullable
              as double,
      healthCoverGap: null == healthCoverGap
          ? _value.healthCoverGap
          : healthCoverGap // ignore: cast_nullable_to_non_nullable
              as double,
      debtPayoff: null == debtPayoff
          ? _value.debtPayoff
          : debtPayoff // ignore: cast_nullable_to_non_nullable
              as DebtPayoffResult,
      goalFunding: null == goalFunding
          ? _value.goalFunding
          : goalFunding // ignore: cast_nullable_to_non_nullable
              as List<GoalFundingResult>,
      cashFlowBreakdown: null == cashFlowBreakdown
          ? _value.cashFlowBreakdown
          : cashFlowBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CashFlowBreakdown>,
      checklist: null == checklist
          ? _value.checklist
          : checklist // ignore: cast_nullable_to_non_nullable
              as List<ActionItem>,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagnosticReportImplCopyWith<$Res>
    implements $DiagnosticReportCopyWith<$Res> {
  factory _$$DiagnosticReportImplCopyWith(_$DiagnosticReportImpl value,
          $Res Function(_$DiagnosticReportImpl) then) =
      __$$DiagnosticReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DiagnosticVerdict verdict,
      double monthlySurplus,
      double netWorth,
      int emergencyFundTargetMonths,
      double emergencyFundTarget,
      double emergencyFundGap,
      double termCoverGap,
      double healthCoverGap,
      @DebtPayoffResultConverter() DebtPayoffResult debtPayoff,
      List<GoalFundingResult> goalFunding,
      List<CashFlowBreakdown> cashFlowBreakdown,
      List<ActionItem> checklist,
      DateTime generatedAt});
}

/// @nodoc
class __$$DiagnosticReportImplCopyWithImpl<$Res>
    extends _$DiagnosticReportCopyWithImpl<$Res, _$DiagnosticReportImpl>
    implements _$$DiagnosticReportImplCopyWith<$Res> {
  __$$DiagnosticReportImplCopyWithImpl(_$DiagnosticReportImpl _value,
      $Res Function(_$DiagnosticReportImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagnosticReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? verdict = null,
    Object? monthlySurplus = null,
    Object? netWorth = null,
    Object? emergencyFundTargetMonths = null,
    Object? emergencyFundTarget = null,
    Object? emergencyFundGap = null,
    Object? termCoverGap = null,
    Object? healthCoverGap = null,
    Object? debtPayoff = null,
    Object? goalFunding = null,
    Object? cashFlowBreakdown = null,
    Object? checklist = null,
    Object? generatedAt = null,
  }) {
    return _then(_$DiagnosticReportImpl(
      verdict: null == verdict
          ? _value.verdict
          : verdict // ignore: cast_nullable_to_non_nullable
              as DiagnosticVerdict,
      monthlySurplus: null == monthlySurplus
          ? _value.monthlySurplus
          : monthlySurplus // ignore: cast_nullable_to_non_nullable
              as double,
      netWorth: null == netWorth
          ? _value.netWorth
          : netWorth // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundTargetMonths: null == emergencyFundTargetMonths
          ? _value.emergencyFundTargetMonths
          : emergencyFundTargetMonths // ignore: cast_nullable_to_non_nullable
              as int,
      emergencyFundTarget: null == emergencyFundTarget
          ? _value.emergencyFundTarget
          : emergencyFundTarget // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundGap: null == emergencyFundGap
          ? _value.emergencyFundGap
          : emergencyFundGap // ignore: cast_nullable_to_non_nullable
              as double,
      termCoverGap: null == termCoverGap
          ? _value.termCoverGap
          : termCoverGap // ignore: cast_nullable_to_non_nullable
              as double,
      healthCoverGap: null == healthCoverGap
          ? _value.healthCoverGap
          : healthCoverGap // ignore: cast_nullable_to_non_nullable
              as double,
      debtPayoff: null == debtPayoff
          ? _value.debtPayoff
          : debtPayoff // ignore: cast_nullable_to_non_nullable
              as DebtPayoffResult,
      goalFunding: null == goalFunding
          ? _value._goalFunding
          : goalFunding // ignore: cast_nullable_to_non_nullable
              as List<GoalFundingResult>,
      cashFlowBreakdown: null == cashFlowBreakdown
          ? _value._cashFlowBreakdown
          : cashFlowBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CashFlowBreakdown>,
      checklist: null == checklist
          ? _value._checklist
          : checklist // ignore: cast_nullable_to_non_nullable
              as List<ActionItem>,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiagnosticReportImpl implements _DiagnosticReport {
  const _$DiagnosticReportImpl(
      {required this.verdict,
      required this.monthlySurplus,
      required this.netWorth,
      required this.emergencyFundTargetMonths,
      required this.emergencyFundTarget,
      required this.emergencyFundGap,
      required this.termCoverGap,
      required this.healthCoverGap,
      @DebtPayoffResultConverter() required this.debtPayoff,
      required final List<GoalFundingResult> goalFunding,
      required final List<CashFlowBreakdown> cashFlowBreakdown,
      required final List<ActionItem> checklist,
      required this.generatedAt})
      : _goalFunding = goalFunding,
        _cashFlowBreakdown = cashFlowBreakdown,
        _checklist = checklist;

  factory _$DiagnosticReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiagnosticReportImplFromJson(json);

  @override
  final DiagnosticVerdict verdict;
// overall health category
  @override
  final double monthlySurplus;
  @override
  final double netWorth;
  @override
  final int emergencyFundTargetMonths;
  @override
  final double emergencyFundTarget;
// in currency units
  @override
  final double emergencyFundGap;
  @override
  final double termCoverGap;
  @override
  final double healthCoverGap;
  @override
  @DebtPayoffResultConverter()
  final DebtPayoffResult debtPayoff;
  final List<GoalFundingResult> _goalFunding;
  @override
  List<GoalFundingResult> get goalFunding {
    if (_goalFunding is EqualUnmodifiableListView) return _goalFunding;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalFunding);
  }

  final List<CashFlowBreakdown> _cashFlowBreakdown;
  @override
  List<CashFlowBreakdown> get cashFlowBreakdown {
    if (_cashFlowBreakdown is EqualUnmodifiableListView)
      return _cashFlowBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cashFlowBreakdown);
  }

// for donut chart
  final List<ActionItem> _checklist;
// for donut chart
  @override
  List<ActionItem> get checklist {
    if (_checklist is EqualUnmodifiableListView) return _checklist;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checklist);
  }

  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'DiagnosticReport(verdict: $verdict, monthlySurplus: $monthlySurplus, netWorth: $netWorth, emergencyFundTargetMonths: $emergencyFundTargetMonths, emergencyFundTarget: $emergencyFundTarget, emergencyFundGap: $emergencyFundGap, termCoverGap: $termCoverGap, healthCoverGap: $healthCoverGap, debtPayoff: $debtPayoff, goalFunding: $goalFunding, cashFlowBreakdown: $cashFlowBreakdown, checklist: $checklist, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticReportImpl &&
            (identical(other.verdict, verdict) || other.verdict == verdict) &&
            (identical(other.monthlySurplus, monthlySurplus) ||
                other.monthlySurplus == monthlySurplus) &&
            (identical(other.netWorth, netWorth) ||
                other.netWorth == netWorth) &&
            (identical(other.emergencyFundTargetMonths,
                    emergencyFundTargetMonths) ||
                other.emergencyFundTargetMonths == emergencyFundTargetMonths) &&
            (identical(other.emergencyFundTarget, emergencyFundTarget) ||
                other.emergencyFundTarget == emergencyFundTarget) &&
            (identical(other.emergencyFundGap, emergencyFundGap) ||
                other.emergencyFundGap == emergencyFundGap) &&
            (identical(other.termCoverGap, termCoverGap) ||
                other.termCoverGap == termCoverGap) &&
            (identical(other.healthCoverGap, healthCoverGap) ||
                other.healthCoverGap == healthCoverGap) &&
            (identical(other.debtPayoff, debtPayoff) ||
                other.debtPayoff == debtPayoff) &&
            const DeepCollectionEquality()
                .equals(other._goalFunding, _goalFunding) &&
            const DeepCollectionEquality()
                .equals(other._cashFlowBreakdown, _cashFlowBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._checklist, _checklist) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      verdict,
      monthlySurplus,
      netWorth,
      emergencyFundTargetMonths,
      emergencyFundTarget,
      emergencyFundGap,
      termCoverGap,
      healthCoverGap,
      debtPayoff,
      const DeepCollectionEquality().hash(_goalFunding),
      const DeepCollectionEquality().hash(_cashFlowBreakdown),
      const DeepCollectionEquality().hash(_checklist),
      generatedAt);

  /// Create a copy of DiagnosticReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticReportImplCopyWith<_$DiagnosticReportImpl> get copyWith =>
      __$$DiagnosticReportImplCopyWithImpl<_$DiagnosticReportImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiagnosticReportImplToJson(
      this,
    );
  }
}

abstract class _DiagnosticReport implements DiagnosticReport {
  const factory _DiagnosticReport(
      {required final DiagnosticVerdict verdict,
      required final double monthlySurplus,
      required final double netWorth,
      required final int emergencyFundTargetMonths,
      required final double emergencyFundTarget,
      required final double emergencyFundGap,
      required final double termCoverGap,
      required final double healthCoverGap,
      @DebtPayoffResultConverter() required final DebtPayoffResult debtPayoff,
      required final List<GoalFundingResult> goalFunding,
      required final List<CashFlowBreakdown> cashFlowBreakdown,
      required final List<ActionItem> checklist,
      required final DateTime generatedAt}) = _$DiagnosticReportImpl;

  factory _DiagnosticReport.fromJson(Map<String, dynamic> json) =
      _$DiagnosticReportImpl.fromJson;

  @override
  DiagnosticVerdict get verdict; // overall health category
  @override
  double get monthlySurplus;
  @override
  double get netWorth;
  @override
  int get emergencyFundTargetMonths;
  @override
  double get emergencyFundTarget; // in currency units
  @override
  double get emergencyFundGap;
  @override
  double get termCoverGap;
  @override
  double get healthCoverGap;
  @override
  @DebtPayoffResultConverter()
  DebtPayoffResult get debtPayoff;
  @override
  List<GoalFundingResult> get goalFunding;
  @override
  List<CashFlowBreakdown> get cashFlowBreakdown; // for donut chart
  @override
  List<ActionItem> get checklist;
  @override
  DateTime get generatedAt;

  /// Create a copy of DiagnosticReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagnosticReportImplCopyWith<_$DiagnosticReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

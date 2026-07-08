// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LumpSumExpense _$LumpSumExpenseFromJson(Map<String, dynamic> json) {
  return _LumpSumExpense.fromJson(json);
}

/// @nodoc
mixin _$LumpSumExpense {
  String get label => throw _privateConstructorUsedError;
  int get yearsFromNow => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;

  /// Serializes this LumpSumExpense to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LumpSumExpense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LumpSumExpenseCopyWith<LumpSumExpense> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LumpSumExpenseCopyWith<$Res> {
  factory $LumpSumExpenseCopyWith(
          LumpSumExpense value, $Res Function(LumpSumExpense) then) =
      _$LumpSumExpenseCopyWithImpl<$Res, LumpSumExpense>;
  @useResult
  $Res call({String label, int yearsFromNow, double amount});
}

/// @nodoc
class _$LumpSumExpenseCopyWithImpl<$Res, $Val extends LumpSumExpense>
    implements $LumpSumExpenseCopyWith<$Res> {
  _$LumpSumExpenseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LumpSumExpense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? yearsFromNow = null,
    Object? amount = null,
  }) {
    return _then(_value.copyWith(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      yearsFromNow: null == yearsFromNow
          ? _value.yearsFromNow
          : yearsFromNow // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LumpSumExpenseImplCopyWith<$Res>
    implements $LumpSumExpenseCopyWith<$Res> {
  factory _$$LumpSumExpenseImplCopyWith(_$LumpSumExpenseImpl value,
          $Res Function(_$LumpSumExpenseImpl) then) =
      __$$LumpSumExpenseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, int yearsFromNow, double amount});
}

/// @nodoc
class __$$LumpSumExpenseImplCopyWithImpl<$Res>
    extends _$LumpSumExpenseCopyWithImpl<$Res, _$LumpSumExpenseImpl>
    implements _$$LumpSumExpenseImplCopyWith<$Res> {
  __$$LumpSumExpenseImplCopyWithImpl(
      _$LumpSumExpenseImpl _value, $Res Function(_$LumpSumExpenseImpl) _then)
      : super(_value, _then);

  /// Create a copy of LumpSumExpense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? yearsFromNow = null,
    Object? amount = null,
  }) {
    return _then(_$LumpSumExpenseImpl(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      yearsFromNow: null == yearsFromNow
          ? _value.yearsFromNow
          : yearsFromNow // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LumpSumExpenseImpl implements _LumpSumExpense {
  const _$LumpSumExpenseImpl(
      {required this.label, required this.yearsFromNow, required this.amount});

  factory _$LumpSumExpenseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LumpSumExpenseImplFromJson(json);

  @override
  final String label;
  @override
  final int yearsFromNow;
  @override
  final double amount;

  @override
  String toString() {
    return 'LumpSumExpense(label: $label, yearsFromNow: $yearsFromNow, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LumpSumExpenseImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.yearsFromNow, yearsFromNow) ||
                other.yearsFromNow == yearsFromNow) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label, yearsFromNow, amount);

  /// Create a copy of LumpSumExpense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LumpSumExpenseImplCopyWith<_$LumpSumExpenseImpl> get copyWith =>
      __$$LumpSumExpenseImplCopyWithImpl<_$LumpSumExpenseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LumpSumExpenseImplToJson(
      this,
    );
  }
}

abstract class _LumpSumExpense implements LumpSumExpense {
  const factory _LumpSumExpense(
      {required final String label,
      required final int yearsFromNow,
      required final double amount}) = _$LumpSumExpenseImpl;

  factory _LumpSumExpense.fromJson(Map<String, dynamic> json) =
      _$LumpSumExpenseImpl.fromJson;

  @override
  String get label;
  @override
  int get yearsFromNow;
  @override
  double get amount;

  /// Create a copy of LumpSumExpense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LumpSumExpenseImplCopyWith<_$LumpSumExpenseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoanEntry _$LoanEntryFromJson(Map<String, dynamic> json) {
  return _LoanEntry.fromJson(json);
}

/// @nodoc
mixin _$LoanEntry {
  LoanType get type => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  double get outstandingPrincipal => throw _privateConstructorUsedError;
  double get monthlyEMI => throw _privateConstructorUsedError;
  double get annualInterestRate => throw _privateConstructorUsedError;
  int get remainingMonths => throw _privateConstructorUsedError;
  bool get isNecessaryDebt => throw _privateConstructorUsedError;

  /// Serializes this LoanEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoanEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoanEntryCopyWith<LoanEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoanEntryCopyWith<$Res> {
  factory $LoanEntryCopyWith(LoanEntry value, $Res Function(LoanEntry) then) =
      _$LoanEntryCopyWithImpl<$Res, LoanEntry>;
  @useResult
  $Res call(
      {LoanType type,
      String label,
      double outstandingPrincipal,
      double monthlyEMI,
      double annualInterestRate,
      int remainingMonths,
      bool isNecessaryDebt});
}

/// @nodoc
class _$LoanEntryCopyWithImpl<$Res, $Val extends LoanEntry>
    implements $LoanEntryCopyWith<$Res> {
  _$LoanEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoanEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? label = null,
    Object? outstandingPrincipal = null,
    Object? monthlyEMI = null,
    Object? annualInterestRate = null,
    Object? remainingMonths = null,
    Object? isNecessaryDebt = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LoanType,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outstandingPrincipal: null == outstandingPrincipal
          ? _value.outstandingPrincipal
          : outstandingPrincipal // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyEMI: null == monthlyEMI
          ? _value.monthlyEMI
          : monthlyEMI // ignore: cast_nullable_to_non_nullable
              as double,
      annualInterestRate: null == annualInterestRate
          ? _value.annualInterestRate
          : annualInterestRate // ignore: cast_nullable_to_non_nullable
              as double,
      remainingMonths: null == remainingMonths
          ? _value.remainingMonths
          : remainingMonths // ignore: cast_nullable_to_non_nullable
              as int,
      isNecessaryDebt: null == isNecessaryDebt
          ? _value.isNecessaryDebt
          : isNecessaryDebt // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoanEntryImplCopyWith<$Res>
    implements $LoanEntryCopyWith<$Res> {
  factory _$$LoanEntryImplCopyWith(
          _$LoanEntryImpl value, $Res Function(_$LoanEntryImpl) then) =
      __$$LoanEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LoanType type,
      String label,
      double outstandingPrincipal,
      double monthlyEMI,
      double annualInterestRate,
      int remainingMonths,
      bool isNecessaryDebt});
}

/// @nodoc
class __$$LoanEntryImplCopyWithImpl<$Res>
    extends _$LoanEntryCopyWithImpl<$Res, _$LoanEntryImpl>
    implements _$$LoanEntryImplCopyWith<$Res> {
  __$$LoanEntryImplCopyWithImpl(
      _$LoanEntryImpl _value, $Res Function(_$LoanEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoanEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? label = null,
    Object? outstandingPrincipal = null,
    Object? monthlyEMI = null,
    Object? annualInterestRate = null,
    Object? remainingMonths = null,
    Object? isNecessaryDebt = null,
  }) {
    return _then(_$LoanEntryImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LoanType,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      outstandingPrincipal: null == outstandingPrincipal
          ? _value.outstandingPrincipal
          : outstandingPrincipal // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyEMI: null == monthlyEMI
          ? _value.monthlyEMI
          : monthlyEMI // ignore: cast_nullable_to_non_nullable
              as double,
      annualInterestRate: null == annualInterestRate
          ? _value.annualInterestRate
          : annualInterestRate // ignore: cast_nullable_to_non_nullable
              as double,
      remainingMonths: null == remainingMonths
          ? _value.remainingMonths
          : remainingMonths // ignore: cast_nullable_to_non_nullable
              as int,
      isNecessaryDebt: null == isNecessaryDebt
          ? _value.isNecessaryDebt
          : isNecessaryDebt // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoanEntryImpl implements _LoanEntry {
  const _$LoanEntryImpl(
      {required this.type,
      required this.label,
      required this.outstandingPrincipal,
      required this.monthlyEMI,
      required this.annualInterestRate,
      required this.remainingMonths,
      required this.isNecessaryDebt});

  factory _$LoanEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoanEntryImplFromJson(json);

  @override
  final LoanType type;
  @override
  final String label;
  @override
  final double outstandingPrincipal;
  @override
  final double monthlyEMI;
  @override
  final double annualInterestRate;
  @override
  final int remainingMonths;
  @override
  final bool isNecessaryDebt;

  @override
  String toString() {
    return 'LoanEntry(type: $type, label: $label, outstandingPrincipal: $outstandingPrincipal, monthlyEMI: $monthlyEMI, annualInterestRate: $annualInterestRate, remainingMonths: $remainingMonths, isNecessaryDebt: $isNecessaryDebt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoanEntryImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.outstandingPrincipal, outstandingPrincipal) ||
                other.outstandingPrincipal == outstandingPrincipal) &&
            (identical(other.monthlyEMI, monthlyEMI) ||
                other.monthlyEMI == monthlyEMI) &&
            (identical(other.annualInterestRate, annualInterestRate) ||
                other.annualInterestRate == annualInterestRate) &&
            (identical(other.remainingMonths, remainingMonths) ||
                other.remainingMonths == remainingMonths) &&
            (identical(other.isNecessaryDebt, isNecessaryDebt) ||
                other.isNecessaryDebt == isNecessaryDebt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      label,
      outstandingPrincipal,
      monthlyEMI,
      annualInterestRate,
      remainingMonths,
      isNecessaryDebt);

  /// Create a copy of LoanEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoanEntryImplCopyWith<_$LoanEntryImpl> get copyWith =>
      __$$LoanEntryImplCopyWithImpl<_$LoanEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoanEntryImplToJson(
      this,
    );
  }
}

abstract class _LoanEntry implements LoanEntry {
  const factory _LoanEntry(
      {required final LoanType type,
      required final String label,
      required final double outstandingPrincipal,
      required final double monthlyEMI,
      required final double annualInterestRate,
      required final int remainingMonths,
      required final bool isNecessaryDebt}) = _$LoanEntryImpl;

  factory _LoanEntry.fromJson(Map<String, dynamic> json) =
      _$LoanEntryImpl.fromJson;

  @override
  LoanType get type;
  @override
  String get label;
  @override
  double get outstandingPrincipal;
  @override
  double get monthlyEMI;
  @override
  double get annualInterestRate;
  @override
  int get remainingMonths;
  @override
  bool get isNecessaryDebt;

  /// Create a copy of LoanEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoanEntryImplCopyWith<_$LoanEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

YouSection _$YouSectionFromJson(Map<String, dynamic> json) {
  return _YouSection.fromJson(json);
}

/// @nodoc
mixin _$YouSection {
  String get name => throw _privateConstructorUsedError;
  int get age => throw _privateConstructorUsedError;
  CityTier get cityTier => throw _privateConstructorUsedError;
  OccupationType get occupation => throw _privateConstructorUsedError;
  IncomeType get incomeType => throw _privateConstructorUsedError;
  JobStability get jobStability => throw _privateConstructorUsedError;
  MaritalStatus get maritalStatus => throw _privateConstructorUsedError;

  /// Serializes this YouSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of YouSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $YouSectionCopyWith<YouSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YouSectionCopyWith<$Res> {
  factory $YouSectionCopyWith(
          YouSection value, $Res Function(YouSection) then) =
      _$YouSectionCopyWithImpl<$Res, YouSection>;
  @useResult
  $Res call(
      {String name,
      int age,
      CityTier cityTier,
      OccupationType occupation,
      IncomeType incomeType,
      JobStability jobStability,
      MaritalStatus maritalStatus});
}

/// @nodoc
class _$YouSectionCopyWithImpl<$Res, $Val extends YouSection>
    implements $YouSectionCopyWith<$Res> {
  _$YouSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of YouSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? age = null,
    Object? cityTier = null,
    Object? occupation = null,
    Object? incomeType = null,
    Object? jobStability = null,
    Object? maritalStatus = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      cityTier: null == cityTier
          ? _value.cityTier
          : cityTier // ignore: cast_nullable_to_non_nullable
              as CityTier,
      occupation: null == occupation
          ? _value.occupation
          : occupation // ignore: cast_nullable_to_non_nullable
              as OccupationType,
      incomeType: null == incomeType
          ? _value.incomeType
          : incomeType // ignore: cast_nullable_to_non_nullable
              as IncomeType,
      jobStability: null == jobStability
          ? _value.jobStability
          : jobStability // ignore: cast_nullable_to_non_nullable
              as JobStability,
      maritalStatus: null == maritalStatus
          ? _value.maritalStatus
          : maritalStatus // ignore: cast_nullable_to_non_nullable
              as MaritalStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$YouSectionImplCopyWith<$Res>
    implements $YouSectionCopyWith<$Res> {
  factory _$$YouSectionImplCopyWith(
          _$YouSectionImpl value, $Res Function(_$YouSectionImpl) then) =
      __$$YouSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      int age,
      CityTier cityTier,
      OccupationType occupation,
      IncomeType incomeType,
      JobStability jobStability,
      MaritalStatus maritalStatus});
}

/// @nodoc
class __$$YouSectionImplCopyWithImpl<$Res>
    extends _$YouSectionCopyWithImpl<$Res, _$YouSectionImpl>
    implements _$$YouSectionImplCopyWith<$Res> {
  __$$YouSectionImplCopyWithImpl(
      _$YouSectionImpl _value, $Res Function(_$YouSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of YouSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? age = null,
    Object? cityTier = null,
    Object? occupation = null,
    Object? incomeType = null,
    Object? jobStability = null,
    Object? maritalStatus = null,
  }) {
    return _then(_$YouSectionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      cityTier: null == cityTier
          ? _value.cityTier
          : cityTier // ignore: cast_nullable_to_non_nullable
              as CityTier,
      occupation: null == occupation
          ? _value.occupation
          : occupation // ignore: cast_nullable_to_non_nullable
              as OccupationType,
      incomeType: null == incomeType
          ? _value.incomeType
          : incomeType // ignore: cast_nullable_to_non_nullable
              as IncomeType,
      jobStability: null == jobStability
          ? _value.jobStability
          : jobStability // ignore: cast_nullable_to_non_nullable
              as JobStability,
      maritalStatus: null == maritalStatus
          ? _value.maritalStatus
          : maritalStatus // ignore: cast_nullable_to_non_nullable
              as MaritalStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$YouSectionImpl implements _YouSection {
  const _$YouSectionImpl(
      {required this.name,
      required this.age,
      required this.cityTier,
      required this.occupation,
      required this.incomeType,
      required this.jobStability,
      required this.maritalStatus});

  factory _$YouSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$YouSectionImplFromJson(json);

  @override
  final String name;
  @override
  final int age;
  @override
  final CityTier cityTier;
  @override
  final OccupationType occupation;
  @override
  final IncomeType incomeType;
  @override
  final JobStability jobStability;
  @override
  final MaritalStatus maritalStatus;

  @override
  String toString() {
    return 'YouSection(name: $name, age: $age, cityTier: $cityTier, occupation: $occupation, incomeType: $incomeType, jobStability: $jobStability, maritalStatus: $maritalStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YouSectionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.cityTier, cityTier) ||
                other.cityTier == cityTier) &&
            (identical(other.occupation, occupation) ||
                other.occupation == occupation) &&
            (identical(other.incomeType, incomeType) ||
                other.incomeType == incomeType) &&
            (identical(other.jobStability, jobStability) ||
                other.jobStability == jobStability) &&
            (identical(other.maritalStatus, maritalStatus) ||
                other.maritalStatus == maritalStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, age, cityTier, occupation,
      incomeType, jobStability, maritalStatus);

  /// Create a copy of YouSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YouSectionImplCopyWith<_$YouSectionImpl> get copyWith =>
      __$$YouSectionImplCopyWithImpl<_$YouSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$YouSectionImplToJson(
      this,
    );
  }
}

abstract class _YouSection implements YouSection {
  const factory _YouSection(
      {required final String name,
      required final int age,
      required final CityTier cityTier,
      required final OccupationType occupation,
      required final IncomeType incomeType,
      required final JobStability jobStability,
      required final MaritalStatus maritalStatus}) = _$YouSectionImpl;

  factory _YouSection.fromJson(Map<String, dynamic> json) =
      _$YouSectionImpl.fromJson;

  @override
  String get name;
  @override
  int get age;
  @override
  CityTier get cityTier;
  @override
  OccupationType get occupation;
  @override
  IncomeType get incomeType;
  @override
  JobStability get jobStability;
  @override
  MaritalStatus get maritalStatus;

  /// Create a copy of YouSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YouSectionImplCopyWith<_$YouSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PeopleSection _$PeopleSectionFromJson(Map<String, dynamic> json) {
  return _PeopleSection.fromJson(json);
}

/// @nodoc
mixin _$PeopleSection {
  bool get hasSpouse => throw _privateConstructorUsedError;
  double get spouseIncome => throw _privateConstructorUsedError;
  OccupationType? get spouseOccupation => throw _privateConstructorUsedError;
  JobStability? get spouseJobStability => throw _privateConstructorUsedError;
  bool get spouseSameEmployer => throw _privateConstructorUsedError;
  bool get fatherAlive => throw _privateConstructorUsedError;
  bool get motherAlive => throw _privateConstructorUsedError;
  bool get parentsFinanciallyIndependent => throw _privateConstructorUsedError;
  bool get parentsHaveHealthInsurance => throw _privateConstructorUsedError;
  bool get parentsHavePreExistingConditions =>
      throw _privateConstructorUsedError;
  bool get siblingsCostSharing => throw _privateConstructorUsedError;
  int get existingChildren => throw _privateConstructorUsedError;
  int get plannedChildren => throw _privateConstructorUsedError;
  int? get nextChildYears => throw _privateConstructorUsedError;
  bool get hasDependencyObligations => throw _privateConstructorUsedError;
  double get dependencyObligationMonthly => throw _privateConstructorUsedError;

  /// Serializes this PeopleSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PeopleSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeopleSectionCopyWith<PeopleSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeopleSectionCopyWith<$Res> {
  factory $PeopleSectionCopyWith(
          PeopleSection value, $Res Function(PeopleSection) then) =
      _$PeopleSectionCopyWithImpl<$Res, PeopleSection>;
  @useResult
  $Res call(
      {bool hasSpouse,
      double spouseIncome,
      OccupationType? spouseOccupation,
      JobStability? spouseJobStability,
      bool spouseSameEmployer,
      bool fatherAlive,
      bool motherAlive,
      bool parentsFinanciallyIndependent,
      bool parentsHaveHealthInsurance,
      bool parentsHavePreExistingConditions,
      bool siblingsCostSharing,
      int existingChildren,
      int plannedChildren,
      int? nextChildYears,
      bool hasDependencyObligations,
      double dependencyObligationMonthly});
}

/// @nodoc
class _$PeopleSectionCopyWithImpl<$Res, $Val extends PeopleSection>
    implements $PeopleSectionCopyWith<$Res> {
  _$PeopleSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeopleSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasSpouse = null,
    Object? spouseIncome = null,
    Object? spouseOccupation = freezed,
    Object? spouseJobStability = freezed,
    Object? spouseSameEmployer = null,
    Object? fatherAlive = null,
    Object? motherAlive = null,
    Object? parentsFinanciallyIndependent = null,
    Object? parentsHaveHealthInsurance = null,
    Object? parentsHavePreExistingConditions = null,
    Object? siblingsCostSharing = null,
    Object? existingChildren = null,
    Object? plannedChildren = null,
    Object? nextChildYears = freezed,
    Object? hasDependencyObligations = null,
    Object? dependencyObligationMonthly = null,
  }) {
    return _then(_value.copyWith(
      hasSpouse: null == hasSpouse
          ? _value.hasSpouse
          : hasSpouse // ignore: cast_nullable_to_non_nullable
              as bool,
      spouseIncome: null == spouseIncome
          ? _value.spouseIncome
          : spouseIncome // ignore: cast_nullable_to_non_nullable
              as double,
      spouseOccupation: freezed == spouseOccupation
          ? _value.spouseOccupation
          : spouseOccupation // ignore: cast_nullable_to_non_nullable
              as OccupationType?,
      spouseJobStability: freezed == spouseJobStability
          ? _value.spouseJobStability
          : spouseJobStability // ignore: cast_nullable_to_non_nullable
              as JobStability?,
      spouseSameEmployer: null == spouseSameEmployer
          ? _value.spouseSameEmployer
          : spouseSameEmployer // ignore: cast_nullable_to_non_nullable
              as bool,
      fatherAlive: null == fatherAlive
          ? _value.fatherAlive
          : fatherAlive // ignore: cast_nullable_to_non_nullable
              as bool,
      motherAlive: null == motherAlive
          ? _value.motherAlive
          : motherAlive // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsFinanciallyIndependent: null == parentsFinanciallyIndependent
          ? _value.parentsFinanciallyIndependent
          : parentsFinanciallyIndependent // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsHaveHealthInsurance: null == parentsHaveHealthInsurance
          ? _value.parentsHaveHealthInsurance
          : parentsHaveHealthInsurance // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsHavePreExistingConditions: null == parentsHavePreExistingConditions
          ? _value.parentsHavePreExistingConditions
          : parentsHavePreExistingConditions // ignore: cast_nullable_to_non_nullable
              as bool,
      siblingsCostSharing: null == siblingsCostSharing
          ? _value.siblingsCostSharing
          : siblingsCostSharing // ignore: cast_nullable_to_non_nullable
              as bool,
      existingChildren: null == existingChildren
          ? _value.existingChildren
          : existingChildren // ignore: cast_nullable_to_non_nullable
              as int,
      plannedChildren: null == plannedChildren
          ? _value.plannedChildren
          : plannedChildren // ignore: cast_nullable_to_non_nullable
              as int,
      nextChildYears: freezed == nextChildYears
          ? _value.nextChildYears
          : nextChildYears // ignore: cast_nullable_to_non_nullable
              as int?,
      hasDependencyObligations: null == hasDependencyObligations
          ? _value.hasDependencyObligations
          : hasDependencyObligations // ignore: cast_nullable_to_non_nullable
              as bool,
      dependencyObligationMonthly: null == dependencyObligationMonthly
          ? _value.dependencyObligationMonthly
          : dependencyObligationMonthly // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PeopleSectionImplCopyWith<$Res>
    implements $PeopleSectionCopyWith<$Res> {
  factory _$$PeopleSectionImplCopyWith(
          _$PeopleSectionImpl value, $Res Function(_$PeopleSectionImpl) then) =
      __$$PeopleSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool hasSpouse,
      double spouseIncome,
      OccupationType? spouseOccupation,
      JobStability? spouseJobStability,
      bool spouseSameEmployer,
      bool fatherAlive,
      bool motherAlive,
      bool parentsFinanciallyIndependent,
      bool parentsHaveHealthInsurance,
      bool parentsHavePreExistingConditions,
      bool siblingsCostSharing,
      int existingChildren,
      int plannedChildren,
      int? nextChildYears,
      bool hasDependencyObligations,
      double dependencyObligationMonthly});
}

/// @nodoc
class __$$PeopleSectionImplCopyWithImpl<$Res>
    extends _$PeopleSectionCopyWithImpl<$Res, _$PeopleSectionImpl>
    implements _$$PeopleSectionImplCopyWith<$Res> {
  __$$PeopleSectionImplCopyWithImpl(
      _$PeopleSectionImpl _value, $Res Function(_$PeopleSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeopleSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasSpouse = null,
    Object? spouseIncome = null,
    Object? spouseOccupation = freezed,
    Object? spouseJobStability = freezed,
    Object? spouseSameEmployer = null,
    Object? fatherAlive = null,
    Object? motherAlive = null,
    Object? parentsFinanciallyIndependent = null,
    Object? parentsHaveHealthInsurance = null,
    Object? parentsHavePreExistingConditions = null,
    Object? siblingsCostSharing = null,
    Object? existingChildren = null,
    Object? plannedChildren = null,
    Object? nextChildYears = freezed,
    Object? hasDependencyObligations = null,
    Object? dependencyObligationMonthly = null,
  }) {
    return _then(_$PeopleSectionImpl(
      hasSpouse: null == hasSpouse
          ? _value.hasSpouse
          : hasSpouse // ignore: cast_nullable_to_non_nullable
              as bool,
      spouseIncome: null == spouseIncome
          ? _value.spouseIncome
          : spouseIncome // ignore: cast_nullable_to_non_nullable
              as double,
      spouseOccupation: freezed == spouseOccupation
          ? _value.spouseOccupation
          : spouseOccupation // ignore: cast_nullable_to_non_nullable
              as OccupationType?,
      spouseJobStability: freezed == spouseJobStability
          ? _value.spouseJobStability
          : spouseJobStability // ignore: cast_nullable_to_non_nullable
              as JobStability?,
      spouseSameEmployer: null == spouseSameEmployer
          ? _value.spouseSameEmployer
          : spouseSameEmployer // ignore: cast_nullable_to_non_nullable
              as bool,
      fatherAlive: null == fatherAlive
          ? _value.fatherAlive
          : fatherAlive // ignore: cast_nullable_to_non_nullable
              as bool,
      motherAlive: null == motherAlive
          ? _value.motherAlive
          : motherAlive // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsFinanciallyIndependent: null == parentsFinanciallyIndependent
          ? _value.parentsFinanciallyIndependent
          : parentsFinanciallyIndependent // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsHaveHealthInsurance: null == parentsHaveHealthInsurance
          ? _value.parentsHaveHealthInsurance
          : parentsHaveHealthInsurance // ignore: cast_nullable_to_non_nullable
              as bool,
      parentsHavePreExistingConditions: null == parentsHavePreExistingConditions
          ? _value.parentsHavePreExistingConditions
          : parentsHavePreExistingConditions // ignore: cast_nullable_to_non_nullable
              as bool,
      siblingsCostSharing: null == siblingsCostSharing
          ? _value.siblingsCostSharing
          : siblingsCostSharing // ignore: cast_nullable_to_non_nullable
              as bool,
      existingChildren: null == existingChildren
          ? _value.existingChildren
          : existingChildren // ignore: cast_nullable_to_non_nullable
              as int,
      plannedChildren: null == plannedChildren
          ? _value.plannedChildren
          : plannedChildren // ignore: cast_nullable_to_non_nullable
              as int,
      nextChildYears: freezed == nextChildYears
          ? _value.nextChildYears
          : nextChildYears // ignore: cast_nullable_to_non_nullable
              as int?,
      hasDependencyObligations: null == hasDependencyObligations
          ? _value.hasDependencyObligations
          : hasDependencyObligations // ignore: cast_nullable_to_non_nullable
              as bool,
      dependencyObligationMonthly: null == dependencyObligationMonthly
          ? _value.dependencyObligationMonthly
          : dependencyObligationMonthly // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PeopleSectionImpl implements _PeopleSection {
  const _$PeopleSectionImpl(
      {required this.hasSpouse,
      required this.spouseIncome,
      this.spouseOccupation,
      this.spouseJobStability,
      required this.spouseSameEmployer,
      required this.fatherAlive,
      required this.motherAlive,
      required this.parentsFinanciallyIndependent,
      required this.parentsHaveHealthInsurance,
      required this.parentsHavePreExistingConditions,
      required this.siblingsCostSharing,
      required this.existingChildren,
      required this.plannedChildren,
      this.nextChildYears,
      required this.hasDependencyObligations,
      required this.dependencyObligationMonthly});

  factory _$PeopleSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeopleSectionImplFromJson(json);

  @override
  final bool hasSpouse;
  @override
  final double spouseIncome;
  @override
  final OccupationType? spouseOccupation;
  @override
  final JobStability? spouseJobStability;
  @override
  final bool spouseSameEmployer;
  @override
  final bool fatherAlive;
  @override
  final bool motherAlive;
  @override
  final bool parentsFinanciallyIndependent;
  @override
  final bool parentsHaveHealthInsurance;
  @override
  final bool parentsHavePreExistingConditions;
  @override
  final bool siblingsCostSharing;
  @override
  final int existingChildren;
  @override
  final int plannedChildren;
  @override
  final int? nextChildYears;
  @override
  final bool hasDependencyObligations;
  @override
  final double dependencyObligationMonthly;

  @override
  String toString() {
    return 'PeopleSection(hasSpouse: $hasSpouse, spouseIncome: $spouseIncome, spouseOccupation: $spouseOccupation, spouseJobStability: $spouseJobStability, spouseSameEmployer: $spouseSameEmployer, fatherAlive: $fatherAlive, motherAlive: $motherAlive, parentsFinanciallyIndependent: $parentsFinanciallyIndependent, parentsHaveHealthInsurance: $parentsHaveHealthInsurance, parentsHavePreExistingConditions: $parentsHavePreExistingConditions, siblingsCostSharing: $siblingsCostSharing, existingChildren: $existingChildren, plannedChildren: $plannedChildren, nextChildYears: $nextChildYears, hasDependencyObligations: $hasDependencyObligations, dependencyObligationMonthly: $dependencyObligationMonthly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeopleSectionImpl &&
            (identical(other.hasSpouse, hasSpouse) ||
                other.hasSpouse == hasSpouse) &&
            (identical(other.spouseIncome, spouseIncome) ||
                other.spouseIncome == spouseIncome) &&
            (identical(other.spouseOccupation, spouseOccupation) ||
                other.spouseOccupation == spouseOccupation) &&
            (identical(other.spouseJobStability, spouseJobStability) ||
                other.spouseJobStability == spouseJobStability) &&
            (identical(other.spouseSameEmployer, spouseSameEmployer) ||
                other.spouseSameEmployer == spouseSameEmployer) &&
            (identical(other.fatherAlive, fatherAlive) ||
                other.fatherAlive == fatherAlive) &&
            (identical(other.motherAlive, motherAlive) ||
                other.motherAlive == motherAlive) &&
            (identical(other.parentsFinanciallyIndependent,
                    parentsFinanciallyIndependent) ||
                other.parentsFinanciallyIndependent ==
                    parentsFinanciallyIndependent) &&
            (identical(other.parentsHaveHealthInsurance,
                    parentsHaveHealthInsurance) ||
                other.parentsHaveHealthInsurance ==
                    parentsHaveHealthInsurance) &&
            (identical(other.parentsHavePreExistingConditions,
                    parentsHavePreExistingConditions) ||
                other.parentsHavePreExistingConditions ==
                    parentsHavePreExistingConditions) &&
            (identical(other.siblingsCostSharing, siblingsCostSharing) ||
                other.siblingsCostSharing == siblingsCostSharing) &&
            (identical(other.existingChildren, existingChildren) ||
                other.existingChildren == existingChildren) &&
            (identical(other.plannedChildren, plannedChildren) ||
                other.plannedChildren == plannedChildren) &&
            (identical(other.nextChildYears, nextChildYears) ||
                other.nextChildYears == nextChildYears) &&
            (identical(other.hasDependencyObligations, hasDependencyObligations) ||
                other.hasDependencyObligations == hasDependencyObligations) &&
            (identical(other.dependencyObligationMonthly,
                    dependencyObligationMonthly) ||
                other.dependencyObligationMonthly == dependencyObligationMonthly));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hasSpouse,
      spouseIncome,
      spouseOccupation,
      spouseJobStability,
      spouseSameEmployer,
      fatherAlive,
      motherAlive,
      parentsFinanciallyIndependent,
      parentsHaveHealthInsurance,
      parentsHavePreExistingConditions,
      siblingsCostSharing,
      existingChildren,
      plannedChildren,
      nextChildYears,
      hasDependencyObligations,
      dependencyObligationMonthly);

  /// Create a copy of PeopleSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeopleSectionImplCopyWith<_$PeopleSectionImpl> get copyWith =>
      __$$PeopleSectionImplCopyWithImpl<_$PeopleSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeopleSectionImplToJson(
      this,
    );
  }
}

abstract class _PeopleSection implements PeopleSection {
  const factory _PeopleSection(
      {required final bool hasSpouse,
      required final double spouseIncome,
      final OccupationType? spouseOccupation,
      final JobStability? spouseJobStability,
      required final bool spouseSameEmployer,
      required final bool fatherAlive,
      required final bool motherAlive,
      required final bool parentsFinanciallyIndependent,
      required final bool parentsHaveHealthInsurance,
      required final bool parentsHavePreExistingConditions,
      required final bool siblingsCostSharing,
      required final int existingChildren,
      required final int plannedChildren,
      final int? nextChildYears,
      required final bool hasDependencyObligations,
      required final double dependencyObligationMonthly}) = _$PeopleSectionImpl;

  factory _PeopleSection.fromJson(Map<String, dynamic> json) =
      _$PeopleSectionImpl.fromJson;

  @override
  bool get hasSpouse;
  @override
  double get spouseIncome;
  @override
  OccupationType? get spouseOccupation;
  @override
  JobStability? get spouseJobStability;
  @override
  bool get spouseSameEmployer;
  @override
  bool get fatherAlive;
  @override
  bool get motherAlive;
  @override
  bool get parentsFinanciallyIndependent;
  @override
  bool get parentsHaveHealthInsurance;
  @override
  bool get parentsHavePreExistingConditions;
  @override
  bool get siblingsCostSharing;
  @override
  int get existingChildren;
  @override
  int get plannedChildren;
  @override
  int? get nextChildYears;
  @override
  bool get hasDependencyObligations;
  @override
  double get dependencyObligationMonthly;

  /// Create a copy of PeopleSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeopleSectionImplCopyWith<_$PeopleSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LifePlansSection _$LifePlansSectionFromJson(Map<String, dynamic> json) {
  return _LifePlansSection.fromJson(json);
}

/// @nodoc
mixin _$LifePlansSection {
  bool get planningHomePurchase => throw _privateConstructorUsedError;
  int? get homePurchaseYearsFromNow => throw _privateConstructorUsedError;
  double? get homePurchaseBudget => throw _privateConstructorUsedError;
  bool get planningBusiness => throw _privateConstructorUsedError;
  int? get businessStartupYears => throw _privateConstructorUsedError;
  double? get businessStartupBudget => throw _privateConstructorUsedError;
  bool get planningRelocation => throw _privateConstructorUsedError;
  List<LumpSumExpense> get upcomingLumpSumExpenses =>
      throw _privateConstructorUsedError;

  /// Serializes this LifePlansSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LifePlansSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LifePlansSectionCopyWith<LifePlansSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LifePlansSectionCopyWith<$Res> {
  factory $LifePlansSectionCopyWith(
          LifePlansSection value, $Res Function(LifePlansSection) then) =
      _$LifePlansSectionCopyWithImpl<$Res, LifePlansSection>;
  @useResult
  $Res call(
      {bool planningHomePurchase,
      int? homePurchaseYearsFromNow,
      double? homePurchaseBudget,
      bool planningBusiness,
      int? businessStartupYears,
      double? businessStartupBudget,
      bool planningRelocation,
      List<LumpSumExpense> upcomingLumpSumExpenses});
}

/// @nodoc
class _$LifePlansSectionCopyWithImpl<$Res, $Val extends LifePlansSection>
    implements $LifePlansSectionCopyWith<$Res> {
  _$LifePlansSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LifePlansSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planningHomePurchase = null,
    Object? homePurchaseYearsFromNow = freezed,
    Object? homePurchaseBudget = freezed,
    Object? planningBusiness = null,
    Object? businessStartupYears = freezed,
    Object? businessStartupBudget = freezed,
    Object? planningRelocation = null,
    Object? upcomingLumpSumExpenses = null,
  }) {
    return _then(_value.copyWith(
      planningHomePurchase: null == planningHomePurchase
          ? _value.planningHomePurchase
          : planningHomePurchase // ignore: cast_nullable_to_non_nullable
              as bool,
      homePurchaseYearsFromNow: freezed == homePurchaseYearsFromNow
          ? _value.homePurchaseYearsFromNow
          : homePurchaseYearsFromNow // ignore: cast_nullable_to_non_nullable
              as int?,
      homePurchaseBudget: freezed == homePurchaseBudget
          ? _value.homePurchaseBudget
          : homePurchaseBudget // ignore: cast_nullable_to_non_nullable
              as double?,
      planningBusiness: null == planningBusiness
          ? _value.planningBusiness
          : planningBusiness // ignore: cast_nullable_to_non_nullable
              as bool,
      businessStartupYears: freezed == businessStartupYears
          ? _value.businessStartupYears
          : businessStartupYears // ignore: cast_nullable_to_non_nullable
              as int?,
      businessStartupBudget: freezed == businessStartupBudget
          ? _value.businessStartupBudget
          : businessStartupBudget // ignore: cast_nullable_to_non_nullable
              as double?,
      planningRelocation: null == planningRelocation
          ? _value.planningRelocation
          : planningRelocation // ignore: cast_nullable_to_non_nullable
              as bool,
      upcomingLumpSumExpenses: null == upcomingLumpSumExpenses
          ? _value.upcomingLumpSumExpenses
          : upcomingLumpSumExpenses // ignore: cast_nullable_to_non_nullable
              as List<LumpSumExpense>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LifePlansSectionImplCopyWith<$Res>
    implements $LifePlansSectionCopyWith<$Res> {
  factory _$$LifePlansSectionImplCopyWith(_$LifePlansSectionImpl value,
          $Res Function(_$LifePlansSectionImpl) then) =
      __$$LifePlansSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool planningHomePurchase,
      int? homePurchaseYearsFromNow,
      double? homePurchaseBudget,
      bool planningBusiness,
      int? businessStartupYears,
      double? businessStartupBudget,
      bool planningRelocation,
      List<LumpSumExpense> upcomingLumpSumExpenses});
}

/// @nodoc
class __$$LifePlansSectionImplCopyWithImpl<$Res>
    extends _$LifePlansSectionCopyWithImpl<$Res, _$LifePlansSectionImpl>
    implements _$$LifePlansSectionImplCopyWith<$Res> {
  __$$LifePlansSectionImplCopyWithImpl(_$LifePlansSectionImpl _value,
      $Res Function(_$LifePlansSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of LifePlansSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planningHomePurchase = null,
    Object? homePurchaseYearsFromNow = freezed,
    Object? homePurchaseBudget = freezed,
    Object? planningBusiness = null,
    Object? businessStartupYears = freezed,
    Object? businessStartupBudget = freezed,
    Object? planningRelocation = null,
    Object? upcomingLumpSumExpenses = null,
  }) {
    return _then(_$LifePlansSectionImpl(
      planningHomePurchase: null == planningHomePurchase
          ? _value.planningHomePurchase
          : planningHomePurchase // ignore: cast_nullable_to_non_nullable
              as bool,
      homePurchaseYearsFromNow: freezed == homePurchaseYearsFromNow
          ? _value.homePurchaseYearsFromNow
          : homePurchaseYearsFromNow // ignore: cast_nullable_to_non_nullable
              as int?,
      homePurchaseBudget: freezed == homePurchaseBudget
          ? _value.homePurchaseBudget
          : homePurchaseBudget // ignore: cast_nullable_to_non_nullable
              as double?,
      planningBusiness: null == planningBusiness
          ? _value.planningBusiness
          : planningBusiness // ignore: cast_nullable_to_non_nullable
              as bool,
      businessStartupYears: freezed == businessStartupYears
          ? _value.businessStartupYears
          : businessStartupYears // ignore: cast_nullable_to_non_nullable
              as int?,
      businessStartupBudget: freezed == businessStartupBudget
          ? _value.businessStartupBudget
          : businessStartupBudget // ignore: cast_nullable_to_non_nullable
              as double?,
      planningRelocation: null == planningRelocation
          ? _value.planningRelocation
          : planningRelocation // ignore: cast_nullable_to_non_nullable
              as bool,
      upcomingLumpSumExpenses: null == upcomingLumpSumExpenses
          ? _value._upcomingLumpSumExpenses
          : upcomingLumpSumExpenses // ignore: cast_nullable_to_non_nullable
              as List<LumpSumExpense>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LifePlansSectionImpl implements _LifePlansSection {
  const _$LifePlansSectionImpl(
      {required this.planningHomePurchase,
      this.homePurchaseYearsFromNow,
      this.homePurchaseBudget,
      required this.planningBusiness,
      this.businessStartupYears,
      this.businessStartupBudget,
      required this.planningRelocation,
      required final List<LumpSumExpense> upcomingLumpSumExpenses})
      : _upcomingLumpSumExpenses = upcomingLumpSumExpenses;

  factory _$LifePlansSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LifePlansSectionImplFromJson(json);

  @override
  final bool planningHomePurchase;
  @override
  final int? homePurchaseYearsFromNow;
  @override
  final double? homePurchaseBudget;
  @override
  final bool planningBusiness;
  @override
  final int? businessStartupYears;
  @override
  final double? businessStartupBudget;
  @override
  final bool planningRelocation;
  final List<LumpSumExpense> _upcomingLumpSumExpenses;
  @override
  List<LumpSumExpense> get upcomingLumpSumExpenses {
    if (_upcomingLumpSumExpenses is EqualUnmodifiableListView)
      return _upcomingLumpSumExpenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_upcomingLumpSumExpenses);
  }

  @override
  String toString() {
    return 'LifePlansSection(planningHomePurchase: $planningHomePurchase, homePurchaseYearsFromNow: $homePurchaseYearsFromNow, homePurchaseBudget: $homePurchaseBudget, planningBusiness: $planningBusiness, businessStartupYears: $businessStartupYears, businessStartupBudget: $businessStartupBudget, planningRelocation: $planningRelocation, upcomingLumpSumExpenses: $upcomingLumpSumExpenses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LifePlansSectionImpl &&
            (identical(other.planningHomePurchase, planningHomePurchase) ||
                other.planningHomePurchase == planningHomePurchase) &&
            (identical(
                    other.homePurchaseYearsFromNow, homePurchaseYearsFromNow) ||
                other.homePurchaseYearsFromNow == homePurchaseYearsFromNow) &&
            (identical(other.homePurchaseBudget, homePurchaseBudget) ||
                other.homePurchaseBudget == homePurchaseBudget) &&
            (identical(other.planningBusiness, planningBusiness) ||
                other.planningBusiness == planningBusiness) &&
            (identical(other.businessStartupYears, businessStartupYears) ||
                other.businessStartupYears == businessStartupYears) &&
            (identical(other.businessStartupBudget, businessStartupBudget) ||
                other.businessStartupBudget == businessStartupBudget) &&
            (identical(other.planningRelocation, planningRelocation) ||
                other.planningRelocation == planningRelocation) &&
            const DeepCollectionEquality().equals(
                other._upcomingLumpSumExpenses, _upcomingLumpSumExpenses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      planningHomePurchase,
      homePurchaseYearsFromNow,
      homePurchaseBudget,
      planningBusiness,
      businessStartupYears,
      businessStartupBudget,
      planningRelocation,
      const DeepCollectionEquality().hash(_upcomingLumpSumExpenses));

  /// Create a copy of LifePlansSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LifePlansSectionImplCopyWith<_$LifePlansSectionImpl> get copyWith =>
      __$$LifePlansSectionImplCopyWithImpl<_$LifePlansSectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LifePlansSectionImplToJson(
      this,
    );
  }
}

abstract class _LifePlansSection implements LifePlansSection {
  const factory _LifePlansSection(
          {required final bool planningHomePurchase,
          final int? homePurchaseYearsFromNow,
          final double? homePurchaseBudget,
          required final bool planningBusiness,
          final int? businessStartupYears,
          final double? businessStartupBudget,
          required final bool planningRelocation,
          required final List<LumpSumExpense> upcomingLumpSumExpenses}) =
      _$LifePlansSectionImpl;

  factory _LifePlansSection.fromJson(Map<String, dynamic> json) =
      _$LifePlansSectionImpl.fromJson;

  @override
  bool get planningHomePurchase;
  @override
  int? get homePurchaseYearsFromNow;
  @override
  double? get homePurchaseBudget;
  @override
  bool get planningBusiness;
  @override
  int? get businessStartupYears;
  @override
  double? get businessStartupBudget;
  @override
  bool get planningRelocation;
  @override
  List<LumpSumExpense> get upcomingLumpSumExpenses;

  /// Create a copy of LifePlansSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LifePlansSectionImplCopyWith<_$LifePlansSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IncomeSection _$IncomeSectionFromJson(Map<String, dynamic> json) {
  return _IncomeSection.fromJson(json);
}

/// @nodoc
mixin _$IncomeSection {
  double get monthlyBaseSalary => throw _privateConstructorUsedError;
  double get monthlyVariablePay => throw _privateConstructorUsedError;
  BonusLikelihood get annualBonusLikelihood =>
      throw _privateConstructorUsedError;
  double get annualBonusAmount => throw _privateConstructorUsedError;
  double get monthlyFreelanceIncome => throw _privateConstructorUsedError;
  double get monthlyRentalIncome => throw _privateConstructorUsedError;
  double get otherMonthlyIncome => throw _privateConstructorUsedError;
  String get otherIncomeLabel => throw _privateConstructorUsedError;

  /// Serializes this IncomeSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IncomeSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IncomeSectionCopyWith<IncomeSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncomeSectionCopyWith<$Res> {
  factory $IncomeSectionCopyWith(
          IncomeSection value, $Res Function(IncomeSection) then) =
      _$IncomeSectionCopyWithImpl<$Res, IncomeSection>;
  @useResult
  $Res call(
      {double monthlyBaseSalary,
      double monthlyVariablePay,
      BonusLikelihood annualBonusLikelihood,
      double annualBonusAmount,
      double monthlyFreelanceIncome,
      double monthlyRentalIncome,
      double otherMonthlyIncome,
      String otherIncomeLabel});
}

/// @nodoc
class _$IncomeSectionCopyWithImpl<$Res, $Val extends IncomeSection>
    implements $IncomeSectionCopyWith<$Res> {
  _$IncomeSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IncomeSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monthlyBaseSalary = null,
    Object? monthlyVariablePay = null,
    Object? annualBonusLikelihood = null,
    Object? annualBonusAmount = null,
    Object? monthlyFreelanceIncome = null,
    Object? monthlyRentalIncome = null,
    Object? otherMonthlyIncome = null,
    Object? otherIncomeLabel = null,
  }) {
    return _then(_value.copyWith(
      monthlyBaseSalary: null == monthlyBaseSalary
          ? _value.monthlyBaseSalary
          : monthlyBaseSalary // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyVariablePay: null == monthlyVariablePay
          ? _value.monthlyVariablePay
          : monthlyVariablePay // ignore: cast_nullable_to_non_nullable
              as double,
      annualBonusLikelihood: null == annualBonusLikelihood
          ? _value.annualBonusLikelihood
          : annualBonusLikelihood // ignore: cast_nullable_to_non_nullable
              as BonusLikelihood,
      annualBonusAmount: null == annualBonusAmount
          ? _value.annualBonusAmount
          : annualBonusAmount // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyFreelanceIncome: null == monthlyFreelanceIncome
          ? _value.monthlyFreelanceIncome
          : monthlyFreelanceIncome // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyRentalIncome: null == monthlyRentalIncome
          ? _value.monthlyRentalIncome
          : monthlyRentalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      otherMonthlyIncome: null == otherMonthlyIncome
          ? _value.otherMonthlyIncome
          : otherMonthlyIncome // ignore: cast_nullable_to_non_nullable
              as double,
      otherIncomeLabel: null == otherIncomeLabel
          ? _value.otherIncomeLabel
          : otherIncomeLabel // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IncomeSectionImplCopyWith<$Res>
    implements $IncomeSectionCopyWith<$Res> {
  factory _$$IncomeSectionImplCopyWith(
          _$IncomeSectionImpl value, $Res Function(_$IncomeSectionImpl) then) =
      __$$IncomeSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double monthlyBaseSalary,
      double monthlyVariablePay,
      BonusLikelihood annualBonusLikelihood,
      double annualBonusAmount,
      double monthlyFreelanceIncome,
      double monthlyRentalIncome,
      double otherMonthlyIncome,
      String otherIncomeLabel});
}

/// @nodoc
class __$$IncomeSectionImplCopyWithImpl<$Res>
    extends _$IncomeSectionCopyWithImpl<$Res, _$IncomeSectionImpl>
    implements _$$IncomeSectionImplCopyWith<$Res> {
  __$$IncomeSectionImplCopyWithImpl(
      _$IncomeSectionImpl _value, $Res Function(_$IncomeSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of IncomeSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monthlyBaseSalary = null,
    Object? monthlyVariablePay = null,
    Object? annualBonusLikelihood = null,
    Object? annualBonusAmount = null,
    Object? monthlyFreelanceIncome = null,
    Object? monthlyRentalIncome = null,
    Object? otherMonthlyIncome = null,
    Object? otherIncomeLabel = null,
  }) {
    return _then(_$IncomeSectionImpl(
      monthlyBaseSalary: null == monthlyBaseSalary
          ? _value.monthlyBaseSalary
          : monthlyBaseSalary // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyVariablePay: null == monthlyVariablePay
          ? _value.monthlyVariablePay
          : monthlyVariablePay // ignore: cast_nullable_to_non_nullable
              as double,
      annualBonusLikelihood: null == annualBonusLikelihood
          ? _value.annualBonusLikelihood
          : annualBonusLikelihood // ignore: cast_nullable_to_non_nullable
              as BonusLikelihood,
      annualBonusAmount: null == annualBonusAmount
          ? _value.annualBonusAmount
          : annualBonusAmount // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyFreelanceIncome: null == monthlyFreelanceIncome
          ? _value.monthlyFreelanceIncome
          : monthlyFreelanceIncome // ignore: cast_nullable_to_non_nullable
              as double,
      monthlyRentalIncome: null == monthlyRentalIncome
          ? _value.monthlyRentalIncome
          : monthlyRentalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      otherMonthlyIncome: null == otherMonthlyIncome
          ? _value.otherMonthlyIncome
          : otherMonthlyIncome // ignore: cast_nullable_to_non_nullable
              as double,
      otherIncomeLabel: null == otherIncomeLabel
          ? _value.otherIncomeLabel
          : otherIncomeLabel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IncomeSectionImpl implements _IncomeSection {
  const _$IncomeSectionImpl(
      {required this.monthlyBaseSalary,
      required this.monthlyVariablePay,
      required this.annualBonusLikelihood,
      required this.annualBonusAmount,
      required this.monthlyFreelanceIncome,
      required this.monthlyRentalIncome,
      required this.otherMonthlyIncome,
      required this.otherIncomeLabel});

  factory _$IncomeSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$IncomeSectionImplFromJson(json);

  @override
  final double monthlyBaseSalary;
  @override
  final double monthlyVariablePay;
  @override
  final BonusLikelihood annualBonusLikelihood;
  @override
  final double annualBonusAmount;
  @override
  final double monthlyFreelanceIncome;
  @override
  final double monthlyRentalIncome;
  @override
  final double otherMonthlyIncome;
  @override
  final String otherIncomeLabel;

  @override
  String toString() {
    return 'IncomeSection(monthlyBaseSalary: $monthlyBaseSalary, monthlyVariablePay: $monthlyVariablePay, annualBonusLikelihood: $annualBonusLikelihood, annualBonusAmount: $annualBonusAmount, monthlyFreelanceIncome: $monthlyFreelanceIncome, monthlyRentalIncome: $monthlyRentalIncome, otherMonthlyIncome: $otherMonthlyIncome, otherIncomeLabel: $otherIncomeLabel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncomeSectionImpl &&
            (identical(other.monthlyBaseSalary, monthlyBaseSalary) ||
                other.monthlyBaseSalary == monthlyBaseSalary) &&
            (identical(other.monthlyVariablePay, monthlyVariablePay) ||
                other.monthlyVariablePay == monthlyVariablePay) &&
            (identical(other.annualBonusLikelihood, annualBonusLikelihood) ||
                other.annualBonusLikelihood == annualBonusLikelihood) &&
            (identical(other.annualBonusAmount, annualBonusAmount) ||
                other.annualBonusAmount == annualBonusAmount) &&
            (identical(other.monthlyFreelanceIncome, monthlyFreelanceIncome) ||
                other.monthlyFreelanceIncome == monthlyFreelanceIncome) &&
            (identical(other.monthlyRentalIncome, monthlyRentalIncome) ||
                other.monthlyRentalIncome == monthlyRentalIncome) &&
            (identical(other.otherMonthlyIncome, otherMonthlyIncome) ||
                other.otherMonthlyIncome == otherMonthlyIncome) &&
            (identical(other.otherIncomeLabel, otherIncomeLabel) ||
                other.otherIncomeLabel == otherIncomeLabel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      monthlyBaseSalary,
      monthlyVariablePay,
      annualBonusLikelihood,
      annualBonusAmount,
      monthlyFreelanceIncome,
      monthlyRentalIncome,
      otherMonthlyIncome,
      otherIncomeLabel);

  /// Create a copy of IncomeSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IncomeSectionImplCopyWith<_$IncomeSectionImpl> get copyWith =>
      __$$IncomeSectionImplCopyWithImpl<_$IncomeSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IncomeSectionImplToJson(
      this,
    );
  }
}

abstract class _IncomeSection implements IncomeSection {
  const factory _IncomeSection(
      {required final double monthlyBaseSalary,
      required final double monthlyVariablePay,
      required final BonusLikelihood annualBonusLikelihood,
      required final double annualBonusAmount,
      required final double monthlyFreelanceIncome,
      required final double monthlyRentalIncome,
      required final double otherMonthlyIncome,
      required final String otherIncomeLabel}) = _$IncomeSectionImpl;

  factory _IncomeSection.fromJson(Map<String, dynamic> json) =
      _$IncomeSectionImpl.fromJson;

  @override
  double get monthlyBaseSalary;
  @override
  double get monthlyVariablePay;
  @override
  BonusLikelihood get annualBonusLikelihood;
  @override
  double get annualBonusAmount;
  @override
  double get monthlyFreelanceIncome;
  @override
  double get monthlyRentalIncome;
  @override
  double get otherMonthlyIncome;
  @override
  String get otherIncomeLabel;

  /// Create a copy of IncomeSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IncomeSectionImplCopyWith<_$IncomeSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExpensesSection _$ExpensesSectionFromJson(Map<String, dynamic> json) {
  return _ExpensesSection.fromJson(json);
}

/// @nodoc
mixin _$ExpensesSection {
// Consumption
  double get rent => throw _privateConstructorUsedError;
  double get foodGroceries => throw _privateConstructorUsedError;
  double get utilities => throw _privateConstructorUsedError;
  double get transport => throw _privateConstructorUsedError;
  double get entertainment => throw _privateConstructorUsedError;
  double get personalCare => throw _privateConstructorUsedError; // Safety
  double get lifeInsurancePremiumMonthly => throw _privateConstructorUsedError;
  double get healthInsurancePremiumMonthly =>
      throw _privateConstructorUsedError;
  double get emergencyFundContributionMonthly =>
      throw _privateConstructorUsedError; // Growth
  double get equityInvestmentMonthly => throw _privateConstructorUsedError;
  double get debtInvestmentMonthly => throw _privateConstructorUsedError;
  double get retirementFundMonthly => throw _privateConstructorUsedError;

  /// Serializes this ExpensesSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExpensesSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpensesSectionCopyWith<ExpensesSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpensesSectionCopyWith<$Res> {
  factory $ExpensesSectionCopyWith(
          ExpensesSection value, $Res Function(ExpensesSection) then) =
      _$ExpensesSectionCopyWithImpl<$Res, ExpensesSection>;
  @useResult
  $Res call(
      {double rent,
      double foodGroceries,
      double utilities,
      double transport,
      double entertainment,
      double personalCare,
      double lifeInsurancePremiumMonthly,
      double healthInsurancePremiumMonthly,
      double emergencyFundContributionMonthly,
      double equityInvestmentMonthly,
      double debtInvestmentMonthly,
      double retirementFundMonthly});
}

/// @nodoc
class _$ExpensesSectionCopyWithImpl<$Res, $Val extends ExpensesSection>
    implements $ExpensesSectionCopyWith<$Res> {
  _$ExpensesSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpensesSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rent = null,
    Object? foodGroceries = null,
    Object? utilities = null,
    Object? transport = null,
    Object? entertainment = null,
    Object? personalCare = null,
    Object? lifeInsurancePremiumMonthly = null,
    Object? healthInsurancePremiumMonthly = null,
    Object? emergencyFundContributionMonthly = null,
    Object? equityInvestmentMonthly = null,
    Object? debtInvestmentMonthly = null,
    Object? retirementFundMonthly = null,
  }) {
    return _then(_value.copyWith(
      rent: null == rent
          ? _value.rent
          : rent // ignore: cast_nullable_to_non_nullable
              as double,
      foodGroceries: null == foodGroceries
          ? _value.foodGroceries
          : foodGroceries // ignore: cast_nullable_to_non_nullable
              as double,
      utilities: null == utilities
          ? _value.utilities
          : utilities // ignore: cast_nullable_to_non_nullable
              as double,
      transport: null == transport
          ? _value.transport
          : transport // ignore: cast_nullable_to_non_nullable
              as double,
      entertainment: null == entertainment
          ? _value.entertainment
          : entertainment // ignore: cast_nullable_to_non_nullable
              as double,
      personalCare: null == personalCare
          ? _value.personalCare
          : personalCare // ignore: cast_nullable_to_non_nullable
              as double,
      lifeInsurancePremiumMonthly: null == lifeInsurancePremiumMonthly
          ? _value.lifeInsurancePremiumMonthly
          : lifeInsurancePremiumMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      healthInsurancePremiumMonthly: null == healthInsurancePremiumMonthly
          ? _value.healthInsurancePremiumMonthly
          : healthInsurancePremiumMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundContributionMonthly: null == emergencyFundContributionMonthly
          ? _value.emergencyFundContributionMonthly
          : emergencyFundContributionMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      equityInvestmentMonthly: null == equityInvestmentMonthly
          ? _value.equityInvestmentMonthly
          : equityInvestmentMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      debtInvestmentMonthly: null == debtInvestmentMonthly
          ? _value.debtInvestmentMonthly
          : debtInvestmentMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      retirementFundMonthly: null == retirementFundMonthly
          ? _value.retirementFundMonthly
          : retirementFundMonthly // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpensesSectionImplCopyWith<$Res>
    implements $ExpensesSectionCopyWith<$Res> {
  factory _$$ExpensesSectionImplCopyWith(_$ExpensesSectionImpl value,
          $Res Function(_$ExpensesSectionImpl) then) =
      __$$ExpensesSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double rent,
      double foodGroceries,
      double utilities,
      double transport,
      double entertainment,
      double personalCare,
      double lifeInsurancePremiumMonthly,
      double healthInsurancePremiumMonthly,
      double emergencyFundContributionMonthly,
      double equityInvestmentMonthly,
      double debtInvestmentMonthly,
      double retirementFundMonthly});
}

/// @nodoc
class __$$ExpensesSectionImplCopyWithImpl<$Res>
    extends _$ExpensesSectionCopyWithImpl<$Res, _$ExpensesSectionImpl>
    implements _$$ExpensesSectionImplCopyWith<$Res> {
  __$$ExpensesSectionImplCopyWithImpl(
      _$ExpensesSectionImpl _value, $Res Function(_$ExpensesSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExpensesSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rent = null,
    Object? foodGroceries = null,
    Object? utilities = null,
    Object? transport = null,
    Object? entertainment = null,
    Object? personalCare = null,
    Object? lifeInsurancePremiumMonthly = null,
    Object? healthInsurancePremiumMonthly = null,
    Object? emergencyFundContributionMonthly = null,
    Object? equityInvestmentMonthly = null,
    Object? debtInvestmentMonthly = null,
    Object? retirementFundMonthly = null,
  }) {
    return _then(_$ExpensesSectionImpl(
      rent: null == rent
          ? _value.rent
          : rent // ignore: cast_nullable_to_non_nullable
              as double,
      foodGroceries: null == foodGroceries
          ? _value.foodGroceries
          : foodGroceries // ignore: cast_nullable_to_non_nullable
              as double,
      utilities: null == utilities
          ? _value.utilities
          : utilities // ignore: cast_nullable_to_non_nullable
              as double,
      transport: null == transport
          ? _value.transport
          : transport // ignore: cast_nullable_to_non_nullable
              as double,
      entertainment: null == entertainment
          ? _value.entertainment
          : entertainment // ignore: cast_nullable_to_non_nullable
              as double,
      personalCare: null == personalCare
          ? _value.personalCare
          : personalCare // ignore: cast_nullable_to_non_nullable
              as double,
      lifeInsurancePremiumMonthly: null == lifeInsurancePremiumMonthly
          ? _value.lifeInsurancePremiumMonthly
          : lifeInsurancePremiumMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      healthInsurancePremiumMonthly: null == healthInsurancePremiumMonthly
          ? _value.healthInsurancePremiumMonthly
          : healthInsurancePremiumMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyFundContributionMonthly: null == emergencyFundContributionMonthly
          ? _value.emergencyFundContributionMonthly
          : emergencyFundContributionMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      equityInvestmentMonthly: null == equityInvestmentMonthly
          ? _value.equityInvestmentMonthly
          : equityInvestmentMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      debtInvestmentMonthly: null == debtInvestmentMonthly
          ? _value.debtInvestmentMonthly
          : debtInvestmentMonthly // ignore: cast_nullable_to_non_nullable
              as double,
      retirementFundMonthly: null == retirementFundMonthly
          ? _value.retirementFundMonthly
          : retirementFundMonthly // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExpensesSectionImpl implements _ExpensesSection {
  const _$ExpensesSectionImpl(
      {required this.rent,
      required this.foodGroceries,
      required this.utilities,
      required this.transport,
      required this.entertainment,
      required this.personalCare,
      required this.lifeInsurancePremiumMonthly,
      required this.healthInsurancePremiumMonthly,
      required this.emergencyFundContributionMonthly,
      required this.equityInvestmentMonthly,
      required this.debtInvestmentMonthly,
      required this.retirementFundMonthly});

  factory _$ExpensesSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpensesSectionImplFromJson(json);

// Consumption
  @override
  final double rent;
  @override
  final double foodGroceries;
  @override
  final double utilities;
  @override
  final double transport;
  @override
  final double entertainment;
  @override
  final double personalCare;
// Safety
  @override
  final double lifeInsurancePremiumMonthly;
  @override
  final double healthInsurancePremiumMonthly;
  @override
  final double emergencyFundContributionMonthly;
// Growth
  @override
  final double equityInvestmentMonthly;
  @override
  final double debtInvestmentMonthly;
  @override
  final double retirementFundMonthly;

  @override
  String toString() {
    return 'ExpensesSection(rent: $rent, foodGroceries: $foodGroceries, utilities: $utilities, transport: $transport, entertainment: $entertainment, personalCare: $personalCare, lifeInsurancePremiumMonthly: $lifeInsurancePremiumMonthly, healthInsurancePremiumMonthly: $healthInsurancePremiumMonthly, emergencyFundContributionMonthly: $emergencyFundContributionMonthly, equityInvestmentMonthly: $equityInvestmentMonthly, debtInvestmentMonthly: $debtInvestmentMonthly, retirementFundMonthly: $retirementFundMonthly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpensesSectionImpl &&
            (identical(other.rent, rent) || other.rent == rent) &&
            (identical(other.foodGroceries, foodGroceries) ||
                other.foodGroceries == foodGroceries) &&
            (identical(other.utilities, utilities) ||
                other.utilities == utilities) &&
            (identical(other.transport, transport) ||
                other.transport == transport) &&
            (identical(other.entertainment, entertainment) ||
                other.entertainment == entertainment) &&
            (identical(other.personalCare, personalCare) ||
                other.personalCare == personalCare) &&
            (identical(other.lifeInsurancePremiumMonthly,
                    lifeInsurancePremiumMonthly) ||
                other.lifeInsurancePremiumMonthly ==
                    lifeInsurancePremiumMonthly) &&
            (identical(other.healthInsurancePremiumMonthly,
                    healthInsurancePremiumMonthly) ||
                other.healthInsurancePremiumMonthly ==
                    healthInsurancePremiumMonthly) &&
            (identical(other.emergencyFundContributionMonthly,
                    emergencyFundContributionMonthly) ||
                other.emergencyFundContributionMonthly ==
                    emergencyFundContributionMonthly) &&
            (identical(
                    other.equityInvestmentMonthly, equityInvestmentMonthly) ||
                other.equityInvestmentMonthly == equityInvestmentMonthly) &&
            (identical(other.debtInvestmentMonthly, debtInvestmentMonthly) ||
                other.debtInvestmentMonthly == debtInvestmentMonthly) &&
            (identical(other.retirementFundMonthly, retirementFundMonthly) ||
                other.retirementFundMonthly == retirementFundMonthly));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      rent,
      foodGroceries,
      utilities,
      transport,
      entertainment,
      personalCare,
      lifeInsurancePremiumMonthly,
      healthInsurancePremiumMonthly,
      emergencyFundContributionMonthly,
      equityInvestmentMonthly,
      debtInvestmentMonthly,
      retirementFundMonthly);

  /// Create a copy of ExpensesSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpensesSectionImplCopyWith<_$ExpensesSectionImpl> get copyWith =>
      __$$ExpensesSectionImplCopyWithImpl<_$ExpensesSectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpensesSectionImplToJson(
      this,
    );
  }
}

abstract class _ExpensesSection implements ExpensesSection {
  const factory _ExpensesSection(
      {required final double rent,
      required final double foodGroceries,
      required final double utilities,
      required final double transport,
      required final double entertainment,
      required final double personalCare,
      required final double lifeInsurancePremiumMonthly,
      required final double healthInsurancePremiumMonthly,
      required final double emergencyFundContributionMonthly,
      required final double equityInvestmentMonthly,
      required final double debtInvestmentMonthly,
      required final double retirementFundMonthly}) = _$ExpensesSectionImpl;

  factory _ExpensesSection.fromJson(Map<String, dynamic> json) =
      _$ExpensesSectionImpl.fromJson;

// Consumption
  @override
  double get rent;
  @override
  double get foodGroceries;
  @override
  double get utilities;
  @override
  double get transport;
  @override
  double get entertainment;
  @override
  double get personalCare; // Safety
  @override
  double get lifeInsurancePremiumMonthly;
  @override
  double get healthInsurancePremiumMonthly;
  @override
  double get emergencyFundContributionMonthly; // Growth
  @override
  double get equityInvestmentMonthly;
  @override
  double get debtInvestmentMonthly;
  @override
  double get retirementFundMonthly;

  /// Create a copy of ExpensesSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpensesSectionImplCopyWith<_$ExpensesSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoansSection _$LoansSectionFromJson(Map<String, dynamic> json) {
  return _LoansSection.fromJson(json);
}

/// @nodoc
mixin _$LoansSection {
  List<LoanEntry> get loans => throw _privateConstructorUsedError;

  /// Serializes this LoansSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoansSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoansSectionCopyWith<LoansSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoansSectionCopyWith<$Res> {
  factory $LoansSectionCopyWith(
          LoansSection value, $Res Function(LoansSection) then) =
      _$LoansSectionCopyWithImpl<$Res, LoansSection>;
  @useResult
  $Res call({List<LoanEntry> loans});
}

/// @nodoc
class _$LoansSectionCopyWithImpl<$Res, $Val extends LoansSection>
    implements $LoansSectionCopyWith<$Res> {
  _$LoansSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoansSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loans = null,
  }) {
    return _then(_value.copyWith(
      loans: null == loans
          ? _value.loans
          : loans // ignore: cast_nullable_to_non_nullable
              as List<LoanEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoansSectionImplCopyWith<$Res>
    implements $LoansSectionCopyWith<$Res> {
  factory _$$LoansSectionImplCopyWith(
          _$LoansSectionImpl value, $Res Function(_$LoansSectionImpl) then) =
      __$$LoansSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<LoanEntry> loans});
}

/// @nodoc
class __$$LoansSectionImplCopyWithImpl<$Res>
    extends _$LoansSectionCopyWithImpl<$Res, _$LoansSectionImpl>
    implements _$$LoansSectionImplCopyWith<$Res> {
  __$$LoansSectionImplCopyWithImpl(
      _$LoansSectionImpl _value, $Res Function(_$LoansSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoansSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loans = null,
  }) {
    return _then(_$LoansSectionImpl(
      loans: null == loans
          ? _value._loans
          : loans // ignore: cast_nullable_to_non_nullable
              as List<LoanEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoansSectionImpl implements _LoansSection {
  const _$LoansSectionImpl({required final List<LoanEntry> loans})
      : _loans = loans;

  factory _$LoansSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoansSectionImplFromJson(json);

  final List<LoanEntry> _loans;
  @override
  List<LoanEntry> get loans {
    if (_loans is EqualUnmodifiableListView) return _loans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_loans);
  }

  @override
  String toString() {
    return 'LoansSection(loans: $loans)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoansSectionImpl &&
            const DeepCollectionEquality().equals(other._loans, _loans));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_loans));

  /// Create a copy of LoansSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoansSectionImplCopyWith<_$LoansSectionImpl> get copyWith =>
      __$$LoansSectionImplCopyWithImpl<_$LoansSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoansSectionImplToJson(
      this,
    );
  }
}

abstract class _LoansSection implements LoansSection {
  const factory _LoansSection({required final List<LoanEntry> loans}) =
      _$LoansSectionImpl;

  factory _LoansSection.fromJson(Map<String, dynamic> json) =
      _$LoansSectionImpl.fromJson;

  @override
  List<LoanEntry> get loans;

  /// Create a copy of LoansSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoansSectionImplCopyWith<_$LoansSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AssetsSection _$AssetsSectionFromJson(Map<String, dynamic> json) {
  return _AssetsSection.fromJson(json);
}

/// @nodoc
mixin _$AssetsSection {
// Fixed
  double get primaryResidenceValue => throw _privateConstructorUsedError;
  double get otherRealEstateValue => throw _privateConstructorUsedError;
  double get vehicleValue => throw _privateConstructorUsedError; // Liquid
  double get fixedDeposits => throw _privateConstructorUsedError;
  double get equityPortfolio => throw _privateConstructorUsedError;
  double get mutualFunds => throw _privateConstructorUsedError;
  double get goldJewellery => throw _privateConstructorUsedError;
  double get retirementCorpus => throw _privateConstructorUsedError;
  double get currentEmergencyFund => throw _privateConstructorUsedError;
  CreditScoreTier get creditScoreTier => throw _privateConstructorUsedError;

  /// Serializes this AssetsSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetsSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetsSectionCopyWith<AssetsSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetsSectionCopyWith<$Res> {
  factory $AssetsSectionCopyWith(
          AssetsSection value, $Res Function(AssetsSection) then) =
      _$AssetsSectionCopyWithImpl<$Res, AssetsSection>;
  @useResult
  $Res call(
      {double primaryResidenceValue,
      double otherRealEstateValue,
      double vehicleValue,
      double fixedDeposits,
      double equityPortfolio,
      double mutualFunds,
      double goldJewellery,
      double retirementCorpus,
      double currentEmergencyFund,
      CreditScoreTier creditScoreTier});
}

/// @nodoc
class _$AssetsSectionCopyWithImpl<$Res, $Val extends AssetsSection>
    implements $AssetsSectionCopyWith<$Res> {
  _$AssetsSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetsSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primaryResidenceValue = null,
    Object? otherRealEstateValue = null,
    Object? vehicleValue = null,
    Object? fixedDeposits = null,
    Object? equityPortfolio = null,
    Object? mutualFunds = null,
    Object? goldJewellery = null,
    Object? retirementCorpus = null,
    Object? currentEmergencyFund = null,
    Object? creditScoreTier = null,
  }) {
    return _then(_value.copyWith(
      primaryResidenceValue: null == primaryResidenceValue
          ? _value.primaryResidenceValue
          : primaryResidenceValue // ignore: cast_nullable_to_non_nullable
              as double,
      otherRealEstateValue: null == otherRealEstateValue
          ? _value.otherRealEstateValue
          : otherRealEstateValue // ignore: cast_nullable_to_non_nullable
              as double,
      vehicleValue: null == vehicleValue
          ? _value.vehicleValue
          : vehicleValue // ignore: cast_nullable_to_non_nullable
              as double,
      fixedDeposits: null == fixedDeposits
          ? _value.fixedDeposits
          : fixedDeposits // ignore: cast_nullable_to_non_nullable
              as double,
      equityPortfolio: null == equityPortfolio
          ? _value.equityPortfolio
          : equityPortfolio // ignore: cast_nullable_to_non_nullable
              as double,
      mutualFunds: null == mutualFunds
          ? _value.mutualFunds
          : mutualFunds // ignore: cast_nullable_to_non_nullable
              as double,
      goldJewellery: null == goldJewellery
          ? _value.goldJewellery
          : goldJewellery // ignore: cast_nullable_to_non_nullable
              as double,
      retirementCorpus: null == retirementCorpus
          ? _value.retirementCorpus
          : retirementCorpus // ignore: cast_nullable_to_non_nullable
              as double,
      currentEmergencyFund: null == currentEmergencyFund
          ? _value.currentEmergencyFund
          : currentEmergencyFund // ignore: cast_nullable_to_non_nullable
              as double,
      creditScoreTier: null == creditScoreTier
          ? _value.creditScoreTier
          : creditScoreTier // ignore: cast_nullable_to_non_nullable
              as CreditScoreTier,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AssetsSectionImplCopyWith<$Res>
    implements $AssetsSectionCopyWith<$Res> {
  factory _$$AssetsSectionImplCopyWith(
          _$AssetsSectionImpl value, $Res Function(_$AssetsSectionImpl) then) =
      __$$AssetsSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double primaryResidenceValue,
      double otherRealEstateValue,
      double vehicleValue,
      double fixedDeposits,
      double equityPortfolio,
      double mutualFunds,
      double goldJewellery,
      double retirementCorpus,
      double currentEmergencyFund,
      CreditScoreTier creditScoreTier});
}

/// @nodoc
class __$$AssetsSectionImplCopyWithImpl<$Res>
    extends _$AssetsSectionCopyWithImpl<$Res, _$AssetsSectionImpl>
    implements _$$AssetsSectionImplCopyWith<$Res> {
  __$$AssetsSectionImplCopyWithImpl(
      _$AssetsSectionImpl _value, $Res Function(_$AssetsSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of AssetsSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primaryResidenceValue = null,
    Object? otherRealEstateValue = null,
    Object? vehicleValue = null,
    Object? fixedDeposits = null,
    Object? equityPortfolio = null,
    Object? mutualFunds = null,
    Object? goldJewellery = null,
    Object? retirementCorpus = null,
    Object? currentEmergencyFund = null,
    Object? creditScoreTier = null,
  }) {
    return _then(_$AssetsSectionImpl(
      primaryResidenceValue: null == primaryResidenceValue
          ? _value.primaryResidenceValue
          : primaryResidenceValue // ignore: cast_nullable_to_non_nullable
              as double,
      otherRealEstateValue: null == otherRealEstateValue
          ? _value.otherRealEstateValue
          : otherRealEstateValue // ignore: cast_nullable_to_non_nullable
              as double,
      vehicleValue: null == vehicleValue
          ? _value.vehicleValue
          : vehicleValue // ignore: cast_nullable_to_non_nullable
              as double,
      fixedDeposits: null == fixedDeposits
          ? _value.fixedDeposits
          : fixedDeposits // ignore: cast_nullable_to_non_nullable
              as double,
      equityPortfolio: null == equityPortfolio
          ? _value.equityPortfolio
          : equityPortfolio // ignore: cast_nullable_to_non_nullable
              as double,
      mutualFunds: null == mutualFunds
          ? _value.mutualFunds
          : mutualFunds // ignore: cast_nullable_to_non_nullable
              as double,
      goldJewellery: null == goldJewellery
          ? _value.goldJewellery
          : goldJewellery // ignore: cast_nullable_to_non_nullable
              as double,
      retirementCorpus: null == retirementCorpus
          ? _value.retirementCorpus
          : retirementCorpus // ignore: cast_nullable_to_non_nullable
              as double,
      currentEmergencyFund: null == currentEmergencyFund
          ? _value.currentEmergencyFund
          : currentEmergencyFund // ignore: cast_nullable_to_non_nullable
              as double,
      creditScoreTier: null == creditScoreTier
          ? _value.creditScoreTier
          : creditScoreTier // ignore: cast_nullable_to_non_nullable
              as CreditScoreTier,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetsSectionImpl implements _AssetsSection {
  const _$AssetsSectionImpl(
      {required this.primaryResidenceValue,
      required this.otherRealEstateValue,
      required this.vehicleValue,
      required this.fixedDeposits,
      required this.equityPortfolio,
      required this.mutualFunds,
      required this.goldJewellery,
      required this.retirementCorpus,
      required this.currentEmergencyFund,
      required this.creditScoreTier});

  factory _$AssetsSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetsSectionImplFromJson(json);

// Fixed
  @override
  final double primaryResidenceValue;
  @override
  final double otherRealEstateValue;
  @override
  final double vehicleValue;
// Liquid
  @override
  final double fixedDeposits;
  @override
  final double equityPortfolio;
  @override
  final double mutualFunds;
  @override
  final double goldJewellery;
  @override
  final double retirementCorpus;
  @override
  final double currentEmergencyFund;
  @override
  final CreditScoreTier creditScoreTier;

  @override
  String toString() {
    return 'AssetsSection(primaryResidenceValue: $primaryResidenceValue, otherRealEstateValue: $otherRealEstateValue, vehicleValue: $vehicleValue, fixedDeposits: $fixedDeposits, equityPortfolio: $equityPortfolio, mutualFunds: $mutualFunds, goldJewellery: $goldJewellery, retirementCorpus: $retirementCorpus, currentEmergencyFund: $currentEmergencyFund, creditScoreTier: $creditScoreTier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetsSectionImpl &&
            (identical(other.primaryResidenceValue, primaryResidenceValue) ||
                other.primaryResidenceValue == primaryResidenceValue) &&
            (identical(other.otherRealEstateValue, otherRealEstateValue) ||
                other.otherRealEstateValue == otherRealEstateValue) &&
            (identical(other.vehicleValue, vehicleValue) ||
                other.vehicleValue == vehicleValue) &&
            (identical(other.fixedDeposits, fixedDeposits) ||
                other.fixedDeposits == fixedDeposits) &&
            (identical(other.equityPortfolio, equityPortfolio) ||
                other.equityPortfolio == equityPortfolio) &&
            (identical(other.mutualFunds, mutualFunds) ||
                other.mutualFunds == mutualFunds) &&
            (identical(other.goldJewellery, goldJewellery) ||
                other.goldJewellery == goldJewellery) &&
            (identical(other.retirementCorpus, retirementCorpus) ||
                other.retirementCorpus == retirementCorpus) &&
            (identical(other.currentEmergencyFund, currentEmergencyFund) ||
                other.currentEmergencyFund == currentEmergencyFund) &&
            (identical(other.creditScoreTier, creditScoreTier) ||
                other.creditScoreTier == creditScoreTier));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      primaryResidenceValue,
      otherRealEstateValue,
      vehicleValue,
      fixedDeposits,
      equityPortfolio,
      mutualFunds,
      goldJewellery,
      retirementCorpus,
      currentEmergencyFund,
      creditScoreTier);

  /// Create a copy of AssetsSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetsSectionImplCopyWith<_$AssetsSectionImpl> get copyWith =>
      __$$AssetsSectionImplCopyWithImpl<_$AssetsSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetsSectionImplToJson(
      this,
    );
  }
}

abstract class _AssetsSection implements AssetsSection {
  const factory _AssetsSection(
      {required final double primaryResidenceValue,
      required final double otherRealEstateValue,
      required final double vehicleValue,
      required final double fixedDeposits,
      required final double equityPortfolio,
      required final double mutualFunds,
      required final double goldJewellery,
      required final double retirementCorpus,
      required final double currentEmergencyFund,
      required final CreditScoreTier creditScoreTier}) = _$AssetsSectionImpl;

  factory _AssetsSection.fromJson(Map<String, dynamic> json) =
      _$AssetsSectionImpl.fromJson;

// Fixed
  @override
  double get primaryResidenceValue;
  @override
  double get otherRealEstateValue;
  @override
  double get vehicleValue; // Liquid
  @override
  double get fixedDeposits;
  @override
  double get equityPortfolio;
  @override
  double get mutualFunds;
  @override
  double get goldJewellery;
  @override
  double get retirementCorpus;
  @override
  double get currentEmergencyFund;
  @override
  CreditScoreTier get creditScoreTier;

  /// Create a copy of AssetsSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetsSectionImplCopyWith<_$AssetsSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LifeCoverSection _$LifeCoverSectionFromJson(Map<String, dynamic> json) {
  return _LifeCoverSection.fromJson(json);
}

/// @nodoc
mixin _$LifeCoverSection {
  double get personalTermCoverAmount => throw _privateConstructorUsedError;
  double get personalEndowmentCoverAmount => throw _privateConstructorUsedError;
  double get corporateGroupTermAmount => throw _privateConstructorUsedError;
  bool get hasPersonalTermPolicy => throw _privateConstructorUsedError;

  /// Serializes this LifeCoverSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LifeCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LifeCoverSectionCopyWith<LifeCoverSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LifeCoverSectionCopyWith<$Res> {
  factory $LifeCoverSectionCopyWith(
          LifeCoverSection value, $Res Function(LifeCoverSection) then) =
      _$LifeCoverSectionCopyWithImpl<$Res, LifeCoverSection>;
  @useResult
  $Res call(
      {double personalTermCoverAmount,
      double personalEndowmentCoverAmount,
      double corporateGroupTermAmount,
      bool hasPersonalTermPolicy});
}

/// @nodoc
class _$LifeCoverSectionCopyWithImpl<$Res, $Val extends LifeCoverSection>
    implements $LifeCoverSectionCopyWith<$Res> {
  _$LifeCoverSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LifeCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personalTermCoverAmount = null,
    Object? personalEndowmentCoverAmount = null,
    Object? corporateGroupTermAmount = null,
    Object? hasPersonalTermPolicy = null,
  }) {
    return _then(_value.copyWith(
      personalTermCoverAmount: null == personalTermCoverAmount
          ? _value.personalTermCoverAmount
          : personalTermCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      personalEndowmentCoverAmount: null == personalEndowmentCoverAmount
          ? _value.personalEndowmentCoverAmount
          : personalEndowmentCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      corporateGroupTermAmount: null == corporateGroupTermAmount
          ? _value.corporateGroupTermAmount
          : corporateGroupTermAmount // ignore: cast_nullable_to_non_nullable
              as double,
      hasPersonalTermPolicy: null == hasPersonalTermPolicy
          ? _value.hasPersonalTermPolicy
          : hasPersonalTermPolicy // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LifeCoverSectionImplCopyWith<$Res>
    implements $LifeCoverSectionCopyWith<$Res> {
  factory _$$LifeCoverSectionImplCopyWith(_$LifeCoverSectionImpl value,
          $Res Function(_$LifeCoverSectionImpl) then) =
      __$$LifeCoverSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double personalTermCoverAmount,
      double personalEndowmentCoverAmount,
      double corporateGroupTermAmount,
      bool hasPersonalTermPolicy});
}

/// @nodoc
class __$$LifeCoverSectionImplCopyWithImpl<$Res>
    extends _$LifeCoverSectionCopyWithImpl<$Res, _$LifeCoverSectionImpl>
    implements _$$LifeCoverSectionImplCopyWith<$Res> {
  __$$LifeCoverSectionImplCopyWithImpl(_$LifeCoverSectionImpl _value,
      $Res Function(_$LifeCoverSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of LifeCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personalTermCoverAmount = null,
    Object? personalEndowmentCoverAmount = null,
    Object? corporateGroupTermAmount = null,
    Object? hasPersonalTermPolicy = null,
  }) {
    return _then(_$LifeCoverSectionImpl(
      personalTermCoverAmount: null == personalTermCoverAmount
          ? _value.personalTermCoverAmount
          : personalTermCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      personalEndowmentCoverAmount: null == personalEndowmentCoverAmount
          ? _value.personalEndowmentCoverAmount
          : personalEndowmentCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      corporateGroupTermAmount: null == corporateGroupTermAmount
          ? _value.corporateGroupTermAmount
          : corporateGroupTermAmount // ignore: cast_nullable_to_non_nullable
              as double,
      hasPersonalTermPolicy: null == hasPersonalTermPolicy
          ? _value.hasPersonalTermPolicy
          : hasPersonalTermPolicy // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LifeCoverSectionImpl implements _LifeCoverSection {
  const _$LifeCoverSectionImpl(
      {required this.personalTermCoverAmount,
      required this.personalEndowmentCoverAmount,
      required this.corporateGroupTermAmount,
      required this.hasPersonalTermPolicy});

  factory _$LifeCoverSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LifeCoverSectionImplFromJson(json);

  @override
  final double personalTermCoverAmount;
  @override
  final double personalEndowmentCoverAmount;
  @override
  final double corporateGroupTermAmount;
  @override
  final bool hasPersonalTermPolicy;

  @override
  String toString() {
    return 'LifeCoverSection(personalTermCoverAmount: $personalTermCoverAmount, personalEndowmentCoverAmount: $personalEndowmentCoverAmount, corporateGroupTermAmount: $corporateGroupTermAmount, hasPersonalTermPolicy: $hasPersonalTermPolicy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LifeCoverSectionImpl &&
            (identical(
                    other.personalTermCoverAmount, personalTermCoverAmount) ||
                other.personalTermCoverAmount == personalTermCoverAmount) &&
            (identical(other.personalEndowmentCoverAmount,
                    personalEndowmentCoverAmount) ||
                other.personalEndowmentCoverAmount ==
                    personalEndowmentCoverAmount) &&
            (identical(
                    other.corporateGroupTermAmount, corporateGroupTermAmount) ||
                other.corporateGroupTermAmount == corporateGroupTermAmount) &&
            (identical(other.hasPersonalTermPolicy, hasPersonalTermPolicy) ||
                other.hasPersonalTermPolicy == hasPersonalTermPolicy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      personalTermCoverAmount,
      personalEndowmentCoverAmount,
      corporateGroupTermAmount,
      hasPersonalTermPolicy);

  /// Create a copy of LifeCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LifeCoverSectionImplCopyWith<_$LifeCoverSectionImpl> get copyWith =>
      __$$LifeCoverSectionImplCopyWithImpl<_$LifeCoverSectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LifeCoverSectionImplToJson(
      this,
    );
  }
}

abstract class _LifeCoverSection implements LifeCoverSection {
  const factory _LifeCoverSection(
      {required final double personalTermCoverAmount,
      required final double personalEndowmentCoverAmount,
      required final double corporateGroupTermAmount,
      required final bool hasPersonalTermPolicy}) = _$LifeCoverSectionImpl;

  factory _LifeCoverSection.fromJson(Map<String, dynamic> json) =
      _$LifeCoverSectionImpl.fromJson;

  @override
  double get personalTermCoverAmount;
  @override
  double get personalEndowmentCoverAmount;
  @override
  double get corporateGroupTermAmount;
  @override
  bool get hasPersonalTermPolicy;

  /// Create a copy of LifeCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LifeCoverSectionImplCopyWith<_$LifeCoverSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HealthCoverSection _$HealthCoverSectionFromJson(Map<String, dynamic> json) {
  return _HealthCoverSection.fromJson(json);
}

/// @nodoc
mixin _$HealthCoverSection {
  double get personalHealthCoverAmount => throw _privateConstructorUsedError;
  double get corporateHealthCoverAmount => throw _privateConstructorUsedError;
  double get parentsHealthCoverAmount => throw _privateConstructorUsedError;
  bool get hasCriticalIllnessRider => throw _privateConstructorUsedError;
  bool get hasDisabilityRider => throw _privateConstructorUsedError;
  bool get coverIncludesPreExisting => throw _privateConstructorUsedError;

  /// Serializes this HealthCoverSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthCoverSectionCopyWith<HealthCoverSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthCoverSectionCopyWith<$Res> {
  factory $HealthCoverSectionCopyWith(
          HealthCoverSection value, $Res Function(HealthCoverSection) then) =
      _$HealthCoverSectionCopyWithImpl<$Res, HealthCoverSection>;
  @useResult
  $Res call(
      {double personalHealthCoverAmount,
      double corporateHealthCoverAmount,
      double parentsHealthCoverAmount,
      bool hasCriticalIllnessRider,
      bool hasDisabilityRider,
      bool coverIncludesPreExisting});
}

/// @nodoc
class _$HealthCoverSectionCopyWithImpl<$Res, $Val extends HealthCoverSection>
    implements $HealthCoverSectionCopyWith<$Res> {
  _$HealthCoverSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personalHealthCoverAmount = null,
    Object? corporateHealthCoverAmount = null,
    Object? parentsHealthCoverAmount = null,
    Object? hasCriticalIllnessRider = null,
    Object? hasDisabilityRider = null,
    Object? coverIncludesPreExisting = null,
  }) {
    return _then(_value.copyWith(
      personalHealthCoverAmount: null == personalHealthCoverAmount
          ? _value.personalHealthCoverAmount
          : personalHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      corporateHealthCoverAmount: null == corporateHealthCoverAmount
          ? _value.corporateHealthCoverAmount
          : corporateHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      parentsHealthCoverAmount: null == parentsHealthCoverAmount
          ? _value.parentsHealthCoverAmount
          : parentsHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      hasCriticalIllnessRider: null == hasCriticalIllnessRider
          ? _value.hasCriticalIllnessRider
          : hasCriticalIllnessRider // ignore: cast_nullable_to_non_nullable
              as bool,
      hasDisabilityRider: null == hasDisabilityRider
          ? _value.hasDisabilityRider
          : hasDisabilityRider // ignore: cast_nullable_to_non_nullable
              as bool,
      coverIncludesPreExisting: null == coverIncludesPreExisting
          ? _value.coverIncludesPreExisting
          : coverIncludesPreExisting // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthCoverSectionImplCopyWith<$Res>
    implements $HealthCoverSectionCopyWith<$Res> {
  factory _$$HealthCoverSectionImplCopyWith(_$HealthCoverSectionImpl value,
          $Res Function(_$HealthCoverSectionImpl) then) =
      __$$HealthCoverSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double personalHealthCoverAmount,
      double corporateHealthCoverAmount,
      double parentsHealthCoverAmount,
      bool hasCriticalIllnessRider,
      bool hasDisabilityRider,
      bool coverIncludesPreExisting});
}

/// @nodoc
class __$$HealthCoverSectionImplCopyWithImpl<$Res>
    extends _$HealthCoverSectionCopyWithImpl<$Res, _$HealthCoverSectionImpl>
    implements _$$HealthCoverSectionImplCopyWith<$Res> {
  __$$HealthCoverSectionImplCopyWithImpl(_$HealthCoverSectionImpl _value,
      $Res Function(_$HealthCoverSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of HealthCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? personalHealthCoverAmount = null,
    Object? corporateHealthCoverAmount = null,
    Object? parentsHealthCoverAmount = null,
    Object? hasCriticalIllnessRider = null,
    Object? hasDisabilityRider = null,
    Object? coverIncludesPreExisting = null,
  }) {
    return _then(_$HealthCoverSectionImpl(
      personalHealthCoverAmount: null == personalHealthCoverAmount
          ? _value.personalHealthCoverAmount
          : personalHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      corporateHealthCoverAmount: null == corporateHealthCoverAmount
          ? _value.corporateHealthCoverAmount
          : corporateHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      parentsHealthCoverAmount: null == parentsHealthCoverAmount
          ? _value.parentsHealthCoverAmount
          : parentsHealthCoverAmount // ignore: cast_nullable_to_non_nullable
              as double,
      hasCriticalIllnessRider: null == hasCriticalIllnessRider
          ? _value.hasCriticalIllnessRider
          : hasCriticalIllnessRider // ignore: cast_nullable_to_non_nullable
              as bool,
      hasDisabilityRider: null == hasDisabilityRider
          ? _value.hasDisabilityRider
          : hasDisabilityRider // ignore: cast_nullable_to_non_nullable
              as bool,
      coverIncludesPreExisting: null == coverIncludesPreExisting
          ? _value.coverIncludesPreExisting
          : coverIncludesPreExisting // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthCoverSectionImpl implements _HealthCoverSection {
  const _$HealthCoverSectionImpl(
      {required this.personalHealthCoverAmount,
      required this.corporateHealthCoverAmount,
      required this.parentsHealthCoverAmount,
      required this.hasCriticalIllnessRider,
      required this.hasDisabilityRider,
      required this.coverIncludesPreExisting});

  factory _$HealthCoverSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthCoverSectionImplFromJson(json);

  @override
  final double personalHealthCoverAmount;
  @override
  final double corporateHealthCoverAmount;
  @override
  final double parentsHealthCoverAmount;
  @override
  final bool hasCriticalIllnessRider;
  @override
  final bool hasDisabilityRider;
  @override
  final bool coverIncludesPreExisting;

  @override
  String toString() {
    return 'HealthCoverSection(personalHealthCoverAmount: $personalHealthCoverAmount, corporateHealthCoverAmount: $corporateHealthCoverAmount, parentsHealthCoverAmount: $parentsHealthCoverAmount, hasCriticalIllnessRider: $hasCriticalIllnessRider, hasDisabilityRider: $hasDisabilityRider, coverIncludesPreExisting: $coverIncludesPreExisting)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthCoverSectionImpl &&
            (identical(other.personalHealthCoverAmount,
                    personalHealthCoverAmount) ||
                other.personalHealthCoverAmount == personalHealthCoverAmount) &&
            (identical(other.corporateHealthCoverAmount,
                    corporateHealthCoverAmount) ||
                other.corporateHealthCoverAmount ==
                    corporateHealthCoverAmount) &&
            (identical(
                    other.parentsHealthCoverAmount, parentsHealthCoverAmount) ||
                other.parentsHealthCoverAmount == parentsHealthCoverAmount) &&
            (identical(
                    other.hasCriticalIllnessRider, hasCriticalIllnessRider) ||
                other.hasCriticalIllnessRider == hasCriticalIllnessRider) &&
            (identical(other.hasDisabilityRider, hasDisabilityRider) ||
                other.hasDisabilityRider == hasDisabilityRider) &&
            (identical(
                    other.coverIncludesPreExisting, coverIncludesPreExisting) ||
                other.coverIncludesPreExisting == coverIncludesPreExisting));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      personalHealthCoverAmount,
      corporateHealthCoverAmount,
      parentsHealthCoverAmount,
      hasCriticalIllnessRider,
      hasDisabilityRider,
      coverIncludesPreExisting);

  /// Create a copy of HealthCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthCoverSectionImplCopyWith<_$HealthCoverSectionImpl> get copyWith =>
      __$$HealthCoverSectionImplCopyWithImpl<_$HealthCoverSectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthCoverSectionImplToJson(
      this,
    );
  }
}

abstract class _HealthCoverSection implements HealthCoverSection {
  const factory _HealthCoverSection(
      {required final double personalHealthCoverAmount,
      required final double corporateHealthCoverAmount,
      required final double parentsHealthCoverAmount,
      required final bool hasCriticalIllnessRider,
      required final bool hasDisabilityRider,
      required final bool coverIncludesPreExisting}) = _$HealthCoverSectionImpl;

  factory _HealthCoverSection.fromJson(Map<String, dynamic> json) =
      _$HealthCoverSectionImpl.fromJson;

  @override
  double get personalHealthCoverAmount;
  @override
  double get corporateHealthCoverAmount;
  @override
  double get parentsHealthCoverAmount;
  @override
  bool get hasCriticalIllnessRider;
  @override
  bool get hasDisabilityRider;
  @override
  bool get coverIncludesPreExisting;

  /// Create a copy of HealthCoverSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthCoverSectionImplCopyWith<_$HealthCoverSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OtherInsuranceSection _$OtherInsuranceSectionFromJson(
    Map<String, dynamic> json) {
  return _OtherInsuranceSection.fromJson(json);
}

/// @nodoc
mixin _$OtherInsuranceSection {
  bool get hasComprehensiveVehicleCover => throw _privateConstructorUsedError;
  bool get hasHomeStructureInsurance => throw _privateConstructorUsedError;

  /// Serializes this OtherInsuranceSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OtherInsuranceSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OtherInsuranceSectionCopyWith<OtherInsuranceSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtherInsuranceSectionCopyWith<$Res> {
  factory $OtherInsuranceSectionCopyWith(OtherInsuranceSection value,
          $Res Function(OtherInsuranceSection) then) =
      _$OtherInsuranceSectionCopyWithImpl<$Res, OtherInsuranceSection>;
  @useResult
  $Res call(
      {bool hasComprehensiveVehicleCover, bool hasHomeStructureInsurance});
}

/// @nodoc
class _$OtherInsuranceSectionCopyWithImpl<$Res,
        $Val extends OtherInsuranceSection>
    implements $OtherInsuranceSectionCopyWith<$Res> {
  _$OtherInsuranceSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtherInsuranceSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasComprehensiveVehicleCover = null,
    Object? hasHomeStructureInsurance = null,
  }) {
    return _then(_value.copyWith(
      hasComprehensiveVehicleCover: null == hasComprehensiveVehicleCover
          ? _value.hasComprehensiveVehicleCover
          : hasComprehensiveVehicleCover // ignore: cast_nullable_to_non_nullable
              as bool,
      hasHomeStructureInsurance: null == hasHomeStructureInsurance
          ? _value.hasHomeStructureInsurance
          : hasHomeStructureInsurance // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OtherInsuranceSectionImplCopyWith<$Res>
    implements $OtherInsuranceSectionCopyWith<$Res> {
  factory _$$OtherInsuranceSectionImplCopyWith(
          _$OtherInsuranceSectionImpl value,
          $Res Function(_$OtherInsuranceSectionImpl) then) =
      __$$OtherInsuranceSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool hasComprehensiveVehicleCover, bool hasHomeStructureInsurance});
}

/// @nodoc
class __$$OtherInsuranceSectionImplCopyWithImpl<$Res>
    extends _$OtherInsuranceSectionCopyWithImpl<$Res,
        _$OtherInsuranceSectionImpl>
    implements _$$OtherInsuranceSectionImplCopyWith<$Res> {
  __$$OtherInsuranceSectionImplCopyWithImpl(_$OtherInsuranceSectionImpl _value,
      $Res Function(_$OtherInsuranceSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of OtherInsuranceSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasComprehensiveVehicleCover = null,
    Object? hasHomeStructureInsurance = null,
  }) {
    return _then(_$OtherInsuranceSectionImpl(
      hasComprehensiveVehicleCover: null == hasComprehensiveVehicleCover
          ? _value.hasComprehensiveVehicleCover
          : hasComprehensiveVehicleCover // ignore: cast_nullable_to_non_nullable
              as bool,
      hasHomeStructureInsurance: null == hasHomeStructureInsurance
          ? _value.hasHomeStructureInsurance
          : hasHomeStructureInsurance // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OtherInsuranceSectionImpl implements _OtherInsuranceSection {
  const _$OtherInsuranceSectionImpl(
      {required this.hasComprehensiveVehicleCover,
      required this.hasHomeStructureInsurance});

  factory _$OtherInsuranceSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$OtherInsuranceSectionImplFromJson(json);

  @override
  final bool hasComprehensiveVehicleCover;
  @override
  final bool hasHomeStructureInsurance;

  @override
  String toString() {
    return 'OtherInsuranceSection(hasComprehensiveVehicleCover: $hasComprehensiveVehicleCover, hasHomeStructureInsurance: $hasHomeStructureInsurance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtherInsuranceSectionImpl &&
            (identical(other.hasComprehensiveVehicleCover,
                    hasComprehensiveVehicleCover) ||
                other.hasComprehensiveVehicleCover ==
                    hasComprehensiveVehicleCover) &&
            (identical(other.hasHomeStructureInsurance,
                    hasHomeStructureInsurance) ||
                other.hasHomeStructureInsurance == hasHomeStructureInsurance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, hasComprehensiveVehicleCover, hasHomeStructureInsurance);

  /// Create a copy of OtherInsuranceSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtherInsuranceSectionImplCopyWith<_$OtherInsuranceSectionImpl>
      get copyWith => __$$OtherInsuranceSectionImplCopyWithImpl<
          _$OtherInsuranceSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OtherInsuranceSectionImplToJson(
      this,
    );
  }
}

abstract class _OtherInsuranceSection implements OtherInsuranceSection {
  const factory _OtherInsuranceSection(
          {required final bool hasComprehensiveVehicleCover,
          required final bool hasHomeStructureInsurance}) =
      _$OtherInsuranceSectionImpl;

  factory _OtherInsuranceSection.fromJson(Map<String, dynamic> json) =
      _$OtherInsuranceSectionImpl.fromJson;

  @override
  bool get hasComprehensiveVehicleCover;
  @override
  bool get hasHomeStructureInsurance;

  /// Create a copy of OtherInsuranceSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtherInsuranceSectionImplCopyWith<_$OtherInsuranceSectionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GoalsSection _$GoalsSectionFromJson(Map<String, dynamic> json) {
  return _GoalsSection.fromJson(json);
}

/// @nodoc
mixin _$GoalsSection {
  double get termCoverTarget => throw _privateConstructorUsedError;
  double get healthCoverTarget => throw _privateConstructorUsedError;
  double get wealthAccumulationTarget => throw _privateConstructorUsedError;
  int get wealthTargetYears => throw _privateConstructorUsedError;
  List<int> get childrenMilestonesYears => throw _privateConstructorUsedError;
  List<double> get childrenMilestonesBudgets =>
      throw _privateConstructorUsedError;
  int? get targetRetirementAge => throw _privateConstructorUsedError;
  double? get retirementMonthlyIncomeTarget =>
      throw _privateConstructorUsedError;

  /// Serializes this GoalsSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalsSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalsSectionCopyWith<GoalsSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalsSectionCopyWith<$Res> {
  factory $GoalsSectionCopyWith(
          GoalsSection value, $Res Function(GoalsSection) then) =
      _$GoalsSectionCopyWithImpl<$Res, GoalsSection>;
  @useResult
  $Res call(
      {double termCoverTarget,
      double healthCoverTarget,
      double wealthAccumulationTarget,
      int wealthTargetYears,
      List<int> childrenMilestonesYears,
      List<double> childrenMilestonesBudgets,
      int? targetRetirementAge,
      double? retirementMonthlyIncomeTarget});
}

/// @nodoc
class _$GoalsSectionCopyWithImpl<$Res, $Val extends GoalsSection>
    implements $GoalsSectionCopyWith<$Res> {
  _$GoalsSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalsSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? termCoverTarget = null,
    Object? healthCoverTarget = null,
    Object? wealthAccumulationTarget = null,
    Object? wealthTargetYears = null,
    Object? childrenMilestonesYears = null,
    Object? childrenMilestonesBudgets = null,
    Object? targetRetirementAge = freezed,
    Object? retirementMonthlyIncomeTarget = freezed,
  }) {
    return _then(_value.copyWith(
      termCoverTarget: null == termCoverTarget
          ? _value.termCoverTarget
          : termCoverTarget // ignore: cast_nullable_to_non_nullable
              as double,
      healthCoverTarget: null == healthCoverTarget
          ? _value.healthCoverTarget
          : healthCoverTarget // ignore: cast_nullable_to_non_nullable
              as double,
      wealthAccumulationTarget: null == wealthAccumulationTarget
          ? _value.wealthAccumulationTarget
          : wealthAccumulationTarget // ignore: cast_nullable_to_non_nullable
              as double,
      wealthTargetYears: null == wealthTargetYears
          ? _value.wealthTargetYears
          : wealthTargetYears // ignore: cast_nullable_to_non_nullable
              as int,
      childrenMilestonesYears: null == childrenMilestonesYears
          ? _value.childrenMilestonesYears
          : childrenMilestonesYears // ignore: cast_nullable_to_non_nullable
              as List<int>,
      childrenMilestonesBudgets: null == childrenMilestonesBudgets
          ? _value.childrenMilestonesBudgets
          : childrenMilestonesBudgets // ignore: cast_nullable_to_non_nullable
              as List<double>,
      targetRetirementAge: freezed == targetRetirementAge
          ? _value.targetRetirementAge
          : targetRetirementAge // ignore: cast_nullable_to_non_nullable
              as int?,
      retirementMonthlyIncomeTarget: freezed == retirementMonthlyIncomeTarget
          ? _value.retirementMonthlyIncomeTarget
          : retirementMonthlyIncomeTarget // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalsSectionImplCopyWith<$Res>
    implements $GoalsSectionCopyWith<$Res> {
  factory _$$GoalsSectionImplCopyWith(
          _$GoalsSectionImpl value, $Res Function(_$GoalsSectionImpl) then) =
      __$$GoalsSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double termCoverTarget,
      double healthCoverTarget,
      double wealthAccumulationTarget,
      int wealthTargetYears,
      List<int> childrenMilestonesYears,
      List<double> childrenMilestonesBudgets,
      int? targetRetirementAge,
      double? retirementMonthlyIncomeTarget});
}

/// @nodoc
class __$$GoalsSectionImplCopyWithImpl<$Res>
    extends _$GoalsSectionCopyWithImpl<$Res, _$GoalsSectionImpl>
    implements _$$GoalsSectionImplCopyWith<$Res> {
  __$$GoalsSectionImplCopyWithImpl(
      _$GoalsSectionImpl _value, $Res Function(_$GoalsSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of GoalsSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? termCoverTarget = null,
    Object? healthCoverTarget = null,
    Object? wealthAccumulationTarget = null,
    Object? wealthTargetYears = null,
    Object? childrenMilestonesYears = null,
    Object? childrenMilestonesBudgets = null,
    Object? targetRetirementAge = freezed,
    Object? retirementMonthlyIncomeTarget = freezed,
  }) {
    return _then(_$GoalsSectionImpl(
      termCoverTarget: null == termCoverTarget
          ? _value.termCoverTarget
          : termCoverTarget // ignore: cast_nullable_to_non_nullable
              as double,
      healthCoverTarget: null == healthCoverTarget
          ? _value.healthCoverTarget
          : healthCoverTarget // ignore: cast_nullable_to_non_nullable
              as double,
      wealthAccumulationTarget: null == wealthAccumulationTarget
          ? _value.wealthAccumulationTarget
          : wealthAccumulationTarget // ignore: cast_nullable_to_non_nullable
              as double,
      wealthTargetYears: null == wealthTargetYears
          ? _value.wealthTargetYears
          : wealthTargetYears // ignore: cast_nullable_to_non_nullable
              as int,
      childrenMilestonesYears: null == childrenMilestonesYears
          ? _value._childrenMilestonesYears
          : childrenMilestonesYears // ignore: cast_nullable_to_non_nullable
              as List<int>,
      childrenMilestonesBudgets: null == childrenMilestonesBudgets
          ? _value._childrenMilestonesBudgets
          : childrenMilestonesBudgets // ignore: cast_nullable_to_non_nullable
              as List<double>,
      targetRetirementAge: freezed == targetRetirementAge
          ? _value.targetRetirementAge
          : targetRetirementAge // ignore: cast_nullable_to_non_nullable
              as int?,
      retirementMonthlyIncomeTarget: freezed == retirementMonthlyIncomeTarget
          ? _value.retirementMonthlyIncomeTarget
          : retirementMonthlyIncomeTarget // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalsSectionImpl implements _GoalsSection {
  const _$GoalsSectionImpl(
      {required this.termCoverTarget,
      required this.healthCoverTarget,
      required this.wealthAccumulationTarget,
      required this.wealthTargetYears,
      required final List<int> childrenMilestonesYears,
      required final List<double> childrenMilestonesBudgets,
      this.targetRetirementAge,
      this.retirementMonthlyIncomeTarget})
      : _childrenMilestonesYears = childrenMilestonesYears,
        _childrenMilestonesBudgets = childrenMilestonesBudgets;

  factory _$GoalsSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalsSectionImplFromJson(json);

  @override
  final double termCoverTarget;
  @override
  final double healthCoverTarget;
  @override
  final double wealthAccumulationTarget;
  @override
  final int wealthTargetYears;
  final List<int> _childrenMilestonesYears;
  @override
  List<int> get childrenMilestonesYears {
    if (_childrenMilestonesYears is EqualUnmodifiableListView)
      return _childrenMilestonesYears;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_childrenMilestonesYears);
  }

  final List<double> _childrenMilestonesBudgets;
  @override
  List<double> get childrenMilestonesBudgets {
    if (_childrenMilestonesBudgets is EqualUnmodifiableListView)
      return _childrenMilestonesBudgets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_childrenMilestonesBudgets);
  }

  @override
  final int? targetRetirementAge;
  @override
  final double? retirementMonthlyIncomeTarget;

  @override
  String toString() {
    return 'GoalsSection(termCoverTarget: $termCoverTarget, healthCoverTarget: $healthCoverTarget, wealthAccumulationTarget: $wealthAccumulationTarget, wealthTargetYears: $wealthTargetYears, childrenMilestonesYears: $childrenMilestonesYears, childrenMilestonesBudgets: $childrenMilestonesBudgets, targetRetirementAge: $targetRetirementAge, retirementMonthlyIncomeTarget: $retirementMonthlyIncomeTarget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalsSectionImpl &&
            (identical(other.termCoverTarget, termCoverTarget) ||
                other.termCoverTarget == termCoverTarget) &&
            (identical(other.healthCoverTarget, healthCoverTarget) ||
                other.healthCoverTarget == healthCoverTarget) &&
            (identical(
                    other.wealthAccumulationTarget, wealthAccumulationTarget) ||
                other.wealthAccumulationTarget == wealthAccumulationTarget) &&
            (identical(other.wealthTargetYears, wealthTargetYears) ||
                other.wealthTargetYears == wealthTargetYears) &&
            const DeepCollectionEquality().equals(
                other._childrenMilestonesYears, _childrenMilestonesYears) &&
            const DeepCollectionEquality().equals(
                other._childrenMilestonesBudgets, _childrenMilestonesBudgets) &&
            (identical(other.targetRetirementAge, targetRetirementAge) ||
                other.targetRetirementAge == targetRetirementAge) &&
            (identical(other.retirementMonthlyIncomeTarget,
                    retirementMonthlyIncomeTarget) ||
                other.retirementMonthlyIncomeTarget ==
                    retirementMonthlyIncomeTarget));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      termCoverTarget,
      healthCoverTarget,
      wealthAccumulationTarget,
      wealthTargetYears,
      const DeepCollectionEquality().hash(_childrenMilestonesYears),
      const DeepCollectionEquality().hash(_childrenMilestonesBudgets),
      targetRetirementAge,
      retirementMonthlyIncomeTarget);

  /// Create a copy of GoalsSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalsSectionImplCopyWith<_$GoalsSectionImpl> get copyWith =>
      __$$GoalsSectionImplCopyWithImpl<_$GoalsSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalsSectionImplToJson(
      this,
    );
  }
}

abstract class _GoalsSection implements GoalsSection {
  const factory _GoalsSection(
      {required final double termCoverTarget,
      required final double healthCoverTarget,
      required final double wealthAccumulationTarget,
      required final int wealthTargetYears,
      required final List<int> childrenMilestonesYears,
      required final List<double> childrenMilestonesBudgets,
      final int? targetRetirementAge,
      final double? retirementMonthlyIncomeTarget}) = _$GoalsSectionImpl;

  factory _GoalsSection.fromJson(Map<String, dynamic> json) =
      _$GoalsSectionImpl.fromJson;

  @override
  double get termCoverTarget;
  @override
  double get healthCoverTarget;
  @override
  double get wealthAccumulationTarget;
  @override
  int get wealthTargetYears;
  @override
  List<int> get childrenMilestonesYears;
  @override
  List<double> get childrenMilestonesBudgets;
  @override
  int? get targetRetirementAge;
  @override
  double? get retirementMonthlyIncomeTarget;

  /// Create a copy of GoalsSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalsSectionImplCopyWith<_$GoalsSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GetHelpSection _$GetHelpSectionFromJson(Map<String, dynamic> json) {
  return _GetHelpSection.fromJson(json);
}

/// @nodoc
mixin _$GetHelpSection {
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  ContactMethod get preferredContactMethod =>
      throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Serializes this GetHelpSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GetHelpSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GetHelpSectionCopyWith<GetHelpSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GetHelpSectionCopyWith<$Res> {
  factory $GetHelpSectionCopyWith(
          GetHelpSection value, $Res Function(GetHelpSection) then) =
      _$GetHelpSectionCopyWithImpl<$Res, GetHelpSection>;
  @useResult
  $Res call(
      {String name,
      String email,
      String phone,
      ContactMethod preferredContactMethod,
      String message});
}

/// @nodoc
class _$GetHelpSectionCopyWithImpl<$Res, $Val extends GetHelpSection>
    implements $GetHelpSectionCopyWith<$Res> {
  _$GetHelpSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GetHelpSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? preferredContactMethod = null,
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      preferredContactMethod: null == preferredContactMethod
          ? _value.preferredContactMethod
          : preferredContactMethod // ignore: cast_nullable_to_non_nullable
              as ContactMethod,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GetHelpSectionImplCopyWith<$Res>
    implements $GetHelpSectionCopyWith<$Res> {
  factory _$$GetHelpSectionImplCopyWith(_$GetHelpSectionImpl value,
          $Res Function(_$GetHelpSectionImpl) then) =
      __$$GetHelpSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String email,
      String phone,
      ContactMethod preferredContactMethod,
      String message});
}

/// @nodoc
class __$$GetHelpSectionImplCopyWithImpl<$Res>
    extends _$GetHelpSectionCopyWithImpl<$Res, _$GetHelpSectionImpl>
    implements _$$GetHelpSectionImplCopyWith<$Res> {
  __$$GetHelpSectionImplCopyWithImpl(
      _$GetHelpSectionImpl _value, $Res Function(_$GetHelpSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of GetHelpSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? preferredContactMethod = null,
    Object? message = null,
  }) {
    return _then(_$GetHelpSectionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      preferredContactMethod: null == preferredContactMethod
          ? _value.preferredContactMethod
          : preferredContactMethod // ignore: cast_nullable_to_non_nullable
              as ContactMethod,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GetHelpSectionImpl implements _GetHelpSection {
  const _$GetHelpSectionImpl(
      {required this.name,
      required this.email,
      required this.phone,
      required this.preferredContactMethod,
      required this.message});

  factory _$GetHelpSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GetHelpSectionImplFromJson(json);

  @override
  final String name;
  @override
  final String email;
  @override
  final String phone;
  @override
  final ContactMethod preferredContactMethod;
  @override
  final String message;

  @override
  String toString() {
    return 'GetHelpSection(name: $name, email: $email, phone: $phone, preferredContactMethod: $preferredContactMethod, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetHelpSectionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.preferredContactMethod, preferredContactMethod) ||
                other.preferredContactMethod == preferredContactMethod) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, email, phone, preferredContactMethod, message);

  /// Create a copy of GetHelpSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetHelpSectionImplCopyWith<_$GetHelpSectionImpl> get copyWith =>
      __$$GetHelpSectionImplCopyWithImpl<_$GetHelpSectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GetHelpSectionImplToJson(
      this,
    );
  }
}

abstract class _GetHelpSection implements GetHelpSection {
  const factory _GetHelpSection(
      {required final String name,
      required final String email,
      required final String phone,
      required final ContactMethod preferredContactMethod,
      required final String message}) = _$GetHelpSectionImpl;

  factory _GetHelpSection.fromJson(Map<String, dynamic> json) =
      _$GetHelpSectionImpl.fromJson;

  @override
  String get name;
  @override
  String get email;
  @override
  String get phone;
  @override
  ContactMethod get preferredContactMethod;
  @override
  String get message;

  /// Create a copy of GetHelpSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetHelpSectionImplCopyWith<_$GetHelpSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiagnosticProfile _$DiagnosticProfileFromJson(Map<String, dynamic> json) {
  return _DiagnosticProfile.fromJson(json);
}

/// @nodoc
mixin _$DiagnosticProfile {
  YouSection get you => throw _privateConstructorUsedError;
  PeopleSection get people => throw _privateConstructorUsedError;
  LifePlansSection get lifePlans => throw _privateConstructorUsedError;
  IncomeSection get income => throw _privateConstructorUsedError;
  ExpensesSection get expenses => throw _privateConstructorUsedError;
  LoansSection get loans => throw _privateConstructorUsedError;
  AssetsSection get assets => throw _privateConstructorUsedError;
  LifeCoverSection get lifeCover => throw _privateConstructorUsedError;
  HealthCoverSection get healthCover => throw _privateConstructorUsedError;
  OtherInsuranceSection get otherInsurance =>
      throw _privateConstructorUsedError;
  GoalsSection get goals => throw _privateConstructorUsedError;
  GetHelpSection get getHelp => throw _privateConstructorUsedError;

  /// Serializes this DiagnosticProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagnosticProfileCopyWith<DiagnosticProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticProfileCopyWith<$Res> {
  factory $DiagnosticProfileCopyWith(
          DiagnosticProfile value, $Res Function(DiagnosticProfile) then) =
      _$DiagnosticProfileCopyWithImpl<$Res, DiagnosticProfile>;
  @useResult
  $Res call(
      {YouSection you,
      PeopleSection people,
      LifePlansSection lifePlans,
      IncomeSection income,
      ExpensesSection expenses,
      LoansSection loans,
      AssetsSection assets,
      LifeCoverSection lifeCover,
      HealthCoverSection healthCover,
      OtherInsuranceSection otherInsurance,
      GoalsSection goals,
      GetHelpSection getHelp});

  $YouSectionCopyWith<$Res> get you;
  $PeopleSectionCopyWith<$Res> get people;
  $LifePlansSectionCopyWith<$Res> get lifePlans;
  $IncomeSectionCopyWith<$Res> get income;
  $ExpensesSectionCopyWith<$Res> get expenses;
  $LoansSectionCopyWith<$Res> get loans;
  $AssetsSectionCopyWith<$Res> get assets;
  $LifeCoverSectionCopyWith<$Res> get lifeCover;
  $HealthCoverSectionCopyWith<$Res> get healthCover;
  $OtherInsuranceSectionCopyWith<$Res> get otherInsurance;
  $GoalsSectionCopyWith<$Res> get goals;
  $GetHelpSectionCopyWith<$Res> get getHelp;
}

/// @nodoc
class _$DiagnosticProfileCopyWithImpl<$Res, $Val extends DiagnosticProfile>
    implements $DiagnosticProfileCopyWith<$Res> {
  _$DiagnosticProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? you = null,
    Object? people = null,
    Object? lifePlans = null,
    Object? income = null,
    Object? expenses = null,
    Object? loans = null,
    Object? assets = null,
    Object? lifeCover = null,
    Object? healthCover = null,
    Object? otherInsurance = null,
    Object? goals = null,
    Object? getHelp = null,
  }) {
    return _then(_value.copyWith(
      you: null == you
          ? _value.you
          : you // ignore: cast_nullable_to_non_nullable
              as YouSection,
      people: null == people
          ? _value.people
          : people // ignore: cast_nullable_to_non_nullable
              as PeopleSection,
      lifePlans: null == lifePlans
          ? _value.lifePlans
          : lifePlans // ignore: cast_nullable_to_non_nullable
              as LifePlansSection,
      income: null == income
          ? _value.income
          : income // ignore: cast_nullable_to_non_nullable
              as IncomeSection,
      expenses: null == expenses
          ? _value.expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as ExpensesSection,
      loans: null == loans
          ? _value.loans
          : loans // ignore: cast_nullable_to_non_nullable
              as LoansSection,
      assets: null == assets
          ? _value.assets
          : assets // ignore: cast_nullable_to_non_nullable
              as AssetsSection,
      lifeCover: null == lifeCover
          ? _value.lifeCover
          : lifeCover // ignore: cast_nullable_to_non_nullable
              as LifeCoverSection,
      healthCover: null == healthCover
          ? _value.healthCover
          : healthCover // ignore: cast_nullable_to_non_nullable
              as HealthCoverSection,
      otherInsurance: null == otherInsurance
          ? _value.otherInsurance
          : otherInsurance // ignore: cast_nullable_to_non_nullable
              as OtherInsuranceSection,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as GoalsSection,
      getHelp: null == getHelp
          ? _value.getHelp
          : getHelp // ignore: cast_nullable_to_non_nullable
              as GetHelpSection,
    ) as $Val);
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YouSectionCopyWith<$Res> get you {
    return $YouSectionCopyWith<$Res>(_value.you, (value) {
      return _then(_value.copyWith(you: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PeopleSectionCopyWith<$Res> get people {
    return $PeopleSectionCopyWith<$Res>(_value.people, (value) {
      return _then(_value.copyWith(people: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LifePlansSectionCopyWith<$Res> get lifePlans {
    return $LifePlansSectionCopyWith<$Res>(_value.lifePlans, (value) {
      return _then(_value.copyWith(lifePlans: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IncomeSectionCopyWith<$Res> get income {
    return $IncomeSectionCopyWith<$Res>(_value.income, (value) {
      return _then(_value.copyWith(income: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExpensesSectionCopyWith<$Res> get expenses {
    return $ExpensesSectionCopyWith<$Res>(_value.expenses, (value) {
      return _then(_value.copyWith(expenses: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LoansSectionCopyWith<$Res> get loans {
    return $LoansSectionCopyWith<$Res>(_value.loans, (value) {
      return _then(_value.copyWith(loans: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AssetsSectionCopyWith<$Res> get assets {
    return $AssetsSectionCopyWith<$Res>(_value.assets, (value) {
      return _then(_value.copyWith(assets: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LifeCoverSectionCopyWith<$Res> get lifeCover {
    return $LifeCoverSectionCopyWith<$Res>(_value.lifeCover, (value) {
      return _then(_value.copyWith(lifeCover: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HealthCoverSectionCopyWith<$Res> get healthCover {
    return $HealthCoverSectionCopyWith<$Res>(_value.healthCover, (value) {
      return _then(_value.copyWith(healthCover: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OtherInsuranceSectionCopyWith<$Res> get otherInsurance {
    return $OtherInsuranceSectionCopyWith<$Res>(_value.otherInsurance, (value) {
      return _then(_value.copyWith(otherInsurance: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GoalsSectionCopyWith<$Res> get goals {
    return $GoalsSectionCopyWith<$Res>(_value.goals, (value) {
      return _then(_value.copyWith(goals: value) as $Val);
    });
  }

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GetHelpSectionCopyWith<$Res> get getHelp {
    return $GetHelpSectionCopyWith<$Res>(_value.getHelp, (value) {
      return _then(_value.copyWith(getHelp: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DiagnosticProfileImplCopyWith<$Res>
    implements $DiagnosticProfileCopyWith<$Res> {
  factory _$$DiagnosticProfileImplCopyWith(_$DiagnosticProfileImpl value,
          $Res Function(_$DiagnosticProfileImpl) then) =
      __$$DiagnosticProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {YouSection you,
      PeopleSection people,
      LifePlansSection lifePlans,
      IncomeSection income,
      ExpensesSection expenses,
      LoansSection loans,
      AssetsSection assets,
      LifeCoverSection lifeCover,
      HealthCoverSection healthCover,
      OtherInsuranceSection otherInsurance,
      GoalsSection goals,
      GetHelpSection getHelp});

  @override
  $YouSectionCopyWith<$Res> get you;
  @override
  $PeopleSectionCopyWith<$Res> get people;
  @override
  $LifePlansSectionCopyWith<$Res> get lifePlans;
  @override
  $IncomeSectionCopyWith<$Res> get income;
  @override
  $ExpensesSectionCopyWith<$Res> get expenses;
  @override
  $LoansSectionCopyWith<$Res> get loans;
  @override
  $AssetsSectionCopyWith<$Res> get assets;
  @override
  $LifeCoverSectionCopyWith<$Res> get lifeCover;
  @override
  $HealthCoverSectionCopyWith<$Res> get healthCover;
  @override
  $OtherInsuranceSectionCopyWith<$Res> get otherInsurance;
  @override
  $GoalsSectionCopyWith<$Res> get goals;
  @override
  $GetHelpSectionCopyWith<$Res> get getHelp;
}

/// @nodoc
class __$$DiagnosticProfileImplCopyWithImpl<$Res>
    extends _$DiagnosticProfileCopyWithImpl<$Res, _$DiagnosticProfileImpl>
    implements _$$DiagnosticProfileImplCopyWith<$Res> {
  __$$DiagnosticProfileImplCopyWithImpl(_$DiagnosticProfileImpl _value,
      $Res Function(_$DiagnosticProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? you = null,
    Object? people = null,
    Object? lifePlans = null,
    Object? income = null,
    Object? expenses = null,
    Object? loans = null,
    Object? assets = null,
    Object? lifeCover = null,
    Object? healthCover = null,
    Object? otherInsurance = null,
    Object? goals = null,
    Object? getHelp = null,
  }) {
    return _then(_$DiagnosticProfileImpl(
      you: null == you
          ? _value.you
          : you // ignore: cast_nullable_to_non_nullable
              as YouSection,
      people: null == people
          ? _value.people
          : people // ignore: cast_nullable_to_non_nullable
              as PeopleSection,
      lifePlans: null == lifePlans
          ? _value.lifePlans
          : lifePlans // ignore: cast_nullable_to_non_nullable
              as LifePlansSection,
      income: null == income
          ? _value.income
          : income // ignore: cast_nullable_to_non_nullable
              as IncomeSection,
      expenses: null == expenses
          ? _value.expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as ExpensesSection,
      loans: null == loans
          ? _value.loans
          : loans // ignore: cast_nullable_to_non_nullable
              as LoansSection,
      assets: null == assets
          ? _value.assets
          : assets // ignore: cast_nullable_to_non_nullable
              as AssetsSection,
      lifeCover: null == lifeCover
          ? _value.lifeCover
          : lifeCover // ignore: cast_nullable_to_non_nullable
              as LifeCoverSection,
      healthCover: null == healthCover
          ? _value.healthCover
          : healthCover // ignore: cast_nullable_to_non_nullable
              as HealthCoverSection,
      otherInsurance: null == otherInsurance
          ? _value.otherInsurance
          : otherInsurance // ignore: cast_nullable_to_non_nullable
              as OtherInsuranceSection,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as GoalsSection,
      getHelp: null == getHelp
          ? _value.getHelp
          : getHelp // ignore: cast_nullable_to_non_nullable
              as GetHelpSection,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiagnosticProfileImpl implements _DiagnosticProfile {
  const _$DiagnosticProfileImpl(
      {required this.you,
      required this.people,
      required this.lifePlans,
      required this.income,
      required this.expenses,
      required this.loans,
      required this.assets,
      required this.lifeCover,
      required this.healthCover,
      required this.otherInsurance,
      required this.goals,
      required this.getHelp});

  factory _$DiagnosticProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiagnosticProfileImplFromJson(json);

  @override
  final YouSection you;
  @override
  final PeopleSection people;
  @override
  final LifePlansSection lifePlans;
  @override
  final IncomeSection income;
  @override
  final ExpensesSection expenses;
  @override
  final LoansSection loans;
  @override
  final AssetsSection assets;
  @override
  final LifeCoverSection lifeCover;
  @override
  final HealthCoverSection healthCover;
  @override
  final OtherInsuranceSection otherInsurance;
  @override
  final GoalsSection goals;
  @override
  final GetHelpSection getHelp;

  @override
  String toString() {
    return 'DiagnosticProfile(you: $you, people: $people, lifePlans: $lifePlans, income: $income, expenses: $expenses, loans: $loans, assets: $assets, lifeCover: $lifeCover, healthCover: $healthCover, otherInsurance: $otherInsurance, goals: $goals, getHelp: $getHelp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticProfileImpl &&
            (identical(other.you, you) || other.you == you) &&
            (identical(other.people, people) || other.people == people) &&
            (identical(other.lifePlans, lifePlans) ||
                other.lifePlans == lifePlans) &&
            (identical(other.income, income) || other.income == income) &&
            (identical(other.expenses, expenses) ||
                other.expenses == expenses) &&
            (identical(other.loans, loans) || other.loans == loans) &&
            (identical(other.assets, assets) || other.assets == assets) &&
            (identical(other.lifeCover, lifeCover) ||
                other.lifeCover == lifeCover) &&
            (identical(other.healthCover, healthCover) ||
                other.healthCover == healthCover) &&
            (identical(other.otherInsurance, otherInsurance) ||
                other.otherInsurance == otherInsurance) &&
            (identical(other.goals, goals) || other.goals == goals) &&
            (identical(other.getHelp, getHelp) || other.getHelp == getHelp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      you,
      people,
      lifePlans,
      income,
      expenses,
      loans,
      assets,
      lifeCover,
      healthCover,
      otherInsurance,
      goals,
      getHelp);

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticProfileImplCopyWith<_$DiagnosticProfileImpl> get copyWith =>
      __$$DiagnosticProfileImplCopyWithImpl<_$DiagnosticProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiagnosticProfileImplToJson(
      this,
    );
  }
}

abstract class _DiagnosticProfile implements DiagnosticProfile {
  const factory _DiagnosticProfile(
      {required final YouSection you,
      required final PeopleSection people,
      required final LifePlansSection lifePlans,
      required final IncomeSection income,
      required final ExpensesSection expenses,
      required final LoansSection loans,
      required final AssetsSection assets,
      required final LifeCoverSection lifeCover,
      required final HealthCoverSection healthCover,
      required final OtherInsuranceSection otherInsurance,
      required final GoalsSection goals,
      required final GetHelpSection getHelp}) = _$DiagnosticProfileImpl;

  factory _DiagnosticProfile.fromJson(Map<String, dynamic> json) =
      _$DiagnosticProfileImpl.fromJson;

  @override
  YouSection get you;
  @override
  PeopleSection get people;
  @override
  LifePlansSection get lifePlans;
  @override
  IncomeSection get income;
  @override
  ExpensesSection get expenses;
  @override
  LoansSection get loans;
  @override
  AssetsSection get assets;
  @override
  LifeCoverSection get lifeCover;
  @override
  HealthCoverSection get healthCover;
  @override
  OtherInsuranceSection get otherInsurance;
  @override
  GoalsSection get goals;
  @override
  GetHelpSection get getHelp;

  /// Create a copy of DiagnosticProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagnosticProfileImplCopyWith<_$DiagnosticProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

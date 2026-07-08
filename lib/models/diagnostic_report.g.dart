// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalFundingResultImpl _$$GoalFundingResultImplFromJson(
        Map<String, dynamic> json) =>
    _$GoalFundingResultImpl(
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      yearsNeeded: (json['yearsNeeded'] as num).toInt(),
      projectedSavings: (json['projectedSavings'] as num).toDouble(),
      fundingGap: (json['fundingGap'] as num).toDouble(),
    );

Map<String, dynamic> _$$GoalFundingResultImplToJson(
        _$GoalFundingResultImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'targetAmount': instance.targetAmount,
      'yearsNeeded': instance.yearsNeeded,
      'projectedSavings': instance.projectedSavings,
      'fundingGap': instance.fundingGap,
    };

_$CashFlowBreakdownImpl _$$CashFlowBreakdownImplFromJson(
        Map<String, dynamic> json) =>
    _$CashFlowBreakdownImpl(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$$CashFlowBreakdownImplToJson(
        _$CashFlowBreakdownImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'amount': instance.amount,
      'percentage': instance.percentage,
    };

_$ActionItemImpl _$$ActionItemImplFromJson(Map<String, dynamic> json) =>
    _$ActionItemImpl(
      priority: (json['priority'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$ActionCategoryEnumMap, json['category']),
      monetaryTarget: (json['monetaryTarget'] as num?)?.toDouble(),
      timelineMonths: (json['timelineMonths'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ActionItemImplToJson(_$ActionItemImpl instance) =>
    <String, dynamic>{
      'priority': instance.priority,
      'title': instance.title,
      'description': instance.description,
      'category': _$ActionCategoryEnumMap[instance.category]!,
      'monetaryTarget': instance.monetaryTarget,
      'timelineMonths': instance.timelineMonths,
    };

const _$ActionCategoryEnumMap = {
  ActionCategory.protection: 'protection',
  ActionCategory.debt: 'debt',
  ActionCategory.savings: 'savings',
  ActionCategory.emergency: 'emergency',
  ActionCategory.goal: 'goal',
};

_$DiagnosticReportImpl _$$DiagnosticReportImplFromJson(
        Map<String, dynamic> json) =>
    _$DiagnosticReportImpl(
      verdict: $enumDecode(_$DiagnosticVerdictEnumMap, json['verdict']),
      monthlySurplus: (json['monthlySurplus'] as num).toDouble(),
      netWorth: (json['netWorth'] as num).toDouble(),
      emergencyFundTargetMonths:
          (json['emergencyFundTargetMonths'] as num).toInt(),
      emergencyFundTarget: (json['emergencyFundTarget'] as num).toDouble(),
      emergencyFundGap: (json['emergencyFundGap'] as num).toDouble(),
      termCoverGap: (json['termCoverGap'] as num).toDouble(),
      healthCoverGap: (json['healthCoverGap'] as num).toDouble(),
      debtPayoff: const DebtPayoffResultConverter()
          .fromJson(json['debtPayoff'] as Map<String, dynamic>),
      goalFunding: (json['goalFunding'] as List<dynamic>)
          .map((e) => GoalFundingResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      cashFlowBreakdown: (json['cashFlowBreakdown'] as List<dynamic>)
          .map((e) => CashFlowBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      checklist: (json['checklist'] as List<dynamic>)
          .map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$$DiagnosticReportImplToJson(
        _$DiagnosticReportImpl instance) =>
    <String, dynamic>{
      'verdict': _$DiagnosticVerdictEnumMap[instance.verdict]!,
      'monthlySurplus': instance.monthlySurplus,
      'netWorth': instance.netWorth,
      'emergencyFundTargetMonths': instance.emergencyFundTargetMonths,
      'emergencyFundTarget': instance.emergencyFundTarget,
      'emergencyFundGap': instance.emergencyFundGap,
      'termCoverGap': instance.termCoverGap,
      'healthCoverGap': instance.healthCoverGap,
      'debtPayoff':
          const DebtPayoffResultConverter().toJson(instance.debtPayoff),
      'goalFunding': instance.goalFunding,
      'cashFlowBreakdown': instance.cashFlowBreakdown,
      'checklist': instance.checklist,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };

const _$DiagnosticVerdictEnumMap = {
  DiagnosticVerdict.excellent: 'excellent',
  DiagnosticVerdict.good: 'good',
  DiagnosticVerdict.needsAttention: 'needsAttention',
  DiagnosticVerdict.critical: 'critical',
};

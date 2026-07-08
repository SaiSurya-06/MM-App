import 'package:freezed_annotation/freezed_annotation.dart';

part 'diagnostic_report.freezed.dart';
part 'diagnostic_report.g.dart';

enum DiagnosticVerdict { excellent, good, needsAttention, critical }
enum ActionCategory { protection, debt, savings, emergency, goal }

class DebtPayoffSchedule {
  final int month;
  final Map<String, double> remainingBalances;
  final double interestPaidThisMonth;
  final double principalPaidThisMonth;
  final double totalPaymentThisMonth;

  DebtPayoffSchedule({
    required this.month,
    required this.remainingBalances,
    required this.interestPaidThisMonth,
    required this.principalPaidThisMonth,
    required this.totalPaymentThisMonth,
  });

  Map<String, dynamic> toJson() => {
        'month': month,
        'remainingBalances': remainingBalances,
        'interestPaidThisMonth': interestPaidThisMonth,
        'principalPaidThisMonth': principalPaidThisMonth,
        'totalPaymentThisMonth': totalPaymentThisMonth,
      };

  factory DebtPayoffSchedule.fromJson(Map<String, dynamic> json) =>
      DebtPayoffSchedule(
        month: json['month'] as int,
        remainingBalances:
            Map<String, double>.from(json['remainingBalances'] as Map),
        interestPaidThisMonth: (json['interestPaidThisMonth'] as num).toDouble(),
        principalPaidThisMonth:
            (json['principalPaidThisMonth'] as num).toDouble(),
        totalPaymentThisMonth: (json['totalPaymentThisMonth'] as num).toDouble(),
      );
}

class DebtPayoffResult {
  final List<DebtPayoffSchedule> avalanche;
  final List<DebtPayoffSchedule> snowball;
  final int avalancheMonths;
  final int snowballMonths;
  final double totalInterestAvalanche;
  final double totalInterestSnowball;

  DebtPayoffResult({
    required this.avalanche,
    required this.snowball,
    required this.avalancheMonths,
    required this.snowballMonths,
    required this.totalInterestAvalanche,
    required this.totalInterestSnowball,
  });

  Map<String, dynamic> toJson() => {
        'avalanche': avalanche.map((s) => s.toJson()).toList(),
        'snowball': snowball.map((s) => s.toJson()).toList(),
        'avalancheMonths': avalancheMonths,
        'snowballMonths': snowballMonths,
        'totalInterestAvalanche': totalInterestAvalanche,
        'totalInterestSnowball': totalInterestSnowball,
      };

  factory DebtPayoffResult.fromJson(Map<String, dynamic> json) =>
      DebtPayoffResult(
        avalanche: (json['avalanche'] as List)
            .map((e) => DebtPayoffSchedule.fromJson(e as Map<String, dynamic>))
            .toList(),
        snowball: (json['snowball'] as List)
            .map((e) => DebtPayoffSchedule.fromJson(e as Map<String, dynamic>))
            .toList(),
        avalancheMonths: json['avalancheMonths'] as int,
        snowballMonths: json['snowballMonths'] as int,
        totalInterestAvalanche:
            (json['totalInterestAvalanche'] as num).toDouble(),
        totalInterestSnowball:
            (json['totalInterestSnowball'] as num).toDouble(),
      );
}

@freezed
class GoalFundingResult with _$GoalFundingResult {
  const factory GoalFundingResult({
    required String name,
    required double targetAmount,
    required int yearsNeeded,
    required double projectedSavings,
    required double fundingGap,
  }) = _GoalFundingResult;

  factory GoalFundingResult.fromJson(Map<String, dynamic> json) =>
      _$GoalFundingResultFromJson(json);
}

@freezed
class CashFlowBreakdown with _$CashFlowBreakdown {
  const factory CashFlowBreakdown({
    required String category,
    required double amount,
    required double percentage,
  }) = _CashFlowBreakdown;

  factory CashFlowBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CashFlowBreakdownFromJson(json);
}

@freezed
class ActionItem with _$ActionItem {
  const factory ActionItem({
    required int priority, // 1 = most urgent
    required String title,
    required String description,
    required ActionCategory category, // protection, debt, savings, emergency, goal
    double? monetaryTarget,
    int? timelineMonths,
  }) = _ActionItem;

  factory ActionItem.fromJson(Map<String, dynamic> json) =>
      _$ActionItemFromJson(json);
}

// Custom converter to handle DebtPayoffResult in json_serializable
class DebtPayoffResultConverter
    implements JsonConverter<DebtPayoffResult, Map<String, dynamic>> {
  const DebtPayoffResultConverter();

  @override
  DebtPayoffResult fromJson(Map<String, dynamic> json) =>
      DebtPayoffResult.fromJson(json);

  @override
  Map<String, dynamic> toJson(DebtPayoffResult object) => object.toJson();
}

@freezed
class DiagnosticReport with _$DiagnosticReport {
  const factory DiagnosticReport({
    required DiagnosticVerdict verdict, // overall health category
    required double monthlySurplus,
    required double netWorth,
    required int emergencyFundTargetMonths,
    required double emergencyFundTarget, // in currency units
    required double emergencyFundGap,
    required double termCoverGap,
    required double healthCoverGap,
    @DebtPayoffResultConverter() required DebtPayoffResult debtPayoff,
    required List<GoalFundingResult> goalFunding,
    required List<CashFlowBreakdown> cashFlowBreakdown, // for donut chart
    required List<ActionItem> checklist,
    required DateTime generatedAt,
  }) = _DiagnosticReport;

  factory DiagnosticReport.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticReportFromJson(json);
}

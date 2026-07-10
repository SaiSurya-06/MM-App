import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'money_intelligence_provider.dart';
import '../core/analytics/models/money_intelligence_report.dart';
import '../core/analytics/models/financial_insight.dart';
import '../core/analytics/models/visualization_models.dart';
import '../core/analytics/models/spending_velocity.dart';

class MoneyMapState {
  final double safeToSpendToday;
  final int daysRemaining;
  final double leftThisMonth;
  final double upcomingBills;
  final double savingsProgress;
  final double budgetHealthScore;
  final String rating;
  final List<FinancialInsight> insights;
  final List<FlowBarItem> flowBars;
  final SpendingVelocity? velocity;
  final bool isLoading;
  final String? errorMessage;

  MoneyMapState({
    required this.safeToSpendToday,
    required this.daysRemaining,
    required this.leftThisMonth,
    required this.upcomingBills,
    required this.savingsProgress,
    required this.budgetHealthScore,
    required this.rating,
    required this.insights,
    required this.flowBars,
    this.velocity,
    required this.isLoading,
    this.errorMessage,
  });

  MoneyMapState copyWith({
    double? safeToSpendToday,
    int? daysRemaining,
    double? leftThisMonth,
    double? upcomingBills,
    double? savingsProgress,
    double? budgetHealthScore,
    String? rating,
    List<FinancialInsight>? insights,
    List<FlowBarItem>? flowBars,
    SpendingVelocity? velocity,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MoneyMapState(
      safeToSpendToday: safeToSpendToday ?? this.safeToSpendToday,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      leftThisMonth: leftThisMonth ?? this.leftThisMonth,
      upcomingBills: upcomingBills ?? this.upcomingBills,
      savingsProgress: savingsProgress ?? this.savingsProgress,
      budgetHealthScore: budgetHealthScore ?? this.budgetHealthScore,
      rating: rating ?? this.rating,
      insights: insights ?? this.insights,
      flowBars: flowBars ?? this.flowBars,
      velocity: velocity ?? this.velocity,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MoneyMapViewModel extends StateNotifier<MoneyMapState> {
  final Ref _ref;

  MoneyMapViewModel(this._ref)
      : super(MoneyMapState(
          safeToSpendToday: 0.0,
          daysRemaining: 15,
          leftThisMonth: 0.0,
          upcomingBills: 0.0,
          savingsProgress: 0.0,
          budgetHealthScore: 100.0,
          rating: 'Good',
          insights: [],
          flowBars: [],
          isLoading: true,
        )) {
    // Listen to changes in the intelligence report and update state
    _ref.listen<MoneyIntelligenceState>(moneyIntelligenceProvider, (previous, next) {
      if (next.report != null) {
        _updateFromReport(next.report!);
      } else if (next.errorMessage != null) {
        state = state.copyWith(isLoading: false, errorMessage: next.errorMessage);
      }
    });
    
    // Initial fetch if report exists
    final currentIntel = _ref.read(moneyIntelligenceProvider);
    if (currentIntel.report != null) {
      _updateFromReport(currentIntel.report!);
    }
  }

  void _updateFromReport(MoneyIntelligenceReport report) {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final elapsedDays = now.day;
    final int remainingDays = totalDays - elapsedDays > 0 ? totalDays - elapsedDays : 1;

    // Safe to Spend Today calculation
    // Amortize unpaid Essentials (Needs) + credit card balances over remaining days
    final double essentials = report.snapshot.essentials;
    final double safeSpend = (report.snapshot.moneyLeft - (essentials * 0.2)) / remainingDays;

    state = MoneyMapState(
      safeToSpendToday: safeSpend > 0 ? safeSpend : 0.0,
      daysRemaining: remainingDays,
      leftThisMonth: report.snapshot.moneyLeft,
      upcomingBills: essentials,
      savingsProgress: report.snapshot.savings + report.snapshot.investments,
      budgetHealthScore: report.health.score,
      rating: report.health.rating,
      insights: report.insights,
      flowBars: report.visualizations.flowBars,
      velocity: report.velocity,
      isLoading: false,
    );
  }
}

final moneyMapViewModelProvider = StateNotifierProvider<MoneyMapViewModel, MoneyMapState>((ref) {
  return MoneyMapViewModel(ref);
});

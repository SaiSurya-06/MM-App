import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../core/database/database.dart';
import '../core/analytics/financial_snapshot_builder.dart';
import '../core/analytics/money_intelligence_engine.dart';
import '../core/analytics/models/money_intelligence_report.dart';
import 'transactions_provider.dart';
import 'budgets_provider.dart';
import 'savings_goals_provider.dart';
import 'debts_provider.dart';
import 'accounts_provider.dart';

class MoneyIntelligenceState {
  final MoneyIntelligenceReport? report;
  final String selectedMonth; // e.g. '2026-07'
  final double simulatedPurchaseAmount;
  final bool isLoading;
  final String? errorMessage;

  MoneyIntelligenceState({
    this.report,
    required this.selectedMonth,
    this.simulatedPurchaseAmount = 0.0,
    this.isLoading = false,
    this.errorMessage,
  });

  MoneyIntelligenceState copyWith({
    MoneyIntelligenceReport? report,
    String? selectedMonth,
    double? simulatedPurchaseAmount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MoneyIntelligenceState(
      report: report ?? this.report,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      simulatedPurchaseAmount: simulatedPurchaseAmount ?? this.simulatedPurchaseAmount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MoneyIntelligenceNotifier extends StateNotifier<MoneyIntelligenceState> {
  final Ref _ref;
  final FinancialSnapshotBuilder _builder = FinancialSnapshotBuilder();

  MoneyIntelligenceNotifier(this._ref)
      : super(MoneyIntelligenceState(
          selectedMonth: DateTime.now().toIso8601String().substring(0, 7),
        )) {
    // Watch relevant providers to invalidate cache and recalculate reactively
    _ref.listen(transactionsProvider, (previous, next) {
      debugPrint('[Riverpod] Transactions updated. Re-running analytics.');
      _recalculate();
    });
    _ref.listen(budgetsProvider, (previous, next) {
      debugPrint('[Riverpod] Budgets updated. Re-running analytics.');
      _recalculate();
    });
    _ref.listen(savingsGoalsProvider, (previous, next) {
      debugPrint('[Riverpod] Savings goals updated. Re-running analytics.');
      _recalculate();
    });
    _ref.listen(debtsProvider, (previous, next) {
      debugPrint('[Riverpod] Debts updated. Re-running analytics.');
      _recalculate();
    });
    _ref.listen(accountsProvider, (previous, next) {
      debugPrint('[Riverpod] Accounts updated. Re-running analytics.');
      _recalculate();
    });

    _recalculate();
  }

  Future<void> _recalculate() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final snapshot = await _builder.build(state.selectedMonth);
      final report = await MoneyIntelligenceOrchestrator.instance.orchestrate(
        snapshot,
        simulatedPurchaseAmount: state.simulatedPurchaseAmount,
      );

      // Auto-archive report to Time Machine database
      await _archiveReportToTimeMachine(state.selectedMonth, report);

      state = state.copyWith(report: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Intelligence calculation error: $e');
    }
  }

  Future<void> selectMonth(String month) async {
    if (state.selectedMonth == month) return;
    state = state.copyWith(selectedMonth: month, simulatedPurchaseAmount: 0.0);
    await _recalculate();
  }

  Future<void> runSimulatedPurchase(double amount) async {
    state = state.copyWith(simulatedPurchaseAmount: amount);
    await _recalculate();
  }

  Future<void> _archiveReportToTimeMachine(String month, MoneyIntelligenceReport report) async {
    try {
      final db = await AppDatabase.instance.database;
      final reportJson = jsonEncode(report.toJson());
      final updatedAt = DateTime.now().toIso8601String();

      await db.insert(
        'intelligence_report_history',
        {
          'month': month,
          'report_json': reportJson,
          'updated_at': updatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[TimeMachine] Failed to archive report: $e');
    }
  }

  // Load archived report for the Time Machine capability
  Future<MoneyIntelligenceReport?> getArchivedReport(String month) async {
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        'intelligence_report_history',
        where: 'month = ?',
        whereArgs: [month],
      );
      if (results.isEmpty) return null;
      return null;
    } catch (_) {
      return null;
    }
  }
}

final moneyIntelligenceProvider = StateNotifierProvider<MoneyIntelligenceNotifier, MoneyIntelligenceState>((ref) {
  return MoneyIntelligenceNotifier(ref);
});

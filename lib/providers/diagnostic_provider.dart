import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/diagnostic_profile_dao.dart';
import '../core/analytics/ai_analyst.dart';
import '../core/services/diagnostic_pdf_service.dart';
import '../models/diagnostic_profile.dart';
import '../models/diagnostic_report.dart';
import 'auth_provider.dart';

class DiagnosticState {
  final DiagnosticProfile profile;
  final int currentActIndex;
  final int currentSectionIndex;
  final bool isLoading;
  final bool isSaving;
  final DiagnosticReport? report;

  DiagnosticState({
    required this.profile,
    this.currentActIndex = 0,
    this.currentSectionIndex = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.report,
  });

  DiagnosticState copyWith({
    DiagnosticProfile? profile,
    int? currentActIndex,
    int? currentSectionIndex,
    bool? isLoading,
    bool? isSaving,
    DiagnosticReport? report,
    bool clearReport = false,
  }) {
    return DiagnosticState(
      profile: profile ?? this.profile,
      currentActIndex: currentActIndex ?? this.currentActIndex,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      report: clearReport ? null : (report ?? this.report),
    );
  }
}

class DiagnosticNotifier extends StateNotifier<DiagnosticState> {
  final Ref ref;
  final DiagnosticProfileDao _dao = DiagnosticProfileDao();
  Timer? _saveTimer;
  int? _currentUserId;

  DiagnosticNotifier(this.ref)
      : super(DiagnosticState(profile: DiagnosticProfile.empty())) {
    _init();
  }

  void _init() {
    // Watch auth status changes to load correct user profile
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.profile?.id != _currentUserId) {
        _currentUserId = next.profile?.id;
        if (_currentUserId != null) {
          loadOrCreate();
        } else {
          state = DiagnosticState(profile: DiagnosticProfile.empty());
        }
      }
    });

    _currentUserId = ref.read(authProvider).profile?.id;
    if (_currentUserId != null) {
      loadOrCreate();
    }
  }

  Future<void> loadOrCreate() async {
    if (_currentUserId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final record = await _dao.getActiveProfile(_currentUserId!);
      if (record != null) {
        // If a completed report exists, generate its calculations too
        DiagnosticReport? rep;
        if (record.completed) {
          rep = await AiAnalyst.generateDiagnosticReport(record.profile);
        }
        state = DiagnosticState(
          profile: record.profile,
          currentActIndex: record.currentAct,
          currentSectionIndex: record.currentSection,
          report: rep,
        );
      } else {
        state = DiagnosticState(profile: DiagnosticProfile.empty());
      }
    } catch (_) {
      state = DiagnosticState(profile: DiagnosticProfile.empty());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSection<T>(T sectionData) {
    final p = state.profile;
    DiagnosticProfile updatedProfile = p;

    if (sectionData is YouSection) {
      updatedProfile = p.copyWith(you: sectionData);
    } else if (sectionData is PeopleSection) {
      updatedProfile = p.copyWith(people: sectionData);
    } else if (sectionData is LifePlansSection) {
      updatedProfile = p.copyWith(lifePlans: sectionData);
    } else if (sectionData is IncomeSection) {
      updatedProfile = p.copyWith(income: sectionData);
    } else if (sectionData is ExpensesSection) {
      updatedProfile = p.copyWith(expenses: sectionData);
    } else if (sectionData is LoansSection) {
      updatedProfile = p.copyWith(loans: sectionData);
    } else if (sectionData is AssetsSection) {
      updatedProfile = p.copyWith(assets: sectionData);
    } else if (sectionData is LifeCoverSection) {
      updatedProfile = p.copyWith(lifeCover: sectionData);
    } else if (sectionData is HealthCoverSection) {
      updatedProfile = p.copyWith(healthCover: sectionData);
    } else if (sectionData is OtherInsuranceSection) {
      updatedProfile = p.copyWith(otherInsurance: sectionData);
    } else if (sectionData is GoalsSection) {
      updatedProfile = p.copyWith(goals: sectionData);
    } else if (sectionData is GetHelpSection) {
      updatedProfile = p.copyWith(getHelp: sectionData);
    }

    state = state.copyWith(profile: updatedProfile);
    _debounceSave();
  }

  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveToDb();
    });
  }

  Future<void> _saveToDb() async {
    if (_currentUserId == null) return;
    state = state.copyWith(isSaving: true);
    try {
      final record = DiagnosticProfileRecord(
        userProfileId: _currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentAct: state.currentActIndex,
        currentSection: state.currentSectionIndex,
        completed: state.report != null,
        profile: state.profile,
      );
      await _dao.upsertProfile(record);
    } catch (_) {
      // ignore
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  void navigateTo(int actIndex, int sectionIndex) {
    state = state.copyWith(
      currentActIndex: actIndex,
      currentSectionIndex: sectionIndex,
    );
    _saveToDb();
  }

  Future<void> generateReport() async {
    state = state.copyWith(isLoading: true);
    try {
      final rep = await AiAnalyst.generateDiagnosticReport(state.profile);
      state = state.copyWith(report: rep);

      if (_currentUserId != null) {
        final existing = await _dao.getActiveProfile(_currentUserId!);
        if (existing != null && existing.id != null) {
          await _dao.markCompleted(existing.id!);
        }
      }
    } catch (_) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> exportPdf() async {
    if (state.report == null) return;
    final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    await DiagnosticPdfService.printReport(state.profile, state.report!, currency);
  }

  Future<void> shareAdvisoryRequest() async {
    final p = state.profile;
    final r = state.report;
    if (r == null) return;

    final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';

    final text = StringBuffer();
    text.writeln('Financial Advisory Request — ${p.getHelp.name}');
    text.writeln('Generated: ${r.generatedAt.toIso8601String().substring(0, 10)}');
    text.writeln();
    text.writeln('=== CONTACT ===');
    text.writeln('Name: ${p.getHelp.name}');
    text.writeln('Email: ${p.getHelp.email}');
    text.writeln('Phone: ${p.getHelp.phone}');
    text.writeln('Preferred: ${p.getHelp.preferredContactMethod.name}');
    text.writeln();
    text.writeln('=== SUMMARY ===');
    text.writeln('Age: ${p.you.age} | Occupation: ${p.you.occupation.name} | City: ${p.you.cityTier.name}');

    double totalIncome = p.income.monthlyBaseSalary +
        p.income.monthlyVariablePay +
        p.income.monthlyFreelanceIncome +
        p.income.monthlyRentalIncome +
        p.income.otherMonthlyIncome;
    if (p.people.hasSpouse) {
      totalIncome += p.people.spouseIncome;
    }

    text.writeln('Monthly Income: $currency ${totalIncome.toStringAsFixed(2)} | Monthly Surplus: $currency ${r.monthlySurplus.toStringAsFixed(2)}');
    text.writeln('Net Worth: $currency ${r.netWorth.toStringAsFixed(2)}');
    text.writeln('Verdict: ${r.verdict.name}');
    text.writeln();
    text.writeln('=== TOP PRIORITIES ===');
    final topActions = r.checklist.take(3).toList();
    for (int i = 0; i < topActions.length; i++) {
      final act = topActions[i];
      text.writeln('${i + 1}. ${act.title}: ${act.description}');
    }
    text.writeln();
    text.writeln('Message: "${p.getHelp.message}"');

    try {
      await Share.share(text.toString(), subject: 'Financial Advisory Request');
    } catch (_) {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: text.toString()));
    }
  }

  Future<void> resetDiagnostic() async {
    if (_currentUserId != null) {
      await _dao.deleteProfile(_currentUserId!);
    }
    state = DiagnosticState(profile: DiagnosticProfile.empty());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final diagnosticProvider =
    StateNotifierProvider<DiagnosticNotifier, DiagnosticState>((ref) {
  return DiagnosticNotifier(ref);
});

// A simple status provider to watch completion & draft status in UI
enum DiagnosticStatus { none, draft, completed }

final diagnosticStatusProvider = Provider<DiagnosticStatus>((ref) {
  final state = ref.watch(diagnosticProvider);
  if (state.report != null) {
    return DiagnosticStatus.completed;
  }
  // Check if any data exists in YouSection name or if they are beyond first step
  if (state.profile.you.name.isNotEmpty ||
      state.currentActIndex > 0 ||
      state.currentSectionIndex > 0) {
    return DiagnosticStatus.draft;
  }
  return DiagnosticStatus.none;
});

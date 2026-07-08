import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/models/diagnostic_profile.dart';
import 'package:money_manager/models/diagnostic_report.dart';
import 'package:money_manager/core/analytics/financial_engine.dart';
import 'package:money_manager/core/analytics/ai_analyst.dart';

void main() {
  group('Diagnostic Analysis Engine Tests', () {
    test('emergencyFundTargetMonths returns 3/6/9 correctly', () {
      final pLow = DiagnosticProfile.empty().copyWith(
        you: YouSection.empty().copyWith(jobStability: JobStability.low),
      );
      expect(FinancialEngine.emergencyFundTargetMonths(pLow), 9);

      final pHighNoDeps = DiagnosticProfile.empty().copyWith(
        you: YouSection.empty().copyWith(jobStability: JobStability.high),
        people: PeopleSection.empty().copyWith(
          hasSpouse: false,
          existingChildren: 0,
          plannedChildren: 0,
          parentsFinanciallyIndependent: true,
        ),
      );
      expect(FinancialEngine.emergencyFundTargetMonths(pHighNoDeps), 3);

      final pMediumWithDeps = DiagnosticProfile.empty().copyWith(
        you: YouSection.empty().copyWith(jobStability: JobStability.medium),
        people: PeopleSection.empty().copyWith(
          existingChildren: 2,
        ),
      );
      expect(FinancialEngine.emergencyFundTargetMonths(pMediumWithDeps), 6);
    });

    test('requiredTermCover computes correctly', () {
      final p = DiagnosticProfile.empty().copyWith(
        income: IncomeSection.empty().copyWith(
          monthlyBaseSalary: 5000.0,
          annualBonusAmount: 10000.0,
        ),
        loans: LoansSection.empty().copyWith(
          loans: [
            const LoanEntry(
              type: LoanType.home,
              label: 'Mortgage',
              outstandingPrincipal: 100000.0,
              monthlyEMI: 1000.0,
              annualInterestRate: 4.0,
              remainingMonths: 120,
              isNecessaryDebt: true,
            ),
          ],
        ),
        people: PeopleSection.empty().copyWith(
          existingChildren: 1, // trigger 15x multiplier
        ),
      );

      // User Monthly = 5000
      // User Annual = 5000 * 12 + 10000 = 70000
      // Multiplier = 15.0 (since has children)
      // Total loans = 100000
      // Required Term Cover = 70000 * 15 + 100000 = 1150000
      expect(FinancialEngine.requiredTermCover(p), 1150000.0);
    });

    test('simulateDebtPayoff total interest paid avalanche <= snowball', () {
      final p = DiagnosticProfile.empty().copyWith(
        income: IncomeSection.empty().copyWith(monthlyBaseSalary: 10000.0),
        expenses: ExpensesSection.empty().copyWith(rent: 1000.0), // Surplus will be high
        loans: LoansSection.empty().copyWith(
          loans: [
            const LoanEntry(
              type: LoanType.personal,
              label: 'Loan 1 (High Rate)',
              outstandingPrincipal: 20000.0,
              monthlyEMI: 500.0,
              annualInterestRate: 15.0,
              remainingMonths: 48,
              isNecessaryDebt: false,
            ),
            const LoanEntry(
              type: LoanType.car,
              label: 'Loan 2 (Low Rate)',
              outstandingPrincipal: 10000.0,
              monthlyEMI: 300.0,
              annualInterestRate: 6.0,
              remainingMonths: 36,
              isNecessaryDebt: true,
            ),
          ],
        ),
      );

      final payoff = FinancialEngine.simulateDebtPayoff(p);
      expect(payoff.totalInterestAvalanche <= payoff.totalInterestSnowball, true);
    });

    test('computeVerdict returns critical when surplus is negative and gaps exist', () async {
      final p = DiagnosticProfile.empty().copyWith(
        income: IncomeSection.empty().copyWith(monthlyBaseSalary: 1000.0),
        expenses: ExpensesSection.empty().copyWith(rent: 1500.0), // Deficit!
        lifeCover: LifeCoverSection.empty(), // Gap!
        healthCover: HealthCoverSection.empty(), // Gap!
      );

      final report = await AiAnalyst.generateDiagnosticReport(p);
      expect(report.verdict, DiagnosticVerdict.critical);
    });
  });
}

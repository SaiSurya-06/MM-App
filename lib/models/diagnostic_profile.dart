import 'package:freezed_annotation/freezed_annotation.dart';

part 'diagnostic_profile.freezed.dart';
part 'diagnostic_profile.g.dart';

enum CityTier { tier1, tier2, tier3, rural }
enum OccupationType { salaried, selfEmployed, professional, business }
enum IncomeType { fixed, variable }
enum JobStability { high, medium, low }
enum MaritalStatus { single, married, divorced, widowed }
enum BonusLikelihood { unlikely, possible, likely, certain }
enum LoanType { home, car, personal, creditCard, education, other }
enum CreditScoreTier { excellent, good, fair, poor, unknown }
enum ContactMethod { email, phone, whatsapp }

@freezed
class LumpSumExpense with _$LumpSumExpense {
  const factory LumpSumExpense({
    required String label,
    required int yearsFromNow,
    required double amount,
  }) = _LumpSumExpense;

  factory LumpSumExpense.fromJson(Map<String, dynamic> json) =>
      _$LumpSumExpenseFromJson(json);
}

@freezed
class LoanEntry with _$LoanEntry {
  const factory LoanEntry({
    required LoanType type,
    required String label,
    required double outstandingPrincipal,
    required double monthlyEMI,
    required double annualInterestRate,
    required int remainingMonths,
    required bool isNecessaryDebt,
  }) = _LoanEntry;

  factory LoanEntry.fromJson(Map<String, dynamic> json) =>
      _$LoanEntryFromJson(json);
}

@freezed
class YouSection with _$YouSection {
  const factory YouSection({
    required String name,
    required int age,
    required CityTier cityTier,
    required OccupationType occupation,
    required IncomeType incomeType,
    required JobStability jobStability,
    required MaritalStatus maritalStatus,
  }) = _YouSection;

  factory YouSection.empty() => const YouSection(
        name: '',
        age: 30,
        cityTier: CityTier.tier1,
        occupation: OccupationType.salaried,
        incomeType: IncomeType.fixed,
        jobStability: JobStability.high,
        maritalStatus: MaritalStatus.single,
      );

  factory YouSection.fromJson(Map<String, dynamic> json) =>
      _$YouSectionFromJson(json);
}

@freezed
class PeopleSection with _$PeopleSection {
  const factory PeopleSection({
    required bool hasSpouse,
    required double spouseIncome,
    OccupationType? spouseOccupation,
    JobStability? spouseJobStability,
    required bool spouseSameEmployer,
    required bool fatherAlive,
    required bool motherAlive,
    required bool parentsFinanciallyIndependent,
    required bool parentsHaveHealthInsurance,
    required bool parentsHavePreExistingConditions,
    required bool siblingsCostSharing,
    required int existingChildren,
    required int plannedChildren,
    int? nextChildYears,
    required bool hasDependencyObligations,
    required double dependencyObligationMonthly,
  }) = _PeopleSection;

  factory PeopleSection.empty() => const PeopleSection(
        hasSpouse: false,
        spouseIncome: 0.0,
        spouseSameEmployer: false,
        fatherAlive: false,
        motherAlive: false,
        parentsFinanciallyIndependent: false,
        parentsHaveHealthInsurance: false,
        parentsHavePreExistingConditions: false,
        siblingsCostSharing: false,
        existingChildren: 0,
        plannedChildren: 0,
        hasDependencyObligations: false,
        dependencyObligationMonthly: 0.0,
      );

  factory PeopleSection.fromJson(Map<String, dynamic> json) =>
      _$PeopleSectionFromJson(json);
}

@freezed
class LifePlansSection with _$LifePlansSection {
  const factory LifePlansSection({
    required bool planningHomePurchase,
    int? homePurchaseYearsFromNow,
    double? homePurchaseBudget,
    required bool planningBusiness,
    int? businessStartupYears,
    double? businessStartupBudget,
    required bool planningRelocation,
    required List<LumpSumExpense> upcomingLumpSumExpenses,
  }) = _LifePlansSection;

  factory LifePlansSection.empty() => const LifePlansSection(
        planningHomePurchase: false,
        planningBusiness: false,
        planningRelocation: false,
        upcomingLumpSumExpenses: [],
      );

  factory LifePlansSection.fromJson(Map<String, dynamic> json) =>
      _$LifePlansSectionFromJson(json);
}

@freezed
class IncomeSection with _$IncomeSection {
  const factory IncomeSection({
    required double monthlyBaseSalary,
    required double monthlyVariablePay,
    required BonusLikelihood annualBonusLikelihood,
    required double annualBonusAmount,
    required double monthlyFreelanceIncome,
    required double monthlyRentalIncome,
    required double otherMonthlyIncome,
    required String otherIncomeLabel,
  }) = _IncomeSection;

  factory IncomeSection.empty() => const IncomeSection(
        monthlyBaseSalary: 0.0,
        monthlyVariablePay: 0.0,
        annualBonusLikelihood: BonusLikelihood.unlikely,
        annualBonusAmount: 0.0,
        monthlyFreelanceIncome: 0.0,
        monthlyRentalIncome: 0.0,
        otherMonthlyIncome: 0.0,
        otherIncomeLabel: '',
      );

  factory IncomeSection.fromJson(Map<String, dynamic> json) =>
      _$IncomeSectionFromJson(json);
}

@freezed
class ExpensesSection with _$ExpensesSection {
  const factory ExpensesSection({
    // Consumption
    required double rent,
    required double foodGroceries,
    required double utilities,
    required double transport,
    required double entertainment,
    required double personalCare,
    // Safety
    required double lifeInsurancePremiumMonthly,
    required double healthInsurancePremiumMonthly,
    required double emergencyFundContributionMonthly,
    // Growth
    required double equityInvestmentMonthly,
    required double debtInvestmentMonthly,
    required double retirementFundMonthly,
  }) = _ExpensesSection;

  factory ExpensesSection.empty() => const ExpensesSection(
        rent: 0.0,
        foodGroceries: 0.0,
        utilities: 0.0,
        transport: 0.0,
        entertainment: 0.0,
        personalCare: 0.0,
        lifeInsurancePremiumMonthly: 0.0,
        healthInsurancePremiumMonthly: 0.0,
        emergencyFundContributionMonthly: 0.0,
        equityInvestmentMonthly: 0.0,
        debtInvestmentMonthly: 0.0,
        retirementFundMonthly: 0.0,
      );

  factory ExpensesSection.fromJson(Map<String, dynamic> json) =>
      _$ExpensesSectionFromJson(json);
}

@freezed
class LoansSection with _$LoansSection {
  const factory LoansSection({
    required List<LoanEntry> loans,
  }) = _LoansSection;

  factory LoansSection.empty() => const LoansSection(
        loans: [],
      );

  factory LoansSection.fromJson(Map<String, dynamic> json) =>
      _$LoansSectionFromJson(json);
}

@freezed
class AssetsSection with _$AssetsSection {
  const factory AssetsSection({
    // Fixed
    required double primaryResidenceValue,
    required double otherRealEstateValue,
    required double vehicleValue,
    // Liquid
    required double fixedDeposits,
    required double equityPortfolio,
    required double mutualFunds,
    required double goldJewellery,
    required double retirementCorpus,
    required double currentEmergencyFund,
    required CreditScoreTier creditScoreTier,
  }) = _AssetsSection;

  factory AssetsSection.empty() => const AssetsSection(
        primaryResidenceValue: 0.0,
        otherRealEstateValue: 0.0,
        vehicleValue: 0.0,
        fixedDeposits: 0.0,
        equityPortfolio: 0.0,
        mutualFunds: 0.0,
        goldJewellery: 0.0,
        retirementCorpus: 0.0,
        currentEmergencyFund: 0.0,
        creditScoreTier: CreditScoreTier.unknown,
      );

  factory AssetsSection.fromJson(Map<String, dynamic> json) =>
      _$AssetsSectionFromJson(json);
}

@freezed
class LifeCoverSection with _$LifeCoverSection {
  const factory LifeCoverSection({
    required double personalTermCoverAmount,
    required double personalEndowmentCoverAmount,
    required double corporateGroupTermAmount,
    required bool hasPersonalTermPolicy,
  }) = _LifeCoverSection;

  factory LifeCoverSection.empty() => const LifeCoverSection(
        personalTermCoverAmount: 0.0,
        personalEndowmentCoverAmount: 0.0,
        corporateGroupTermAmount: 0.0,
        hasPersonalTermPolicy: false,
      );

  factory LifeCoverSection.fromJson(Map<String, dynamic> json) =>
      _$LifeCoverSectionFromJson(json);
}

@freezed
class HealthCoverSection with _$HealthCoverSection {
  const factory HealthCoverSection({
    required double personalHealthCoverAmount,
    required double corporateHealthCoverAmount,
    required double parentsHealthCoverAmount,
    required bool hasCriticalIllnessRider,
    required bool hasDisabilityRider,
    required bool coverIncludesPreExisting,
  }) = _HealthCoverSection;

  factory HealthCoverSection.empty() => const HealthCoverSection(
        personalHealthCoverAmount: 0.0,
        corporateHealthCoverAmount: 0.0,
        parentsHealthCoverAmount: 0.0,
        hasCriticalIllnessRider: false,
        hasDisabilityRider: false,
        coverIncludesPreExisting: false,
      );

  factory HealthCoverSection.fromJson(Map<String, dynamic> json) =>
      _$HealthCoverSectionFromJson(json);
}

@freezed
class OtherInsuranceSection with _$OtherInsuranceSection {
  const factory OtherInsuranceSection({
    required bool hasComprehensiveVehicleCover,
    required bool hasHomeStructureInsurance,
  }) = _OtherInsuranceSection;

  factory OtherInsuranceSection.empty() => const OtherInsuranceSection(
        hasComprehensiveVehicleCover: false,
        hasHomeStructureInsurance: false,
      );

  factory OtherInsuranceSection.fromJson(Map<String, dynamic> json) =>
      _$OtherInsuranceSectionFromJson(json);
}

@freezed
class GoalsSection with _$GoalsSection {
  const factory GoalsSection({
    required double termCoverTarget,
    required double healthCoverTarget,
    required double wealthAccumulationTarget,
    required int wealthTargetYears,
    required List<int> childrenMilestonesYears,
    required List<double> childrenMilestonesBudgets,
    int? targetRetirementAge,
    double? retirementMonthlyIncomeTarget,
  }) = _GoalsSection;

  factory GoalsSection.empty() => const GoalsSection(
        termCoverTarget: 0.0,
        healthCoverTarget: 0.0,
        wealthAccumulationTarget: 0.0,
        wealthTargetYears: 10,
        childrenMilestonesYears: [],
        childrenMilestonesBudgets: [],
      );

  factory GoalsSection.fromJson(Map<String, dynamic> json) =>
      _$GoalsSectionFromJson(json);
}

@freezed
class GetHelpSection with _$GetHelpSection {
  const factory GetHelpSection({
    required String name,
    required String email,
    required String phone,
    required ContactMethod preferredContactMethod,
    required String message,
  }) = _GetHelpSection;

  factory GetHelpSection.empty() => const GetHelpSection(
        name: '',
        email: '',
        phone: '',
        preferredContactMethod: ContactMethod.email,
        message: '',
      );

  factory GetHelpSection.fromJson(Map<String, dynamic> json) =>
      _$GetHelpSectionFromJson(json);
}

@freezed
class DiagnosticProfile with _$DiagnosticProfile {
  const factory DiagnosticProfile({
    required YouSection you,
    required PeopleSection people,
    required LifePlansSection lifePlans,
    required IncomeSection income,
    required ExpensesSection expenses,
    required LoansSection loans,
    required AssetsSection assets,
    required LifeCoverSection lifeCover,
    required HealthCoverSection healthCover,
    required OtherInsuranceSection otherInsurance,
    required GoalsSection goals,
    required GetHelpSection getHelp,
  }) = _DiagnosticProfile;

  factory DiagnosticProfile.empty() => DiagnosticProfile(
        you: YouSection.empty(),
        people: PeopleSection.empty(),
        lifePlans: LifePlansSection.empty(),
        income: IncomeSection.empty(),
        expenses: ExpensesSection.empty(),
        loans: LoansSection.empty(),
        assets: AssetsSection.empty(),
        lifeCover: LifeCoverSection.empty(),
        healthCover: HealthCoverSection.empty(),
        otherInsurance: OtherInsuranceSection.empty(),
        goals: GoalsSection.empty(),
        getHelp: GetHelpSection.empty(),
      );

  factory DiagnosticProfile.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticProfileFromJson(json);
}

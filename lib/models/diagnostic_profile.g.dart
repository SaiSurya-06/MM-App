// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LumpSumExpenseImpl _$$LumpSumExpenseImplFromJson(Map<String, dynamic> json) =>
    _$LumpSumExpenseImpl(
      label: json['label'] as String,
      yearsFromNow: (json['yearsFromNow'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$$LumpSumExpenseImplToJson(
        _$LumpSumExpenseImpl instance) =>
    <String, dynamic>{
      'label': instance.label,
      'yearsFromNow': instance.yearsFromNow,
      'amount': instance.amount,
    };

_$LoanEntryImpl _$$LoanEntryImplFromJson(Map<String, dynamic> json) =>
    _$LoanEntryImpl(
      type: $enumDecode(_$LoanTypeEnumMap, json['type']),
      label: json['label'] as String,
      outstandingPrincipal: (json['outstandingPrincipal'] as num).toDouble(),
      monthlyEMI: (json['monthlyEMI'] as num).toDouble(),
      annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
      remainingMonths: (json['remainingMonths'] as num).toInt(),
      isNecessaryDebt: json['isNecessaryDebt'] as bool,
    );

Map<String, dynamic> _$$LoanEntryImplToJson(_$LoanEntryImpl instance) =>
    <String, dynamic>{
      'type': _$LoanTypeEnumMap[instance.type]!,
      'label': instance.label,
      'outstandingPrincipal': instance.outstandingPrincipal,
      'monthlyEMI': instance.monthlyEMI,
      'annualInterestRate': instance.annualInterestRate,
      'remainingMonths': instance.remainingMonths,
      'isNecessaryDebt': instance.isNecessaryDebt,
    };

const _$LoanTypeEnumMap = {
  LoanType.home: 'home',
  LoanType.car: 'car',
  LoanType.personal: 'personal',
  LoanType.creditCard: 'creditCard',
  LoanType.education: 'education',
  LoanType.other: 'other',
};

_$YouSectionImpl _$$YouSectionImplFromJson(Map<String, dynamic> json) =>
    _$YouSectionImpl(
      name: json['name'] as String,
      age: (json['age'] as num).toInt(),
      cityTier: $enumDecode(_$CityTierEnumMap, json['cityTier']),
      occupation: $enumDecode(_$OccupationTypeEnumMap, json['occupation']),
      incomeType: $enumDecode(_$IncomeTypeEnumMap, json['incomeType']),
      jobStability: $enumDecode(_$JobStabilityEnumMap, json['jobStability']),
      maritalStatus: $enumDecode(_$MaritalStatusEnumMap, json['maritalStatus']),
    );

Map<String, dynamic> _$$YouSectionImplToJson(_$YouSectionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'age': instance.age,
      'cityTier': _$CityTierEnumMap[instance.cityTier]!,
      'occupation': _$OccupationTypeEnumMap[instance.occupation]!,
      'incomeType': _$IncomeTypeEnumMap[instance.incomeType]!,
      'jobStability': _$JobStabilityEnumMap[instance.jobStability]!,
      'maritalStatus': _$MaritalStatusEnumMap[instance.maritalStatus]!,
    };

const _$CityTierEnumMap = {
  CityTier.tier1: 'tier1',
  CityTier.tier2: 'tier2',
  CityTier.tier3: 'tier3',
  CityTier.rural: 'rural',
};

const _$OccupationTypeEnumMap = {
  OccupationType.salaried: 'salaried',
  OccupationType.selfEmployed: 'selfEmployed',
  OccupationType.professional: 'professional',
  OccupationType.business: 'business',
};

const _$IncomeTypeEnumMap = {
  IncomeType.fixed: 'fixed',
  IncomeType.variable: 'variable',
};

const _$JobStabilityEnumMap = {
  JobStability.high: 'high',
  JobStability.medium: 'medium',
  JobStability.low: 'low',
};

const _$MaritalStatusEnumMap = {
  MaritalStatus.single: 'single',
  MaritalStatus.married: 'married',
  MaritalStatus.divorced: 'divorced',
  MaritalStatus.widowed: 'widowed',
};

_$PeopleSectionImpl _$$PeopleSectionImplFromJson(Map<String, dynamic> json) =>
    _$PeopleSectionImpl(
      hasSpouse: json['hasSpouse'] as bool,
      spouseIncome: (json['spouseIncome'] as num).toDouble(),
      spouseOccupation: $enumDecodeNullable(
          _$OccupationTypeEnumMap, json['spouseOccupation']),
      spouseJobStability: $enumDecodeNullable(
          _$JobStabilityEnumMap, json['spouseJobStability']),
      spouseSameEmployer: json['spouseSameEmployer'] as bool,
      fatherAlive: json['fatherAlive'] as bool,
      motherAlive: json['motherAlive'] as bool,
      parentsFinanciallyIndependent:
          json['parentsFinanciallyIndependent'] as bool,
      parentsHaveHealthInsurance: json['parentsHaveHealthInsurance'] as bool,
      parentsHavePreExistingConditions:
          json['parentsHavePreExistingConditions'] as bool,
      siblingsCostSharing: json['siblingsCostSharing'] as bool,
      existingChildren: (json['existingChildren'] as num).toInt(),
      plannedChildren: (json['plannedChildren'] as num).toInt(),
      nextChildYears: (json['nextChildYears'] as num?)?.toInt(),
      hasDependencyObligations: json['hasDependencyObligations'] as bool,
      dependencyObligationMonthly:
          (json['dependencyObligationMonthly'] as num).toDouble(),
    );

Map<String, dynamic> _$$PeopleSectionImplToJson(_$PeopleSectionImpl instance) =>
    <String, dynamic>{
      'hasSpouse': instance.hasSpouse,
      'spouseIncome': instance.spouseIncome,
      'spouseOccupation': _$OccupationTypeEnumMap[instance.spouseOccupation],
      'spouseJobStability': _$JobStabilityEnumMap[instance.spouseJobStability],
      'spouseSameEmployer': instance.spouseSameEmployer,
      'fatherAlive': instance.fatherAlive,
      'motherAlive': instance.motherAlive,
      'parentsFinanciallyIndependent': instance.parentsFinanciallyIndependent,
      'parentsHaveHealthInsurance': instance.parentsHaveHealthInsurance,
      'parentsHavePreExistingConditions':
          instance.parentsHavePreExistingConditions,
      'siblingsCostSharing': instance.siblingsCostSharing,
      'existingChildren': instance.existingChildren,
      'plannedChildren': instance.plannedChildren,
      'nextChildYears': instance.nextChildYears,
      'hasDependencyObligations': instance.hasDependencyObligations,
      'dependencyObligationMonthly': instance.dependencyObligationMonthly,
    };

_$LifePlansSectionImpl _$$LifePlansSectionImplFromJson(
        Map<String, dynamic> json) =>
    _$LifePlansSectionImpl(
      planningHomePurchase: json['planningHomePurchase'] as bool,
      homePurchaseYearsFromNow:
          (json['homePurchaseYearsFromNow'] as num?)?.toInt(),
      homePurchaseBudget: (json['homePurchaseBudget'] as num?)?.toDouble(),
      planningBusiness: json['planningBusiness'] as bool,
      businessStartupYears: (json['businessStartupYears'] as num?)?.toInt(),
      businessStartupBudget:
          (json['businessStartupBudget'] as num?)?.toDouble(),
      planningRelocation: json['planningRelocation'] as bool,
      upcomingLumpSumExpenses:
          (json['upcomingLumpSumExpenses'] as List<dynamic>)
              .map((e) => LumpSumExpense.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$$LifePlansSectionImplToJson(
        _$LifePlansSectionImpl instance) =>
    <String, dynamic>{
      'planningHomePurchase': instance.planningHomePurchase,
      'homePurchaseYearsFromNow': instance.homePurchaseYearsFromNow,
      'homePurchaseBudget': instance.homePurchaseBudget,
      'planningBusiness': instance.planningBusiness,
      'businessStartupYears': instance.businessStartupYears,
      'businessStartupBudget': instance.businessStartupBudget,
      'planningRelocation': instance.planningRelocation,
      'upcomingLumpSumExpenses': instance.upcomingLumpSumExpenses,
    };

_$IncomeSectionImpl _$$IncomeSectionImplFromJson(Map<String, dynamic> json) =>
    _$IncomeSectionImpl(
      monthlyBaseSalary: (json['monthlyBaseSalary'] as num).toDouble(),
      monthlyVariablePay: (json['monthlyVariablePay'] as num).toDouble(),
      annualBonusLikelihood:
          $enumDecode(_$BonusLikelihoodEnumMap, json['annualBonusLikelihood']),
      annualBonusAmount: (json['annualBonusAmount'] as num).toDouble(),
      monthlyFreelanceIncome:
          (json['monthlyFreelanceIncome'] as num).toDouble(),
      monthlyRentalIncome: (json['monthlyRentalIncome'] as num).toDouble(),
      otherMonthlyIncome: (json['otherMonthlyIncome'] as num).toDouble(),
      otherIncomeLabel: json['otherIncomeLabel'] as String,
    );

Map<String, dynamic> _$$IncomeSectionImplToJson(_$IncomeSectionImpl instance) =>
    <String, dynamic>{
      'monthlyBaseSalary': instance.monthlyBaseSalary,
      'monthlyVariablePay': instance.monthlyVariablePay,
      'annualBonusLikelihood':
          _$BonusLikelihoodEnumMap[instance.annualBonusLikelihood]!,
      'annualBonusAmount': instance.annualBonusAmount,
      'monthlyFreelanceIncome': instance.monthlyFreelanceIncome,
      'monthlyRentalIncome': instance.monthlyRentalIncome,
      'otherMonthlyIncome': instance.otherMonthlyIncome,
      'otherIncomeLabel': instance.otherIncomeLabel,
    };

const _$BonusLikelihoodEnumMap = {
  BonusLikelihood.unlikely: 'unlikely',
  BonusLikelihood.possible: 'possible',
  BonusLikelihood.likely: 'likely',
  BonusLikelihood.certain: 'certain',
};

_$ExpensesSectionImpl _$$ExpensesSectionImplFromJson(
        Map<String, dynamic> json) =>
    _$ExpensesSectionImpl(
      rent: (json['rent'] as num).toDouble(),
      foodGroceries: (json['foodGroceries'] as num).toDouble(),
      utilities: (json['utilities'] as num).toDouble(),
      transport: (json['transport'] as num).toDouble(),
      entertainment: (json['entertainment'] as num).toDouble(),
      personalCare: (json['personalCare'] as num).toDouble(),
      lifeInsurancePremiumMonthly:
          (json['lifeInsurancePremiumMonthly'] as num).toDouble(),
      healthInsurancePremiumMonthly:
          (json['healthInsurancePremiumMonthly'] as num).toDouble(),
      emergencyFundContributionMonthly:
          (json['emergencyFundContributionMonthly'] as num).toDouble(),
      equityInvestmentMonthly:
          (json['equityInvestmentMonthly'] as num).toDouble(),
      debtInvestmentMonthly: (json['debtInvestmentMonthly'] as num).toDouble(),
      retirementFundMonthly: (json['retirementFundMonthly'] as num).toDouble(),
    );

Map<String, dynamic> _$$ExpensesSectionImplToJson(
        _$ExpensesSectionImpl instance) =>
    <String, dynamic>{
      'rent': instance.rent,
      'foodGroceries': instance.foodGroceries,
      'utilities': instance.utilities,
      'transport': instance.transport,
      'entertainment': instance.entertainment,
      'personalCare': instance.personalCare,
      'lifeInsurancePremiumMonthly': instance.lifeInsurancePremiumMonthly,
      'healthInsurancePremiumMonthly': instance.healthInsurancePremiumMonthly,
      'emergencyFundContributionMonthly':
          instance.emergencyFundContributionMonthly,
      'equityInvestmentMonthly': instance.equityInvestmentMonthly,
      'debtInvestmentMonthly': instance.debtInvestmentMonthly,
      'retirementFundMonthly': instance.retirementFundMonthly,
    };

_$LoansSectionImpl _$$LoansSectionImplFromJson(Map<String, dynamic> json) =>
    _$LoansSectionImpl(
      loans: (json['loans'] as List<dynamic>)
          .map((e) => LoanEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LoansSectionImplToJson(_$LoansSectionImpl instance) =>
    <String, dynamic>{
      'loans': instance.loans,
    };

_$AssetsSectionImpl _$$AssetsSectionImplFromJson(Map<String, dynamic> json) =>
    _$AssetsSectionImpl(
      primaryResidenceValue: (json['primaryResidenceValue'] as num).toDouble(),
      otherRealEstateValue: (json['otherRealEstateValue'] as num).toDouble(),
      vehicleValue: (json['vehicleValue'] as num).toDouble(),
      fixedDeposits: (json['fixedDeposits'] as num).toDouble(),
      equityPortfolio: (json['equityPortfolio'] as num).toDouble(),
      mutualFunds: (json['mutualFunds'] as num).toDouble(),
      goldJewellery: (json['goldJewellery'] as num).toDouble(),
      retirementCorpus: (json['retirementCorpus'] as num).toDouble(),
      currentEmergencyFund: (json['currentEmergencyFund'] as num).toDouble(),
      creditScoreTier:
          $enumDecode(_$CreditScoreTierEnumMap, json['creditScoreTier']),
    );

Map<String, dynamic> _$$AssetsSectionImplToJson(_$AssetsSectionImpl instance) =>
    <String, dynamic>{
      'primaryResidenceValue': instance.primaryResidenceValue,
      'otherRealEstateValue': instance.otherRealEstateValue,
      'vehicleValue': instance.vehicleValue,
      'fixedDeposits': instance.fixedDeposits,
      'equityPortfolio': instance.equityPortfolio,
      'mutualFunds': instance.mutualFunds,
      'goldJewellery': instance.goldJewellery,
      'retirementCorpus': instance.retirementCorpus,
      'currentEmergencyFund': instance.currentEmergencyFund,
      'creditScoreTier': _$CreditScoreTierEnumMap[instance.creditScoreTier]!,
    };

const _$CreditScoreTierEnumMap = {
  CreditScoreTier.excellent: 'excellent',
  CreditScoreTier.good: 'good',
  CreditScoreTier.fair: 'fair',
  CreditScoreTier.poor: 'poor',
  CreditScoreTier.unknown: 'unknown',
};

_$LifeCoverSectionImpl _$$LifeCoverSectionImplFromJson(
        Map<String, dynamic> json) =>
    _$LifeCoverSectionImpl(
      personalTermCoverAmount:
          (json['personalTermCoverAmount'] as num).toDouble(),
      personalEndowmentCoverAmount:
          (json['personalEndowmentCoverAmount'] as num).toDouble(),
      corporateGroupTermAmount:
          (json['corporateGroupTermAmount'] as num).toDouble(),
      hasPersonalTermPolicy: json['hasPersonalTermPolicy'] as bool,
    );

Map<String, dynamic> _$$LifeCoverSectionImplToJson(
        _$LifeCoverSectionImpl instance) =>
    <String, dynamic>{
      'personalTermCoverAmount': instance.personalTermCoverAmount,
      'personalEndowmentCoverAmount': instance.personalEndowmentCoverAmount,
      'corporateGroupTermAmount': instance.corporateGroupTermAmount,
      'hasPersonalTermPolicy': instance.hasPersonalTermPolicy,
    };

_$HealthCoverSectionImpl _$$HealthCoverSectionImplFromJson(
        Map<String, dynamic> json) =>
    _$HealthCoverSectionImpl(
      personalHealthCoverAmount:
          (json['personalHealthCoverAmount'] as num).toDouble(),
      corporateHealthCoverAmount:
          (json['corporateHealthCoverAmount'] as num).toDouble(),
      parentsHealthCoverAmount:
          (json['parentsHealthCoverAmount'] as num).toDouble(),
      hasCriticalIllnessRider: json['hasCriticalIllnessRider'] as bool,
      hasDisabilityRider: json['hasDisabilityRider'] as bool,
      coverIncludesPreExisting: json['coverIncludesPreExisting'] as bool,
    );

Map<String, dynamic> _$$HealthCoverSectionImplToJson(
        _$HealthCoverSectionImpl instance) =>
    <String, dynamic>{
      'personalHealthCoverAmount': instance.personalHealthCoverAmount,
      'corporateHealthCoverAmount': instance.corporateHealthCoverAmount,
      'parentsHealthCoverAmount': instance.parentsHealthCoverAmount,
      'hasCriticalIllnessRider': instance.hasCriticalIllnessRider,
      'hasDisabilityRider': instance.hasDisabilityRider,
      'coverIncludesPreExisting': instance.coverIncludesPreExisting,
    };

_$OtherInsuranceSectionImpl _$$OtherInsuranceSectionImplFromJson(
        Map<String, dynamic> json) =>
    _$OtherInsuranceSectionImpl(
      hasComprehensiveVehicleCover:
          json['hasComprehensiveVehicleCover'] as bool,
      hasHomeStructureInsurance: json['hasHomeStructureInsurance'] as bool,
    );

Map<String, dynamic> _$$OtherInsuranceSectionImplToJson(
        _$OtherInsuranceSectionImpl instance) =>
    <String, dynamic>{
      'hasComprehensiveVehicleCover': instance.hasComprehensiveVehicleCover,
      'hasHomeStructureInsurance': instance.hasHomeStructureInsurance,
    };

_$GoalsSectionImpl _$$GoalsSectionImplFromJson(Map<String, dynamic> json) =>
    _$GoalsSectionImpl(
      termCoverTarget: (json['termCoverTarget'] as num).toDouble(),
      healthCoverTarget: (json['healthCoverTarget'] as num).toDouble(),
      wealthAccumulationTarget:
          (json['wealthAccumulationTarget'] as num).toDouble(),
      wealthTargetYears: (json['wealthTargetYears'] as num).toInt(),
      childrenMilestonesYears:
          (json['childrenMilestonesYears'] as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList(),
      childrenMilestonesBudgets:
          (json['childrenMilestonesBudgets'] as List<dynamic>)
              .map((e) => (e as num).toDouble())
              .toList(),
      targetRetirementAge: (json['targetRetirementAge'] as num?)?.toInt(),
      retirementMonthlyIncomeTarget:
          (json['retirementMonthlyIncomeTarget'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$GoalsSectionImplToJson(_$GoalsSectionImpl instance) =>
    <String, dynamic>{
      'termCoverTarget': instance.termCoverTarget,
      'healthCoverTarget': instance.healthCoverTarget,
      'wealthAccumulationTarget': instance.wealthAccumulationTarget,
      'wealthTargetYears': instance.wealthTargetYears,
      'childrenMilestonesYears': instance.childrenMilestonesYears,
      'childrenMilestonesBudgets': instance.childrenMilestonesBudgets,
      'targetRetirementAge': instance.targetRetirementAge,
      'retirementMonthlyIncomeTarget': instance.retirementMonthlyIncomeTarget,
    };

_$GetHelpSectionImpl _$$GetHelpSectionImplFromJson(Map<String, dynamic> json) =>
    _$GetHelpSectionImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      preferredContactMethod:
          $enumDecode(_$ContactMethodEnumMap, json['preferredContactMethod']),
      message: json['message'] as String,
    );

Map<String, dynamic> _$$GetHelpSectionImplToJson(
        _$GetHelpSectionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'preferredContactMethod':
          _$ContactMethodEnumMap[instance.preferredContactMethod]!,
      'message': instance.message,
    };

const _$ContactMethodEnumMap = {
  ContactMethod.email: 'email',
  ContactMethod.phone: 'phone',
  ContactMethod.whatsapp: 'whatsapp',
};

_$DiagnosticProfileImpl _$$DiagnosticProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$DiagnosticProfileImpl(
      you: YouSection.fromJson(json['you'] as Map<String, dynamic>),
      people: PeopleSection.fromJson(json['people'] as Map<String, dynamic>),
      lifePlans:
          LifePlansSection.fromJson(json['lifePlans'] as Map<String, dynamic>),
      income: IncomeSection.fromJson(json['income'] as Map<String, dynamic>),
      expenses:
          ExpensesSection.fromJson(json['expenses'] as Map<String, dynamic>),
      loans: LoansSection.fromJson(json['loans'] as Map<String, dynamic>),
      assets: AssetsSection.fromJson(json['assets'] as Map<String, dynamic>),
      lifeCover:
          LifeCoverSection.fromJson(json['lifeCover'] as Map<String, dynamic>),
      healthCover: HealthCoverSection.fromJson(
          json['healthCover'] as Map<String, dynamic>),
      otherInsurance: OtherInsuranceSection.fromJson(
          json['otherInsurance'] as Map<String, dynamic>),
      goals: GoalsSection.fromJson(json['goals'] as Map<String, dynamic>),
      getHelp: GetHelpSection.fromJson(json['getHelp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$DiagnosticProfileImplToJson(
        _$DiagnosticProfileImpl instance) =>
    <String, dynamic>{
      'you': instance.you,
      'people': instance.people,
      'lifePlans': instance.lifePlans,
      'income': instance.income,
      'expenses': instance.expenses,
      'loans': instance.loans,
      'assets': instance.assets,
      'lifeCover': instance.lifeCover,
      'healthCover': instance.healthCover,
      'otherInsurance': instance.otherInsurance,
      'goals': instance.goals,
      'getHelp': instance.getHelp,
    };

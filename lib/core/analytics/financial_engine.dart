import 'dart:math' as math;
import '../../models/budget.dart';
import '../../models/category.dart';
import '../utils/currency_formatter.dart';
import '../../models/diagnostic_profile.dart';
import '../../models/diagnostic_report.dart';

class OptimizationSuggestion {
  final String categoryName;
  final double reductionAmount;

  OptimizationSuggestion({
    required this.categoryName,
    required this.reductionAmount,
  });
}

class GoalOptimizationResult {
  final String recommendationText;
  final List<OptimizationSuggestion> suggestions;
  final double totalProposedSavings;
  final double newSavingsRate;
  final int monthsSaved;

  GoalOptimizationResult({
    required this.recommendationText,
    required this.suggestions,
    required this.totalProposedSavings,
    required this.newSavingsRate,
    required this.monthsSaved,
  });
}

class FinancialEngine {
  /// 1. Holt-Winters Double Exponential Smoothing for forecasting seasonal trend data
  static double forecastDoubleExponentialSmoothing(List<double> history, {double alpha = 0.3, double beta = 0.1}) {
    if (history.isEmpty) return 0.0;
    if (history.length == 1) return history.first;

    // Initialize level (a) and trend (b)
    double level = history[0];
    double trend = history[1] - history[0];

    for (int i = 1; i < history.length; i++) {
      double lastLevel = level;
      level = alpha * history[i] + (1 - alpha) * (level + trend);
      trend = beta * (level - lastLevel) + (1 - beta) * trend;
    }

    // Forecast for 1 step ahead
    final forecast = level + trend;
    return forecast.clamp(0.0, double.infinity);
  }

  /// Helper to approximate the error function (erf) for normal distribution CDF
  static double _erf(double x) {
    // Constants for approximation
    const a1 =  0.254829592;
    const a2 = -0.284496736;
    const a3 =  1.421413741;
    const a4 = -1.453152027;
    const a5 =  1.061405429;
    const p  =  0.3275911;

    final sign = x < 0 ? -1 : 1;
    final absX = x.abs();

    final t = 1.0 / (1.0 + p * absX);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-absX * absX);

    return sign * y;
  }

  /// 2. Calculate dynamic probability of achieving a savings goal using normal distribution CDF
  static double calculateGoalProbability({
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    required List<double> monthlySavingsHistory,
    required double currentMonthlySavingsRate,
  }) {
    final remainingAmount = targetAmount - currentAmount;
    if (remainingAmount <= 0) return 100.0;

    final monthsRemaining = targetDate.difference(DateTime.now()).inDays / 30.43;
    if (monthsRemaining <= 0) return 0.0;

    // Use monthly savings history to compute standard deviation
    double meanSavings = currentMonthlySavingsRate;
    double stdDev = 0.0;

    if (monthlySavingsHistory.length >= 2) {
      final n = monthlySavingsHistory.length;
      meanSavings = monthlySavingsHistory.reduce((a, b) => a + b) / n;
      final variance = monthlySavingsHistory.map((s) => math.pow(s - meanSavings, 2)).reduce((a, b) => a + b) / n;
      stdDev = math.sqrt(variance);
    } else {
      // Default fallback standard deviation if history is sparse (25% of current rate)
      stdDev = (currentMonthlySavingsRate * 0.25).abs();
    }

    // Expected value and variance of cumulative savings over N months
    final expectedCumulativeSavings = meanSavings * monthsRemaining;
    final cumulativeStdDev = stdDev * math.sqrt(monthsRemaining);

    if (cumulativeStdDev <= 1.0) {
      // Avoid division by zero, perform deterministic check
      return expectedCumulativeSavings >= remainingAmount ? 100.0 : 0.0;
    }

    // Z-Score: how many standard deviations away is the target remaining amount
    final zScore = (remainingAmount - expectedCumulativeSavings) / cumulativeStdDev;

    // CDF of Z-score: P(Savings >= remainingAmount) = 1 - CDF(zScore)
    // CDF(z) = 0.5 * (1 + erf(z / sqrt(2)))
    final cdf = 0.5 * (1.0 + _erf(zScore / math.sqrt(2.0)));
    final probability = (1.0 - cdf) * 100.0;

    return probability.clamp(0.0, 100.0);
  }

  /// 3. Goal Optimizer: Computes optimal monthly savings allocations across category budgets
  static GoalOptimizationResult optimizeGoalSavings({
    required double targetAmount,
    required double currentAmount,
    required double currentSavingsRate,
    required List<Budget> budgets,
    required List<Category> categories,
    required Map<int, double> categoryMonthlySpends,
    required int monthsToReduce,
    required String currencyCode,
  }) {
    final remaining = targetAmount - currentAmount;

    if (remaining <= 0) {
      return GoalOptimizationResult(
        recommendationText: "Goal already achieved!",
        suggestions: [],
        totalProposedSavings: 0.0,
        newSavingsRate: currentSavingsRate,
        monthsSaved: 0,
      );
    }

    // If current savings rate is 0 or negative, we cannot calculate current months.
    double baseSavingsRate = currentSavingsRate;
    if (currentSavingsRate <= 10.0) {
      baseSavingsRate = 0.0;
    }

    final double currentMonths = baseSavingsRate > 0 ? (remaining / baseSavingsRate) : double.infinity;
    
    // Target rate
    double targetSavingsRate = 0.0;
    double requiredAdditionalSavings = 0.0;
    
    if (currentMonths.isInfinite || currentMonths > 240) {
      // Suggest saving enough to achieve it in 24 months
      const targetMonths = 24.0;
      targetSavingsRate = remaining / targetMonths;
      requiredAdditionalSavings = targetSavingsRate - baseSavingsRate;
    } else {
      final targetMonths = (currentMonths - monthsToReduce).clamp(1.0, currentMonths);
      targetSavingsRate = remaining / targetMonths;
      requiredAdditionalSavings = targetSavingsRate - baseSavingsRate;
    }

    // Build category map to identify flexibility
    final Map<int, Category> catMap = {for (var c in categories) c.id!: c};

    // Calculate category flexibility weights
    final Map<int, double> flexibilityWeights = {};
    for (var cat in categories) {
      final name = cat.name.toLowerCase();
      if (name.contains('rent') || name.contains('utilit') || name.contains('health') || name.contains('credit card') || cat.type == 'income') {
        flexibilityWeights[cat.id!] = 0.0; // Essential / fixed
      } else if (name.contains('food') || name.contains('grocer')) {
        flexibilityWeights[cat.id!] = 0.5; // Medium flexibility
      } else if (name.contains('transport')) {
        flexibilityWeights[cat.id!] = 0.4; // Medium-low flexibility
      } else if (name.contains('entertain') || name.contains('movie') || name.contains('other') || name.contains('leisure')) {
        flexibilityWeights[cat.id!] = 1.0; // High flexibility
      } else {
        flexibilityWeights[cat.id!] = 0.3; // Default flexibility
      }
    }

    // Collect budgets that can be reduced
    final List<Map<String, dynamic>> reducables = [];
    double totalWeight = 0.0;

    for (var b in budgets) {
      final cat = catMap[b.categoryId];
      if (cat == null) continue;

      final weight = flexibilityWeights[cat.id!] ?? 0.3;
      if (weight <= 0.0) continue;

      // Ensure limit is positive
      if (b.limitAmount <= 10.0) continue;

      reducables.add({
        'budget': b,
        'category': cat,
        'weight': weight,
        'limit': b.limitAmount,
      });
      totalWeight += weight * b.limitAmount;
    }

    if (reducables.isEmpty || totalWeight == 0.0) {
      return GoalOptimizationResult(
        recommendationText: "No flexible budgets found to optimize. Create budgets for flexible categories like Food or Entertainment.",
        suggestions: [],
        totalProposedSavings: 0.0,
        newSavingsRate: currentSavingsRate,
        monthsSaved: 0,
      );
    }

    // Allocate required reductions proportionally
    final List<OptimizationSuggestion> suggestions = [];
    double totalReduction = 0.0;

    for (var item in reducables) {
      final weight = item['weight'] as double;
      final limit = item['limit'] as double;
      final cat = item['category'] as Category;

      // Proportional allocation based on weight & limit size
      final proportion = (weight * limit) / totalWeight;
      double reduction = requiredAdditionalSavings * proportion;

      // Don't reduce a budget by more than 50% of its limit
      final maxReduction = limit * 0.5;
      if (reduction > maxReduction) {
        reduction = maxReduction;
      }

      // Round to readable values
      if (reduction > 100) {
        reduction = (reduction / 50.0).round() * 50.0;
      } else {
        reduction = (reduction / 5.0).round() * 5.0;
      }

      if (reduction > 0) {
        suggestions.add(OptimizationSuggestion(
          categoryName: cat.name,
          reductionAmount: reduction,
        ));
        totalReduction += reduction;
      }
    }

    if (suggestions.isEmpty || totalReduction == 0) {
      return GoalOptimizationResult(
        recommendationText: "Cannot optimize further without reducing essential expenses. Consider extending the goal timeline.",
        suggestions: [],
        totalProposedSavings: 0.0,
        newSavingsRate: currentSavingsRate,
        monthsSaved: 0,
      );
    }

    // Recalculate actual months saved
    final newSavingsRate = baseSavingsRate + totalReduction;
    double actualMonthsSaved = 0.0;
    
    if (baseSavingsRate > 0) {
      final newMonths = remaining / newSavingsRate;
      actualMonthsSaved = currentMonths - newMonths;
    } else {
      actualMonthsSaved = remaining / newSavingsRate;
    }

    // Generate recommendation sentence:
    final suggestionStrings = suggestions.map((s) {
      final formattedAmount = CurrencyFormatter.format(s.reductionAmount, currencyCode);
      return "Reduce ${s.categoryName} by $formattedAmount";
    }).join(", ");

    String recommendationText = "";
    if (baseSavingsRate > 0) {
      if (actualMonthsSaved >= 0.1) {
        recommendationText = "$suggestionStrings → reach goal ${actualMonthsSaved.toStringAsFixed(1)} months earlier";
      } else {
        recommendationText = "$suggestionStrings → reach goal slightly earlier (budgets are small)";
      }
    } else {
      recommendationText = "$suggestionStrings → save enough to achieve goal in ${actualMonthsSaved.toStringAsFixed(1)} months (currently not saving)";
    }

    return GoalOptimizationResult(
      recommendationText: recommendationText,
      suggestions: suggestions,
      totalProposedSavings: totalReduction,
      newSavingsRate: newSavingsRate,
      monthsSaved: actualMonthsSaved.round(),
    );
  }

  // Emergency fund target in months (3, 6, or 9 based on stability + dependents)
  static int emergencyFundTargetMonths(DiagnosticProfile p) {
    if (p.you.jobStability == JobStability.low) {
      return 9;
    }
    final hasDependents = (p.people.hasSpouse && p.people.spouseIncome == 0) ||
        p.people.existingChildren > 0 ||
        p.people.plannedChildren > 0 ||
        ((p.people.fatherAlive || p.people.motherAlive) && !p.people.parentsFinanciallyIndependent) ||
        p.people.hasDependencyObligations;

    if (p.you.jobStability == JobStability.high && !hasDependents) {
      return 3;
    }
    return 6;
  }

  // Monthly consumption total from expenses section
  static double monthlyConsumption(DiagnosticProfile p) {
    final e = p.expenses;
    return e.rent + e.foodGroceries + e.utilities + e.transport + e.entertainment + e.personalCare;
  }

  // Total monthly outflow (consumption + EMIs + insurance + investments)
  static double totalMonthlyOutflow(DiagnosticProfile p) {
    final totalEMI = p.loans.loans.map((l) => l.monthlyEMI).fold(0.0, (a, b) => a + b);
    final insurance = p.expenses.lifeInsurancePremiumMonthly + p.expenses.healthInsurancePremiumMonthly;
    final investments = p.expenses.emergencyFundContributionMonthly +
        p.expenses.equityInvestmentMonthly +
        p.expenses.debtInvestmentMonthly +
        p.expenses.retirementFundMonthly;
    return monthlyConsumption(p) + totalEMI + insurance + investments;
  }

  // Monthly surplus/deficit
  static double monthlySurplus(DiagnosticProfile p) {
    double totalIncome = p.income.monthlyBaseSalary +
        p.income.monthlyVariablePay +
        p.income.monthlyFreelanceIncome +
        p.income.monthlyRentalIncome +
        p.income.otherMonthlyIncome;
    if (p.people.hasSpouse) {
      totalIncome += p.people.spouseIncome;
    }
    return totalIncome - totalMonthlyOutflow(p) - p.people.dependencyObligationMonthly;
  }

  // Debt payoff simulation — returns both avalanche and snowball schedules
  static DebtPayoffResult simulateDebtPayoff(DiagnosticProfile p) {
    final activeLoans = p.loans.loans;
    if (activeLoans.isEmpty) {
      return DebtPayoffResult(
        avalanche: [],
        snowball: [],
        avalancheMonths: 0,
        snowballMonths: 0,
        totalInterestAvalanche: 0.0,
        totalInterestSnowball: 0.0,
      );
    }

    final surplus = monthlySurplus(p);
    final extraPayment = math.max(0.0, surplus * 0.5);

    // 1. Run Avalanche
    final List<DebtPayoffSchedule> avalancheSchedule = [];
    double totalInterestAvalanche = 0.0;
    int avalancheMonths = 0;
    
    // Copy loans state for simulation
    List<_SimLoan> avalancheLoans = activeLoans.map((l) => _SimLoan(
      label: l.label,
      principal: l.outstandingPrincipal,
      emi: l.monthlyEMI,
      rate: l.annualInterestRate / 100 / 12,
    )).toList();

    for (int month = 1; month <= 360; month++) {
      // Sort for Avalanche: highest interest rate first
      avalancheLoans.sort((a, b) => b.rate.compareTo(a.rate));
      
      // Calculate interest accrued
      double monthInterest = 0.0;
      for (final loan in avalancheLoans) {
        if (loan.principal > 0) {
          final interest = loan.principal * loan.rate;
          loan.accruedInterest = interest;
          monthInterest += interest;
        } else {
          loan.accruedInterest = 0.0;
        }
      }
      
      // Check if all loans are paid off
      final activeCount = avalancheLoans.where((l) => l.principal > 0).length;
      if (activeCount == 0) {
        avalancheMonths = month - 1;
        break;
      }
      
      // Minimum payments required
      for (final loan in avalancheLoans) {
        if (loan.principal > 0) {
          final due = loan.principal + loan.accruedInterest;
          loan.tempPayment = math.min(loan.emi, due);
        } else {
          loan.tempPayment = 0.0;
        }
      }
      
      // Extra payment distribution
      double availableExtra = extraPayment;
      for (final loan in avalancheLoans) {
        if (loan.principal > 0) {
          final due = loan.principal + loan.accruedInterest;
          final remainingNeeded = due - loan.tempPayment;
          if (remainingNeeded > 0 && availableExtra > 0) {
            final addPayment = math.min(availableExtra, remainingNeeded);
            loan.tempPayment += addPayment;
            availableExtra -= addPayment;
          }
        }
      }
      
      // Apply payments
      double principalPaidThisMonth = 0.0;
      double totalPaidThisMonth = 0.0;
      final Map<String, double> balances = {};
      
      for (final loan in avalancheLoans) {
        if (loan.principal > 0) {
          final interestPaid = math.min(loan.tempPayment, loan.accruedInterest);
          final principalPaid = loan.tempPayment - interestPaid;
          
          loan.principal = math.max(0.0, loan.principal + loan.accruedInterest - loan.tempPayment);
          totalInterestAvalanche += interestPaid;
          principalPaidThisMonth += principalPaid;
          totalPaidThisMonth += loan.tempPayment;
          
          balances[loan.label] = loan.principal;
        } else {
          balances[loan.label] = 0.0;
        }
      }
      
      avalancheSchedule.add(DebtPayoffSchedule(
        month: month,
        remainingBalances: balances,
        interestPaidThisMonth: monthInterest,
        principalPaidThisMonth: principalPaidThisMonth,
        totalPaymentThisMonth: totalPaidThisMonth,
      ));
      
      if (avalancheLoans.every((l) => l.principal <= 0)) {
        avalancheMonths = month;
        break;
      }
      if (month == 360) {
        avalancheMonths = 360;
      }
    }

    // 2. Run Snowball
    final List<DebtPayoffSchedule> snowballSchedule = [];
    double totalInterestSnowball = 0.0;
    int snowballMonths = 0;
    
    List<_SimLoan> snowballLoans = activeLoans.map((l) => _SimLoan(
      label: l.label,
      principal: l.outstandingPrincipal,
      emi: l.monthlyEMI,
      rate: l.annualInterestRate / 100 / 12,
    )).toList();

    for (int month = 1; month <= 360; month++) {
      // Sort for Snowball: smallest remaining principal first
      snowballLoans.sort((a, b) {
        if (a.principal <= 0 && b.principal > 0) return 1;
        if (b.principal <= 0 && a.principal > 0) return -1;
        return a.principal.compareTo(b.principal);
      });
      
      // Calculate interest accrued
      double monthInterest = 0.0;
      for (final loan in snowballLoans) {
        if (loan.principal > 0) {
          final interest = loan.principal * loan.rate;
          loan.accruedInterest = interest;
          monthInterest += interest;
        } else {
          loan.accruedInterest = 0.0;
        }
      }
      
      // Check if all loans are paid off
      final activeCount = snowballLoans.where((l) => l.principal > 0).length;
      if (activeCount == 0) {
        snowballMonths = month - 1;
        break;
      }
      
      // Minimum payments required
      for (final loan in snowballLoans) {
        if (loan.principal > 0) {
          final due = loan.principal + loan.accruedInterest;
          loan.tempPayment = math.min(loan.emi, due);
        } else {
          loan.tempPayment = 0.0;
        }
      }
      
      // Extra payment distribution
      double availableExtra = extraPayment;
      for (final loan in snowballLoans) {
        if (loan.principal > 0) {
          final due = loan.principal + loan.accruedInterest;
          final remainingNeeded = due - loan.tempPayment;
          if (remainingNeeded > 0 && availableExtra > 0) {
            final addPayment = math.min(availableExtra, remainingNeeded);
            loan.tempPayment += addPayment;
            availableExtra -= addPayment;
          }
        }
      }
      
      // Apply payments
      double principalPaidThisMonth = 0.0;
      double totalPaidThisMonth = 0.0;
      final Map<String, double> balances = {};
      
      for (final loan in snowballLoans) {
        if (loan.principal > 0) {
          final interestPaid = math.min(loan.tempPayment, loan.accruedInterest);
          final principalPaid = loan.tempPayment - interestPaid;
          
          loan.principal = math.max(0.0, loan.principal + loan.accruedInterest - loan.tempPayment);
          totalInterestSnowball += interestPaid;
          principalPaidThisMonth += principalPaid;
          totalPaidThisMonth += loan.tempPayment;
          
          balances[loan.label] = loan.principal;
        } else {
          balances[loan.label] = 0.0;
        }
      }
      
      snowballSchedule.add(DebtPayoffSchedule(
        month: month,
        remainingBalances: balances,
        interestPaidThisMonth: monthInterest,
        principalPaidThisMonth: principalPaidThisMonth,
        totalPaymentThisMonth: totalPaidThisMonth,
      ));
      
      if (snowballLoans.every((l) => l.principal <= 0)) {
        snowballMonths = month;
        break;
      }
      if (month == 360) {
        snowballMonths = 360;
      }
    }

    return DebtPayoffResult(
      avalanche: avalancheSchedule,
      snowball: snowballSchedule,
      avalancheMonths: avalancheMonths,
      snowballMonths: snowballMonths,
      totalInterestAvalanche: totalInterestAvalanche,
      totalInterestSnowball: totalInterestSnowball,
    );
  }

  // Required term cover = (10–15x annual income) + total outstanding loans
  static double requiredTermCover(DiagnosticProfile p) {
    final userMonthly = p.income.monthlyBaseSalary +
        p.income.monthlyVariablePay +
        p.income.monthlyFreelanceIncome +
        p.income.monthlyRentalIncome +
        p.income.otherMonthlyIncome;
    final userAnnual = userMonthly * 12 + p.income.annualBonusAmount;
    final multiplier = (p.people.existingChildren > 0 ||
            p.people.plannedChildren > 0 ||
            (p.people.hasSpouse && p.people.spouseIncome == 0))
        ? 15.0
        : 10.0;
    final totalLoans = p.loans.loans.map((l) => l.outstandingPrincipal).fold(0.0, (a, b) => a + b);
    return (userAnnual * multiplier) + totalLoans;
  }

  // Term cover gap (positive = underinsured, negative = overinsured)
  static double termCoverGap(DiagnosticProfile p) {
    final currentCover = p.lifeCover.personalTermCoverAmount +
        p.lifeCover.corporateGroupTermAmount +
        p.lifeCover.personalEndowmentCoverAmount;
    return requiredTermCover(p) - currentCover;
  }

  // Health cover adequacy check
  static double requiredHealthCover(DiagnosticProfile p) {
    final base = monthlyConsumption(p);
    double factor = 10.0;
    if (p.people.hasSpouse) factor += 5.0;
    factor += p.people.existingChildren * 3.0;
    if ((p.people.fatherAlive || p.people.motherAlive) && !p.people.parentsFinanciallyIndependent) {
      factor += 5.0;
    }
    if (p.you.cityTier == CityTier.tier1) {
      factor *= 1.2;
    } else if (p.you.cityTier == CityTier.rural) {
      factor *= 0.8;
    }
    return base * factor;
  }

  static double healthCoverGap(DiagnosticProfile p) {
    final currentCover = p.healthCover.personalHealthCoverAmount + p.healthCover.corporateHealthCoverAmount;
    return requiredHealthCover(p) - currentCover;
  }

  // Net worth snapshot
  static double netWorth(DiagnosticProfile p) {
    final fixed = p.assets.primaryResidenceValue + p.assets.otherRealEstateValue + p.assets.vehicleValue;
    final liquid = p.assets.fixedDeposits +
        p.assets.equityPortfolio +
        p.assets.mutualFunds +
        p.assets.goldJewellery +
        p.assets.retirementCorpus +
        p.assets.currentEmergencyFund;
    final liabilities = p.loans.loans.map((l) => l.outstandingPrincipal).fold(0.0, (a, b) => a + b);
    return (fixed + liquid) - liabilities;
  }

  // Retirement corpus projection (FV of current corpus + monthly contributions at 8% real)
  static double projectedRetirementCorpus(DiagnosticProfile p) {
    final currentAge = p.you.age;
    final retirementAge = p.goals.targetRetirementAge ?? 60;
    final years = math.max(0, retirementAge - currentAge);
    final months = years * 12;
    
    const r = 0.08 / 12;
    final currentCorpus = p.assets.retirementCorpus;
    final monthlyContribution = p.expenses.retirementFundMonthly;
    
    if (months == 0) return currentCorpus;
    
    final fvCorpus = currentCorpus * math.pow(1 + r, months);
    final fvContributions = monthlyContribution * (math.pow(1 + r, months) - 1) / r;
    
    return fvCorpus + fvContributions;
  }

  // Goal funding shortfall for each LumpSumExpense / children milestone
  static List<GoalFundingResult> goalFundingAnalysis(DiagnosticProfile p) {
    final List<GoalFundingResult> results = [];
    const r = 0.08 / 12;
    
    // Collect goals
    final List<_TempGoal> goals = [];
    for (final exp in p.lifePlans.upcomingLumpSumExpenses) {
      goals.add(_TempGoal(name: exp.label, years: exp.yearsFromNow, target: exp.amount));
    }
    final cmYears = p.goals.childrenMilestonesYears;
    final cmBudgets = p.goals.childrenMilestonesBudgets;
    final cmCount = math.min(cmYears.length, cmBudgets.length);
    for (int i = 0; i < cmCount; i++) {
      goals.add(_TempGoal(
        name: 'Child Milestone ${i + 1}',
        years: cmYears[i],
        target: cmBudgets[i],
      ));
    }
    
    // Sort goals by years ascending
    goals.sort((a, b) => a.years.compareTo(b.years));
    
    // Total growth pool
    final initialLiquid = p.assets.mutualFunds +
        p.assets.equityPortfolio +
        p.assets.fixedDeposits +
        p.assets.goldJewellery;
    final monthlyGrowth = p.expenses.equityInvestmentMonthly + p.expenses.debtInvestmentMonthly;
    
    for (final goal in goals) {
      final months = goal.years * 12;
      double fv = initialLiquid;
      if (months > 0) {
        final fvLiquid = initialLiquid * math.pow(1 + r, months);
        final fvContributions = monthlyGrowth * (math.pow(1 + r, months) - 1) / r;
        fv = fvLiquid + fvContributions;
      }
      
      final gap = math.max(0.0, goal.target - fv);
      results.add(GoalFundingResult(
        name: goal.name,
        targetAmount: goal.target,
        yearsNeeded: goal.years,
        projectedSavings: fv,
        fundingGap: gap,
      ));
    }
    
    return results;
  }
}

class _TempGoal {
  final String name;
  final int years;
  final double target;
  _TempGoal({required this.name, required this.years, required this.target});
}

class _SimLoan {
  final String label;
  double principal;
  final double emi;
  final double rate;
  double accruedInterest = 0.0;
  double tempPayment = 0.0;
  _SimLoan({required this.label, required this.principal, required this.emi, required this.rate});
}

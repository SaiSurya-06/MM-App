import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/savings_goal.dart';
import '../../providers/analytics_provider.dart';
import '../../models/diagnostic_profile.dart';
import '../../models/diagnostic_report.dart';
import 'financial_engine.dart';
import '../utils/currency_formatter.dart';

class AiSpendingForecast {
  final double predictedExpense;
  final double rSquared;
  final String trendDirection; // 'upward', 'downward', 'stable'
  final String confidenceRating; // 'High', 'Medium', 'Low'
  final double changePercentage;
  final Map<String, double> categoryForecasts; // Category-level forecasts

  AiSpendingForecast({
    required this.predictedExpense,
    required this.rSquared,
    required this.trendDirection,
    required this.confidenceRating,
    required this.changePercentage,
    required this.categoryForecasts,
  });
}

class AiAnomaly {
  final int? transactionId;
  final String title;
  final String categoryName;
  final double amount;
  final double averageAmount;
  final double zScore;
  final DateTime date;
  final String contextReason; // Reason explaining context

  AiAnomaly({
    this.transactionId,
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.averageAmount,
    required this.zScore,
    required this.date,
    required this.contextReason,
  });
}

class AiGoalProjection {
  final int? goalId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final double monthsRemaining;
  final DateTime? projectedDate;
  final String status; // 'On Track', 'Lagging', 'Needs Savings'
  final double probability; // Dynamic probability (0-100)

  AiGoalProjection({
    this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthsRemaining,
    this.projectedDate,
    required this.status,
    required this.probability,
  });
}

class AiRecommendation {
  final String title;
  final String description;
  final String type; // 'warning', 'saving', 'info'

  AiRecommendation({
    required this.title,
    required this.description,
    required this.type,
  });
}

class AiAnalyst {
  /// 1. Holt-Winters/Exponential Smoothing Forecasting on Category & Total levels
  static AiSpendingForecast calculateForecast(
    List<MonthlyComparison> history,
    double currentMonthExpense,
    Map<String, List<double>> categoryMonthlyHistories,
  ) {
    // Total level forecasting using double exponential smoothing
    final totalHistory = history.map((e) => e.expense).toList();
    double predicted = currentMonthExpense;
    double rSquared = 0.0;
    String confidence = 'Low';
    String direction = 'stable';
    double changePct = 0.0;

    if (totalHistory.isNotEmpty) {
      predicted = FinancialEngine.forecastDoubleExponentialSmoothing(totalHistory);
      
      // Compute basic metrics for backward compatibility with regression UI
      final n = totalHistory.length;
      if (n >= 2) {
        final meanY = totalHistory.reduce((a, b) => a + b) / n;
        double ssResiduals = 0.0;
        double ssTotal = 0.0;
        for (int i = 0; i < n; i++) {
          ssResiduals += math.pow(totalHistory[i] - predicted, 2);
          ssTotal += math.pow(totalHistory[i] - meanY, 2);
        }
        rSquared = ssTotal > 0 ? (1 - (ssResiduals / ssTotal)).clamp(0.0, 1.0) : 1.0;
        confidence = rSquared >= 0.7 ? 'High' : (rSquared >= 0.4 ? 'Medium' : 'Low');
        
        final diff = predicted - currentMonthExpense;
        direction = diff > 50 ? 'upward' : (diff < -50 ? 'downward' : 'stable');
        if (currentMonthExpense > 0) {
          changePct = (diff / currentMonthExpense) * 100;
        }
      }
    }

    // Category-level forecasts
    final Map<String, double> categoryForecasts = {};
    categoryMonthlyHistories.forEach((catName, spends) {
      categoryForecasts[catName] = FinancialEngine.forecastDoubleExponentialSmoothing(spends);
    });

    return AiSpendingForecast(
      predictedExpense: predicted,
      rSquared: rSquared,
      trendDirection: direction,
      confidenceRating: confidence,
      changePercentage: changePct,
      categoryForecasts: categoryForecasts,
    );
  }

  /// 2. Contextual anomalies (z-score grouped by day of week)
  static List<AiAnomaly> detectAnomalies(
    List<Transaction> allTransactions,
    Map<int, String> categoryNames, [
    String currencyCode = 'USD',
  ]) {
    final List<AiAnomaly> anomalies = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Group transactions by category AND day-of-week for context
    // key format: 'categoryId_dayOfWeek' (e.g. '3_6' for category 3 on Saturdays)
    final Map<String, List<double>> contextSpends = {};
    
    for (var tx in allTransactions) {
      if (tx.type == 'expense' && tx.id != null) {
        final key = '${tx.categoryId}_${tx.date.weekday}';
        contextSpends.putIfAbsent(key, () => []).add(tx.amount);
      }
    }

    // Calculate contextual metrics
    final Map<String, double> contextMean = {};
    final Map<String, double> contextStdDev = {};

    contextSpends.forEach((key, amounts) {
      if (amounts.length >= 3) {
        final mean = amounts.reduce((a, b) => a + b) / amounts.length;
        contextMean[key] = mean;

        final variance = amounts.map((a) => math.pow(a - mean, 2)).reduce((a, b) => a + b) / (amounts.length - 1);
        contextStdDev[key] = math.sqrt(variance);
      }
    });

    // Check recent transactions
    for (var tx in allTransactions) {
      if (tx.type != 'expense' || tx.id == null) continue;
      if (tx.date.isBefore(thirtyDaysAgo)) continue;

      final key = '${tx.categoryId}_${tx.date.weekday}';
      final mean = contextMean[key];
      final stdDev = contextStdDev[key];

      if (mean != null && stdDev != null && stdDev > 20) {
        final zScore = (tx.amount - mean) / stdDev;
        if (zScore > 2.0) {
          final catName = categoryNames[tx.categoryId] ?? 'Category';
          final weekdayName = DateFormat('EEEE').format(tx.date);
          
          anomalies.add(AiAnomaly(
            transactionId: tx.id,
            title: tx.title,
            categoryName: catName,
            amount: tx.amount,
            averageAmount: mean,
            zScore: zScore,
            date: tx.date,
            contextReason: 'Statistically high for a $weekdayName (usual $catName spend is ${CurrencyFormatter.format(mean, currencyCode)}).',
          ));
        }
      }
    }

    anomalies.sort((a, b) => b.zScore.compareTo(a.zScore));
    return anomalies;
  }

  /// 3. Project Savings Goal achievement using dynamic probability formulas
  static List<AiGoalProjection> projectSavingsTimeline(
    List<SavingsGoal> goals,
    double averageSavingsVelocity,
    List<double> monthlySavingsHistory,
  ) {
    final List<AiGoalProjection> projections = [];
    final now = DateTime.now();

    for (var goal in goals) {
      final remaining = goal.targetAmount - goal.currentAmount;
      if (remaining <= 0) {
        projections.add(AiGoalProjection(
          goalId: goal.id,
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount,
          monthsRemaining: 0.0,
          projectedDate: goal.createdAt,
          status: 'Achieved',
          probability: 100.0,
        ));
        continue;
      }

      if (averageSavingsVelocity <= 0) {
        projections.add(AiGoalProjection(
          goalId: goal.id,
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount,
          monthsRemaining: double.infinity,
          projectedDate: null,
          status: 'Needs Savings',
          probability: 0.0,
        ));
        continue;
      }

      final months = remaining / averageSavingsVelocity;
      final days = (months * 30.43).round();
      final projectedDate = now.add(Duration(days: days));

      String status = 'On Track';
      if (goal.targetDate != null) {
        if (projectedDate.isAfter(goal.targetDate!)) {
          status = 'Lagging';
        }
      }

      // Compute CDF Dynamic Probability
      final targetDate = goal.targetDate ?? now.add(const Duration(days: 365));
      final probability = FinancialEngine.calculateGoalProbability(
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        targetDate: targetDate,
        monthlySavingsHistory: monthlySavingsHistory,
        currentMonthlySavingsRate: averageSavingsVelocity,
      );

      projections.add(AiGoalProjection(
        goalId: goal.id,
        goalName: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        monthsRemaining: months,
        projectedDate: projectedDate,
        status: status,
        probability: probability,
      ));
    }

    return projections;
  }

  /// 4. Generate Personalized Recommendations from patterns
  static List<AiRecommendation> generateRecommendations(
    List<Transaction> transactions,
    Map<String, double> categoryForecasts,
    double averageSavingsRate,
    String currencyCode,
  ) {
    final List<AiRecommendation> recs = [];

    // Analyze high spending patterns on weekends
    double weekendFoodSpend = 0.0;
    double weekdayFoodSpend = 0.0;
    int weekendDays = 0;
    int weekdayDays = 0;

    for (var tx in transactions) {
      if (tx.type == 'expense' && (tx.title.toLowerCase().contains('food') || tx.tags.contains('food'))) {
        if (tx.date.weekday == DateTime.saturday || tx.date.weekday == DateTime.sunday) {
          weekendFoodSpend += tx.amount;
          weekendDays++;
        } else {
          weekdayFoodSpend += tx.amount;
          weekdayDays++;
        }
      }
    }

    final weekendAvg = weekendDays > 0 ? weekendFoodSpend / weekendDays : 0.0;
    final weekdayAvg = weekdayDays > 0 ? weekdayFoodSpend / weekdayDays : 0.0;

    if (weekendAvg > weekdayAvg * 1.5 && weekendAvg > 30) {
      final formattedWeekend = CurrencyFormatter.format(weekendAvg, currencyCode);
      final formattedWeekday = CurrencyFormatter.format(weekdayAvg, currencyCode);
      final formattedSaving = CurrencyFormatter.format(120, currencyCode);
      recs.add(AiRecommendation(
        title: 'High Weekend Dining',
        description: 'You spend 50%+ more on food during weekends ($formattedWeekend vs $formattedWeekday). Preparing meals at home on Saturdays could save you around $formattedSaving/month.',
        type: 'saving',
      ));
    }

    // Check forecasted increases in category spends
    categoryForecasts.forEach((catName, forecast) {
      if (forecast > 150) {
        final formattedForecast = CurrencyFormatter.format(forecast, currencyCode);
        recs.add(AiRecommendation(
          title: 'Upcoming $catName Trend',
          description: 'Holt-Winters models predict your $catName spending will rise to $formattedForecast next month. Consider setting a category spending limit.',
          type: 'warning',
        ));
      }
    });

    if (averageSavingsRate < 50) {
      recs.add(AiRecommendation(
        title: 'Boost Savings Rate',
        description: 'Your monthly savings rate is currently below 20%. Try setting up a Goal Achievement Optimizer recommendation to prioritize your allocations.',
        type: 'info',
      ));
    }

    return recs;
  }

  /// Diagnostic Tool methods
  static Future<DiagnosticReport> generateDiagnosticReport(DiagnosticProfile p) {
    return FinancialHealthCalculator.generateDiagnosticReport(p);
  }

  static List<ActionItem> generateActionChecklist(DiagnosticProfile p, DiagnosticReport report) {
    return FinancialHealthCalculator.generateActionChecklist(p, report);
  }

  static DiagnosticVerdict computeVerdict(DiagnosticProfile p, DiagnosticReport report) {
    return FinancialHealthCalculator.computeVerdict(p, report);
  }
}


class FinancialHealthCalculator {
  static double calculate({
    required double monthlyIncome,
    required double monthlyExpense,
    required double budgetCompliance,
    required double debtPayments,
    required List<double> last6MonthsIncome,
    required int anomalyCount,
    required int transactionCount,
  }) {
    double savingsRateScore = 0.0;
    if (monthlyIncome > 0) {
      final savingsRate = (monthlyIncome - monthlyExpense) / monthlyIncome * 100;
      savingsRateScore = savingsRate.clamp(0.0, 100.0);
    }

    double budgetComplianceScore = budgetCompliance.clamp(0.0, 100.0);

    double dtiScore = 100.0;
    if (monthlyIncome > 0) {
      final dti = debtPayments / monthlyIncome;
      dtiScore = ((1.0 - (dti / 0.40)) * 100.0).clamp(0.0, 100.0);
    } else if (debtPayments > 0) {
      dtiScore = 0.0;
    }

    double stabilityScore = 100.0;
    if (last6MonthsIncome.isNotEmpty) {
      final n = last6MonthsIncome.length;
      final mean = last6MonthsIncome.reduce((a, b) => a + b) / n;
      if (mean > 0) {
        final variance = last6MonthsIncome.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / n;
        final stdDev = math.sqrt(variance);
        final cv = stdDev / mean;
        stabilityScore = ((1.0 - cv) * 100.0).clamp(0.0, 100.0);
      } else {
        stabilityScore = 0.0;
      }
    }

    double anomalyScore = 100.0;
    if (transactionCount > 0) {
      anomalyScore = (1.0 - (anomalyCount / transactionCount)) * 100.0;
      anomalyScore = anomalyScore.clamp(0.0, 100.0);
    }

    final compositeScore = (savingsRateScore * 0.30) +
        (budgetComplianceScore * 0.25) +
        (dtiScore * 0.20) +
        (stabilityScore * 0.15) +
        (anomalyScore * 0.10);

    return compositeScore.clamp(0.0, 100.0);
  }

  // Generates the full DiagnosticReport
  static Future<DiagnosticReport> generateDiagnosticReport(DiagnosticProfile p) async {
    final monthlySurplus = FinancialEngine.monthlySurplus(p);
    final netWorth = FinancialEngine.netWorth(p);
    final emergencyFundTargetMonths = FinancialEngine.emergencyFundTargetMonths(p);
    final emergencyFundTarget = emergencyFundTargetMonths * FinancialEngine.monthlyConsumption(p);
    final emergencyFundGap = math.max(0.0, emergencyFundTarget - p.assets.currentEmergencyFund);
    final termCoverGap = FinancialEngine.termCoverGap(p);
    final healthCoverGap = FinancialEngine.healthCoverGap(p);
    final debtPayoff = FinancialEngine.simulateDebtPayoff(p);
    final goalFunding = FinancialEngine.goalFundingAnalysis(p);

    // Cash flow breakdown
    final consumptionAmount = FinancialEngine.monthlyConsumption(p);
    final debtAmount = p.loans.loans.map((l) => l.monthlyEMI).fold(0.0, (a, b) => a + b);
    final safetyAmount = p.expenses.lifeInsurancePremiumMonthly + p.expenses.healthInsurancePremiumMonthly;
    final growthAmount = p.expenses.emergencyFundContributionMonthly +
        p.expenses.equityInvestmentMonthly +
        p.expenses.debtInvestmentMonthly +
        p.expenses.retirementFundMonthly;

    final totalOutflow = consumptionAmount + debtAmount + safetyAmount + growthAmount;
    final double consumptionPct = totalOutflow > 0 ? (consumptionAmount / totalOutflow) * 100 : 0.0;
    final double debtPct = totalOutflow > 0 ? (debtAmount / totalOutflow) * 100 : 0.0;
    final double safetyPct = totalOutflow > 0 ? (safetyAmount / totalOutflow) * 100 : 0.0;
    final double growthPct = totalOutflow > 0 ? (growthAmount / totalOutflow) * 100 : 0.0;

    final cashFlowBreakdown = [
      CashFlowBreakdown(category: 'Consumption', amount: consumptionAmount, percentage: consumptionPct),
      CashFlowBreakdown(category: 'Debt Payments', amount: debtAmount, percentage: debtPct),
      CashFlowBreakdown(category: 'Protection/Insurance', amount: safetyAmount, percentage: safetyPct),
      CashFlowBreakdown(category: 'Savings/Investments', amount: growthAmount, percentage: growthPct),
    ];

    // Build intermediate report to calculate verdict and checklist
    final tempReport = DiagnosticReport(
      verdict: DiagnosticVerdict.needsAttention, // temporary
      monthlySurplus: monthlySurplus,
      netWorth: netWorth,
      emergencyFundTargetMonths: emergencyFundTargetMonths,
      emergencyFundTarget: emergencyFundTarget,
      emergencyFundGap: emergencyFundGap,
      termCoverGap: termCoverGap,
      healthCoverGap: healthCoverGap,
      debtPayoff: debtPayoff,
      goalFunding: goalFunding,
      cashFlowBreakdown: cashFlowBreakdown,
      checklist: [],
      generatedAt: DateTime.now(),
    );

    final verdict = computeVerdict(p, tempReport);
    final checklist = generateActionChecklist(p, tempReport);

    return tempReport.copyWith(
      verdict: verdict,
      checklist: checklist,
    );
  }

  // Returns a prioritized list of action items
  static List<ActionItem> generateActionChecklist(DiagnosticProfile p, DiagnosticReport report) {
    final List<ActionItem> checklist = [];

    // 1. Deficit
    if (report.monthlySurplus < 0) {
      checklist.add(ActionItem(
        priority: 1,
        title: "Eliminate Monthly Deficit",
        description: "Your monthly outflow exceeds your household income. Review flexible expenses (entertainment, dining out, utilities) immediately to stop capital erosion.",
        category: ActionCategory.savings,
        monetaryTarget: report.monthlySurplus.abs(),
      ));
    }

    // 2. High Interest Debt
    final highInterestLoans = p.loans.loans.where((l) => l.annualInterestRate > 12.0).toList();
    if (highInterestLoans.isNotEmpty) {
      checklist.add(ActionItem(
        priority: 1,
        title: "Pay Off High-Interest Debt",
        description: "You have outstanding debt with interest rates above 12% (${highInterestLoans.map((l) => '${l.label} (${l.annualInterestRate}%)').join(', ')}). Prioritize paying this down using your monthly surplus.",
        category: ActionCategory.debt,
      ));
    }

    // 3. Emergency Fund Gap
    if (report.emergencyFundGap > 0) {
      checklist.add(ActionItem(
        priority: 2,
        title: "Establish Emergency Buffer",
        description: "Build an emergency fund covering at least ${report.emergencyFundTargetMonths} months of consumption to protect against sudden job loss or income drops.",
        category: ActionCategory.emergency,
        monetaryTarget: report.emergencyFundGap,
      ));
    }

    // 4. Health Cover Gap
    if (report.healthCoverGap > 0) {
      checklist.add(ActionItem(
        priority: 2,
        title: "Close Health Insurance Gap",
        description: "Your current medical coverage is insufficient by ${report.healthCoverGap.toStringAsFixed(0)}. Secure a dedicated family floater or top-up policy.",
        category: ActionCategory.protection,
        monetaryTarget: report.healthCoverGap,
      ));
    }

    // 5. Term Cover Gap
    if (report.termCoverGap > 0) {
      checklist.add(ActionItem(
        priority: 3,
        title: "Purchase Term Life Cover",
        description: "You are underinsured for life cover by ${report.termCoverGap.toStringAsFixed(0)}. Secure a pure term life insurance policy to support your dependents.",
        category: ActionCategory.protection,
        monetaryTarget: report.termCoverGap,
      ));
    }

    // 6. Goal Shortfalls
    for (final goal in report.goalFunding) {
      if (goal.fundingGap > 0) {
        checklist.add(ActionItem(
          priority: 4,
          title: "Boost Goal Funding: ${goal.name}",
          description: "You have a projected funding gap of ${goal.fundingGap.toStringAsFixed(0)} for ${goal.name} in ${goal.yearsNeeded} years. Increase monthly investments to bridge this gap.",
          category: ActionCategory.goal,
          monetaryTarget: goal.fundingGap,
        ));
      }
    }

    // 7. General Savings Rate
    double totalIncome = p.income.monthlyBaseSalary +
        p.income.monthlyVariablePay +
        p.income.monthlyFreelanceIncome +
        p.income.monthlyRentalIncome +
        p.income.otherMonthlyIncome;
    if (p.people.hasSpouse) {
      totalIncome += p.people.spouseIncome;
    }
    final growthAmount = p.expenses.emergencyFundContributionMonthly +
        p.expenses.equityInvestmentMonthly +
        p.expenses.debtInvestmentMonthly +
        p.expenses.retirementFundMonthly;
    final savingsRate = totalIncome > 0 ? (growthAmount / totalIncome) : 0.0;
    if (savingsRate < 0.20 && report.monthlySurplus >= 0) {
      checklist.add(ActionItem(
        priority: 5,
        title: "Optimize Savings Rate",
        description: "Your household savings rate is ${(savingsRate * 100).toStringAsFixed(1)}%. Aim to save and invest at least 20% of your total income into wealth-building assets.",
        category: ActionCategory.savings,
      ));
    }

    checklist.sort((a, b) => a.priority.compareTo(b.priority));
    return checklist;
  }

  // Financial health verdict for the diagnostic
  static DiagnosticVerdict computeVerdict(DiagnosticProfile p, DiagnosticReport report) {
    final surplus = report.monthlySurplus;
    final termGap = report.termCoverGap;
    final healthGap = report.healthCoverGap;
    final efGap = report.emergencyFundGap;

    if (surplus < 0 && (termGap > 0 || healthGap > 0)) {
      return DiagnosticVerdict.critical;
    }

    if (surplus < 0 ||
        termGap > (FinancialEngine.requiredTermCover(p) * 0.5) ||
        healthGap > (FinancialEngine.requiredHealthCover(p) * 0.5) ||
        efGap > (report.emergencyFundTarget * 0.5)) {
      return DiagnosticVerdict.needsAttention;
    }

    if (termGap <= 0 && healthGap <= 0 && efGap <= 0 && surplus > 0) {
      return DiagnosticVerdict.excellent;
    }

    return DiagnosticVerdict.good;
  }
}

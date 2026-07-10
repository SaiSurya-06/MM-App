class ExecutionPlan {
  final String intent; // 'search', 'compare', 'balance', 'budget', 'advice', 'forecast'
  final String? merchant;
  final String? category;
  final double? minAmount;
  final double? maxAmount;
  final int? targetMonth;
  final int? targetYear;
  final int? comparisonMonth;
  final int? comparisonYear;
  final String? paymentMethod;
  final String? timeFilter;
  final String? targetType;

  // OS Capability registry requests
  final List<String> requiredTools; // 'transaction', 'budget', 'goal', 'account', 'subscription'
  final List<String> requiredStrategies; // 'comparison', 'anomaly', 'trend', 'root_cause'
  final bool needsForecast;
  final bool needsDecision;
  final bool needsCoaching;
  final double confidence;

  ExecutionPlan({
    required this.intent,
    this.merchant,
    this.category,
    this.minAmount,
    this.maxAmount,
    this.targetMonth,
    this.targetYear,
    this.comparisonMonth,
    this.comparisonYear,
    this.paymentMethod,
    this.timeFilter,
    this.targetType,
    required this.requiredTools,
    required this.requiredStrategies,
    required this.needsForecast,
    required this.needsDecision,
    required this.needsCoaching,
    required this.confidence,
  });

  factory ExecutionPlan.fromJson(Map<String, dynamic> json) {
    return ExecutionPlan(
      intent: json['intent']?.toString() ?? 'search',
      merchant: json['merchant']?.toString(),
      category: json['category']?.toString(),
      minAmount: json['minAmount'] != null ? double.tryParse(json['minAmount'].toString()) : null,
      maxAmount: json['maxAmount'] != null ? double.tryParse(json['maxAmount'].toString()) : null,
      targetMonth: json['targetMonth'] != null ? int.tryParse(json['targetMonth'].toString()) : null,
      targetYear: json['targetYear'] != null ? int.tryParse(json['targetYear'].toString()) : null,
      comparisonMonth: json['comparisonMonth'] != null ? int.tryParse(json['comparisonMonth'].toString()) : null,
      comparisonYear: json['comparisonYear'] != null ? int.tryParse(json['comparisonYear'].toString()) : null,
      paymentMethod: json['paymentMethod']?.toString(),
      timeFilter: json['timeFilter']?.toString(),
      targetType: json['targetType']?.toString(),
      requiredTools: (json['requiredTools'] as List?)?.map((e) => e.toString()).toList() ?? [],
      requiredStrategies: (json['requiredStrategies'] as List?)?.map((e) => e.toString()).toList() ?? [],
      needsForecast: json['needsForecast'] == true,
      needsDecision: json['needsDecision'] == true,
      needsCoaching: json['needsCoaching'] == true,
      confidence: json['confidence'] != null ? double.tryParse(json['confidence'].toString()) ?? 1.0 : 1.0,
    );
  }

  factory ExecutionPlan.empty() {
    return ExecutionPlan(
      intent: 'search',
      requiredTools: ['transaction'],
      requiredStrategies: [],
      needsForecast: false,
      needsDecision: false,
      needsCoaching: false,
      confidence: 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'merchant': merchant,
      'category': category,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'targetMonth': targetMonth,
      'targetYear': targetYear,
      'comparisonMonth': comparisonMonth,
      'comparisonYear': comparisonYear,
      'paymentMethod': paymentMethod,
      'timeFilter': timeFilter,
      'targetType': targetType,
      'requiredTools': requiredTools,
      'requiredStrategies': requiredStrategies,
      'needsForecast': needsForecast,
      'needsDecision': needsDecision,
      'needsCoaching': needsCoaching,
      'confidence': confidence,
    };
  }
}

class ShortMemory {
  ExecutionPlan? lastPlan;
  void clear() => lastPlan = null;
}

class FinancialProfile {
  int salaryDay = 5;
  int rentDay = 10;
  double savingsTargetPercentage = 20.0;
}

class BehaviorProfile {
  Map<String, String> observedHabits = {};
}

class Preferences {
  bool prefersCharts = true;
  bool isDarkMode = true;
}

class ConversationMemory {
  final ShortMemory shortMemory = ShortMemory();
  final FinancialProfile financialProfile = FinancialProfile();
  final BehaviorProfile behaviorProfile = BehaviorProfile();
  final Preferences preferences = Preferences();

  ExecutionPlan? get lastPlan => shortMemory.lastPlan;

  void clear() {
    shortMemory.clear();
  }

  ExecutionPlan mergeNewPlan(ExecutionPlan newPlan) {
    if (shortMemory.lastPlan == null) {
      shortMemory.lastPlan = newPlan;
      return newPlan;
    }

    final isFollowUp = newPlan.intent == 'compare' || 
                       newPlan.intent == 'advice' || 
                       newPlan.intent == 'forecast' ||
                       newPlan.intent == 'decision' ||
                       (newPlan.merchant == null && newPlan.category == null && newPlan.minAmount == null && newPlan.maxAmount == null);

    if (!isFollowUp) {
      shortMemory.lastPlan = newPlan;
      return newPlan;
    }

    final mergedMerchant = newPlan.merchant ?? shortMemory.lastPlan!.merchant;
    final mergedCategory = newPlan.category ?? shortMemory.lastPlan!.category;
    final mergedMinAmount = newPlan.minAmount ?? shortMemory.lastPlan!.minAmount;
    final mergedMaxAmount = newPlan.maxAmount ?? shortMemory.lastPlan!.maxAmount;
    final mergedTargetMonth = newPlan.targetMonth ?? shortMemory.lastPlan!.targetMonth;
    final mergedTargetYear = newPlan.targetYear ?? shortMemory.lastPlan!.targetYear;
    final mergedPaymentMethod = newPlan.paymentMethod ?? shortMemory.lastPlan!.paymentMethod;
    final mergedTimeFilter = newPlan.timeFilter ?? shortMemory.lastPlan!.timeFilter;
    final mergedTargetType = newPlan.targetType ?? shortMemory.lastPlan!.targetType;

    final mergedCompMonth = newPlan.comparisonMonth ?? shortMemory.lastPlan!.comparisonMonth;
    final mergedCompYear = newPlan.comparisonYear ?? shortMemory.lastPlan!.comparisonYear;

    final merged = ExecutionPlan(
      intent: newPlan.intent != 'search' ? newPlan.intent : shortMemory.lastPlan!.intent,
      merchant: mergedMerchant,
      category: mergedCategory,
      minAmount: mergedMinAmount,
      maxAmount: mergedMaxAmount,
      targetMonth: mergedTargetMonth,
      targetYear: mergedTargetYear,
      comparisonMonth: mergedCompMonth,
      comparisonYear: mergedCompYear,
      paymentMethod: mergedPaymentMethod,
      timeFilter: mergedTimeFilter,
      targetType: mergedTargetType,
      requiredTools: newPlan.requiredTools.isNotEmpty ? newPlan.requiredTools : shortMemory.lastPlan!.requiredTools,
      requiredStrategies: newPlan.requiredStrategies.isNotEmpty ? newPlan.requiredStrategies : shortMemory.lastPlan!.requiredStrategies,
      needsForecast: newPlan.needsForecast || shortMemory.lastPlan!.needsForecast,
      needsDecision: newPlan.needsDecision || shortMemory.lastPlan!.needsDecision,
      needsCoaching: newPlan.needsCoaching || shortMemory.lastPlan!.needsCoaching,
      confidence: newPlan.confidence,
    );

    shortMemory.lastPlan = merged;
    return merged;
  }
}

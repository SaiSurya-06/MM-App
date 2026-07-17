class GoalAllocation {
  final int goalId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int delayDays; // Positive if delayed, negative if ahead
  final double accelerationPotential; // Potential savings that can speed this up
  final double allocatedMonthlyAmount;
  final double achievementProbability; // 0.0 to 100.0

  const GoalAllocation({
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.delayDays,
    required this.accelerationPotential,
    required this.allocatedMonthlyAmount,
    required this.achievementProbability,
  });

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'delayDays': delayDays,
        'accelerationPotential': accelerationPotential,
        'allocatedMonthlyAmount': allocatedMonthlyAmount,
        'achievementProbability': achievementProbability,
      };

  factory GoalAllocation.fromJson(Map<String, dynamic> json) => GoalAllocation(
        goalId: json['goalId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        delayDays: json['delayDays'] as int? ?? 0,
        accelerationPotential: (json['accelerationPotential'] as num?)?.toDouble() ?? 0.0,
        allocatedMonthlyAmount: (json['allocatedMonthlyAmount'] as num?)?.toDouble() ?? 0.0,
        achievementProbability: (json['achievementProbability'] as num?)?.toDouble() ?? 0.0,
      );
}

class GoalPlan {
  final List<GoalAllocation> allocations;
  final String recommendations;

  const GoalPlan({
    required this.allocations,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'allocations': allocations.map((e) => e.toJson()).toList(),
        'recommendations': recommendations,
      };

  factory GoalPlan.fromJson(Map<String, dynamic> json) => GoalPlan(
        allocations: (json['allocations'] as List?)
                ?.map((e) => GoalAllocation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recommendations: json['recommendations'] as String? ?? '',
      );
}

class SpendingVelocity {
  final double dailyBurnRate;
  final double weeklyBurnRate;
  final double expectedDailyPace;
  final bool isAheadOfPace; // True if spending faster than expected pace
  final double paceDriftPercentage; // Difference from expected pace
  final String statusDescription; // Ahead, Behind, On Pace

  const SpendingVelocity({
    required this.dailyBurnRate,
    required this.weeklyBurnRate,
    required this.expectedDailyPace,
    required this.isAheadOfPace,
    required this.paceDriftPercentage,
    required this.statusDescription,
  });

  Map<String, dynamic> toJson() => {
        'dailyBurnRate': dailyBurnRate,
        'weeklyBurnRate': weeklyBurnRate,
        'expectedDailyPace': expectedDailyPace,
        'isAheadOfPace': isAheadOfPace,
        'paceDriftPercentage': paceDriftPercentage,
        'statusDescription': statusDescription,
      };

  factory SpendingVelocity.fromJson(Map<String, dynamic> json) => SpendingVelocity(
        dailyBurnRate: (json['dailyBurnRate'] as num?)?.toDouble() ?? 0.0,
        weeklyBurnRate: (json['weeklyBurnRate'] as num?)?.toDouble() ?? 0.0,
        expectedDailyPace: (json['expectedDailyPace'] as num?)?.toDouble() ?? 0.0,
        isAheadOfPace: json['isAheadOfPace'] as bool? ?? false,
        paceDriftPercentage: (json['paceDriftPercentage'] as num?)?.toDouble() ?? 0.0,
        statusDescription: json['statusDescription'] as String? ?? 'On Pace',
      );

  SpendingVelocity copyWith({
    double? dailyBurnRate,
    double? weeklyBurnRate,
    double? expectedDailyPace,
    bool? isAheadOfPace,
    double? paceDriftPercentage,
    String? statusDescription,
  }) {
    return SpendingVelocity(
      dailyBurnRate: dailyBurnRate ?? this.dailyBurnRate,
      weeklyBurnRate: weeklyBurnRate ?? this.weeklyBurnRate,
      expectedDailyPace: expectedDailyPace ?? this.expectedDailyPace,
      isAheadOfPace: isAheadOfPace ?? this.isAheadOfPace,
      paceDriftPercentage: paceDriftPercentage ?? this.paceDriftPercentage,
      statusDescription: statusDescription ?? this.statusDescription,
    );
  }
}

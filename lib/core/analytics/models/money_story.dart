class MoneyStory {
  final String dailyStory;
  final String weeklyStory;
  final String monthlyStory;
  final String yearlyStory;

  const MoneyStory({
    required this.dailyStory,
    required this.weeklyStory,
    required this.monthlyStory,
    required this.yearlyStory,
  });

  Map<String, dynamic> toJson() => {
        'dailyStory': dailyStory,
        'weeklyStory': weeklyStory,
        'monthlyStory': monthlyStory,
        'yearlyStory': yearlyStory,
      };

  MoneyStory copyWith({
    String? dailyStory,
    String? weeklyStory,
    String? monthlyStory,
    String? yearlyStory,
  }) {
    return MoneyStory(
      dailyStory: dailyStory ?? this.dailyStory,
      weeklyStory: weeklyStory ?? this.weeklyStory,
      monthlyStory: monthlyStory ?? this.monthlyStory,
      yearlyStory: yearlyStory ?? this.yearlyStory,
    );
  }
}

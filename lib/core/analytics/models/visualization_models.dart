class LineChartDataPoint {
  final DateTime x;
  final double y;
  const LineChartDataPoint(this.x, this.y);
  Map<String, dynamic> toJson() => {'x': x.toIso8601String(), 'y': y};
  factory LineChartDataPoint.fromJson(Map<String, dynamic> json) => LineChartDataPoint(
        DateTime.parse(json['x'] as String),
        (json['y'] as num?)?.toDouble() ?? 0.0,
      );
}

class HeatmapDataPoint {
  final DateTime date;
  final double amount;
  const HeatmapDataPoint(this.date, this.amount);
  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'amount': amount};
  factory HeatmapDataPoint.fromJson(Map<String, dynamic> json) => HeatmapDataPoint(
        DateTime.parse(json['date'] as String),
        (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class FlowBarItem {
  final String label;
  final double amount;
  final double percentage;
  final String colorHex;
  const FlowBarItem({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.colorHex,
  });
  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'percentage': percentage,
        'colorHex': colorHex,
      };
  factory FlowBarItem.fromJson(Map<String, dynamic> json) => FlowBarItem(
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        colorHex: json['colorHex'] as String? ?? '',
      );
}

class TimelineItem {
  final DateTime date;
  final String title;
  final double amount;
  final String type; // income, expense, transfer
  final String categoryName;
  const TimelineItem({
    required this.date,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryName,
  });
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'amount': amount,
        'type': type,
        'categoryName': categoryName,
      };
  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] as String? ?? 'expense',
        categoryName: json['categoryName'] as String? ?? 'Other',
      );
}

class VisualizationModels {
  final List<LineChartDataPoint> forecastPoints;
  final List<HeatmapDataPoint> dailySpends;
  final List<FlowBarItem> flowBars;
  final List<TimelineItem> timelineEvents;

  const VisualizationModels({
    required this.forecastPoints,
    required this.dailySpends,
    required this.flowBars,
    required this.timelineEvents,
  });

  Map<String, dynamic> toJson() => {
        'forecastPoints': forecastPoints.map((e) => e.toJson()).toList(),
        'dailySpends': dailySpends.map((e) => e.toJson()).toList(),
        'flowBars': flowBars.map((e) => e.toJson()).toList(),
        'timelineEvents': timelineEvents.map((e) => e.toJson()).toList(),
      };

  factory VisualizationModels.fromJson(Map<String, dynamic> json) => VisualizationModels(
        forecastPoints: (json['forecastPoints'] as List?)
                ?.map((e) => LineChartDataPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        dailySpends: (json['dailySpends'] as List?)
                ?.map((e) => HeatmapDataPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        flowBars: (json['flowBars'] as List?)
                ?.map((e) => FlowBarItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timelineEvents: (json['timelineEvents'] as List?)
                ?.map((e) => TimelineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class LineChartDataPoint {
  final DateTime x;
  final double y;
  const LineChartDataPoint(this.x, this.y);
  Map<String, dynamic> toJson() => {'x': x.toIso8601String(), 'y': y};
}

class HeatmapDataPoint {
  final DateTime date;
  final double amount;
  const HeatmapDataPoint(this.date, this.amount);
  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'amount': amount};
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
}

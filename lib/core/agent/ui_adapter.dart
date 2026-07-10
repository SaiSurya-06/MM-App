import 'coaching_engine.dart';
import 'analytics_engine.dart';

enum UiComponentType {
  healthScore,
  summary,
  insights,
  warnings,
  recommendations,
  nextActions,
  chart,
  motivationalMessage,
}

class UiComponent {
  final UiComponentType type;
  final Map<String, dynamic> data;

  UiComponent({required this.type, required this.data});
}

class UIAdapter {
  static List<UiComponent> adapt(CoachingResult coaching, FinancialScores scores) {
    final List<UiComponent> components = [];

    // 1. Health Score widget
    components.add(UiComponent(
      type: UiComponentType.healthScore,
      data: {
        'overallScore': scores.overallScore,
        'savingsScore': scores.savingsScore,
        'budgetScore': scores.budgetScore,
        'emergencyScore': scores.emergencyScore,
      },
    ));

    // 2. Summary text widget
    components.add(UiComponent(
      type: UiComponentType.summary,
      data: {'text': coaching.summary},
    ));

    // 3. Chart widget
    if (coaching.chartType != 'NONE') {
      components.add(UiComponent(
        type: UiComponentType.chart,
        data: {'chartType': coaching.chartType},
      ));
    }

    // 4. Key Insights
    if (coaching.insights.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.insights,
        data: {'list': coaching.insights},
      ));
    }

    // 5. Warnings
    if (coaching.warnings.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.warnings,
        data: {'list': coaching.warnings},
      ));
    }

    // 6. Recommendations
    if (coaching.recommendations.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.recommendations,
        data: {'list': coaching.recommendations},
      ));
    }

    // 7. Next Actions
    if (coaching.nextActions.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.nextActions,
        data: {'list': coaching.nextActions},
      ));
    }

    // 8. Motivational Quote
    if (coaching.motivationalMessage.isNotEmpty) {
      components.add(UiComponent(
        type: UiComponentType.motivationalMessage,
        data: {'text': coaching.motivationalMessage},
      ));
    }

    return components;
  }
}

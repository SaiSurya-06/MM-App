import 'execution_plan.dart';
import 'retriever.dart';
import 'analytics_engine.dart';
import 'investigation_engine.dart';
import 'prediction_engine.dart';
import 'decision_engine.dart';
import 'evaluation_engine.dart';
import 'coaching_engine.dart';

abstract class FinancialEngine {
  Future<FinancialContext> execute(FinancialContext context);
}

class FinancialContext {
  final String query;
  final ExecutionPlan plan;
  final RetrievedData rawData;
  
  // Enriched stages
  final Map<String, dynamic> metrics;
  final List<String> insights;
  final FinancialScores scores;
  final InvestigationResult investigation;
  final ForecastResult forecast;
  final DecisionResult decision;
  final EvaluationResult evaluation;
  final CoachingResult coaching;
  
  final List<String> actions;
  final Map<String, dynamic> observabilityLogs;

  FinancialContext({
    required this.query,
    required this.plan,
    required this.rawData,
    required this.metrics,
    required this.insights,
    required this.scores,
    required this.investigation,
    required this.forecast,
    required this.decision,
    required this.evaluation,
    required this.coaching,
    required this.actions,
    required this.observabilityLogs,
  });

  factory FinancialContext.initial(String query, ExecutionPlan plan, RetrievedData rawData) {
    return FinancialContext(
      query: query,
      plan: plan,
      rawData: rawData,
      metrics: {},
      insights: [],
      scores: FinancialScores.empty(),
      investigation: InvestigationResult.empty(),
      forecast: ForecastResult.empty(),
      decision: DecisionResult.empty(),
      evaluation: EvaluationResult.empty(),
      coaching: CoachingResult.empty(),
      actions: [],
      observabilityLogs: {},
    );
  }

  FinancialContext copyWith({
    Map<String, dynamic>? metrics,
    List<String>? insights,
    FinancialScores? scores,
    InvestigationResult? investigation,
    ForecastResult? forecast,
    DecisionResult? decision,
    EvaluationResult? evaluation,
    CoachingResult? coaching,
    List<String>? actions,
    Map<String, dynamic>? observabilityLogs,
  }) {
    return FinancialContext(
      query: query,
      plan: plan,
      rawData: rawData,
      metrics: metrics ?? this.metrics,
      insights: insights ?? this.insights,
      scores: scores ?? this.scores,
      investigation: investigation ?? this.investigation,
      forecast: forecast ?? this.forecast,
      decision: decision ?? this.decision,
      evaluation: evaluation ?? this.evaluation,
      coaching: coaching ?? this.coaching,
      actions: actions ?? this.actions,
      observabilityLogs: observabilityLogs ?? this.observabilityLogs,
    );
  }
}

class AgentOrchestrator {
  final List<FinancialEngine> engines;

  AgentOrchestrator({required this.engines});

  Future<FinancialContext> orchestrate(FinancialContext context) async {
    FinancialContext currentContext = context;
    final Map<String, dynamic> logs = Map.from(context.observabilityLogs);
    final stopwatch = Stopwatch()..start();

    for (final engine in engines) {
      final engineStopwatch = Stopwatch()..start();
      currentContext = await engine.execute(currentContext);
      engineStopwatch.stop();
      logs[engine.runtimeType.toString()] = "${engineStopwatch.elapsedMilliseconds}ms";
    }

    stopwatch.stop();
    logs['TotalOrchestrationTime'] = "${stopwatch.elapsedMilliseconds}ms";

    return currentContext.copyWith(observabilityLogs: logs);
  }
}

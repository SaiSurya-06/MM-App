import 'execution_plan.dart';
export 'rule_planner.dart';

abstract class Planner {
  Future<ExecutionPlan> plan(String query, ConversationMemory memory);
}

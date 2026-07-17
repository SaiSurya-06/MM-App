import 'package:intl/intl.dart';
import '../capability.dart';

class CashFlowPredictor implements Capability<Map<String, double>> {
  @override
  String get id => 'cash_flow_predictor';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Cash Flow Predictor';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<Map<String, double>> execute(OrchestratorContext context) async {
    final Map<String, double> projection = {};
    final now = context.snapshot.selectedDate;

    // Total Cash balance today
    double runningBalance = context.snapshot.accounts
        .where((acc) => acc.type != 'Credit Card')
        .fold(0.0, (sum, acc) => sum + acc.balance);

    final int totalDays = DateTime(now.year, now.month + 1, 0).day;
    final int today = now.day;

    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    projection[dateStr] = runningBalance;

    // Daily variable spending burn rate
    final velocity = context.velocity;
    final double dailyBurn = velocity?.dailyBurnRate ?? 1000.0; // Fallback 1000/day

    // Identify upcoming bills (categories that have budget limits but haven't been spent yet)
    final budgetAnalysis = context.budget;
    double upcomingBillsSum = 0.0;
    if (budgetAnalysis != null) {
      for (var status in budgetAnalysis.categoryStatuses) {
        if (!status.isOverspent && status.limit > status.spent) {
          // Approximate remaining bills budget
          upcomingBillsSum += (status.limit - status.spent);
        }
      }
    }

    final int remainingDays = totalDays - today;
    if (remainingDays <= 0) return projection;

    final double dailyFixedOutflow = upcomingBillsSum / remainingDays;

    for (int day = today + 1; day <= totalDays; day++) {
      final date = DateTime(now.year, now.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      // Subtract expected daily discretionary spend and fixed outflow amortized
      runningBalance -= (dailyBurn + dailyFixedOutflow);
      projection[dateKey] = runningBalance;
    }

    return projection;
  }
}

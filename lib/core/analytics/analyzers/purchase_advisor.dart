import '../capability.dart';
import '../models/purchase_decision.dart';
import '../../../../models/savings_goal.dart';

class PurchaseAdvisor implements Capability<PurchaseDecision> {
  @override
  String get id => 'purchase_advisor';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Purchase Advisor';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<PurchaseDecision> execute(OrchestratorContext context) async {
    final double amount = context.simulatedPurchaseAmount;
    if (amount <= 0.0) {
      return const PurchaseDecision(
        purchaseAmount: 0.0,
        isApproved: true,
        postPurchaseEmergencyFund: 0.0,
        isSavingsGoalAffected: false,
        budgetRecoveryDays: 0,
        confidenceScore: 1.0,
        explanation: 'Enter a simulated purchase amount to get advisor evaluation.',
      );
    }

    // 1. Current cash balance today
    final double totalBalance = context.snapshot.accounts
        .where((acc) => acc.type != 'Credit Card')
        .fold(0.0, (sum, acc) => sum + acc.balance);

    // 2. Find emergency fund target and current savings
    final emergencyGoal = context.snapshot.goals.firstWhere(
      (g) => g.name.toLowerCase().contains('emergency'),
      orElse: () => SavingsGoal(
        id: -99,
        name: 'Emergency Fund',
        targetAmount: 20000.0,
        currentAmount: 15000.0,
        color: '00ACC1',
        icon: 'savings',
        createdAt: DateTime.now(),
      ),
    );

    // 3. Monthly savings rate
    final double income = context.incomeAnalysis?.totalIncome ?? 0.0;
    final double expense = context.expenseAnalysis?.totalExpense ?? 0.0;
    double netSavings = income - expense;
    if (netSavings <= 0) {
      final double histInc = context.stability?.baseExpectedMonthlyIncome ?? 0.0;
      netSavings = histInc > expense ? histInc - expense : 5000.0;
    }

    // 4. Calculate Recovery Days
    final double dailySavings = netSavings / 30.43;
    final int recoveryDays = (amount / (dailySavings > 0 ? dailySavings : 100.0)).round();

    // 5. Evaluate Decision
    final double remainingCash = totalBalance - amount;
    final bool dipsIntoEmergency = remainingCash < emergencyGoal.currentAmount;
    final bool isApproved = remainingCash >= 0 && !dipsIntoEmergency;

    // 6. Confidence Score based on stability
    final double baseConfidence = context.stability?.stabilityScore ?? 85.0;
    final double confidence = (baseConfidence / 100.0).clamp(0.50, 0.98);

    String explanation = '';
    if (isApproved) {
      explanation = 'Yes! Buying this still leaves ₹${remainingCash.toStringAsFixed(0)} cash, '
          'leaving your emergency fund (₹${emergencyGoal.currentAmount.toStringAsFixed(0)}) untouched. '
          'Your savings goals are unaffected. Budget recovery time: $recoveryDays days.';
    } else if (remainingCash >= 0) {
      explanation = 'Warning: Buying this will dip into your emergency fund by '
          '₹${(emergencyGoal.currentAmount - remainingCash).toStringAsFixed(0)}. '
          'While you have enough cash today, your emergency cushion is compromised. '
          'Budget recovery time: $recoveryDays days.';
    } else {
      explanation = 'No: Buying this exceeds your total cash balance today by '
          '₹${(amount - totalBalance).toStringAsFixed(0)}. This purchase is unsafe and '
          'would result in immediate cash depletion. Budget recovery time: $recoveryDays days.';
    }

    final decision = PurchaseDecision(
      purchaseAmount: amount,
      isApproved: isApproved,
      postPurchaseEmergencyFund: remainingCash > 0 ? remainingCash.clamp(0.0, emergencyGoal.currentAmount) : 0.0,
      isSavingsGoalAffected: dipsIntoEmergency,
      budgetRecoveryDays: recoveryDays,
      confidenceScore: confidence,
      explanation: explanation,
    );

    context.purchase = decision; // Cache in context
    return decision;
  }
}

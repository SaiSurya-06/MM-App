import '../../../models/category.dart';
import '../capability.dart';

class BudgetCategoryStatus {
  final int categoryId;
  final String categoryName;
  final double spent;
  final double limit;
  final double remaining;
  final double compliancePercentage; // 0.0 to 100.0
  final bool isOverspent;

  const BudgetCategoryStatus({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.compliancePercentage,
    required this.isOverspent,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'spent': spent,
        'limit': limit,
        'remaining': remaining,
        'compliancePercentage': compliancePercentage,
        'isOverspent': isOverspent,
      };
}

class BudgetAnalysis {
  final double totalBudgetLimits;
  final double totalSpent;
  final double overallCompliance; // 0.0 to 100.0
  final List<BudgetCategoryStatus> categoryStatuses;

  const BudgetAnalysis({
    required this.totalBudgetLimits,
    required this.totalSpent,
    required this.overallCompliance,
    required this.categoryStatuses,
  });

  Map<String, dynamic> toJson() => {
        'totalBudgetLimits': totalBudgetLimits,
        'totalSpent': totalSpent,
        'overallCompliance': overallCompliance,
        'categoryStatuses': categoryStatuses.map((e) => e.toJson()).toList(),
      };
}

class BudgetAnalyzer implements Capability<BudgetAnalysis> {
  @override
  String get id => 'budget_analyzer';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Budget Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<BudgetAnalysis> execute(OrchestratorContext context) async {
    final snapshot = context.snapshot;
    final expenseAnalysis = context.expenseAnalysis;

    if (expenseAnalysis == null) {
      return const BudgetAnalysis(
        totalBudgetLimits: 0.0,
        totalSpent: 0.0,
        overallCompliance: 100.0,
        categoryStatuses: [],
      );
    }

    double totalBudgetLimits = 0.0;
    double exceededAmount = 0.0;
    final List<BudgetCategoryStatus> statuses = [];

    for (var b in snapshot.budgets) {
      final catId = b.categoryId;
      final limit = b.limitAmount;
      totalBudgetLimits += limit;

      // Find category name
      final cat = snapshot.categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category(id: catId, name: 'Other', icon: 'payments', color: 'E53935', isDefault: true),
      );

      // Find spent amount in expenseAnalysis
      final spent = expenseAnalysis.spendByCategory[cat.name] ?? 0.0;
      final remaining = limit - spent;
      final isOverspent = spent > limit;
      
      if (isOverspent) {
        exceededAmount += (spent - limit);
      }

      final compliance = limit > 0 
          ? ((limit - (isOverspent ? spent - limit : 0.0)) / limit * 100.0).clamp(0.0, 100.0)
          : 100.0;

      statuses.add(BudgetCategoryStatus(
        categoryId: catId,
        categoryName: cat.name,
        spent: spent,
        limit: limit,
        remaining: remaining,
        compliancePercentage: compliance,
        isOverspent: isOverspent,
      ));
    }

    final double overallCompliance = totalBudgetLimits > 0
        ? ((totalBudgetLimits - exceededAmount) / totalBudgetLimits * 100.0).clamp(0.0, 100.0)
        : 100.0;

    final budgetAnalysis = BudgetAnalysis(
      totalBudgetLimits: totalBudgetLimits,
      totalSpent: expenseAnalysis.totalExpense,
      overallCompliance: overallCompliance,
      categoryStatuses: statuses,
    );

    // Cache overall totals in context for downstream calculators to read easily
    context.budgetCompliance = overallCompliance;
    context.totalBudgetLimits = totalBudgetLimits;
    context.budget = budgetAnalysis;

    return budgetAnalysis;
  }
}

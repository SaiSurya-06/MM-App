import '../capability.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';

class ExpenseAnalysis {
  final double totalExpense;
  final List<Transaction> expenseTransactions;
  final Map<String, double> spendByFlowGroup; // Flow Group -> sum
  final Map<String, double> spendByCategory;  // Category Name -> sum

  const ExpenseAnalysis({
    required this.totalExpense,
    required this.expenseTransactions,
    required this.spendByFlowGroup,
    required this.spendByCategory,
  });
}

class ExpenseAnalyzer implements Capability<ExpenseAnalysis> {
  @override
  String get id => 'expense_analyzer';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Expense Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  String classifyCategoryToFlowGroup(String categoryName, String txType) {
    if (txType == 'transfer') {
      return 'Transfers';
    }

    final name = categoryName.toLowerCase();
    
    // 1. Debt
    if (name.contains('loan') || name.contains('debt') || name.contains('emi') || name.contains('credit card payment') || name.contains('card payment')) {
      return 'Debt';
    }
    
    // 2. Taxes
    if (name.contains('tax') || name.contains('taxes') || name.contains('gst') || name.contains('income tax')) {
      return 'Taxes';
    }

    // 3. Savings
    if (name.contains('savings') || name.contains('saving') || name.contains('goal') || name.contains('emergency')) {
      return 'Savings';
    }

    // 4. Investments
    if (name.contains('investment') || name.contains('investments') || name.contains('invest') || name.contains('stock') || name.contains('mutual') || name.contains('retirement') || name.contains('equity') || name.contains('crypto')) {
      return 'Investments';
    }

    // 5. Essentials (Needs)
    if (name.contains('rent') || name.contains('mortgage') || name.contains('bill') || name.contains('utility') || name.contains('utilities') || 
        name.contains('electricity') || name.contains('internet') || name.contains('water') || name.contains('insurance') || name.contains('medicine') || 
        name.contains('health') || name.contains('hospital') || name.contains('medicine') || name.contains('school') || name.contains('tuition') || name.contains('telecom')) {
      return 'Essentials';
    }

    // 6. Lifestyle (Wants)
    if (name.contains('food') || name.contains('groceries') || name.contains('transport') || name.contains('entertainment') || name.contains('shopping') || 
        name.contains('fuel') || name.contains('dining') || name.contains('movie') || name.contains('travel') || name.contains('hobbies') || 
        name.contains('clothing') || name.contains('gift') || name.contains('personal') || name.contains('cafe') || name.contains('restaurant')) {
      return 'Lifestyle';
    }

    // Default
    return 'Others';
  }

  @override
  Future<ExpenseAnalysis> execute(OrchestratorContext context) async {
    final snapshot = context.snapshot;
    final currentMonth = snapshot.selectedMonth;

    final expenseTx = snapshot.transactions.where((tx) {
      final txMonth = tx.date.toIso8601String().substring(0, 7);
      // Filter out split parents to avoid double-counting, and select non-income txs
      return tx.type != 'income' && txMonth == currentMonth && tx.parentId == null;
    }).toList();

    double totalExpense = 0.0;
    final Map<String, double> spendByFlowGroup = {
      'Essentials': 0.0,
      'Lifestyle': 0.0,
      'Savings': 0.0,
      'Investments': 0.0,
      'Debt': 0.0,
      'Taxes': 0.0,
      'Transfers': 0.0,
      'Others': 0.0,
    };
    final Map<String, double> spendByCategory = {};

    for (var tx in expenseTx) {
      final amount = tx.amount;
      if (tx.type != 'transfer') {
        totalExpense += amount;
      }

      final cat = snapshot.categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => Category(
          id: tx.categoryId,
          name: 'Other Outflow',
          icon: 'payments',
          color: 'E53935',
          isDefault: true,
          type: 'expense',
        ),
      );

      final flowGroup = classifyCategoryToFlowGroup(cat.name, tx.type);
      spendByFlowGroup[flowGroup] = (spendByFlowGroup[flowGroup] ?? 0.0) + amount;
      spendByCategory[cat.name] = (spendByCategory[cat.name] ?? 0.0) + amount;
    }

    return ExpenseAnalysis(
      totalExpense: totalExpense,
      expenseTransactions: expenseTx,
      spendByFlowGroup: spendByFlowGroup,
      spendByCategory: spendByCategory,
    );
  }
}

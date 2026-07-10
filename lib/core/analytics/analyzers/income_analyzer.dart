import '../capability.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';

class IncomeAnalysis {
  final double totalIncome;
  final List<Transaction> incomeTransactions;
  final Map<String, double> incomeBySource; // Category Name -> sum

  const IncomeAnalysis({
    required this.totalIncome,
    required this.incomeTransactions,
    required this.incomeBySource,
  });
}

class IncomeAnalyzer implements Capability<IncomeAnalysis> {
  @override
  String get id => 'income_analyzer';
  @override
  String get version => '1.0.0';
  @override
  String get name => 'Income Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;

  @override
  Future<IncomeAnalysis> execute(OrchestratorContext context) async {
    final snapshot = context.snapshot;
    final currentMonth = snapshot.selectedMonth;

    final incomeTx = snapshot.transactions.where((tx) {
      final txMonth = tx.date.toIso8601String().substring(0, 7);
      // Ensure we check parent_id to avoid double-counting splits
      return tx.type == 'income' && txMonth == currentMonth && tx.parentId == null;
    }).toList();

    double totalIncome = 0.0;
    final Map<String, double> incomeBySource = {};

    for (var tx in incomeTx) {
      totalIncome += tx.amount;
      final cat = snapshot.categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => Category(
          id: tx.categoryId,
          name: 'Other Income',
          icon: 'payments',
          color: '4CAF50',
          isDefault: true,
          type: 'income',
        ),
      );
      incomeBySource[cat.name] = (incomeBySource[cat.name] ?? 0.0) + tx.amount;
    }

    return IncomeAnalysis(
      totalIncome: totalIncome,
      incomeTransactions: incomeTx,
      incomeBySource: incomeBySource,
    );
  }
}

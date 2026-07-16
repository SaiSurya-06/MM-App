import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../../models/debt_loan.dart';
import '../../models/account.dart';

class FinancialSnapshot {
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Budget> budgets;
  final List<SavingsGoal> goals;
  final List<DebtLoan> debts;
  final List<Account> accounts;
  final String selectedMonth; // e.g. '2026-07'
  final DateTime selectedDate;
  final double estimatedIncome;

  const FinancialSnapshot({
    required this.transactions,
    required this.categories,
    required this.budgets,
    required this.goals,
    required this.debts,
    required this.accounts,
    required this.selectedMonth,
    required this.selectedDate,
    this.estimatedIncome = 0.0,
  });

  String get snapshotId {
    // Generate a unique fingerprint based on content to detect database changes
    final double txSum = transactions.fold(0.0, (sum, tx) => sum + tx.amount + (tx.id ?? 0));
    final double budgetSum = budgets.fold(0.0, (sum, b) => sum + b.limitAmount + (b.id ?? 0));
    final double goalSum = goals.fold(0.0, (sum, g) => sum + g.currentAmount + (g.id ?? 0));
    final double debtSum = debts.fold(0.0, (sum, d) => sum + d.balance + (d.id ?? 0));
    final double accSum = accounts.fold(0.0, (sum, a) => sum + a.balance + (a.id ?? 0));
    return '${selectedMonth}_${transactions.length}_${txSum.toStringAsFixed(2)}_${budgetSum.toStringAsFixed(2)}_${goalSum.toStringAsFixed(2)}_${debtSum.toStringAsFixed(2)}_${accSum.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() => {
        'transactionsCount': transactions.length,
        'categoriesCount': categories.length,
        'budgetsCount': budgets.length,
        'goalsCount': goals.length,
        'debtsCount': debts.length,
        'accountsCount': accounts.length,
        'selectedMonth': selectedMonth,
        'selectedDate': selectedDate.toIso8601String(),
        'snapshotId': snapshotId,
      };

  Map<String, dynamic> toFullJson() => {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'goals': goals.map((g) => g.toMap()).toList(),
        'debts': debts.map((d) => d.toMap()).toList(),
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'selectedMonth': selectedMonth,
        'selectedDate': selectedDate.toIso8601String(),
        'estimatedIncome': estimatedIncome,
      };

  factory FinancialSnapshot.fromFullJson(Map<String, dynamic> json) {
    return FinancialSnapshot(
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromMap(Map<String, dynamic>.from(t as Map)))
          .toList(),
      categories: (json['categories'] as List)
          .map((c) => Category.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      budgets: (json['budgets'] as List)
          .map((b) => Budget.fromMap(Map<String, dynamic>.from(b as Map)))
          .toList(),
      goals: (json['goals'] as List)
          .map((g) => SavingsGoal.fromMap(Map<String, dynamic>.from(g as Map)))
          .toList(),
      debts: (json['debts'] as List)
          .map((d) => DebtLoan.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      accounts: (json['accounts'] as List)
          .map((a) => Account.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList(),
      selectedMonth: json['selectedMonth'] as String,
      selectedDate: DateTime.parse(json['selectedDate'] as String),
      estimatedIncome: (json['estimatedIncome'] as num).toDouble(),
    );
  }
}

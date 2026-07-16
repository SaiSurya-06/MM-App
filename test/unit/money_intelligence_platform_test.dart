import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/analytics/financial_snapshot.dart';
import 'package:money_manager/core/analytics/capability.dart';
import 'package:money_manager/core/analytics/analyzers/income_analyzer.dart';
import 'package:money_manager/core/analytics/analyzers/expense_analyzer.dart';
import 'package:money_manager/core/analytics/analyzers/subscription_analyzer.dart';
import 'package:money_manager/core/analytics/analyzers/spending_predictor.dart';
import 'package:money_manager/core/analytics/analyzers/purchase_advisor.dart';
import 'package:money_manager/models/transaction.dart';
import 'package:money_manager/models/category.dart';
import 'package:money_manager/models/budget.dart';
import 'package:money_manager/models/savings_goal.dart';
import 'package:money_manager/models/debt_loan.dart';
import 'package:money_manager/models/account.dart';

void main() {
  group('Financial Intelligence Platform Unit Tests', () {
    late FinancialSnapshot mockSnapshot;

    setUp(() {
      final now = DateTime(2026, 7, 10);
      final categories = [
        const Category(id: 1, name: 'Salary', icon: 'payments', color: '4CAF50', isDefault: true, type: 'income'),
        const Category(id: 2, name: 'Rent', icon: 'home', color: '1E88E5', isDefault: true, type: 'expense'),
        const Category(id: 3, name: 'Food', icon: 'fastfood', color: 'E53935', isDefault: true, type: 'expense'),
        const Category(id: 4, name: 'Netflix', icon: 'movie', color: 'E53935', isDefault: true, type: 'expense'),
      ];

      final transactions = [
        Transaction(
          id: 101,
          accountId: 1,
          categoryId: 1,
          title: 'Monthly Salary Payment',
          amount: 80000.0,
          type: 'income',
          date: DateTime(2026, 7, 1),
          isPrivate: false,
          createdAt: DateTime(2026, 7, 1),
        ),
        Transaction(
          id: 102,
          accountId: 1,
          categoryId: 2,
          title: 'Apartment Rent Payment',
          amount: 18000.0,
          type: 'expense',
          date: DateTime(2026, 7, 2),
          isPrivate: false,
          createdAt: DateTime(2026, 7, 2),
        ),
        Transaction(
          id: 103,
          accountId: 1,
          categoryId: 3,
          title: 'Grocery Supermarket',
          amount: 9000.0,
          type: 'expense',
          date: DateTime(2026, 7, 5),
          isPrivate: false,
          createdAt: DateTime(2026, 7, 5),
        ),
        Transaction(
          id: 104,
          accountId: 1,
          categoryId: 4,
          title: 'Netflix Subscription',
          amount: 650.0,
          type: 'expense',
          date: DateTime(2026, 7, 8),
          recurrence: 'monthly',
          isPrivate: false,
          createdAt: DateTime(2026, 7, 8),
        ),
      ];

      final budgets = [
        const Budget(id: 1, categoryId: 2, month: '2026-07', limitAmount: 18000.0),
        const Budget(id: 2, categoryId: 3, month: '2026-07', limitAmount: 10000.0),
      ];

      final goals = [
        SavingsGoal(
          id: 1,
          name: 'Emergency Fund',
          targetAmount: 20000.0,
          currentAmount: 15000.0,
          color: '00ACC1',
          icon: 'savings',
          createdAt: DateTime(2026, 7, 1),
        ),
      ];

      final debts = <DebtLoan>[];
      final accounts = [
        Account(
          id: 1,
          name: 'Main Wallet',
          type: 'Cash',
          balance: 50000.0,
          icon: 'wallet',
          color: '4CAF50',
          isShared: true,
          createdAt: DateTime(2026, 7, 1),
        ),
      ];

      mockSnapshot = FinancialSnapshot(
        transactions: transactions,
        categories: categories,
        budgets: budgets,
        goals: goals,
        debts: debts,
        accounts: accounts,
        selectedMonth: '2026-07',
        selectedDate: now,
      );
    });

    test('IncomeAnalyzer filters and aggregates salary correct', () async {
      final context = OrchestratorContext(mockSnapshot);
      final analyzer = IncomeAnalyzer();
      final result = await analyzer.execute(context);

      expect(result.totalIncome, equals(80000.0));
      expect(result.incomeTransactions.length, equals(1));
      expect(result.incomeBySource['Salary'], equals(80000.0));
    });

    test('ExpenseAnalyzer filters and categorizes Flow Groups correct', () async {
      final context = OrchestratorContext(mockSnapshot);
      final analyzer = ExpenseAnalyzer();
      final result = await analyzer.execute(context);

      expect(result.totalExpense, equals(27650.0)); // Rent 18k + Food 9k + Netflix 650
      expect(result.spendByFlowGroup['Essentials'], equals(18000.0)); // Rent 18k
      expect(result.spendByFlowGroup['Lifestyle'], equals(9000.0)); // Food 9k
      expect(result.spendByFlowGroup['Others'], equals(650.0)); // Netflix 650
    });

    test('SubscriptionAnalyzer identifies Netflix correctly', () async {
      final context = OrchestratorContext(mockSnapshot);
      final analyzer = SubscriptionAnalyzer();
      final result = await analyzer.execute(context);

      expect(result.totalSubscriptionSpend, equals(650.0));
      expect(result.activeSubscriptions.length, equals(1));
      expect(result.activeSubscriptions.first.title, contains('Netflix'));
    });

    test('SpendingPredictor calculates velocity burn rate', () async {
      final context = OrchestratorContext(mockSnapshot);
      context.expenseAnalysis = await ExpenseAnalyzer().execute(context);
      
      final predictor = SpendingPredictor();
      final result = await predictor.execute(context);

      expect(result.dailyBurnRate, equals(27650.0 / 10)); // July 10th benchmark date
      expect(result.weeklyBurnRate, equals((27650.0 / 10) * 7));
    });

    test('PurchaseAdvisor simulates purchase recovery speed', () async {
      final context = OrchestratorContext(mockSnapshot);
      context.incomeAnalysis = await IncomeAnalyzer().execute(context);
      context.expenseAnalysis = await ExpenseAnalyzer().execute(context);
      
      // Simulate purchase amount
      context.simulatedPurchaseAmount = 10000.0;

      final advisor = PurchaseAdvisor();
      final result = await advisor.execute(context);

      expect(result.purchaseAmount, equals(10000.0));
      // Net savings: 80k - 27650 = 52350
      // Recovery days: 10000 / (52350 / 30.43) = 6 days
      expect(result.budgetRecoveryDays, equals(6));
    });
  });
}

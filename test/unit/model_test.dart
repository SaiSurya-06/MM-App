import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/models/account.dart';
import 'package:money_manager/models/transaction.dart';
import 'package:money_manager/models/budget.dart';

void main() {
  group('Account Model Tests', () {
    test('Account serialization and deserialization with exact rounding', () {
      final now = DateTime.now();
      final account = Account(
        id: 1,
        name: 'Test Account',
        type: 'Credit Card',
        balance: -40.237, // Should round to -40.24
        icon: 'account_balance',
        color: 'FF0000',
        isShared: true,
        createdAt: now,
        limitAmount: 500.124, // Should round to 500.12
      );

      final map = account.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Test Account');
      expect(map['balance'], -40.237); // original value preserved in raw map serialization

      // Deserialization rounding check
      final parsed = Account.fromMap({
        'id': 1,
        'name': 'Test Account',
        'type': 'Credit Card',
        'balance': -40.237,
        'icon': 'account_balance',
        'color': 'FF0000',
        'is_shared': 1,
        'created_at': now.toIso8601String(),
        'limit_amount': 500.124,
      });

      expect(parsed.balance, -40.24);
      expect(parsed.limitAmount, 500.12);
      expect(parsed.pendingPayment, 40.24);
      expect(parsed.isShared, true);
    });

    test('Account copyWith generates correct updated model', () {
      final account = Account(
        name: 'Savings',
        type: 'Bank',
        balance: 10.0,
        icon: 'savings',
        color: '00FF00',
        isShared: false,
        createdAt: DateTime.now(),
      );

      final updated = account.copyWith(name: 'Updated Savings', isShared: true);
      expect(updated.name, 'Updated Savings');
      expect(updated.isShared, true);
      expect(updated.balance, 10.0);
    });
  });

  group('Transaction Model Tests', () {
    test('Transaction serialization, deserialization, and amount rounding', () {
      final now = DateTime.now();
      final tx = Transaction(
        id: 101,
        accountId: 1,
        categoryId: 5,
        title: 'Lunch',
        amount: 15.549, // Should round to 15.55
        type: 'expense',
        date: DateTime(2026, 6, 20),
        note: 'Tasty meal',
        recurrence: 'none',
        isPrivate: false,
        createdAt: now,
      );

      final map = tx.toMap();
      expect(map['id'], 101);
      expect(map['amount'], 15.549);
      expect(map['date'], '2026-06-20');

      final parsed = Transaction.fromMap({
        'id': 101,
        'account_id': 1,
        'category_id': 5,
        'title': 'Lunch',
        'amount': 15.549,
        'type': 'expense',
        'date': '2026-06-20',
        'note': 'Tasty meal',
        'recurrence': 'none',
        'is_private': 0,
        'created_at': now.toIso8601String(),
      });

      expect(parsed.amount, 15.55);
      expect(parsed.isPrivate, false);
      expect(parsed.date.year, 2026);
    });
  });

  group('Budget Model Tests', () {
    test('Budget serialization and copyWith', () {
      const budget = Budget(
        id: 45,
        categoryId: 2,
        month: '2026-06',
        limitAmount: 400.0,
        recurrence: 'monthly',
        groupName: 'Essentials',
      );

      final map = budget.toMap();
      expect(map['category_id'], 2);
      expect(map['limit_amount'], 400.0);

      final parsed = Budget.fromMap(map);
      expect(parsed.id, 45);
      expect(parsed.limitAmount, 400.0);
      expect(parsed.groupName, 'Essentials');

      final updated = budget.copyWith(limitAmount: 500.0);
      expect(updated.limitAmount, 500.0);
      expect(updated.month, '2026-06');
    });
  });
}

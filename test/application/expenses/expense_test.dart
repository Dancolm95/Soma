import 'package:flutter_test/flutter_test.dart';

import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';

Map<String, dynamic> rowWith({required dynamic amount}) {
  return {
    'id': 'exp-1',
    'amount': amount,
    'expense_date': '2026-09-10',
    'merchant': 'Bodega',
    'category_id': 'cat-1',
    'created_at': '2026-09-10T12:00:00.000Z',
    'updated_at': '2026-09-10T12:00:00.000Z',
  };
}

void main() {
  group('exact money representation', () {
    test('converts minor units to DB strings without double', () {
      expect(expenseAmountToDb(1), '0.01');
      expect(expenseAmountToDb(100), '1.00');
      expect(expenseAmountToDb(1990), '19.90');
      expect(expenseAmountToDb(999999999999), '9999999999.99');
    });

    test('parses DB values back to identical minor units', () {
      expect(parseExpenseAmount('0.01'), 1);
      expect(parseExpenseAmount('1.00'), 100);
      expect(parseExpenseAmount('19.90'), 1990);
      expect(parseExpenseAmount('9999999999.99'), 999999999999);
      expect(parseExpenseAmount('19.9'), 1990);
      expect(parseExpenseAmount(19), 1900);
    });

    test('round-trip domain to payload to domain is exact', () {
      for (final minor in [1, 100, 1990, 999999999999]) {
        expect(parseExpenseAmount(expenseAmountToDb(minor)), minor);
      }
    });

    test('rejects zero, negatives and over-limit amounts', () {
      expect(
        () => validateExpenseAmount(0),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.error,
            'error',
            ExpenseError.invalidAmount,
          ),
        ),
      );
      expect(() => validateExpenseAmount(-5), throwsA(isA<ExpenseException>()));
      expect(
        () => validateExpenseAmount(1000000000000),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.error,
            'error',
            ExpenseError.invalidAmount,
          ),
        ),
      );
    });
  });

  group('Expense mapping', () {
    test('maps a full row', () {
      final expense = Expense.fromJson(rowWith(amount: '19.90'));

      expect(expense.id, 'exp-1');
      expect(expense.amountMinor, 1990);
      expect(expense.expenseDate, DateTime(2026, 9, 10));
      expect(expense.merchant, 'Bodega');
      expect(expense.categoryId, 'cat-1');
    });

    test('ignores session-owned user_id without exposing it', () {
      final row = {...rowWith(amount: '1.00'), 'user_id': 'user-a'};
      final expense = Expense.fromJson(row);

      expect(expense.amountMinor, 100);
      expect(expense.id, 'exp-1');
    });
  });

  group('validations', () {
    test('rejects blank and overlong merchants', () {
      expect(
        () => validateExpenseMerchant('   '),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.error,
            'error',
            ExpenseError.invalidMerchant,
          ),
        ),
      );
      expect(
        () => validateExpenseMerchant(List.filled(121, 'x').join()),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.error,
            'error',
            ExpenseError.invalidMerchant,
          ),
        ),
      );
      expect(
        () => validateExpenseMerchant(List.filled(120, 'y').join()),
        returnsNormally,
      );
    });

    test('rejects empty category ids', () {
      expect(
        () => validateExpenseCategoryId('  '),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.error,
            'error',
            ExpenseError.invalidCategory,
          ),
        ),
      );
    });
  });

  group('expenseErrorMessage', () {
    test('never leaks technical details', () {
      for (final error in ExpenseError.values) {
        final message = expenseErrorMessage(error);

        expect(message, isNotEmpty);
        expect(message, isNot(contains('23503')));
        expect(message, isNot(contains('23514')));
        expect(message, isNot(contains('42501')));
        expect(message, isNot(contains('SELECT')));
        expect(message, isNot(contains('Postgrest')));
        expect(message, isNot(contains('uuid')));
      }
    });
  });
}

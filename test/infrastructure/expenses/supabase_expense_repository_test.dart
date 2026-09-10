import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/infrastructure/expenses/supabase_expense_repository.dart';

import '../../helpers/fake_expense_store.dart';

Future<ExpenseException> capture(Future<void> Function() action) async {
  try {
    await action();
  } on ExpenseException catch (error) {
    return error;
  }
  fail('expected an ExpenseException');
}

Map<String, dynamic> seedRow({
  required String id,
  required String userId,
  required String amount,
  required String date,
  required String created,
  required String category,
}) {
  return {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'expense_date': date,
    'merchant': 'M-$id',
    'category_id': category,
    'created_at': created,
    'updated_at': created,
  };
}

void main() {
  group('listExpenses', () {
    test('returns own rows ordered by date then created desc', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      store.rows.addAll([
        seedRow(
          id: 'old',
          userId: 'user-a',
          amount: '1.00',
          date: '2026-09-01',
          created: '2026-09-01T10:00:00.000Z',
          category: fakeGlobalCategory,
        ),
        seedRow(
          id: 'new',
          userId: 'user-a',
          amount: '2.00',
          date: '2026-09-05',
          created: '2026-09-05T10:00:00.000Z',
          category: fakeGlobalCategory,
        ),
        seedRow(
          id: 'same-day-early',
          userId: 'user-a',
          amount: '3.00',
          date: '2026-09-05',
          created: '2026-09-05T09:00:00.000Z',
          category: fakeGlobalCategory,
        ),
        seedRow(
          id: 'foreign',
          userId: 'user-b',
          amount: '99.99',
          date: '2026-09-09',
          created: '2026-09-09T10:00:00.000Z',
          category: fakeForeignCategory,
        ),
      ]);
      final repository = SupabaseExpenseRepository(store);

      final expenses = await repository.listExpenses();

      expect(expenses.map((e) => e.id), ['new', 'same-day-early', 'old']);
    });

    test('maps forbidden failures safely', () async {
      final store = FakeExpenseStore(visibleUserId: null);
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(repository.listExpenses);

      expect(error.error, ExpenseError.forbidden);
      expect(expenseErrorMessage(error.error), isNot(contains('42501')));
    });

    test('maps unexpected failures safely', () async {
      final store = _ThrowingStore();
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(repository.listExpenses);

      expect(error.error, ExpenseError.unexpected);
      expect(expenseErrorMessage(error.error), isNot(contains('explode')));
    });
  });

  group('createExpense', () {
    test('sends only allowed columns without user_id', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      await repository.createExpense(
        amountMinor: 1990,
        expenseDate: DateTime(2026, 9, 10),
        merchant: 'Bodega',
        categoryId: fakeGlobalCategory,
      );

      expect(store.lastInsertPayload, {
        'amount': '19.90',
        'expense_date': '2026-09-10',
        'merchant': 'Bodega',
        'category_id': fakeGlobalCategory,
      });
      expect(store.lastInsertPayload!.containsKey('user_id'), isFalse);
      expect(store.lastInsertPayload!.containsKey('currency'), isFalse);
    });

    test('encodes 0.01 and the DB maximum exactly', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      final one = await repository.createExpense(
        amountMinor: 1,
        expenseDate: DateTime(2026, 9, 1),
        merchant: 'Min',
        categoryId: fakeGlobalCategory,
      );
      final max = await repository.createExpense(
        amountMinor: 999999999999,
        expenseDate: DateTime(2026, 9, 2),
        merchant: 'Max',
        categoryId: fakeOwnCategory,
      );

      expect(one.amountMinor, 1);
      expect(max.amountMinor, 999999999999);
      expect(store.rows.last['amount'], '9999999999.99');
    });

    test('rejects invalid amounts before touching the store', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(
        () => repository.createExpense(
          amountMinor: 0,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'Bodega',
          categoryId: fakeGlobalCategory,
        ),
      );

      expect(error.error, ExpenseError.invalidAmount);
      expect(store.lastInsertPayload, isNull);
    });

    test('rejects invalid merchants before touching the store', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(
        () => repository.createExpense(
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: '   ',
          categoryId: fakeGlobalCategory,
        ),
      );

      expect(error.error, ExpenseError.invalidMerchant);
      expect(store.lastInsertPayload, isNull);
    });

    test('rejects empty categories before touching the store', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(
        () => repository.createExpense(
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'Bodega',
          categoryId: '  ',
        ),
      );

      expect(error.error, ExpenseError.invalidCategory);
      expect(store.lastInsertPayload, isNull);
    });

    test('maps foreign categories without leaking ownership', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      final repository = SupabaseExpenseRepository(store);

      final error = await capture(
        () => repository.createExpense(
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'Bodega',
          categoryId: fakeForeignCategory,
        ),
      );

      expect(error.error, ExpenseError.invalidCategory);
      expect(
        expenseErrorMessage(error.error),
        isNot(contains(fakeForeignCategory)),
      );
    });
  });

  group('updateExpense', () {
    test('sends only editable columns', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      store.rows.add(
        seedRow(
          id: 'exp-1',
          userId: 'user-a',
          amount: '1.00',
          date: '2026-09-01',
          created: '2026-09-01T10:00:00.000Z',
          category: fakeGlobalCategory,
        ),
      );
      final repository = SupabaseExpenseRepository(store);

      final updated = await repository.updateExpense(
        id: 'exp-1',
        amountMinor: 1990,
        expenseDate: DateTime(2026, 8, 15),
        merchant: 'Editado',
        categoryId: fakeOwnCategory,
      );

      expect(store.lastUpdate!.id, 'exp-1');
      expect(store.lastUpdate!.payload, {
        'amount': '19.90',
        'expense_date': '2026-08-15',
        'merchant': 'Editado',
        'category_id': fakeOwnCategory,
      });
      expect(updated.amountMinor, 1990);
    });

    test('reports missing or foreign rows as notFound', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      store.rows.add(
        seedRow(
          id: 'foreign',
          userId: 'user-b',
          amount: '7.25',
          date: '2026-09-01',
          created: '2026-09-01T10:00:00.000Z',
          category: fakeForeignCategory,
        ),
      );
      final repository = SupabaseExpenseRepository(store);

      final foreign = await capture(
        () => repository.updateExpense(
          id: 'foreign',
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'X',
          categoryId: fakeGlobalCategory,
        ),
      );
      final missing = await capture(
        () => repository.updateExpense(
          id: 'no-such-id',
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'X',
          categoryId: fakeGlobalCategory,
        ),
      );

      expect(foreign.error, ExpenseError.notFound);
      expect(missing.error, ExpenseError.notFound);
    });

    test('maps amount and merchant check failures distinctly', () async {
      final repository = SupabaseExpenseRepository(
        _CheckFailureStore('amount'),
      );
      final amountError = await capture(
        () => repository.createExpense(
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'Bodega',
          categoryId: fakeGlobalCategory,
        ),
      );
      expect(amountError.error, ExpenseError.invalidAmount);

      final merchantRepo = SupabaseExpenseRepository(
        _CheckFailureStore('merchant'),
      );
      final merchantError = await capture(
        () => merchantRepo.createExpense(
          amountMinor: 100,
          expenseDate: DateTime(2026, 9, 10),
          merchant: 'Bodega',
          categoryId: fakeGlobalCategory,
        ),
      );
      expect(merchantError.error, ExpenseError.invalidMerchant);
    });
  });

  group('deleteExpense', () {
    test('deletes an own expense', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      store.rows.add(
        seedRow(
          id: 'exp-1',
          userId: 'user-a',
          amount: '5.00',
          date: '2026-09-03',
          created: '2026-09-03T10:00:00.000Z',
          category: fakeGlobalCategory,
        ),
      );
      final repository = SupabaseExpenseRepository(store);

      await repository.deleteExpense('exp-1');

      expect(store.lastDeleteId, 'exp-1');
      expect(await repository.listExpenses(), isEmpty);
    });

    test('reports foreign or missing deletes as notFound', () async {
      final store = FakeExpenseStore(visibleUserId: 'user-a');
      store.rows.add(
        seedRow(
          id: 'foreign',
          userId: 'user-b',
          amount: '7.25',
          date: '2026-09-01',
          created: '2026-09-01T10:00:00.000Z',
          category: fakeForeignCategory,
        ),
      );
      final repository = SupabaseExpenseRepository(store);

      final foreign = await capture(() => repository.deleteExpense('foreign'));
      final missing = await capture(
        () => repository.deleteExpense('no-such-id'),
      );

      expect(foreign.error, ExpenseError.notFound);
      expect(missing.error, ExpenseError.notFound);
      expect(store.rows.where((r) => r['id'] == 'foreign'), isNotEmpty);
    });
  });
}

class _ThrowingStore extends FakeExpenseStore {
  _ThrowingStore() : super(visibleUserId: 'user-a');

  @override
  Future<List<Map<String, dynamic>>> fetchAll() =>
      throw const PostgrestException(message: 'explode', code: 'XX000');
}

class _CheckFailureStore extends FakeExpenseStore {
  _CheckFailureStore(this.marker) : super(visibleUserId: 'user-a');

  final String marker;

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload) =>
      throw PostgrestException(
        message: 'violates $marker check',
        code: '23514',
      );
}

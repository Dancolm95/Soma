import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  test('load success populates expenses', () async {
    final repo = FakeExpenseRepository()..expenses = [testExpense()];
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.expenses, hasLength(1));
    expect(controller.errorMessage, isNull);
  });

  test('load error exposes safe message', () async {
    final repo = FakeExpenseRepository()
      ..listError = const ExpenseException(ExpenseError.unexpected);
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.expenses, isEmpty);
    expect(controller.errorMessage, isNotNull);
    expect(controller.errorMessage, isNot(contains('Postgrest')));
  });

  test('create refreshes after success', () async {
    final repo = FakeExpenseRepository();
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);

    final ok = await controller.createExpense(
      amountMinor: 1990,
      expenseDate: DateTime(2026, 9, 10),
      merchant: 'Bodega',
      categoryId: 'cat-global',
    );

    expect(ok, isTrue);
    expect(controller.expenses, hasLength(1));
    expect(controller.busy, isFalse);
  });

  test('create error keeps safe message', () async {
    final repo = FakeExpenseRepository()
      ..createError = const ExpenseException(ExpenseError.invalidAmount);
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);

    final ok = await controller.createExpense(
      amountMinor: 0,
      expenseDate: DateTime(2026, 9, 10),
      merchant: 'Bodega',
      categoryId: 'cat-global',
    );

    expect(ok, isFalse);
    expect(controller.errorMessage, isNotNull);
  });

  test('delete notFound shows safe message and refreshes', () async {
    final repo = FakeExpenseRepository()
      ..deleteError = const ExpenseException(ExpenseError.notFound);
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);

    final ok = await controller.deleteExpense('missing');

    expect(ok, isFalse);
    expect(controller.errorMessage, contains('no existe'));
  });

  test('busy prevents duplicate submit', () async {
    final repo = FakeExpenseRepository();
    final controller = ExpensesController(repo);
    addTearDown(controller.dispose);
    controller.busy = true;

    final ok = await controller.createExpense(
      amountMinor: 1990,
      expenseDate: DateTime(2026, 9, 10),
      merchant: 'Bodega',
      categoryId: 'cat-global',
    );

    expect(ok, isFalse);
    expect(repo.createCalls, 0);
    controller.busy = false;
  });
}

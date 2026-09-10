import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expense_form_page.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

import '../../helpers/fake_repositories.dart';

Future<FakeExpenseRepository> pumpForm(
  WidgetTester tester, {
  bool editing = false,
  FakeExpenseRepository? expenseRepo,
  FakeCategoryRepository? categoryRepo,
}) async {
  final repo = expenseRepo ?? FakeExpenseRepository();
  final expenses = ExpensesController(repo);
  final categories = CategoriesController(
    categoryRepo ?? (FakeCategoryRepository()..categories = testCategories()),
  );
  addTearDown(expenses.dispose);
  addTearDown(categories.dispose);
  await categories.load();
  await tester.pumpWidget(
    MaterialApp(
      home: ExpenseFormPage(
        expensesController: expenses,
        categoriesController: categories,
        expense: editing ? testExpense() : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('validates amount and merchant', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Importe'),
      'abc',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Comercio o concepto'),
      '',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un importe válido.'), findsOneWidget);
    expect(find.textContaining('comercio'), findsWidgets);
  });

  testWidgets('rejects more than two decimals', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Importe'),
      '19.999',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un importe válido.'), findsOneWidget);
  });

  testWidgets('submit creates expense and pops', (tester) async {
    final repo = FakeExpenseRepository();
    await pumpForm(tester, expenseRepo: repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Importe'),
      '19,90',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Comercio o concepto'),
      'Bodega',
    );
    await tester.tap(find.textContaining('Categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.expenses.single.amountMinor, 1990);
  });

  testWidgets('submit error keeps form and shows safe message', (tester) async {
    final repo = FakeExpenseRepository()
      ..createError = const ExpenseException(ExpenseError.unexpected);
    await pumpForm(tester, expenseRepo: repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Importe'),
      '10.00',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Comercio o concepto'),
      'Bodega',
    );
    await tester.tap(find.textContaining('Categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Bodega'), findsOneWidget);
    expect(find.textContaining('inesperado'), findsOneWidget);
  });

  testWidgets('edit prefills amount, merchant and category', (tester) async {
    await pumpForm(tester, editing: true);

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.map((f) => f.controller?.text), contains('19.90'));
    expect(fields.map((f) => f.controller?.text), contains('Bodega Central'));
    expect(find.text('Editar gasto'), findsOneWidget);
  });
}

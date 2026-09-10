import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_page.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_repositories.dart';

Future<void> pumpExpenses(
  WidgetTester tester, {
  required FakeExpenseRepository expenseRepo,
  required FakeCategoryRepository categoryRepo,
}) async {
  final authService = FakeAuthService();
  final auth = AuthController(authService);
  final expenses = ExpensesController(expenseRepo);
  final categories = CategoriesController(categoryRepo);
  addTearDown(auth.dispose);
  addTearDown(authService.dispose);
  addTearDown(expenses.dispose);
  addTearDown(categories.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: ExpensesPage(
        expensesController: expenses,
        categoriesController: categories,
        authController: auth,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state', (tester) async {
    await pumpExpenses(
      tester,
      expenseRepo: FakeExpenseRepository(),
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    expect(find.text('No tienes gastos registrados todavía.'), findsOneWidget);
    expect(find.text('Agregar gasto'), findsWidgets);
  });

  testWidgets('renders expense with PEN, merchant, date and category', (
    tester,
  ) async {
    await pumpExpenses(
      tester,
      expenseRepo: FakeExpenseRepository()..expenses = [testExpense()],
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    expect(find.text('Bodega Central'), findsOneWidget);
    expect(find.text('S/ 19.90'), findsOneWidget);
    expect(find.textContaining('10/09/2026'), findsOneWidget);
    expect(find.textContaining('Otros'), findsOneWidget);
  });

  testWidgets('shows error state without internals', (tester) async {
    await pumpExpenses(
      tester,
      expenseRepo: FakeExpenseRepository()
        ..listError = const ExpenseException(ExpenseError.unexpected),
      categoryRepo: FakeCategoryRepository(),
    );

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('Postgrest'), findsNothing);
    expect(find.textContaining('UUID'), findsNothing);
  });

  testWidgets('delete asks confirmation and removes on success', (
    tester,
  ) async {
    await pumpExpenses(
      tester,
      expenseRepo: FakeExpenseRepository()..expenses = [testExpense()],
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await tester.tap(find.byTooltip('Eliminar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar este gasto?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Bodega Central'), findsNothing);
    expect(find.text('Gasto eliminado.'), findsOneWidget);
  });

  testWidgets('delete error keeps row and shows safe message', (tester) async {
    await pumpExpenses(
      tester,
      expenseRepo: FakeExpenseRepository()
        ..expenses = [testExpense()]
        ..deleteError = const ExpenseException(ExpenseError.unexpected),
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await tester.tap(find.byTooltip('Eliminar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Bodega Central'), findsOneWidget);
    expect(find.textContaining('Postgrest'), findsNothing);
  });
}

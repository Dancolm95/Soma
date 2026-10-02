import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/home/home_shell.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_metrics_repository.dart';
import '../../helpers/fake_repositories.dart';

Future<FakeExpenseRepository> _pumpHome(
  WidgetTester tester, {
  FakeExpenseRepository? expenseRepo,
  FakeCategoryRepository? categoryRepo,
  FakeMetricsRepository? metricsRepo,
}) async {
  final expenses = expenseRepo ?? FakeExpenseRepository();
  final categories = categoryRepo ?? FakeCategoryRepository();
  final metrics = metricsRepo ?? FakeMetricsRepository();
  final authService = FakeAuthService();
  final auth = AuthController(authService);
  final expensesController = ExpensesController(expenses);
  final categoriesController = CategoriesController(categories);
  final metricsController = MetricsController(metrics);
  addTearDown(auth.dispose);
  addTearDown(authService.dispose);
  addTearDown(expensesController.dispose);
  addTearDown(categoriesController.dispose);
  addTearDown(metricsController.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: HomeShell(
        expensesController: expensesController,
        categoriesController: categoriesController,
        metricsController: metricsController,
        authController: auth,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return expenses;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('shows balance hero, tiles and recents', (tester) async {
    await _pumpHome(
      tester,
      expenseRepo: FakeExpenseRepository()..expenses = [testExpense()],
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    expect(find.text('S/ 1234.56'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Bodega Central'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);
  });

  testWidgets('tile opens capture and saving refreshes home', (tester) async {
    final expenseRepo = await _pumpHome(
      tester,
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await tester.tap(find.text('Transporte'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);

    await _tapVisible(tester, find.text('5'));
    await _tapVisible(tester, find.text('0'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Taxi');
    await _tapVisible(tester, find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(expenseRepo.createCalls, 1);
    expect(find.text('Gasto guardado.'), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('center action opens capture', (tester) async {
    await _pumpHome(
      tester,
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/capture/quick_capture_sheet.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

import '../../helpers/fake_repositories.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FakeExpenseRepository expenseRepo,
  required FakeCategoryRepository categoryRepo,
}) async {
  final expenses = ExpensesController(expenseRepo);
  final categories = CategoriesController(categoryRepo);
  addTearDown(expenses.dispose);
  addTearDown(categories.dispose);
  await categories.load();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showQuickCapture(
            context,
            expensesController: expenses,
            categoriesController: categories,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('shows amount, categories and numpad', (tester) async {
    await _pumpSheet(
      tester,
      expenseRepo: FakeExpenseRepository(),
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    expect(find.text('Nuevo gasto'), findsOneWidget);
    expect(find.text('S/ 0.00'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Guardar gasto'), findsOneWidget);
  });

  testWidgets('saves with numpad amount and merchant', (tester) async {
    final expenseRepo = FakeExpenseRepository();
    await _pumpSheet(
      tester,
      expenseRepo: expenseRepo,
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await _tapVisible(tester, find.text('2'));
    await _tapVisible(tester, find.text('5'));
    await tester.pump();
    expect(find.text('S/ 0.25'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bodega');
    await _tapVisible(tester, find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(expenseRepo.createCalls, 1);
    expect(find.text('Nuevo gasto'), findsNothing);
  });

  testWidgets('zero amount keeps save disabled', (tester) async {
    final expenseRepo = FakeExpenseRepository();
    await _pumpSheet(
      tester,
      expenseRepo: expenseRepo,
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await tester.enterText(find.byType(TextField), 'Bodega');
    await _tapVisible(tester, find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(expenseRepo.createCalls, 0);
    expect(find.text('Nuevo gasto'), findsOneWidget);
  });

  testWidgets('missing merchant shows domain message', (tester) async {
    final expenseRepo = FakeExpenseRepository();
    await _pumpSheet(
      tester,
      expenseRepo: expenseRepo,
      categoryRepo: FakeCategoryRepository()..categories = testCategories(),
    );

    await _tapVisible(tester, find.text('5'));
    await tester.pump();
    await _tapVisible(tester, find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(expenseRepo.createCalls, 0);
    expect(find.textContaining('1 y 120 caracteres'), findsOneWidget);
  });

  testWidgets('without categories save stays disabled', (tester) async {
    final expenseRepo = FakeExpenseRepository();
    await _pumpSheet(
      tester,
      expenseRepo: expenseRepo,
      categoryRepo: FakeCategoryRepository(),
    );

    expect(
      find.text('Primero crea una categoría desde la pestaña Más.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Guardar gasto'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.enabled, isFalse);

    await _tapVisible(tester, find.text('5'));
    await _tapVisible(tester, find.text('Guardar gasto'));

    expect(expenseRepo.createCalls, 0);
    expect(find.text('Nuevo gasto'), findsOneWidget);
  });
}

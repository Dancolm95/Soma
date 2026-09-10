import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/infrastructure/auth/supabase_auth_service.dart';
import 'package:soma_app/infrastructure/categories/supabase_category_repository.dart';
import 'package:soma_app/infrastructure/categories/supabase_category_store.dart';
import 'package:soma_app/infrastructure/expenses/supabase_expense_repository.dart';
import 'package:soma_app/infrastructure/expenses/supabase_expense_store.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final email =
      'soma.itest.${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'Password123456';

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      password,
    );
  }

  testWidgets('registro, sesión, logout, login y restauración reales', (
    tester,
  ) async {
    app.main();
    await waitFor(tester, find.text('Inicia sesión'));

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();
    await enterCredentials(tester, email: email, password: password);
    await tester.tap(find.text('Registrarse'));
    await waitFor(tester, find.text('Gastos'));

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await waitFor(tester, find.text('Inicia sesión'));

    await enterCredentials(tester, email: email, password: password);
    await tester.tap(find.text('Entrar'));
    await waitFor(tester, find.text('Gastos'));

    await tester.pumpWidget(const SizedBox.shrink());
    final restoredController = AuthController(
      SupabaseAuthService(Supabase.instance.client),
    );
    final client = Supabase.instance.client;
    final restoredExpenses = ExpensesController(
      SupabaseExpenseRepository(SupabaseExpenseStore(client)),
    );
    final restoredCategories = CategoriesController(
      SupabaseCategoryRepository(SupabaseCategoryStore(client)),
    );
    await tester.pumpWidget(
      SomaApp(
        authController: restoredController,
        expensesController: restoredExpenses,
        categoriesController: restoredCategories,
      ),
    );
    await waitFor(tester, find.text('Gastos'));

    restoredController.dispose();
    restoredExpenses.dispose();
    restoredCategories.dispose();
  });
}

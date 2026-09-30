// Local-only smoke for Task 4.5 (Supabase local + real app/repo/controller).
// Requires `supabase start` and seed migrations. Not run by `flutter test`
// in CI (integration_test is device-driven); run explicitly:
//   fvm flutter test integration_test/metrics_dashboard_smoke_test.dart
// Uses publishable key only. Fixture users are removed at the end
// (auth.users delete via SQL cascade); the test deletes its expenses first.
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
import 'package:soma_app/infrastructure/metrics/supabase_metrics_repository.dart';
import 'package:soma_app/infrastructure/metrics/supabase_metrics_store.dart';

const _url = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);
const _publishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
);

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('metrics dashboard smoke against local Supabase', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final emailA = 'smoke45a$stamp@example.com';
    final emailB = 'smoke45b$stamp@example.com';
    const password = 'Password123456';

    final client = SupabaseClient(_url, _publishableKey);
    final authController = AuthController(SupabaseAuthService(client));
    addTearDown(authController.dispose);
    await tester.pumpWidget(
      SomaApp(
        authController: authController,
        expenseRepository: SupabaseExpenseRepository(
          SupabaseExpenseStore(client),
        ),
        categoryRepository: SupabaseCategoryRepository(
          SupabaseCategoryStore(client),
        ),
        metricsRepository: SupabaseMetricsRepository(
          SupabaseMetricsStore(client),
        ),
      ),
    );
    await _waitFor(tester, find.text('Inicia sesión'));

    // A: sign up via backend, app must reach Gastos.
    final signUp = await client.auth.signUp(email: emailA, password: password);
    expect(signUp.session, isNotNull, reason: 'local autoconfirm expected');
    await _waitFor(tester, find.text('Gastos'));

    // A fixtures through RLS as A.
    final cats = await client
        .from('categories')
        .select('id')
        .isFilter('user_id', null)
        .limit(2);
    final cat1 = (cats[0] as Map)['id'] as String;
    final cat2 = (cats[1] as Map)['id'] as String;
    await client.from('expenses').insert([
      {
        'amount': '19.90',
        'expense_date': '2026-09-10',
        'merchant': 'Metro',
        'category_id': cat1,
      },
      {
        'amount': '5.50',
        'expense_date': '2026-09-12',
        'merchant': 'metro',
        'category_id': cat1,
      },
      {
        'amount': '100.00',
        'expense_date': '2026-08-05',
        'merchant': 'Plaza',
        'category_id': cat2,
      },
    ]);

    // Gastos -> Resumen.
    await tester.tap(find.byTooltip('Resumen'));
    await _waitFor(tester, find.text('Total del mes'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 25.40'), findsWidgets);
    expect(find.text('Metro'), findsOneWidget);
    expect(find.text('metro'), findsOneWidget);
    expect(find.textContaining('Disminución'), findsOneWidget);

    // Month change + back + refresh via real UI taps.
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('S/ 100.00'), findsWidgets);
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Septiembre 2026'), findsOneWidget);

    // Back to Gastos, logout via real button.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Gastos'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await _waitFor(tester, find.text('Inicia sesión'));
    expect(find.text('S/ 25.40'), findsNothing);

    // B: fresh login sees no A data.
    try {
      await client.auth.signInWithPassword(email: emailB, password: password);
    } catch (_) {
      await client.auth.signUp(email: emailB, password: password);
    }
    if (client.auth.currentSession?.user.email != emailB) {
      await client.auth.signUp(email: emailB, password: password);
    }
    await _waitFor(tester, find.text('Gastos'));
    await tester.tap(find.byTooltip('Resumen'));
    await _waitFor(tester, find.text('Total del mes'));
    await tester.pumpAndSettle();
    expect(find.text('Metro'), findsNothing);
    expect(find.text('Sin gastos en este mes.'), findsWidgets);

    // Cleanup own fixtures (auth users removed via SQL cascade afterwards).
    await tester.pageBack();
    await tester.pumpAndSettle();
    await client.auth.signInWithPassword(email: emailA, password: password);
    await client
        .from('expenses')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
    await client.auth.signOut();
    client.dispose();
  });
}

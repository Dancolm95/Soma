import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/home/home_shell.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';
import 'package:soma_app/presentation/metrics/metrics_page.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_metrics_repository.dart';
import '../../helpers/fake_repositories.dart';

MetricsController readyController({
  FakeMetricsRepository? repository,
  DateTime? initialMonth,
  DateTime? currentMonth,
}) {
  final repo = repository ?? FakeMetricsRepository(month: DateTime(2026, 9, 1));
  final controller = MetricsController(
    repo,
    initialMonth: initialMonth ?? DateTime(2026, 9, 15),
    currentMonth: currentMonth ?? DateTime(2026, 9, 30),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> pumpMetrics(
  WidgetTester tester,
  MetricsController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(home: MetricsPage(controller: controller)),
  );
}

Future<void> settleLoad(WidgetTester tester, Future<void> load) async {
  final pending = load;
  await tester.pump();
  await pending;
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows loading indicator while fetching', (tester) async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final gate = Completer<void>();
    repo.totalHandler = (_) =>
        gate.future.then((value) => testTotal(month: DateTime(2026, 9, 1)));
    final controller = readyController(repository: repo);
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });

    final load = controller.load();
    await pumpMetrics(tester, controller);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    gate.complete();
    await load;
    await tester.pumpAndSettle();
    expect(find.text('S/ 1234.56'), findsOneWidget);
  });

  testWidgets('month change does not display the previous month total', (
    tester,
  ) async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = readyController(repository: repo);
    await controller.load();
    await pumpMetrics(tester, controller);
    expect(find.text('S/ 1234.56'), findsOneWidget);

    final gate = Completer<MonthlyTotal>();
    repo.totalHandler = (_) => gate.future;
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('S/ 1234.56'), findsNothing);

    gate.complete(testTotal(month: DateTime(2026, 8, 1)));
    await tester.pumpAndSettle();
    expect(find.text('S/ 1234.56'), findsOneWidget);
  });

  testWidgets('renders total in PEN without currency selector', (tester) async {
    final controller = readyController();
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('S/ 1234.56'), findsOneWidget);
    expect(find.textContaining('USD'), findsNothing);
  });

  testWidgets('refresh action reloads all six metrics', (tester) async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = readyController(repository: repo);
    await controller.load();
    await pumpMetrics(tester, controller);

    await tester.tap(find.byTooltip('Actualizar resumen'));
    await tester.pumpAndSettle();

    for (final calls in [
      repo.totalCalls,
      repo.breakdownCalls,
      repo.topCategoriesCalls,
      repo.topMerchantsCalls,
      repo.trendCalls,
      repo.comparisonCalls,
    ]) {
      expect(calls.length, 2);
    }
  });

  testWidgets('positive comparison shows increase and percentage', (
    tester,
  ) async {
    final controller = readyController();
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('Aumento'), findsOneWidget);
    expect(find.text('S/ 120.00'), findsOneWidget);
    expect(find.text('10.8%'), findsOneWidget);
  });

  testWidgets('negative comparison shows decrease', (tester) async {
    final repo = FakeMetricsRepository(
      month: DateTime(2026, 9, 1),
      comparison: testComparison(
        month: DateTime(2026, 9, 1),
        differenceMinor: -5000,
        percentageChange: const PercentageChange('-4.2'),
      ),
    );
    final controller = readyController(repository: repo);
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('Disminución'), findsOneWidget);
    expect(find.text('-4.2%'), findsOneWidget);
  });

  testWidgets('zero comparison shows no change', (tester) async {
    final repo = FakeMetricsRepository(
      month: DateTime(2026, 9, 1),
      comparison: testComparison(
        month: DateTime(2026, 9, 1),
        differenceMinor: 0,
        percentageChange: const PercentageChange('0'),
      ),
    );
    final controller = readyController(repository: repo);
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin cambio'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('∞'), findsNothing);
  });

  testWidgets('null percentage shows neutral text', (tester) async {
    final repo = FakeMetricsRepository(
      month: DateTime(2026, 9, 1),
      comparison: testComparison(
        month: DateTime(2026, 9, 1),
        differenceMinor: 1000,
        percentageChange: null,
      ),
    );
    final controller = readyController(repository: repo);
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Sin base de comparación'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    expect(find.text('NaN'), findsNothing);
  });

  testWidgets('renders six trend points with totals', (tester) async {
    final controller = readyController();
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Evolución — 6 meses'), findsOneWidget);
    for (final label in [
      '04/2026',
      '05/2026',
      '06/2026',
      '07/2026',
      '08/2026',
      '09/2026',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('S/ 60.00'), findsOneWidget);
  });

  testWidgets('renders breakdown, top categories and exact merchants', (
    tester,
  ) async {
    final controller = readyController();
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Por categoría'), 500);
    expect(find.text('Por categoría'), findsOneWidget);
    expect(find.text('Comida'), findsWidgets);
    expect(find.text('S/ 50.00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Top categorías'), 500);
    expect(find.text('Top categorías'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Top comercios'), 500);
    expect(find.text('Top comercios'), findsOneWidget);
    expect(find.text('Metro'), findsOneWidget);
    expect(find.text('metro'), findsOneWidget);
  });

  testWidgets('empty month is valid, not an error', (tester) async {
    final repo = FakeMetricsRepository(
      month: DateTime(2026, 9, 1),
      total: testTotal(month: DateTime(2026, 9, 1), totalMinor: 0),
      breakdown: const [],
      topCategories: const [],
      topMerchants: const [],
      trend: testTrend(month: DateTime(2026, 9, 1)),
      comparison: testComparison(
        month: DateTime(2026, 9, 1),
        differenceMinor: 0,
        percentageChange: null,
      ),
    );
    final controller = readyController(repository: repo);
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('S/ 0.00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Por categoría'), 500);
    expect(find.text('Sin gastos en este mes.'), findsWidgets);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('error shows safe message with retry that recovers', (
    tester,
  ) async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1))
      ..trendError = const MetricsException(MetricsError.unexpected);
    final controller = readyController(repository: repo);
    final load = controller.load();
    await pumpMetrics(tester, controller);
    await load;
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('Postgrest'), findsNothing);

    repo.trendError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('S/ 1234.56'), findsOneWidget);
  });

  testWidgets('month navigation previous/next and future disabled', (
    tester,
  ) async {
    final controller = readyController();
    await settleLoad(tester, controller.load());
    await pumpMetrics(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Septiembre 2026'), findsOneWidget);
  });

  testWidgets('shell navigates to Resumen; Más keeps categories and logout', (
    tester,
  ) async {
    final authService = FakeAuthService();
    final auth = AuthController(authService);
    final expenses = ExpensesController(FakeExpenseRepository());
    final categories = CategoriesController(
      FakeCategoryRepository()..categories = testCategories(),
    );
    final metrics = MetricsController(
      FakeMetricsRepository(month: DateTime(2026, 9, 1)),
      initialMonth: DateTime(2026, 9, 15),
      currentMonth: DateTime(2026, 9, 30),
    );
    addTearDown(auth.dispose);
    addTearDown(authService.dispose);
    addTearDown(expenses.dispose);
    addTearDown(categories.dispose);
    addTearDown(metrics.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          expensesController: expenses,
          categoriesController: categories,
          metricsController: metrics,
          authController: auth,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);

    await tester.tap(find.text('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Total del mes'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Gastos'), findsOneWidget);

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}

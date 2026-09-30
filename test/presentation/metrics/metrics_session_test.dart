import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';
import 'package:soma_app/application/metrics/metrics.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_metrics_repository.dart';
import '../../helpers/fake_repositories.dart';

const _userA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _userB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

MonthlyTotal totalFor(DateTime month, int minor) =>
    MonthlyTotal(periodStart: month, totalMinor: minor);

void main() {
  testWidgets('A to B: pending B load never shows A metrics', (tester) async {
    final service = FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    addTearDown(service.dispose);
    final metrics = GatedMetricsRepository();
    await tester.pumpWidget(
      SomaApp(
        authController: auth,
        expenseRepository: FakeExpenseRepository(),
        categoryRepository: FakeCategoryRepository(),
        metricsRepository: metrics,
      ),
    );

    metrics.onTotal = (month) async =>
        totalFor(canonicalMetricsMonth(month), 11111);
    service.emit(const SessionUser(id: _userA, email: 'a@example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 111.11'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final gateB = Completer<MonthlyTotal>();
    metrics.onTotal = (_) => gateB.future;
    service.emit(const SessionUser(id: _userB, email: 'b@example.com'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Resumen'));
    await tester.pump();
    await tester.pump();
    expect(find.text('S/ 111.11'), findsNothing);

    gateB.complete(totalFor(DateTime(2026, 9, 1), 22222));
    await tester.pumpAndSettle();
    expect(find.text('S/ 222.22'), findsOneWidget);
    expect(find.text('S/ 111.11'), findsNothing);
  });

  testWidgets('logout clears metrics state', (tester) async {
    final service = FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    addTearDown(service.dispose);
    final metrics = GatedMetricsRepository();
    metrics.onTotal = (month) async =>
        totalFor(canonicalMetricsMonth(month), 11111);
    await tester.pumpWidget(
      SomaApp(
        authController: auth,
        expenseRepository: FakeExpenseRepository(),
        categoryRepository: FakeCategoryRepository(),
        metricsRepository: metrics,
      ),
    );

    service.emit(const SessionUser(id: _userA, email: 'a@example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 111.11'), findsOneWidget);

    service.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('S/ 111.11'), findsNothing);
    expect(find.text('Resumen'), findsNothing);
  });
}

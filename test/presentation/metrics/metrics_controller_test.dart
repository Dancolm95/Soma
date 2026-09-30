import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';

import '../../helpers/fake_metrics_repository.dart';

MetricsController buildController({
  FakeMetricsRepository? repository,
  DateTime? initialMonth,
  DateTime? currentMonth,
}) {
  final repo = repository ?? FakeMetricsRepository(month: DateTime(2026, 9, 1));
  final controller = MetricsController(
    repo,
    initialMonth: initialMonth ?? DateTime(2026, 9, 18),
    currentMonth: currentMonth ?? DateTime(2026, 9, 30),
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  test(
    'initial state uses canonical current-local month, empty, not loading',
    () {
      final controller = MetricsController(
        FakeMetricsRepository(),
        initialMonth: DateTime(2026, 9, 18, 15, 30),
        currentMonth: DateTime(2026, 9, 30),
      );
      addTearDown(controller.dispose);

      expect(controller.selectedMonth, DateTime(2026, 9, 1));
      expect(controller.loading, isFalse);
      expect(controller.snapshot, isNull);
      expect(controller.errorMessage, isNull);
    },
  );

  test(
    'successful load publishes a full snapshot for the same month',
    () async {
      final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
      final controller = buildController(repository: repo);

      await controller.load();

      expect(controller.loading, isFalse);
      expect(controller.errorMessage, isNull);
      final snapshot = controller.snapshot!;
      expect(snapshot.month, DateTime(2026, 9, 1));
      expect(snapshot.total.totalMinor, 123456);
      expect(snapshot.breakdown.length, 2);
      expect(snapshot.topCategories.length, 2);
      expect(snapshot.topMerchants.length, 2);
      expect(snapshot.trend.length, 6);
      expect(snapshot.comparison.differenceMinor, 12000);
      for (final calls in [
        repo.totalCalls,
        repo.breakdownCalls,
        repo.topCategoriesCalls,
        repo.topMerchantsCalls,
        repo.trendCalls,
        repo.comparisonCalls,
      ]) {
        expect(calls, [DateTime(2026, 9, 1)]);
      }
    },
  );

  test('change month loads the new canonical month', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = buildController(repository: repo);

    await controller.selectMonth(DateTime(2026, 8, 20));

    expect(controller.selectedMonth, DateTime(2026, 8, 1));
    expect(repo.totalCalls.last, DateTime(2026, 8, 1));
    expect(repo.comparisonCalls.last, DateTime(2026, 8, 1));
  });

  test('previous and next navigate one month', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = buildController(repository: repo);
    await controller.load();
    repo.totalCalls.clear();

    await controller.previousMonth();
    expect(controller.selectedMonth, DateTime(2026, 8, 1));

    await controller.nextMonth();
    expect(controller.selectedMonth, DateTime(2026, 9, 1));
  });

  test('future months are blocked', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = buildController(repository: repo);
    await controller.load();
    final calls = repo.totalCallCount;

    await controller.selectMonth(DateTime(2026, 10, 1));
    await controller.nextMonth();

    expect(controller.selectedMonth, DateTime(2026, 9, 1));
    expect(repo.totalCallCount, calls);
    expect(controller.isAtCurrentMonth, isTrue);
  });

  test('refresh reloads the same six operations', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final controller = buildController(repository: repo);
    await controller.load();

    await controller.refresh();

    expect(repo.totalCalls.length, 2);
    expect(repo.comparisonCalls.length, 2);
    expect(controller.selectedMonth, DateTime(2026, 9, 1));
  });

  test(
    'error in each operation yields safe error without partial snapshot',
    () async {
      final kinds = <String, void Function(FakeMetricsRepository)>{
        'total': (r) =>
            r.totalError = const MetricsException(MetricsError.unexpected),
        'breakdown': (r) => r.breakdownError = const MetricsException(
          MetricsError.invalidResponse,
        ),
        'topCategories': (r) => r.topCategoriesError = const MetricsException(
          MetricsError.unauthorized,
        ),
        'topMerchants': (r) => r.topMerchantsError = const MetricsException(
          MetricsError.unexpected,
        ),
        'trend': (r) =>
            r.trendError = const MetricsException(MetricsError.unexpected),
        'comparison': (r) =>
            r.comparisonError = const MetricsException(MetricsError.unexpected),
      };
      for (final entry in kinds.entries) {
        final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
        entry.value(repo);
        final controller = buildController(repository: repo);

        await controller.load();

        expect(
          controller.errorMessage,
          isNotNull,
          reason: 'failing op: ${entry.key}',
        );
        expect(
          controller.snapshot,
          isNull,
          reason: 'no partial snapshot on ${entry.key} failure',
        );
        expect(controller.loading, isFalse);
      }
    },
  );

  test('safe messages never leak internals', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1))
      ..comparisonError = const MetricsException(MetricsError.unexpected);
    final controller = buildController(repository: repo);

    await controller.load();

    expect(controller.errorMessage, isNotNull);
    for (final banned in ['Postgrest', 'SQLSTATE', 'jwt', '42501']) {
      expect(controller.errorMessage, isNot(contains(banned)));
    }
  });

  test('stale response does not overwrite a newer selection', () async {
    final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
    final septemberGate = Completer<MonthlyTotal>();
    final controller = buildController(repository: repo);

    repo.totalHandler = (month) {
      if (month == DateTime(2026, 9, 1)) return septemberGate.future;
      return Future.value(testTotal(month: month));
    };

    final first = controller.load();
    await controller.selectMonth(DateTime(2026, 8, 10));
    septemberGate.complete(testTotal(month: DateTime(2026, 9, 1)));
    await first;
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectedMonth, DateTime(2026, 8, 1));
    expect(controller.snapshot?.month, DateTime(2026, 8, 1));
    expect(controller.errorMessage, isNull);
  });

  test(
    'month change hides the old snapshot until all six results arrive',
    () async {
      final repo = FakeMetricsRepository(month: DateTime(2026, 9, 1));
      final gate = Completer<List<CategorySpending>>();
      final controller = buildController(repository: repo);
      await controller.load();
      expect(controller.snapshot?.month, DateTime(2026, 9, 1));

      repo.breakdownHandler = (_) => gate.future;
      final nextLoad = controller.selectMonth(DateTime(2026, 8, 15));
      expect(controller.selectedMonth, DateTime(2026, 8, 1));
      expect(controller.loading, isTrue);
      expect(controller.snapshot, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(controller.snapshot, isNull);

      gate.complete(repo.breakdown);
      await nextLoad;
      expect(controller.snapshot?.month, DateTime(2026, 8, 1));
      expect(controller.loading, isFalse);
    },
  );

  test('null percentage is preserved as absence', () async {
    final repo = FakeMetricsRepository(
      month: DateTime(2026, 9, 1),
      comparison: testComparison(
        month: DateTime(2026, 9, 1),
        differenceMinor: 0,
        percentageChange: null,
      ),
    );
    final controller = buildController(repository: repo);

    await controller.load();

    expect(controller.snapshot?.comparison.percentageChange, isNull);
    expect(controller.snapshot?.comparison.differenceMinor, 0);
  });

  test('dispose does not throw after load', () async {
    final controller = MetricsController(
      FakeMetricsRepository(month: DateTime(2026, 9, 1)),
      initialMonth: DateTime(2026, 9, 18),
      currentMonth: DateTime(2026, 9, 30),
    );
    await controller.load();
    controller.dispose();
  });
}

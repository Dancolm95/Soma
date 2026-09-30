import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';
import 'package:soma_app/infrastructure/metrics/supabase_metrics_repository.dart';

import '../../helpers/fake_metrics_store.dart';

const _catA = '11111111-1111-1111-1111-111111111111';
const _catB = '22222222-2222-2222-2222-222222222222';

Future<MetricsException> capture(Future<void> Function() action) async {
  try {
    await action();
  } on MetricsException catch (error) {
    return error;
  }
  fail('expected a MetricsException');
}

Map<String, dynamic> totalRow(String period, dynamic total) => {
  'period_start': period,
  'total': total,
};

Map<String, dynamic> categoryRow(String id, String name, dynamic total) => {
  'category_id': id,
  'category_name': name,
  'total': total,
};

Map<String, dynamic> merchantRow(String merchant, dynamic total) => {
  'merchant': merchant,
  'total': total,
};

Map<String, dynamic> comparisonRow({
  required String period,
  required dynamic current,
  required String previousPeriod,
  required dynamic previous,
  required dynamic difference,
  required dynamic percentage,
}) => {
  'period_start': period,
  'current_total': current,
  'previous_period_start': previousPeriod,
  'previous_total': previous,
  'difference': difference,
  'percentage_change': percentage,
};

List<Map<String, dynamic>> trendRows(
  List<String> periods,
  List<dynamic> totals,
) {
  assert(periods.length == totals.length);
  return [
    for (var i = 0; i < periods.length; i++)
      {'period_start': periods[i], 'total': totals[i]},
  ];
}

void main() {
  group('month canonicalization and payload', () {
    test('canonicalizes any day to day 1 ISO without time or zone', () async {
      final store = FakeMetricsStore(
        monthlyTotalRows: [totalRow('2026-09-01', '0')],
      );
      final repository = SupabaseMetricsRepository(store);

      await repository.monthlyTotal(DateTime(2026, 9, 18, 15, 30));

      expect(store.calls['expenses_monthly_total'], {'p_month': '2026-09-01'});
    });

    test('handles year boundary (January -> previous December)', () async {
      final store = FakeMetricsStore(
        monthlyComparisonRows: [
          comparisonRow(
            period: '2026-01-01',
            current: '10.00',
            previousPeriod: '2025-12-01',
            previous: '5.00',
            difference: '5.00',
            percentage: '100',
          ),
        ],
      );
      final repository = SupabaseMetricsRepository(store);

      final comparison = await repository.monthlyComparison(
        DateTime(2026, 1, 7),
      );

      expect(store.calls['expenses_monthly_comparison'], {
        'p_month': '2026-01-01',
      });
      expect(comparison.previousPeriodStart, DateTime(2025, 12, 1));
    });

    test('sends exactly p_month on every RPC', () async {
      final store = FakeMetricsStore(
        monthlyTotalRows: [totalRow('2026-09-01', '1.00')],
        spendingByCategoryRows: [],
        topCategoriesRows: [],
        topMerchantsRows: [],
        monthlyTrendRows: trendRows(
          [
            '2026-04-01',
            '2026-05-01',
            '2026-06-01',
            '2026-07-01',
            '2026-08-01',
            '2026-09-01',
          ],
          ['0', '0', '0', '0', '0', '1.00'],
        ),
        monthlyComparisonRows: [
          comparisonRow(
            period: '2026-09-01',
            current: '1.00',
            previousPeriod: '2026-08-01',
            previous: '0',
            difference: '1.00',
            percentage: null,
          ),
        ],
      );
      final repository = SupabaseMetricsRepository(store);
      final month = DateTime(2026, 9, 20);

      await repository.monthlyTotal(month);
      await repository.spendingByCategory(month);
      await repository.topCategories(month);
      await repository.topMerchants(month);
      await repository.monthlyTrend(month);
      await repository.monthlyComparison(month);

      expect(store.calls.length, 6);
      for (final params in store.calls.values) {
        expect(params.keys, ['p_month']);
        expect(params['p_month'], '2026-09-01');
      }
    });
  });

  group('money parsing', () {
    test('converts exact decimal strings to minor units', () {
      expect(parseMetricsAmount('0.01'), 1);
      expect(parseMetricsAmount('19.90'), 1990);
      expect(parseMetricsAmount('120'), 12000);
      expect(parseMetricsAmount('20000000059.98'), 2000000005998);
    });

    test('supports negatives for difference', () {
      expect(parseMetricsAmount('-20.50'), -2050);
      expect(parseMetricsAmount('-0.01'), -1);
    });

    test('rejects malformed numerics', () {
      expect(() => parseMetricsAmount('abc'), throwsA(isA<FormatException>()));
      expect(
        () => parseMetricsAmount('1.234'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseMetricsAmount('1.2.3'),
        throwsA(isA<FormatException>()),
      );
      expect(() => parseMetricsAmount(''), throwsA(isA<FormatException>()));
    });
  });

  group('monthlyTotal', () {
    test('maps a valid row', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(monthlyTotalRows: [totalRow('2026-09-01', '19.90')]),
      );

      final total = await repository.monthlyTotal(DateTime(2026, 9, 15));

      expect(total.periodStart, DateTime(2026, 9, 1));
      expect(total.totalMinor, 1990);
    });

    test('preserves zero totals', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(monthlyTotalRows: [totalRow('2026-09-01', '0')]),
      );

      final total = await repository.monthlyTotal(DateTime(2026, 9, 1));

      expect(total.totalMinor, 0);
    });

    test('rejects zero, multiple or mismatched rows', () async {
      final empty = SupabaseMetricsRepository(FakeMetricsStore());
      expect(
        (await capture(() => empty.monthlyTotal(DateTime(2026, 9, 1)))).error,
        MetricsError.invalidResponse,
      );

      final two = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTotalRows: [
            totalRow('2026-09-01', '1.00'),
            totalRow('2026-09-01', '2.00'),
          ],
        ),
      );
      expect(
        (await capture(() => two.monthlyTotal(DateTime(2026, 9, 1)))).error,
        MetricsError.invalidResponse,
      );

      final wrongMonth = SupabaseMetricsRepository(
        FakeMetricsStore(monthlyTotalRows: [totalRow('2026-08-01', '1.00')]),
      );
      expect(
        (await capture(() => wrongMonth.monthlyTotal(DateTime(2026, 9, 1))))
            .error,
        MetricsError.invalidResponse,
      );
    });

    test('rejects invalid numeric and date', () async {
      final badNumeric = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTotalRows: [totalRow('2026-09-01', 'not-a-number')],
        ),
      );
      expect(
        (await capture(() => badNumeric.monthlyTotal(DateTime(2026, 9, 1))))
            .error,
        MetricsError.invalidResponse,
      );

      final badDate = SupabaseMetricsRepository(
        FakeMetricsStore(monthlyTotalRows: [totalRow('not-a-date', '1.00')]),
      );
      expect(
        (await capture(() => badDate.monthlyTotal(DateTime(2026, 9, 1)))).error,
        MetricsError.invalidResponse,
      );
    });
  });

  group('spendingByCategory', () {
    test('maps rows preserving DB order', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          spendingByCategoryRows: [
            categoryRow(_catB, 'Zeta', '30.00'),
            categoryRow(_catA, 'Alfa', '10.00'),
          ],
        ),
      );

      final rows = await repository.spendingByCategory(DateTime(2026, 9, 1));

      expect(rows.map((r) => r.categoryName), ['Zeta', 'Alfa']);
      expect(rows.map((r) => r.totalMinor), [3000, 1000]);
    });

    test('rejects invalid uuid, name or total', () async {
      for (final bad in [
        categoryRow('not-a-uuid', 'Ok', '1.00'),
        categoryRow(_catA, '', '1.00'),
        categoryRow(_catA, 'Ok', 'bogus'),
      ]) {
        final repository = SupabaseMetricsRepository(
          FakeMetricsStore(spendingByCategoryRows: [bad]),
        );
        expect(
          (await capture(
            () => repository.spendingByCategory(DateTime(2026, 9, 1)),
          )).error,
          MetricsError.invalidResponse,
        );
      }
    });
  });

  group('top categories and merchants', () {
    test('accepts 0..5 rows preserving order', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          topCategoriesRows: [
            categoryRow(_catA, 'A', '5.00'),
            categoryRow(_catB, 'B', '1.00'),
          ],
        ),
      );

      final rows = await repository.topCategories(DateTime(2026, 9, 1));

      expect(rows.length, 2);
      expect(rows.first.categoryName, 'A');

      final emptyRepo = SupabaseMetricsRepository(FakeMetricsStore());
      expect(await emptyRepo.topCategories(DateTime(2026, 9, 1)), isEmpty);
      expect(await emptyRepo.topMerchants(DateTime(2026, 9, 1)), isEmpty);
    });

    test('rejects more than 5 rows as contract violation', () async {
      final cats = SupabaseMetricsRepository(
        FakeMetricsStore(
          topCategoriesRows: [
            for (var i = 0; i < 6; i++)
              categoryRow(_catA, 'C$i', '${i + 1}.00'),
          ],
        ),
      );
      expect(
        (await capture(() => cats.topCategories(DateTime(2026, 9, 1)))).error,
        MetricsError.invalidResponse,
      );

      final merchants = SupabaseMetricsRepository(
        FakeMetricsStore(
          topMerchantsRows: [
            for (var i = 0; i < 6; i++) merchantRow('M$i', '${i + 1}.00'),
          ],
        ),
      );
      expect(
        (await capture(() => merchants.topMerchants(DateTime(2026, 9, 1))))
            .error,
        MetricsError.invalidResponse,
      );
    });

    test('keeps Metro and metro distinct without normalization', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          topMerchantsRows: [
            merchantRow('Metro', '10.00'),
            merchantRow('metro', '9.00'),
          ],
        ),
      );

      final rows = await repository.topMerchants(DateTime(2026, 9, 1));

      expect(rows.map((r) => r.merchant), ['Metro', 'metro']);
    });
  });

  group('monthlyTrend', () {
    List<String> sixEndingSeptember() => [
      '2026-04-01',
      '2026-05-01',
      '2026-06-01',
      '2026-07-01',
      '2026-08-01',
      '2026-09-01',
    ];

    test('maps six consecutive months ending at requested month', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTrendRows: trendRows(sixEndingSeptember(), [
            '0',
            '10.00',
            '0',
            '5.50',
            '0',
            '19.90',
          ]),
        ),
      );

      final points = await repository.monthlyTrend(DateTime(2026, 9, 20));

      expect(points.length, 6);
      expect(points.map((p) => p.totalMinor), [0, 1000, 0, 550, 0, 1990]);
      expect(points.last.periodStart, DateTime(2026, 9, 1));
    });

    test('supports year boundary windows', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTrendRows: trendRows(
            [
              '2025-08-01',
              '2025-09-01',
              '2025-10-01',
              '2025-11-01',
              '2025-12-01',
              '2026-01-01',
            ],
            ['1.00', '0', '0', '0', '0', '2.00'],
          ),
        ),
      );

      final points = await repository.monthlyTrend(DateTime(2026, 1, 10));

      expect(points.first.periodStart, DateTime(2025, 8, 1));
      expect(points.last.periodStart, DateTime(2026, 1, 1));
    });

    test('rejects 5 or 7 rows', () async {
      for (final count in [5, 7]) {
        final repository = SupabaseMetricsRepository(
          FakeMetricsStore(
            monthlyTrendRows: trendRows(
              List.generate(count, (i) => '2026-0${i + 1}-01'),
              List.generate(count, (_) => '0'),
            ),
          ),
        );
        expect(
          (await capture(() => repository.monthlyTrend(DateTime(2026, 7, 1))))
              .error,
          MetricsError.invalidResponse,
        );
      }
    });

    test('rejects gaps and wrong ending month', () async {
      final gap = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTrendRows: trendRows(
            [
              '2026-04-01',
              '2026-05-01',
              '2026-06-01',
              '2026-07-01',
              '2026-08-01',
              '2026-10-01',
            ],
            ['0', '0', '0', '0', '0', '0'],
          ),
        ),
      );
      expect(
        (await capture(() => gap.monthlyTrend(DateTime(2026, 10, 1)))).error,
        MetricsError.invalidResponse,
      );

      final wrongEnd = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyTrendRows: trendRows(sixEndingSeptember(), [
            '0',
            '0',
            '0',
            '0',
            '0',
            '0',
          ]),
        ),
      );
      expect(
        (await capture(() => wrongEnd.monthlyTrend(DateTime(2026, 10, 1))))
            .error,
        MetricsError.invalidResponse,
      );
    });
  });

  group('monthlyComparison', () {
    test('maps positive, negative and zero differences', () async {
      final up = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '150.00',
              previousPeriod: '2026-08-01',
              previous: '100.00',
              difference: '50.00',
              percentage: '50',
            ),
          ],
        ),
      );
      final upResult = await up.monthlyComparison(DateTime(2026, 9, 5));
      expect(upResult.differenceMinor, 5000);
      expect(upResult.percentageChange, const PercentageChange('50'));

      final down = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '80.00',
              previousPeriod: '2026-08-01',
              previous: '100.00',
              difference: '-20.00',
              percentage: '-20',
            ),
          ],
        ),
      );
      final downResult = await down.monthlyComparison(DateTime(2026, 9, 5));
      expect(downResult.differenceMinor, -2000);
      expect(downResult.percentageChange, const PercentageChange('-20'));

      final zero = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '100.00',
              previousPeriod: '2026-08-01',
              previous: '100.00',
              difference: '0',
              percentage: '0',
            ),
          ],
        ),
      );
      final zeroResult = await zero.monthlyComparison(DateTime(2026, 9, 5));
      expect(zeroResult.differenceMinor, 0);
      expect(zeroResult.percentageChange, const PercentageChange('0'));
    });

    test('preserves NULL percentage as absent, distinct from zero', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '10.00',
              previousPeriod: '2026-08-01',
              previous: '0',
              difference: '10.00',
              percentage: null,
            ),
          ],
        ),
      );

      final result = await repository.monthlyComparison(DateTime(2026, 9, 1));

      expect(result.percentageChange, isNull);
    });

    test('rejects missing, multiple or mismatched rows', () async {
      final empty = SupabaseMetricsRepository(FakeMetricsStore());
      expect(
        (await capture(() => empty.monthlyComparison(DateTime(2026, 9, 1))))
            .error,
        MetricsError.invalidResponse,
      );

      final two = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '1.00',
              previousPeriod: '2026-08-01',
              previous: '0',
              difference: '1.00',
              percentage: null,
            ),
            comparisonRow(
              period: '2026-09-01',
              current: '2.00',
              previousPeriod: '2026-08-01',
              previous: '0',
              difference: '2.00',
              percentage: null,
            ),
          ],
        ),
      );
      expect(
        (await capture(() => two.monthlyComparison(DateTime(2026, 9, 1))))
            .error,
        MetricsError.invalidResponse,
      );

      final wrongPrevious = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '1.00',
              previousPeriod: '2026-07-01',
              previous: '0',
              difference: '1.00',
              percentage: null,
            ),
          ],
        ),
      );
      expect(
        (await capture(
          () => wrongPrevious.monthlyComparison(DateTime(2026, 9, 1)),
        )).error,
        MetricsError.invalidResponse,
      );
    });

    test('rejects malformed numerics without recalculating', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          monthlyComparisonRows: [
            comparisonRow(
              period: '2026-09-01',
              current: '150.00',
              previousPeriod: '2026-08-01',
              previous: '100.00',
              difference: 'WRONG',
              percentage: 'not-a-number',
            ),
          ],
        ),
      );

      expect(
        (await capture(
          () => repository.monthlyComparison(DateTime(2026, 9, 1)),
        )).error,
        MetricsError.invalidResponse,
      );
    });
  });

  group('errors', () {
    test('maps authorization failures to unauthorized', () async {
      for (final failure in [
        const PostgrestException(message: 'permission denied', code: '42501'),
        const PostgrestException(message: 'not authenticated', code: '42501'),
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      ]) {
        final repository = SupabaseMetricsRepository(
          FakeMetricsStore(failure: failure),
        );
        expect(
          (await capture(() => repository.monthlyTotal(DateTime(2026, 9, 1))))
              .error,
          MetricsError.unauthorized,
        );
      }
    });

    test('maps unexpected failures without leaking details', () async {
      final repository = SupabaseMetricsRepository(
        FakeMetricsStore(
          failure: const PostgrestException(
            message: 'explode 23503 uuid payload',
            code: 'XX000',
          ),
        ),
      );

      final error = await capture(
        () => repository.monthlyTotal(DateTime(2026, 9, 1)),
      );

      expect(error.error, MetricsError.unexpected);
      expect(metricsErrorMessage(error.error), isNot(contains('23503')));
    });

    test('all messages are safe', () {
      for (final error in MetricsError.values) {
        final message = metricsErrorMessage(error);
        expect(message, isNotEmpty);
        expect(message, isNot(contains('Postgrest')));
        expect(message, isNot(contains('SQLSTATE')));
        expect(message, isNot(contains('uuid')));
        expect(message, isNot(contains('JWT')));
      }
    });

    test('contract never exposes Supabase types or user ids', () {
      const repository = TypeTester();
      expect(repository, isA<MetricsRepository>());
    });
  });
}

class TypeTester implements MetricsRepository {
  const TypeTester();

  @override
  Future<MonthlyTotal> monthlyTotal(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<List<CategorySpending>> spendingByCategory(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<List<CategorySpending>> topCategories(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<List<MerchantSpending>> topMerchants(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<List<MonthlyTrendPoint>> monthlyTrend(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<MonthlyComparison> monthlyComparison(DateTime month) =>
      throw UnimplementedError();
}

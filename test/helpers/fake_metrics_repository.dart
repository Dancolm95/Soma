import 'dart:async';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';

MonthlyTotal testTotal({DateTime? month, int totalMinor = 123456}) {
  final canonical = canonicalMetricsMonth(month ?? DateTime(2026, 9, 15));
  return MonthlyTotal(periodStart: canonical, totalMinor: totalMinor);
}

CategorySpending testCategorySpending({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'Comida',
  int totalMinor = 5000,
}) => CategorySpending(
  categoryId: id,
  categoryName: name,
  totalMinor: totalMinor,
);

MerchantSpending testMerchantSpending({
  String merchant = 'Metro',
  int totalMinor = 3000,
}) => MerchantSpending(merchant: merchant, totalMinor: totalMinor);

List<MonthlyTrendPoint> testTrend({DateTime? month}) {
  final canonical = canonicalMetricsMonth(month ?? DateTime(2026, 9, 15));
  return [
    for (var i = 5; i >= 0; i--)
      MonthlyTrendPoint(
        periodStart: addMetricsMonths(canonical, -i),
        totalMinor: (6 - i) * 1000,
      ),
  ];
}

MonthlyComparison testComparison({
  DateTime? month,
  int differenceMinor = 12000,
  PercentageChange? percentageChange = const PercentageChange('10.8'),
}) {
  final canonical = canonicalMetricsMonth(month ?? DateTime(2026, 9, 15));
  return MonthlyComparison(
    periodStart: canonical,
    currentTotalMinor: 123456,
    previousPeriodStart: addMetricsMonths(canonical, -1),
    previousTotalMinor: 111456,
    differenceMinor: differenceMinor,
    percentageChange: percentageChange,
  );
}

class FakeMetricsRepository implements MetricsRepository {
  FakeMetricsRepository({
    MonthlyTotal? total,
    List<CategorySpending>? breakdown,
    List<CategorySpending>? topCategories,
    List<MerchantSpending>? topMerchants,
    List<MonthlyTrendPoint>? trend,
    MonthlyComparison? comparison,
    DateTime? month,
  }) : total = total ?? testTotal(month: month),
       breakdown =
           breakdown ??
           [
             testCategorySpending(),
             testCategorySpending(
               id: '22222222-2222-2222-2222-222222222222',
               name: 'Transporte',
               totalMinor: 2500,
             ),
           ],
       topCategoriesData =
           topCategories ??
           [
             testCategorySpending(),
             testCategorySpending(
               id: '22222222-2222-2222-2222-222222222222',
               name: 'Transporte',
               totalMinor: 2500,
             ),
           ],
       topMerchantsData =
           topMerchants ??
           [
             testMerchantSpending(),
             testMerchantSpending(merchant: 'metro', totalMinor: 1000),
           ],
       trend = trend ?? testTrend(month: month),
       comparison = comparison ?? testComparison(month: month);

  MonthlyTotal total;
  List<CategorySpending> breakdown;
  List<CategorySpending> topCategoriesData;
  List<MerchantSpending> topMerchantsData;
  List<MonthlyTrendPoint> trend;
  MonthlyComparison comparison;

  MetricsException? totalError;
  MetricsException? breakdownError;
  MetricsException? topCategoriesError;
  MetricsException? topMerchantsError;
  MetricsException? trendError;
  MetricsException? comparisonError;

  Future<MonthlyTotal> Function(DateTime month)? totalHandler;
  Future<List<CategorySpending>> Function(DateTime month)? breakdownHandler;

  final List<DateTime> totalCalls = [];
  final List<DateTime> breakdownCalls = [];
  final List<DateTime> topCategoriesCalls = [];
  final List<DateTime> topMerchantsCalls = [];
  final List<DateTime> trendCalls = [];
  final List<DateTime> comparisonCalls = [];

  int get totalCallCount => totalCalls.length;

  @override
  Future<MonthlyTotal> monthlyTotal(DateTime month) async {
    totalCalls.add(month);
    if (totalHandler != null) return totalHandler!(month);
    if (totalError != null) throw totalError!;
    return total;
  }

  @override
  Future<List<CategorySpending>> spendingByCategory(DateTime month) async {
    breakdownCalls.add(month);
    if (breakdownHandler != null) return breakdownHandler!(month);
    if (breakdownError != null) throw breakdownError!;
    return breakdown;
  }

  @override
  Future<List<CategorySpending>> topCategories(DateTime month) async {
    topCategoriesCalls.add(month);
    if (topCategoriesError != null) throw topCategoriesError!;
    return topCategoriesData;
  }

  @override
  Future<List<MerchantSpending>> topMerchants(DateTime month) async {
    topMerchantsCalls.add(month);
    if (topMerchantsError != null) throw topMerchantsError!;
    return topMerchantsData;
  }

  @override
  Future<List<MonthlyTrendPoint>> monthlyTrend(DateTime month) async {
    trendCalls.add(month);
    if (trendError != null) throw trendError!;
    return trend;
  }

  @override
  Future<MonthlyComparison> monthlyComparison(DateTime month) async {
    comparisonCalls.add(month);
    if (comparisonError != null) throw comparisonError!;
    return comparison;
  }
}

class GatedMetricsRepository implements MetricsRepository {
  GatedMetricsRepository();

  Future<MonthlyTotal> Function(DateTime month)? onTotal;
  Future<List<CategorySpending>> Function(DateTime month)? onBreakdown;
  Future<List<CategorySpending>> Function(DateTime month)? onTopCategories;
  Future<List<MerchantSpending>> Function(DateTime month)? onTopMerchants;
  Future<List<MonthlyTrendPoint>> Function(DateTime month)? onTrend;
  Future<MonthlyComparison> Function(DateTime month)? onComparison;

  MonthlyTotal gatedTotal(DateTime month) => testTotal(month: month);

  @override
  Future<MonthlyTotal> monthlyTotal(DateTime month) =>
      onTotal?.call(month) ?? Future.value(gatedTotal(month));

  @override
  Future<List<CategorySpending>> spendingByCategory(DateTime month) =>
      onBreakdown?.call(month) ?? Future.value(const []);

  @override
  Future<List<CategorySpending>> topCategories(DateTime month) =>
      onTopCategories?.call(month) ?? Future.value(const []);

  @override
  Future<List<MerchantSpending>> topMerchants(DateTime month) =>
      onTopMerchants?.call(month) ?? Future.value(const []);

  @override
  Future<List<MonthlyTrendPoint>> monthlyTrend(DateTime month) =>
      onTrend?.call(month) ?? Future.value(testTrend(month: month));

  @override
  Future<MonthlyComparison> monthlyComparison(DateTime month) =>
      onComparison?.call(month) ??
      Future.value(
        testComparison(
          month: month,
          differenceMinor: 0,
          percentageChange: null,
        ),
      );
}

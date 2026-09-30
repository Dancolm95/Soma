import 'package:soma_app/infrastructure/metrics/metrics_store.dart';

class FakeMetricsStore implements MetricsStore {
  FakeMetricsStore({
    List<Map<String, dynamic>>? monthlyTotalRows,
    List<Map<String, dynamic>>? spendingByCategoryRows,
    List<Map<String, dynamic>>? topCategoriesRows,
    List<Map<String, dynamic>>? topMerchantsRows,
    List<Map<String, dynamic>>? monthlyTrendRows,
    List<Map<String, dynamic>>? monthlyComparisonRows,
    this.failure,
  }) : monthlyTotalRows = monthlyTotalRows ?? [],
       spendingByCategoryRows = spendingByCategoryRows ?? [],
       topCategoriesRows = topCategoriesRows ?? [],
       topMerchantsRows = topMerchantsRows ?? [],
       monthlyTrendRows = monthlyTrendRows ?? [],
       monthlyComparisonRows = monthlyComparisonRows ?? [];

  List<Map<String, dynamic>> monthlyTotalRows;
  List<Map<String, dynamic>> spendingByCategoryRows;
  List<Map<String, dynamic>> topCategoriesRows;
  List<Map<String, dynamic>> topMerchantsRows;
  List<Map<String, dynamic>> monthlyTrendRows;
  List<Map<String, dynamic>> monthlyComparisonRows;

  final Map<String, Map<String, dynamic>> calls = {};
  Exception? failure;

  Map<String, dynamic> _record(String rpc, String monthIso) {
    final params = {'p_month': monthIso};
    calls[rpc] = params;
    if (failure != null) throw failure!;
    return params;
  }

  static List<Map<String, dynamic>> _copy(List<Map<String, dynamic>> rows) => [
    for (final row in rows) Map<String, dynamic>.from(row),
  ];

  @override
  Future<List<Map<String, dynamic>>> monthlyTotal(String monthIso) async {
    _record('expenses_monthly_total', monthIso);
    return _copy(monthlyTotalRows);
  }

  @override
  Future<List<Map<String, dynamic>>> spendingByCategory(String monthIso) async {
    _record('expenses_spending_by_category', monthIso);
    return _copy(spendingByCategoryRows);
  }

  @override
  Future<List<Map<String, dynamic>>> topCategories(String monthIso) async {
    _record('expenses_top_categories', monthIso);
    return _copy(topCategoriesRows);
  }

  @override
  Future<List<Map<String, dynamic>>> topMerchants(String monthIso) async {
    _record('expenses_top_merchants', monthIso);
    return _copy(topMerchantsRows);
  }

  @override
  Future<List<Map<String, dynamic>>> monthlyTrend(String monthIso) async {
    _record('expenses_monthly_trend', monthIso);
    return _copy(monthlyTrendRows);
  }

  @override
  Future<List<Map<String, dynamic>>> monthlyComparison(String monthIso) async {
    _record('expenses_monthly_comparison', monthIso);
    return _copy(monthlyComparisonRows);
  }
}

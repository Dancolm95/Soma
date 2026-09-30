abstract class MetricsStore {
  Future<List<Map<String, dynamic>>> monthlyTotal(String monthIso);

  Future<List<Map<String, dynamic>>> spendingByCategory(String monthIso);

  Future<List<Map<String, dynamic>>> topCategories(String monthIso);

  Future<List<Map<String, dynamic>>> topMerchants(String monthIso);

  Future<List<Map<String, dynamic>>> monthlyTrend(String monthIso);

  Future<List<Map<String, dynamic>>> monthlyComparison(String monthIso);
}

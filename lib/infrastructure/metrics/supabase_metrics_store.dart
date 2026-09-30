import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/infrastructure/metrics/metrics_store.dart';

class SupabaseMetricsStore implements MetricsStore {
  SupabaseMetricsStore(this._client);

  final SupabaseClient _client;

  static List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is List) {
      return [
        for (final row in response) Map<String, dynamic>.from(row as Map),
      ];
    }
    if (response is Map) {
      return [Map<String, dynamic>.from(response)];
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> monthlyTotal(String monthIso) async {
    final response = await _client.rpc(
      'expenses_monthly_total',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }

  @override
  Future<List<Map<String, dynamic>>> spendingByCategory(String monthIso) async {
    final response = await _client.rpc(
      'expenses_spending_by_category',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }

  @override
  Future<List<Map<String, dynamic>>> topCategories(String monthIso) async {
    final response = await _client.rpc(
      'expenses_top_categories',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }

  @override
  Future<List<Map<String, dynamic>>> topMerchants(String monthIso) async {
    final response = await _client.rpc(
      'expenses_top_merchants',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }

  @override
  Future<List<Map<String, dynamic>>> monthlyTrend(String monthIso) async {
    final response = await _client.rpc(
      'expenses_monthly_trend',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }

  @override
  Future<List<Map<String, dynamic>>> monthlyComparison(String monthIso) async {
    final response = await _client.rpc(
      'expenses_monthly_comparison',
      params: {'p_month': monthIso},
    );
    return _rows(response);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/infrastructure/expenses/expense_store.dart';

class SupabaseExpenseStore implements ExpenseStore {
  SupabaseExpenseStore(this._client);

  final SupabaseClient _client;

  static const _table = 'expenses';
  static const _columns =
      'id,amount,expense_date,merchant,category_id,created_at,updated_at';

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload) async {
    final row = await _client
        .from(_table)
        .insert(payload)
        .select(_columns)
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final rows = await _client
        .from(_table)
        .update(payload)
        .eq('id', id)
        .select(_columns);
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }

  @override
  Future<List<Map<String, dynamic>>> delete(String id) async {
    final rows = await _client.from(_table).delete().eq('id', id).select('id');
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }
}

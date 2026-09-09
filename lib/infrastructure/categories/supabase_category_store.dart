import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/infrastructure/categories/category_store.dart';

/// PostgREST-backed [CategoryStore].
///
/// Uses the publishable key plus the authenticated session only; RLS is
/// the authorization boundary. No RPC, no views, no service_role.
class SupabaseCategoryStore implements CategoryStore {
  SupabaseCategoryStore(this._client);

  final SupabaseClient _client;

  static const _table = 'categories';
  static const _columns = 'id,name,user_id';

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client.from(_table).select(_columns).order('name');
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }

  @override
  Future<Map<String, dynamic>?> fetchOwner(String id) async {
    final row = await _client
        .from(_table)
        .select('user_id')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row as Map);
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
  Future<List<Map<String, dynamic>>> updateName(String id, String name) async {
    final rows = await _client
        .from(_table)
        .update({'name': name})
        .eq('id', id)
        .select(_columns);
    return [for (final row in rows) Map<String, dynamic>.from(row as Map)];
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

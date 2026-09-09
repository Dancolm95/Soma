import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/infrastructure/categories/category_store.dart';

/// Controllable [CategoryStore] double for tests.
///
/// Holds rows in memory as `{id, name, user_id}` maps and mimics the
/// database scoping: [visibleUserId] (null for anonymous) sees system rows
/// plus its own private ones. Writes record their payloads so tests can
/// assert exactly what the repository sends.
class FakeCategoryStore implements CategoryStore {
  FakeCategoryStore({required this.visibleUserId});

  /// User id the fake session sees as, or null for anonymous.
  final String? visibleUserId;

  final List<Map<String, dynamic>> rows = [];
  final Set<String> usedIds = {};

  Map<String, dynamic>? lastInsertPayload;
  ({String id, String name})? lastUpdate;
  String? lastDeleteId;

  bool _visible(Map<String, dynamic> row) {
    final owner = row['user_id'] as String?;
    return owner == null || owner == visibleUserId;
  }

  static PostgrestException _dbError(String code) =>
      PostgrestException(message: 'db rejected', code: code);

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final visible = rows.where(_visible).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return visible.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>?> fetchOwner(String id) async {
    for (final row in rows) {
      if (row['id'] == id && _visible(row)) {
        return {'user_id': row['user_id']};
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload) async {
    if (visibleUserId == null) {
      throw _dbError('42501');
    }
    final name = payload['name'] as String;
    final normalized = name.trim().toLowerCase();
    final duplicate = rows.any(
      (row) =>
          row['user_id'] == visibleUserId &&
          (row['name'] as String).trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw _dbError('23505');
    }
    final row = {
      'id': 'generated-id-${rows.length}',
      'name': name,
      'user_id': visibleUserId,
    };
    rows.add(row);
    lastInsertPayload = Map<String, dynamic>.from(payload);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> updateName(String id, String name) async {
    lastUpdate = (id: id, name: name);
    final index = rows.indexWhere((row) => row['id'] == id && _visible(row));
    if (index < 0) {
      return [];
    }
    final normalized = name.trim().toLowerCase();
    final duplicate = rows.any(
      (row) =>
          row['id'] != id &&
          row['user_id'] == rows[index]['user_id'] &&
          (row['name'] as String).trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw _dbError('23505');
    }
    rows[index] = {...rows[index], 'name': name};
    return [Map<String, dynamic>.from(rows[index])];
  }

  @override
  Future<void> delete(String id) async {
    lastDeleteId = id;
    if (usedIds.contains(id)) {
      throw _dbError('23503');
    }
    rows.removeWhere((row) => row['id'] == id && _visible(row));
  }
}

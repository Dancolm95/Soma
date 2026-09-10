import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/infrastructure/expenses/expense_store.dart';

const fakeGlobalCategory = 'cat-global';
const fakeOwnCategory = 'cat-own-a';
const fakeForeignCategory = 'cat-private-b';

class FakeExpenseStore implements ExpenseStore {
  FakeExpenseStore({required this.visibleUserId});

  final String? visibleUserId;

  final List<Map<String, dynamic>> rows = [];

  Map<String, dynamic>? lastInsertPayload;
  ({String id, Map<String, dynamic> payload})? lastUpdate;
  String? lastDeleteId;

  static PostgrestException _dbError(String code, String message) =>
      PostgrestException(message: message, code: code);

  bool _visible(Map<String, dynamic> row) => row['user_id'] == visibleUserId;

  bool _categoryAllowed(String categoryId) =>
      categoryId == fakeGlobalCategory || categoryId == fakeOwnCategory;

  void _checkDbConstraints(Map<String, dynamic> payload) {
    final categoryId = payload['category_id'] as String;
    if (!_categoryAllowed(categoryId)) {
      throw _dbError('23503', 'category is not available to this user');
    }
    final minor = parseExpenseAmount(payload['amount']);
    if (minor <= 0) {
      throw _dbError('23514', 'violates amount check');
    }
    final merchant = payload['merchant'] as String;
    final trimmed = merchant.trim();
    if (trimmed.isEmpty || trimmed.length > 120) {
      throw _dbError('23514', 'violates merchant check');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    if (visibleUserId == null) throw _dbError('42501', 'permission denied');
    final visible = rows.where(_visible).toList()
      ..sort((a, b) {
        final date = (b['expense_date'] as String).compareTo(
          a['expense_date'] as String,
        );
        if (date != 0) return date;
        return (b['created_at'] as String).compareTo(a['created_at'] as String);
      });
    return visible.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload) async {
    if (visibleUserId == null) throw _dbError('42501', 'permission denied');
    _checkDbConstraints(payload);
    lastInsertPayload = Map<String, dynamic>.from(payload);
    final now = '2026-09-10T12:00:00.000Z';
    final row = {
      'id': 'exp-${rows.length}',
      'user_id': visibleUserId,
      'amount': payload['amount'],
      'expense_date': payload['expense_date'],
      'merchant': payload['merchant'],
      'category_id': payload['category_id'],
      'created_at': now,
      'updated_at': now,
    };
    rows.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    if (visibleUserId == null) throw _dbError('42501', 'permission denied');
    lastUpdate = (id: id, payload: Map<String, dynamic>.from(payload));
    _checkDbConstraints(payload);
    final index = rows.indexWhere((row) => row['id'] == id && _visible(row));
    if (index < 0) return [];
    rows[index] = {
      ...rows[index],
      'amount': payload['amount'],
      'expense_date': payload['expense_date'],
      'merchant': payload['merchant'],
      'category_id': payload['category_id'],
      'updated_at': '2026-09-11T12:00:00.000Z',
    };
    return [Map<String, dynamic>.from(rows[index])];
  }

  @override
  Future<List<Map<String, dynamic>>> delete(String id) async {
    if (visibleUserId == null) throw _dbError('42501', 'permission denied');
    lastDeleteId = id;
    final index = rows.indexWhere((row) => row['id'] == id && _visible(row));
    if (index < 0) return [];
    final removed = rows.removeAt(index);
    return [
      {'id': removed['id']},
    ];
  }
}

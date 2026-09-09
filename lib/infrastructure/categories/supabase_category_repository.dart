import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/infrastructure/categories/category_store.dart';

/// [CategoryRepository] backed by Supabase through a [CategoryStore].
///
/// Sends only `name` for writes; ownership comes from the session via the
/// `user_id DEFAULT auth.uid()` column default. System categories are
/// rejected up front so forbidden actions fail fast with a clean domain
/// error, while RLS remains the authorization boundary in depth.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._store);

  final CategoryStore _store;

  @override
  Future<List<Category>> listCategories() async {
    try {
      final rows = await _store.fetchAll();
      final categories = [for (final row in rows) Category.fromJson(row)];
      categories.sort(_systemFirstAlphabetical);
      return categories;
    } on PostgrestException catch (error) {
      throw CategoryException(_translate(error.code));
    }
  }

  @override
  Future<Category> createCategory(String name) async {
    validateCategoryName(name);
    try {
      final row = await _store.insert({'name': name});
      return Category.fromJson(row);
    } on PostgrestException catch (error) {
      throw CategoryException(_translate(error.code));
    }
  }

  @override
  Future<Category> renameCategory({
    required String id,
    required String name,
  }) async {
    validateCategoryName(name);
    try {
      await _requireOwnPrivate(id);
      final rows = await _store.updateName(id, name);
      if (rows.isEmpty) {
        throw const CategoryException(CategoryError.forbidden);
      }
      return Category.fromJson(rows.first);
    } on PostgrestException catch (error) {
      throw CategoryException(_translate(error.code));
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _requireOwnPrivate(id);
      await _store.delete(id);
    } on PostgrestException catch (error) {
      throw CategoryException(_translate(error.code));
    }
  }

  /// Application-level guard: only own private categories are writable.
  ///
  /// System rows and rows invisible to the session (foreign or missing)
  /// are rejected as forbidden without revealing which case applied.
  Future<void> _requireOwnPrivate(String id) async {
    final owner = await _store.fetchOwner(id);
    if (owner == null || owner['user_id'] == null) {
      throw const CategoryException(CategoryError.forbidden);
    }
  }

  static int _systemFirstAlphabetical(Category a, Category b) {
    if (a.isSystem != b.isSystem) {
      return a.isSystem ? -1 : 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static CategoryError _translate(String? code) {
    switch (code) {
      case '23505':
        return CategoryError.duplicateName;
      case '23503':
        return CategoryError.categoryInUse;
      case '23514':
        return CategoryError.invalidName;
      case '42501':
        return CategoryError.forbidden;
      default:
        return CategoryError.unexpected;
    }
  }
}

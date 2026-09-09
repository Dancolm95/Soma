import 'package:soma_app/application/categories/category.dart';

/// Maximum category name length, mirroring the database constraint.
const kMaxCategoryNameLength = 60;

/// Small domain error set for category operations.
///
/// Technical details (SQL codes, stack traces, internal ids) are never
/// exposed; see [categoryErrorMessage] for the user-safe text.
enum CategoryError {
  invalidName,
  duplicateName,
  categoryInUse,
  forbidden,
  unexpected,
}

/// Failure thrown by [CategoryRepository] operations.
class CategoryException implements Exception {
  const CategoryException(this.error);

  final CategoryError error;
}

/// User-safe message for a [CategoryError].
String categoryErrorMessage(CategoryError error) {
  switch (error) {
    case CategoryError.invalidName:
      return 'El nombre no es válido. Usa entre 1 y 60 caracteres.';
    case CategoryError.duplicateName:
      return 'Ya existe una categoría con ese nombre.';
    case CategoryError.categoryInUse:
      return 'Esta categoría está siendo utilizada por uno o más gastos.';
    case CategoryError.forbidden:
      return 'No tienes permiso para realizar esta acción.';
    case CategoryError.unexpected:
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}

/// Validates a category name without transforming it.
///
/// The trimmed value must hold 1-60 characters, mirroring the database
/// check. The original [name] is returned untouched for persistence: the
/// database remains the final authority and the app never silently
/// rewrites what the user typed.
void validateCategoryName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.length > kMaxCategoryNameLength) {
    throw const CategoryException(CategoryError.invalidName);
  }
}

/// Boundary for category access.
///
/// This is the only place the application talks about categories. UI and
/// app state depend on this contract, never on Supabase types. Ownership
/// always comes from the authenticated session: no method accepts a user
/// id, and only [name] is ever sent for writes.
abstract class CategoryRepository {
  /// Visible categories: system ones plus the user's own private ones.
  ///
  /// System categories come first, then private ones, alphabetical by
  /// name within each group.
  Future<List<Category>> listCategories();

  /// Creates a private category owned by the current user.
  Future<Category> createCategory(String name);

  /// Renames a private category owned by the current user.
  Future<Category> renameCategory({required String id, required String name});

  /// Deletes a private category owned by the current user.
  Future<void> deleteCategory(String id);
}

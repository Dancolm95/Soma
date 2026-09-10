import 'package:flutter/foundation.dart' hide Category;

import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/application/categories/category_repository.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController(this._repository);

  final CategoryRepository _repository;

  List<Category> categories = const [];
  bool loading = false;
  bool busy = false;
  String? errorMessage;

  List<Category> get system => [
    for (final c in categories)
      if (c.isSystem) c,
  ];
  List<Category> get private => [
    for (final c in categories)
      if (!c.isSystem) c,
  ];

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      categories = await _repository.listCategories();
    } on CategoryException catch (e) {
      categories = const [];
      errorMessage = categoryErrorMessage(e.error);
    } catch (_) {
      categories = const [];
      errorMessage = categoryErrorMessage(CategoryError.unexpected);
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> createCategory(String name) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.createCategory(name);
      categories = await _repository.listCategories();
      return true;
    } on CategoryException catch (e) {
      errorMessage = categoryErrorMessage(e.error);
      await _refreshQuietly();
      return false;
    } catch (_) {
      errorMessage = categoryErrorMessage(CategoryError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> renameCategory({
    required String id,
    required String name,
  }) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.renameCategory(id: id, name: name);
      categories = await _repository.listCategories();
      return true;
    } on CategoryException catch (e) {
      errorMessage = categoryErrorMessage(e.error);
      await _refreshQuietly();
      return false;
    } catch (_) {
      errorMessage = categoryErrorMessage(CategoryError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteCategory(id);
      categories = await _repository.listCategories();
      return true;
    } on CategoryException catch (e) {
      errorMessage = categoryErrorMessage(e.error);
      await _refreshQuietly();
      return false;
    } catch (_) {
      errorMessage = categoryErrorMessage(CategoryError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      categories = await _repository.listCategories();
    } catch (_) {
      // Keep the last error message; the list stays as-is.
    }
  }
}

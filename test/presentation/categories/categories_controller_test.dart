import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  test('load splits system and private', () async {
    final repo = FakeCategoryRepository()..categories = testCategories();
    final controller = CategoriesController(repo);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.system, hasLength(2));
    expect(controller.private, hasLength(1));
  });

  test('delete categoryInUse exposes domain message', () async {
    final repo = FakeCategoryRepository()
      ..categories = testCategories()
      ..deleteError = const CategoryException(CategoryError.categoryInUse);
    final controller = CategoriesController(repo);
    addTearDown(controller.dispose);
    await controller.load();

    final ok = await controller.deleteCategory('cat-own');

    expect(ok, isFalse);
    expect(
      controller.errorMessage,
      'Esta categoría está siendo utilizada por uno o más gastos.',
    );
  });

  test('forbidden mutation shows safe message and refreshes', () async {
    final repo = FakeCategoryRepository()
      ..categories = testCategories()
      ..renameError = const CategoryException(CategoryError.forbidden);
    final controller = CategoriesController(repo);
    addTearDown(controller.dispose);
    await controller.load();

    final ok = await controller.renameCategory(id: 'missing', name: 'X');

    expect(ok, isFalse);
    expect(controller.errorMessage, isNotNull);
    expect(controller.categories, isNotEmpty);
  });

  test('busy prevents duplicate submit', () async {
    final repo = FakeCategoryRepository();
    final controller = CategoriesController(repo);
    addTearDown(controller.dispose);
    controller.busy = true;

    expect(await controller.createCategory('Nueva'), isFalse);
  });
}

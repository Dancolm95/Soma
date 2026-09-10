import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/categories/categories_page.dart';

import '../../helpers/fake_repositories.dart';

Future<void> pumpCategories(
  WidgetTester tester, {
  required FakeCategoryRepository repo,
}) async {
  final controller = CategoriesController(repo);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(home: CategoriesPage(controller: controller)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('system visible read-only, private editable', (tester) async {
    await pumpCategories(
      tester,
      repo: FakeCategoryRepository()..categories = testCategories(),
    );

    expect(find.text('Del sistema'), findsOneWidget);
    expect(find.text('Otros'), findsOneWidget);
    expect(find.text('Solo lectura'), findsWidgets);
    expect(find.text('Mis categorías'), findsOneWidget);
    expect(find.text('Mía'), findsOneWidget);
    expect(find.byTooltip('Renombrar'), findsOneWidget);
    expect(find.byTooltip('Eliminar categoría'), findsOneWidget);
  });

  testWidgets('create category', (tester) async {
    final repo = FakeCategoryRepository()..categories = testCategories();
    await pumpCategories(tester, repo: repo);

    await tester.tap(find.text('Agregar categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Farmacia',
    );
    await tester.tap(find.text('Agregar').last);
    await tester.pumpAndSettle();

    expect(find.text('Farmacia'), findsWidgets);
    expect(find.text('Categoría creada.'), findsOneWidget);
  });

  testWidgets('rename private category', (tester) async {
    final repo = FakeCategoryRepository()..categories = testCategories();
    await pumpCategories(tester, repo: repo);

    await tester.tap(find.byTooltip('Renombrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Renombrada',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Renombrada'), findsOneWidget);
  });

  testWidgets('delete asks confirmation and removes', (tester) async {
    final repo = FakeCategoryRepository()..categories = testCategories();
    await pumpCategories(tester, repo: repo);

    await tester.tap(find.byTooltip('Eliminar categoría'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar esta categoría?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Mía'), findsNothing);
    expect(find.text('Categoría eliminada.'), findsOneWidget);
  });

  testWidgets('categoryInUse shows domain message', (tester) async {
    final repo = FakeCategoryRepository()
      ..categories = testCategories()
      ..deleteError = const CategoryException(CategoryError.categoryInUse);
    await pumpCategories(tester, repo: repo);

    await tester.tap(find.byTooltip('Eliminar categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Esta categoría está siendo utilizada por uno o más gastos.'),
      findsOneWidget,
    );
    expect(find.text('Mía'), findsOneWidget);
  });

  testWidgets('errors never leak internals', (tester) async {
    final repo = FakeCategoryRepository()
      ..listError = const CategoryException(CategoryError.unexpected);
    await pumpCategories(tester, repo: repo);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('23503'), findsNothing);
    expect(find.textContaining('SQL'), findsNothing);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/infrastructure/categories/supabase_category_repository.dart';

import '../../helpers/fake_category_store.dart';

Future<CategoryException> capture<T>(Future<T> Function() action) async {
  try {
    await action();
  } on CategoryException catch (error) {
    return error;
  }
  fail('expected a CategoryException');
}

const userA = 'user-a';
const userB = 'user-b';

void main() {
  FakeCategoryStore storeWith() {
    final store = FakeCategoryStore(visibleUserId: userA);
    store.rows.addAll([
      {'id': 'sys-transporte', 'name': 'Transporte', 'user_id': null},
      {'id': 'sys-otros', 'name': 'Otros', 'user_id': null},
      {'id': 'priv-a', 'name': 'Mascotas', 'user_id': userA},
      {'id': 'priv-b', 'name': 'Privada B', 'user_id': userB},
    ]);
    return store;
  }

  group('listCategories', () {
    test('returns system plus own, ordered system-first then name', () async {
      final repository = SupabaseCategoryRepository(storeWith());

      final categories = await repository.listCategories();

      expect(categories.map((item) => item.name), [
        'Otros',
        'Transporte',
        'Mascotas',
      ]);
      expect(categories.where((item) => item.isSystem).length, 2);
    });

    test('never returns another user private categories', () async {
      final repository = SupabaseCategoryRepository(storeWith());

      final categories = await repository.listCategories();

      expect(categories.where((item) => item.name == 'Privada B'), isEmpty);
    });

    test('maps provider failures to a safe unexpected error', () async {
      final store = _ThrowingStore();
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(repository.listCategories);

      expect(error.error, CategoryError.unexpected);
    });
  });

  group('createCategory', () {
    test('sends only the name and returns the created row', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      final created = await repository.createCategory('Viajes');

      expect(store.lastInsertPayload, {'name': 'Viajes'});
      expect(store.lastInsertPayload!.containsKey('user_id'), isFalse);
      expect(created.name, 'Viajes');
      expect(created.isSystem, isFalse);
    });

    test('sends the name untouched without silent trimming', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      await repository.createCategory(' Salidas ');

      expect(store.lastInsertPayload, {'name': ' Salidas '});
    });

    test('maps duplicate names', () async {
      final repository = SupabaseCategoryRepository(storeWith());

      final error = await capture(() => repository.createCategory('mascotas'));

      expect(error.error, CategoryError.duplicateName);
    });

    test('rejects invalid names before touching the store', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(() => repository.createCategory('  '));

      expect(error.error, CategoryError.invalidName);
      expect(store.lastInsertPayload, isNull);
    });
  });

  group('renameCategory', () {
    test('sends only the new name', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      final renamed = await repository.renameCategory(
        id: 'priv-a',
        name: 'Perros',
      );

      expect(store.lastUpdate, (id: 'priv-a', name: 'Perros'));
      expect(renamed.name, 'Perros');
    });

    test('refuses system categories', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(
        () => repository.renameCategory(id: 'sys-otros', name: 'Cambio'),
      );

      expect(error.error, CategoryError.forbidden);
      expect(store.lastUpdate, isNull);
    });

    test(
      'refuses foreign or missing categories without leaking which',
      () async {
        final store = storeWith();
        final repository = SupabaseCategoryRepository(store);

        final foreign = await capture(
          () => repository.renameCategory(id: 'priv-b', name: 'Cambio'),
        );
        final missing = await capture(
          () => repository.renameCategory(id: 'no-such-id', name: 'Cambio'),
        );

        expect(foreign.error, CategoryError.forbidden);
        expect(missing.error, CategoryError.forbidden);
      },
    );

    test('maps duplicate names', () async {
      final store = storeWith();
      store.rows.add({'id': 'priv-a2', 'name': 'Viajes', 'user_id': userA});
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(
        () => repository.renameCategory(id: 'priv-a', name: 'viajes'),
      );

      expect(error.error, CategoryError.duplicateName);
    });
  });

  group('deleteCategory', () {
    test('deletes an own private category', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      await repository.deleteCategory('priv-a');

      expect(store.lastDeleteId, 'priv-a');
      expect(
        (await repository.listCategories()).where(
          (item) => item.id == 'priv-a',
        ),
        isEmpty,
      );
    });

    test('refuses system categories', () async {
      final store = storeWith();
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(() => repository.deleteCategory('sys-otros'));

      expect(error.error, CategoryError.forbidden);
      expect(store.lastDeleteId, isNull);
    });

    test('maps categories in use', () async {
      final store = storeWith();
      store.usedIds.add('priv-a');
      final repository = SupabaseCategoryRepository(store);

      final error = await capture(() => repository.deleteCategory('priv-a'));

      expect(error.error, CategoryError.categoryInUse);
    });

    test('maps unexpected provider errors safely', () async {
      final repository = SupabaseCategoryRepository(_ThrowingStore());

      final error = await capture(() => repository.deleteCategory('priv-a'));

      expect(error.error, CategoryError.unexpected);
      expect(categoryErrorMessage(error.error), isNot(contains('explode')));
    });
  });

  group('public API surface', () {
    test('repository exposes no user id parameter', () async {
      final repository = SupabaseCategoryRepository(storeWith());

      expect(repository.createCategory, isA<Function>());
      expect(() => repository.createCategory('Viajes'), returnsNormally);
    });
  });
}

/// Store double that fails every operation with an unexpected provider error.
class _ThrowingStore extends FakeCategoryStore {
  _ThrowingStore() : super(visibleUserId: userA);

  PostgrestException get _failure =>
      const PostgrestException(message: 'explode', code: 'XX000');

  @override
  Future<List<Map<String, dynamic>>> fetchAll() => throw _failure;

  @override
  Future<Map<String, dynamic>?> fetchOwner(String id) => throw _failure;

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload) =>
      throw _failure;

  @override
  Future<void> delete(String id) => throw _failure;
}

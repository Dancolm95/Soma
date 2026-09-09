import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/application/categories/category_repository.dart';

void main() {
  group('Category', () {
    test('maps a system row with null user_id', () {
      final category = Category.fromJson({
        'id': 'id-system',
        'name': 'Otros',
        'user_id': null,
      });

      expect(category.id, 'id-system');
      expect(category.name, 'Otros');
      expect(category.userId, isNull);
      expect(category.isSystem, isTrue);
    });

    test('maps a private row with its owner', () {
      final category = Category.fromJson({
        'id': 'id-private',
        'name': 'Mascotas',
        'user_id': 'user-a',
      });

      expect(category.userId, 'user-a');
      expect(category.isSystem, isFalse);
    });
  });

  group('validateCategoryName', () {
    test('accepts a regular name untouched', () {
      expect(() => validateCategoryName('Viajes'), returnsNormally);
    });

    test('rejects empty and blank-only names', () {
      expect(
        () => validateCategoryName(''),
        throwsA(
          isA<CategoryException>().having(
            (error) => error.error,
            'error',
            CategoryError.invalidName,
          ),
        ),
      );
      expect(
        () => validateCategoryName('   '),
        throwsA(
          isA<CategoryException>().having(
            (error) => error.error,
            'error',
            CategoryError.invalidName,
          ),
        ),
      );
    });

    test('rejects names longer than 60 characters', () {
      final long = List.filled(61, 'x').join();

      expect(
        () => validateCategoryName(long),
        throwsA(
          isA<CategoryException>().having(
            (error) => error.error,
            'error',
            CategoryError.invalidName,
          ),
        ),
      );
    });
  });

  group('categoryErrorMessage', () {
    test('never leaks technical details', () {
      for (final error in CategoryError.values) {
        final message = categoryErrorMessage(error);

        expect(message, isNotEmpty);
        expect(message, isNot(contains('23505')));
        expect(message, isNot(contains('23503')));
        expect(message, isNot(contains('23514')));
        expect(message, isNot(contains('SELECT')));
        expect(message, isNot(contains('Postgrest')));
      }
    });

    test('maps the in-use case to the approved wording', () {
      expect(
        categoryErrorMessage(CategoryError.categoryInUse),
        contains('utilizada'),
      );
    });
  });
}

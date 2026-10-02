import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/presentation/theme/category_colors.dart';

void main() {
  test('indexFor is deterministic per id', () {
    expect(
      SomaCategoryColors.indexFor('cat-food'),
      SomaCategoryColors.indexFor('cat-food'),
    );
  });

  test('indexFor stays within the palette', () {
    for (final id in ['a', 'cat-1', 'cat-food', 'uuid-1234', 'Otros', '']) {
      final index = SomaCategoryColors.indexFor(id);
      expect(index, greaterThanOrEqualTo(0));
      expect(index, lessThan(SomaCategoryColors.palette.length));
    }
  });

  test('palette has eight entries', () {
    expect(SomaCategoryColors.palette.length, 8);
  });
}

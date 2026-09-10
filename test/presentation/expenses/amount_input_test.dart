import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';

void main() {
  group('tryParseAmountMinor', () {
    test('parses dot and comma decimals without double', () {
      expect(tryParseAmountMinor('19.90'), 1990);
      expect(tryParseAmountMinor('19,90'), 1990);
      expect(tryParseAmountMinor('19.9'), 1990);
      expect(tryParseAmountMinor('19'), 1900);
    });

    test('rejects invalid formats', () {
      expect(tryParseAmountMinor(''), isNull);
      expect(tryParseAmountMinor('abc'), isNull);
      expect(tryParseAmountMinor('19.999'), isNull);
      expect(tryParseAmountMinor('1.2.3'), isNull);
      expect(tryParseAmountMinor('-5'), isNull);
      expect(tryParseAmountMinor('S/ 10'), isNull);
    });
  });

  group('formatPen', () {
    test('formats PEN without double', () {
      expect(formatPen(1990), 'S/ 19.90');
      expect(formatPen(1), 'S/ 0.01');
      expect(formatPen(999999999999), 'S/ 9999999999.99');
    });

    test('source contains no double usage', () {
      expect(formatPen(100), isNot(contains('e')));
    });
  });
}

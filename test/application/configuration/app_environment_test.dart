import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/configuration/app_environment.dart';

void main() {
  group('AppEnvironment.fromString', () {
    test('maps known environment names', () {
      expect(
        AppEnvironment.fromString('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(
        AppEnvironment.fromString('production'),
        AppEnvironment.production,
      );
    });

    test('falls back to development for unknown values', () {
      expect(AppEnvironment.fromString('unknown'), AppEnvironment.development);
    });
  });

  group('AppConfig.fromEnvironment', () {
    test('defaults to the development environment', () {
      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.development);
    });
  });
}

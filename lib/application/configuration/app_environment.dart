/// Named execution environments.
///
/// The active environment is selected at build time via the `APP_ENV`
/// `--dart-define` flag (see README). No sensitive values belong here.
enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.name);

  final String name;

  static AppEnvironment fromString(String value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == value,
      orElse: () => AppEnvironment.development,
    );
  }
}

/// Build-time, environment-independent application configuration.
///
/// Populated exclusively from compile-time constants so that no runtime
/// sensitive-value loading is required at this stage.
class AppConfig {
  const AppConfig({required this.environment});

  factory AppConfig.fromEnvironment() {
    const raw = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    return AppConfig(environment: AppEnvironment.fromString(raw));
  }

  final AppEnvironment environment;
}

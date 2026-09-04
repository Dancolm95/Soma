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

/// Build-time application configuration populated from compile-time constants.
///
/// All values are provided via `--dart-define` at build/run time.
/// No sensitive values are hardcoded here or stored in version control.
///
/// Flutter only receives the publishable (anon) key for Supabase.
/// service_role, JWT signing secrets, and database passwords must
/// never appear in this class.
class AppConfig {
  const AppConfig({
    required this.environment,
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
  });

  factory AppConfig.fromEnvironment() {
    const raw = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    return AppConfig(
      environment: AppEnvironment.fromString(raw),
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );
  }

  final AppEnvironment environment;

  /// Supabase project URL (e.g. `https://<ref>.supabase.co`).
  /// Provided via `--dart-define=SUPABASE_URL=...`
  final String supabaseUrl;

  /// Supabase publishable (anon) key.
  /// Provided via --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  final String supabasePublishableKey;
}

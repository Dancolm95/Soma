import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/configuration/app_environment.dart';

/// Bootstraps the Supabase client from build-time [AppConfig].
///
/// Must be called once before [runApp] from the application entry point.
/// Fails fast with a [StateError] if required configuration is missing,
/// without logging the credential values themselves.
///
/// Security constraints:
///   - Flutter only receives the publishable (anon) key.
///   - service_role, JWT signing secrets, and database passwords must
///     never be passed to this initializer or stored in [AppConfig].
class SupabaseInitializer {
  SupabaseInitializer._();

  static Future<void> initialize(AppConfig config) async {
    if (config.supabaseUrl.isEmpty || config.supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required. '
        'Provide them via --dart-define when running or building. '
        'See docs/operations.md for setup instructions.',
      );
    }

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
  }
}

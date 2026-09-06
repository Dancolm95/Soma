import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/configuration/app_environment.dart';
import 'package:soma_app/infrastructure/auth/supabase_auth_service.dart';
import 'package:soma_app/infrastructure/supabase/supabase_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await SupabaseInitializer.initialize(config);

  final authController = AuthController(
    SupabaseAuthService(
      Supabase.instance.client,
      webRedirectUrl: config.supabaseRedirectUrl.isEmpty
          ? null
          : config.supabaseRedirectUrl,
    ),
  );

  runApp(SomaApp(authController: authController));
}

import 'package:flutter/widgets.dart';

import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/configuration/app_environment.dart';
import 'package:soma_app/infrastructure/supabase/supabase_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await SupabaseInitializer.initialize(config);

  runApp(SomaApp(config: config));
}

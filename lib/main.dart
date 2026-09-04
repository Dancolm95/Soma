import 'package:flutter/widgets.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/configuration/app_environment.dart';

void main() {
  runApp(SomaApp(config: AppConfig.fromEnvironment()));
}

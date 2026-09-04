import 'package:flutter/material.dart';
import 'package:soma_app/application/configuration/app_environment.dart';
import 'package:soma_app/features/launch/launch_screen.dart';

/// Root widget of the Soma application.
///
/// Owns application-wide configuration (theme, title) and delegates the
/// visible content to feature-level screens.
class SomaApp extends StatelessWidget {
  const SomaApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma',
      theme: ThemeData(useMaterial3: true),
      home: LaunchScreen(environmentName: config.environment.name),
    );
  }
}

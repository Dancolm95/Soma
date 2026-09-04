import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/features/auth/auth_gate.dart';

/// Root widget of the Soma application.
///
/// Owns application-wide configuration (theme, title) and delegates the
/// visible content to the authentication flow.
class SomaApp extends StatelessWidget {
  const SomaApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma',
      theme: ThemeData(useMaterial3: true),
      home: AuthGate(authController: authController),
    );
  }
}

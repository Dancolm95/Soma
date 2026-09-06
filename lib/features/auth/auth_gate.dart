import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/features/auth/auth_screen.dart';
import 'package:soma_app/features/auth/reset_password_screen.dart';
import 'package:soma_app/features/auth/signed_in_screen.dart';

/// Selects the visible screen based on the authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        return switch (authController.status) {
          AuthStatus.initializing => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          AuthStatus.unauthenticated => AuthScreen(
            authController: authController,
          ),
          AuthStatus.passwordRecovery => ResetPasswordScreen(
            authController: authController,
          ),
          AuthStatus.authenticated => SignedInScreen(
            authController: authController,
          ),
        };
      },
    );
  }
}

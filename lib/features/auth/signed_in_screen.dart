import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';

/// Placeholder screen shown while a session is active.
///
/// Demonstrates that a session exists and exposes the minimal identity plus a
/// sign-out action. It is not the real dashboard.
class SignedInScreen extends StatelessWidget {
  const SignedInScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soma')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sesión iniciada'),
            const SizedBox(height: 8),
            Text(authController.user?.email ?? ''),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                authController.signOut();
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

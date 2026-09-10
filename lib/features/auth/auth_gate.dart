import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/features/auth/auth_screen.dart';
import 'package:soma_app/features/auth/reset_password_screen.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authController,
    required this.expensesController,
    required this.categoriesController,
  });

  final AuthController authController;
  final ExpensesController expensesController;
  final CategoriesController categoriesController;

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
          AuthStatus.authenticated => ExpensesPage(
            expensesController: expensesController,
            categoriesController: categoriesController,
            authController: authController,
          ),
        };
      },
    );
  }
}

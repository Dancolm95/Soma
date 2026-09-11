import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/features/auth/auth_screen.dart';
import 'package:soma_app/features/auth/reset_password_screen.dart';
import 'package:soma_app/features/auth/session_scope.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authController,
    required this.expenseRepository,
    required this.categoryRepository,
  });

  final AuthController authController;
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;

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
          AuthStatus.authenticated => SessionScope(
            key: ValueKey(authController.user?.id ?? 'anonymous'),
            authController: authController,
            expenseRepository: expenseRepository,
            categoryRepository: categoryRepository,
          ),
        };
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/features/auth/auth_gate.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

class SomaApp extends StatelessWidget {
  const SomaApp({
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
    return MaterialApp(
      title: 'Soma',
      theme: ThemeData(useMaterial3: true),
      home: AuthGate(
        authController: authController,
        expensesController: expensesController,
        categoriesController: categoriesController,
      ),
    );
  }
}

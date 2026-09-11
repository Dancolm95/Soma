import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/features/auth/auth_gate.dart';

class SomaApp extends StatelessWidget {
  const SomaApp({
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
    return MaterialApp(
      title: 'Soma',
      theme: ThemeData(useMaterial3: true),
      home: AuthGate(
        authController: authController,
        expenseRepository: expenseRepository,
        categoryRepository: categoryRepository,
      ),
    );
  }
}

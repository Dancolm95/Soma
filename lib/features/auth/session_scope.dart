import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_page.dart';

/// Session-scoped composition root for the authenticated area.
///
/// A new [SessionScope] state (and therefore brand-new financial
/// controllers starting empty) is created every time the surrounding
/// [Key] changes. [AuthGate] keys this subtree by the authenticated
/// user's email, so controllers never survive an identity change:
/// the previous session's expenses, private categories, errors and
/// submission states are disposed with the old state before the new
/// session renders anything.
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    required this.authController,
    required this.expenseRepository,
    required this.categoryRepository,
  });

  final AuthController authController;
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final ExpensesController _expensesController;
  late final CategoriesController _categoriesController;

  @override
  void initState() {
    super.initState();
    _expensesController = ExpensesController(widget.expenseRepository);
    _categoriesController = CategoriesController(widget.categoryRepository);
  }

  @override
  void dispose() {
    _expensesController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpensesPage(
      expensesController: _expensesController,
      categoriesController: _categoriesController,
      authController: widget.authController,
    );
  }
}

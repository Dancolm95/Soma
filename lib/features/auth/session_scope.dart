import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/home/home_shell.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';

/// Session-scoped composition root for the authenticated area.
///
/// A new [SessionScope] state (and therefore brand-new financial
/// controllers starting empty) is created every time the surrounding
/// [Key] changes. [AuthGate] keys this subtree by the authenticated
/// user's id, so controllers never survive an identity change:
/// the previous session's expenses, private categories, metrics, errors and
/// submission states are disposed with the old state before the new
/// session renders anything.
///
/// Authenticated navigation lives in a nested [Navigator] owned by this
/// scope, so pushed routes (categories, metrics) are destroyed together
/// with the session: after logout or an identity change no previously
/// pushed financial screen can remain renderable.
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    required this.authController,
    required this.expenseRepository,
    required this.categoryRepository,
    required this.metricsRepository,
  });

  final AuthController authController;
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;
  final MetricsRepository metricsRepository;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final ExpensesController _expensesController;
  late final CategoriesController _categoriesController;
  late final MetricsController _metricsController;

  @override
  void initState() {
    super.initState();
    _expensesController = ExpensesController(widget.expenseRepository);
    _categoriesController = CategoriesController(widget.categoryRepository);
    _metricsController = MetricsController(widget.metricsRepository);
  }

  @override
  void dispose() {
    _expensesController.dispose();
    _categoriesController.dispose();
    _metricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => HomeShell(
          expensesController: _expensesController,
          categoriesController: _categoriesController,
          metricsController: _metricsController,
          authController: widget.authController,
        ),
      ),
    );
  }
}

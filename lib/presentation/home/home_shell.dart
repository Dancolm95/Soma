import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/presentation/capture/quick_capture_sheet.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_page.dart';
import 'package:soma_app/presentation/home/home_page.dart';
import 'package:soma_app/presentation/home/more_page.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';
import 'package:soma_app/presentation/metrics/metrics_page.dart';

/// Authenticated shell: Decidida home with bottom navigation.
///
/// The center action opens quick capture; Resumen and Más push onto the
/// session [Navigator] like before, so existing routes are untouched.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.expensesController,
    required this.categoriesController,
    required this.metricsController,
    required this.authController,
  });

  final ExpensesController expensesController;
  final CategoriesController categoriesController;
  final MetricsController metricsController;
  final AuthController authController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Future<void> _openCapture(String? categoryId) async {
    final saved = await showQuickCapture(
      context,
      expensesController: widget.expensesController,
      categoriesController: widget.categoriesController,
      initialCategoryId: categoryId,
    );
    if (saved != true || !mounted) return;
    await widget.expensesController.load();
    await widget.metricsController.load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gasto guardado.')));
  }

  Future<void> _push(Widget page) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        _openCapture(null);
      case 2:
        _push(MetricsPage(controller: widget.metricsController));
      case 3:
        _push(
          MorePage(
            authController: widget.authController,
            categoriesController: widget.categoriesController,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: HomePage(
              expensesController: widget.expensesController,
              categoriesController: widget.categoriesController,
              metricsController: widget.metricsController,
              onCapture: _openCapture,
              onSeeAll: () => _push(
                ExpensesPage(
                  expensesController: widget.expensesController,
                  categoriesController: widget.categoriesController,
                  metricsController: widget.metricsController,
                  authController: widget.authController,
                ),
              ),
              onOpenMetrics: () =>
                  _push(MetricsPage(controller: widget.metricsController)),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Agregar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Resumen',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
        ],
      ),
    );
  }
}

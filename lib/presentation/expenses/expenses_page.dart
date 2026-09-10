import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/categories/categories_page.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';
import 'package:soma_app/presentation/expenses/expense_form_page.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({
    super.key,
    required this.expensesController,
    required this.categoriesController,
    required this.authController,
  });

  final ExpensesController expensesController;
  final CategoriesController categoriesController;
  final AuthController authController;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.expensesController.load();
      widget.categoriesController.load();
    });
  }

  Map<String, String> _categoryNames() {
    return {
      for (final c in widget.categoriesController.categories) c.id: c.name,
    };
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormPage(
          expensesController: widget.expensesController,
          categoriesController: widget.categoriesController,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gasto guardado.')));
    }
  }

  Future<void> _openEdit(String expenseId) async {
    final expense = widget.expensesController.expenses
        .where((e) => e.id == expenseId)
        .firstOrNull;
    if (expense == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormPage(
          expensesController: widget.expensesController,
          categoriesController: widget.categoriesController,
          expense: expense,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gasto actualizado.')));
    }
  }

  Future<void> _confirmDelete(String expenseId, String merchant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este gasto?'),
        content: Text(
          'Se eliminará el registro de "$merchant". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await widget.expensesController.deleteExpense(expenseId);
    if (!mounted) return;
    final message = ok
        ? 'Gasto eliminado.'
        : (widget.expensesController.errorMessage ??
              'No se pudo completar la operación. Inténtalo nuevamente.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesPage(controller: widget.categoriesController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.category_outlined),
            onPressed: _openCategories,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => widget.authController.signOut(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              widget.expensesController,
              widget.categoriesController,
            ]),
            builder: (context, _) {
              final controller = widget.expensesController;
              if (controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage != null &&
                  controller.expenses.isEmpty) {
                return _ErrorView(
                  message: controller.errorMessage!,
                  onRetry: controller.load,
                );
              }
              if (controller.expenses.isEmpty) {
                return _EmptyView(onAdd: _openCreate);
              }
              final names = _categoryNames();
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = controller.expenses[index];
                    final categoryName =
                        names[expense.categoryId] ?? 'Sin categoría';
                    return Card(
                      child: ListTile(
                        title: Text(expense.merchant),
                        subtitle: Text(
                          '${formatDateLabel(expense.expenseDate)} • $categoryName',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatPen(expense.amountMinor),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              tooltip: 'Editar gasto',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEdit(expense.id),
                            ),
                            IconButton(
                              tooltip: 'Eliminar gasto',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _confirmDelete(expense.id, expense.merchant),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Agregar gasto'),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No tienes gastos registrados todavía.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAdd, child: const Text('Agregar gasto')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

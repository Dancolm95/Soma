import 'package:flutter/material.dart';

import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/theme/category_colors.dart';

/// Two-tap quick capture: numpad amount, category chip, merchant, save.
///
/// Reuses the domain validators and [ExpensesController.createExpense].
/// The AI (photo/text) entry stays out of v1 until the extractor exists.
Future<bool?> showQuickCapture(
  BuildContext context, {
  required ExpensesController expensesController,
  required CategoriesController categoriesController,
  String? initialCategoryId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _QuickCaptureSheet(
      expensesController: expensesController,
      categoriesController: categoriesController,
      initialCategoryId: initialCategoryId,
    ),
  );
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet({
    required this.expensesController,
    required this.categoriesController,
    this.initialCategoryId,
  });

  final ExpensesController expensesController;
  final CategoriesController categoriesController;
  final String? initialCategoryId;

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  int _cents = 0;
  String? _categoryId;
  String? _error;
  bool _submitting = false;
  late final TextEditingController _merchantController;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    final categories = widget.categoriesController.categories;
    if (widget.initialCategoryId != null &&
        categories.any((c) => c.id == widget.initialCategoryId)) {
      _categoryId = widget.initialCategoryId;
    } else if (categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  void _press(String key) {
    setState(() {
      if (key == 'back') {
        _cents ~/= 10;
      } else if (_cents < 1000000000000) {
        _cents = _cents * 10 + int.parse(key);
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_submitting) return;
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _error = 'Elige una categoría.');
      return;
    }
    try {
      validateExpenseAmount(_cents);
      validateExpenseMerchant(_merchantController.text);
      validateExpenseCategoryId(categoryId);
    } on ExpenseException catch (e) {
      setState(() => _error = expenseErrorMessage(e.error));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final ok = await widget.expensesController.createExpense(
        amountMinor: _cents,
        expenseDate: DateTime(now.year, now.month, now.day),
        merchant: _merchantController.text,
        categoryId: categoryId,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error =
              widget.expensesController.errorMessage ??
              'No se pudo completar la operación. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = widget.categoriesController.categories;
    final canSave = _cents > 0 && _categoryId != null && categories.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Grab(),
            Text('Nuevo gasto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              formatPen(_cents),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              const Text('Primero crea una categoría desde la pestaña Más.'),
            if (categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = _categoryId == category.id;
                    final colors = SomaCategoryColors.of(context, category.id);
                    return ChoiceChip(
                      label: Text(category.name),
                      selected: selected,
                      showCheckmark: false,
                      side: BorderSide.none,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      selectedShadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: scheme.surfaceContainerLow,
                      selectedColor: colors.background,
                      labelStyle: TextStyle(
                        color: selected
                            ? colors.foreground
                            : scheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          setState(() => _categoryId = category.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Comercio o concepto',
                hintText: 'Bodega Central',
              ),
              maxLength: 120,
            ),
            const SizedBox(height: 4),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.2,
              children: [
                for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                  _Key(label: key, onTap: () => _press(key)),
                const SizedBox.shrink(),
                _Key(label: '0', onTap: () => _press('0')),
                _KeyIcon(
                  icon: Icons.backspace_outlined,
                  label: 'Borrar',
                  color: scheme.primary,
                  onTap: () => _press('back'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.error),
                ),
              ),
            FilledButton(
              onPressed: canSave && !_submitting ? _save : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
  }
}

class _KeyIcon extends StatelessWidget {
  const _KeyIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Icon(icon, semanticLabel: label, color: color),
        ),
      ),
    );
  }
}

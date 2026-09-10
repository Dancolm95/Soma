import 'package:flutter/material.dart';

import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({
    super.key,
    required this.expensesController,
    required this.categoriesController,
    this.expense,
  });

  final ExpensesController expensesController;
  final CategoriesController categoriesController;
  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late DateTime _date;
  String? _categoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : expenseAmountToDb(expense.amountMinor),
    );
    _merchantController = TextEditingController(text: expense?.merchant ?? '');
    final now = DateTime.now();
    _date = expense == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(
            expense.expenseDate.year,
            expense.expenseDate.month,
            expense.expenseDate.day,
          );
    _categoryId = expense?.categoryId;
    final categories = widget.categoriesController.categories;
    final selected = _categoryId;
    if (selected != null &&
        categories.isNotEmpty &&
        categories.every((c) => c.id != selected)) {
      _categoryId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final minor = tryParseAmountMinor(value ?? '');
    if (minor == null) return 'Ingresa un importe válido.';
    try {
      validateExpenseAmount(minor);
    } on ExpenseException catch (e) {
      return expenseErrorMessage(e.error);
    }
    return null;
  }

  String? _validateMerchant(String? value) {
    try {
      validateExpenseMerchant(value ?? '');
    } on ExpenseException catch (e) {
      return expenseErrorMessage(e.error);
    }
    return null;
  }

  String? _validateCategory(String? value) {
    try {
      validateExpenseCategoryId(value ?? '');
    } on ExpenseException catch (e) {
      return expenseErrorMessage(e.error);
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final minor = tryParseAmountMinor(_amountController.text);
      if (minor == null) return;
      final merchant = _merchantController.text;
      final categoryId = _categoryId ?? '';
      final ok = widget.isEditing
          ? await widget.expensesController.updateExpense(
              id: widget.expense!.id,
              amountMinor: minor,
              expenseDate: _date,
              merchant: merchant,
              categoryId: categoryId,
            )
          : await widget.expensesController.createExpense(
              amountMinor: minor,
              expenseDate: _date,
              merchant: merchant,
              categoryId: categoryId,
            );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expensesController.errorMessage ??
                  'No se pudo completar la operación. Inténtalo nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoriesController.categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar gasto' : 'Agregar gasto'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Importe',
                    prefixText: 'S/ ',
                    hintText: '19.90',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Comercio o concepto',
                  ),
                  maxLength: 120,
                  validator: _validateMerchant,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Fecha: ${formatDateLabel(_date)}')),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Seleccionar fecha'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: _validateCategory,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Guardar' : 'Agregar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

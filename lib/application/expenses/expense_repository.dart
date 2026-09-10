import 'package:soma_app/application/expenses/expense.dart';

const kMaxMerchantLength = 120;

enum ExpenseError {
  invalidAmount,
  invalidMerchant,
  invalidDate,
  invalidCategory,
  forbidden,
  notFound,
  unexpected,
}

class ExpenseException implements Exception {
  const ExpenseException(this.error);

  final ExpenseError error;
}

String expenseErrorMessage(ExpenseError error) {
  switch (error) {
    case ExpenseError.invalidAmount:
      return 'El importe no es válido. Usa un valor mayor a S/ 0.00.';
    case ExpenseError.invalidMerchant:
      return 'El comercio no es válido. Usa entre 1 y 120 caracteres.';
    case ExpenseError.invalidDate:
      return 'La fecha no es válida.';
    case ExpenseError.invalidCategory:
      return 'La categoría no es válida.';
    case ExpenseError.forbidden:
      return 'No tienes permiso para realizar esta acción.';
    case ExpenseError.notFound:
      return 'El gasto no existe o no tienes acceso a él.';
    case ExpenseError.unexpected:
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}

void validateExpenseAmount(int amountMinor) {
  if (amountMinor < kMinExpenseAmountMinor ||
      amountMinor > kMaxExpenseAmountMinor) {
    throw const ExpenseException(ExpenseError.invalidAmount);
  }
}

void validateExpenseMerchant(String merchant) {
  final trimmed = merchant.trim();
  if (trimmed.isEmpty || trimmed.length > kMaxMerchantLength) {
    throw const ExpenseException(ExpenseError.invalidMerchant);
  }
}

void validateExpenseCategoryId(String categoryId) {
  if (categoryId.trim().isEmpty) {
    throw const ExpenseException(ExpenseError.invalidCategory);
  }
}

abstract class ExpenseRepository {
  Future<List<Expense>> listExpenses();

  Future<Expense> createExpense({
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  });

  Future<Expense> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  });

  Future<void> deleteExpense(String id);
}

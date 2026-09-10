import 'package:flutter/foundation.dart';

import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';

class ExpensesController extends ChangeNotifier {
  ExpensesController(this._repository);

  final ExpenseRepository _repository;

  List<Expense> expenses = const [];
  bool loading = false;
  bool busy = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      expenses = await _repository.listExpenses();
    } on ExpenseException catch (e) {
      expenses = const [];
      errorMessage = expenseErrorMessage(e.error);
    } catch (_) {
      expenses = const [];
      errorMessage = expenseErrorMessage(ExpenseError.unexpected);
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> createExpense({
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.createExpense(
        amountMinor: amountMinor,
        expenseDate: expenseDate,
        merchant: merchant,
        categoryId: categoryId,
      );
      expenses = await _repository.listExpenses();
      return true;
    } on ExpenseException catch (e) {
      errorMessage = expenseErrorMessage(e.error);
      return false;
    } catch (_) {
      errorMessage = expenseErrorMessage(ExpenseError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateExpense(
        id: id,
        amountMinor: amountMinor,
        expenseDate: expenseDate,
        merchant: merchant,
        categoryId: categoryId,
      );
      expenses = await _repository.listExpenses();
      return true;
    } on ExpenseException catch (e) {
      errorMessage = expenseErrorMessage(e.error);
      await _refreshQuietly();
      return false;
    } catch (_) {
      errorMessage = expenseErrorMessage(ExpenseError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense(String id) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteExpense(id);
      expenses = await _repository.listExpenses();
      return true;
    } on ExpenseException catch (e) {
      errorMessage = expenseErrorMessage(e.error);
      await _refreshQuietly();
      return false;
    } catch (_) {
      errorMessage = expenseErrorMessage(ExpenseError.unexpected);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      expenses = await _repository.listExpenses();
    } catch (_) {
      // Keep the last error message; the list stays as-is.
    }
  }
}

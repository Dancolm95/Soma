import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';
import 'package:soma_app/infrastructure/expenses/expense_store.dart';

class SupabaseExpenseRepository implements ExpenseRepository {
  SupabaseExpenseRepository(this._store);

  final ExpenseStore _store;

  @override
  Future<List<Expense>> listExpenses() async {
    try {
      final rows = await _store.fetchAll();
      return [for (final row in rows) Expense.fromJson(row)];
    } on PostgrestException catch (error) {
      throw ExpenseException(_translate(error.code, error.message));
    } catch (_) {
      throw const ExpenseException(ExpenseError.unexpected);
    }
  }

  @override
  Future<Expense> createExpense({
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    validateExpenseAmount(amountMinor);
    validateExpenseMerchant(merchant);
    validateExpenseCategoryId(categoryId);
    try {
      final row = await _store.insert(
        _payload(amountMinor, expenseDate, merchant, categoryId),
      );
      return Expense.fromJson(row);
    } on PostgrestException catch (error) {
      throw ExpenseException(_translate(error.code, error.message));
    } catch (_) {
      throw const ExpenseException(ExpenseError.unexpected);
    }
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    validateExpenseAmount(amountMinor);
    validateExpenseMerchant(merchant);
    validateExpenseCategoryId(categoryId);
    try {
      final rows = await _store.update(
        id,
        _payload(amountMinor, expenseDate, merchant, categoryId),
      );
      if (rows.isEmpty) {
        throw const ExpenseException(ExpenseError.notFound);
      }
      return Expense.fromJson(rows.first);
    } on PostgrestException catch (error) {
      throw ExpenseException(_translate(error.code, error.message));
    } on ExpenseException {
      rethrow;
    } catch (_) {
      throw const ExpenseException(ExpenseError.unexpected);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final rows = await _store.delete(id);
      if (rows.isEmpty) {
        throw const ExpenseException(ExpenseError.notFound);
      }
    } on PostgrestException catch (error) {
      throw ExpenseException(_translate(error.code, error.message));
    } on ExpenseException {
      rethrow;
    } catch (_) {
      throw const ExpenseException(ExpenseError.unexpected);
    }
  }

  static Map<String, dynamic> _payload(
    int amountMinor,
    DateTime expenseDate,
    String merchant,
    String categoryId,
  ) {
    return {
      'amount': expenseAmountToDb(amountMinor),
      'expense_date': formatExpenseDate(expenseDate),
      'merchant': merchant,
      'category_id': categoryId,
    };
  }

  static ExpenseError _translate(String? code, String message) {
    switch (code) {
      case '23503':
        return ExpenseError.invalidCategory;
      case '42501':
        return ExpenseError.forbidden;
      case '23514':
        final text = message.toLowerCase();
        if (text.contains('amount')) return ExpenseError.invalidAmount;
        if (text.contains('merchant')) return ExpenseError.invalidMerchant;
        return ExpenseError.unexpected;
      default:
        return ExpenseError.unexpected;
    }
  }
}

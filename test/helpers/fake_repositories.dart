import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  List<Expense> expenses = [];
  ExpenseException? listError;
  ExpenseException? createError;
  ExpenseException? updateError;
  ExpenseException? deleteError;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  Expense _row({
    String id = 'exp-1',
    int amountMinor = 1990,
    String merchant = 'Bodega',
    String categoryId = 'cat-1',
  }) {
    final date = DateTime(2026, 9, 10);
    return Expense(
      id: id,
      amountMinor: amountMinor,
      expenseDate: date,
      merchant: merchant,
      categoryId: categoryId,
      createdAt: date,
      updatedAt: date,
    );
  }

  @override
  Future<List<Expense>> listExpenses() async {
    if (listError != null) throw listError!;
    return List<Expense>.from(expenses);
  }

  @override
  Future<Expense> createExpense({
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    createCalls++;
    if (createError != null) throw createError!;
    final expense = _row(
      id: 'exp-${expenses.length + 1}',
      amountMinor: amountMinor,
      merchant: merchant,
      categoryId: categoryId,
    );
    expenses = [...expenses, expense];
    return expense;
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    final index = expenses.indexWhere((e) => e.id == id);
    if (index < 0) throw const ExpenseException(ExpenseError.notFound);
    final updated = Expense(
      id: id,
      amountMinor: amountMinor,
      expenseDate: expenseDate,
      merchant: merchant,
      categoryId: categoryId,
      createdAt: expenses[index].createdAt,
      updatedAt: DateTime(2026, 9, 11),
    );
    expenses = [...expenses]..[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
    final index = expenses.indexWhere((e) => e.id == id);
    if (index < 0) throw const ExpenseException(ExpenseError.notFound);
    expenses = [...expenses]..removeAt(index);
  }
}

class FakeCategoryRepository implements CategoryRepository {
  List<Category> categories = const [];
  CategoryException? listError;
  CategoryException? createError;
  CategoryException? renameError;
  CategoryException? deleteError;

  @override
  Future<List<Category>> listCategories() async {
    if (listError != null) throw listError!;
    return List<Category>.from(categories);
  }

  @override
  Future<Category> createCategory(String name) async {
    if (createError != null) throw createError!;
    final category = Category(
      id: 'cat-${categories.length + 1}',
      name: name,
      userId: 'user-1',
    );
    categories = [...categories, category];
    return category;
  }

  @override
  Future<Category> renameCategory({
    required String id,
    required String name,
  }) async {
    if (renameError != null) throw renameError!;
    final index = categories.indexWhere((c) => c.id == id);
    if (index < 0) throw const CategoryException(CategoryError.forbidden);
    final updated = Category(
      id: id,
      name: name,
      userId: categories[index].userId,
    );
    categories = [...categories]..[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (deleteError != null) throw deleteError!;
    final index = categories.indexWhere((c) => c.id == id);
    if (index < 0) throw const CategoryException(CategoryError.forbidden);
    categories = [...categories]..removeAt(index);
  }
}

List<Category> testCategories() => const [
  Category(id: 'cat-global', name: 'Otros', userId: null),
  Category(id: 'cat-food', name: 'Comida', userId: null),
  Category(id: 'cat-own', name: 'Mía', userId: 'user-1'),
];

Expense testExpense({String id = 'exp-1', String categoryId = 'cat-global'}) {
  final date = DateTime(2026, 9, 10);
  return Expense(
    id: id,
    amountMinor: 1990,
    expenseDate: date,
    merchant: 'Bodega Central',
    categoryId: categoryId,
    createdAt: date,
    updatedAt: date,
  );
}

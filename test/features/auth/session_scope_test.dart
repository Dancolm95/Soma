import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';
import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/application/categories/category_repository.dart';
import 'package:soma_app/application/expenses/expense.dart';
import 'package:soma_app/application/expenses/expense_repository.dart';

import '../../helpers/fake_auth_service.dart';

class GatedExpenseRepository implements ExpenseRepository {
  Future<List<Expense>> Function() onList = () async => const [];

  @override
  Future<List<Expense>> listExpenses() => onList();

  @override
  Future<Expense> createExpense({
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) => throw UnimplementedError();

  @override
  Future<Expense> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime expenseDate,
    required String merchant,
    required String categoryId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteExpense(String id) => throw UnimplementedError();
}

class GatedCategoryRepository implements CategoryRepository {
  Future<List<Category>> Function() onList = () async => const [];

  @override
  Future<List<Category>> listCategories() => onList();

  @override
  Future<Category> createCategory(String name) => throw UnimplementedError();

  @override
  Future<Category> renameCategory({required String id, required String name}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();
}

const _userA = '11111111-1111-1111-1111-111111111111';
const _userB = '22222222-2222-2222-2222-222222222222';

Expense _expense({required String id, required String merchant}) {
  final date = DateTime(2026, 9, 10);
  return Expense(
    id: id,
    amountMinor: 1990,
    expenseDate: date,
    merchant: merchant,
    categoryId: 'cat-global',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  testWidgets('switching identity never renders previous session data', (
    tester,
  ) async {
    final service = FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    addTearDown(service.dispose);
    final expenses = GatedExpenseRepository();
    final categories = GatedCategoryRepository();
    await tester.pumpWidget(
      SomaApp(
        authController: auth,
        expenseRepository: expenses,
        categoryRepository: categories,
      ),
    );

    // A loads.
    final gateA = Completer<List<Expense>>();
    final gateACats = Completer<List<Category>>();
    expenses.onList = () => gateA.future;
    categories.onList = () => gateACats.future;
    service.emit(const SessionUser(id: _userA, email: 'a@example.com'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Bodega A'), findsNothing);
    gateA.complete([_expense(id: 'exp-a', merchant: 'Bodega A')]);
    gateACats.complete(const [
      Category(id: 'cat-own-a', name: 'Privada A', userId: 'user-a'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Bodega A'), findsOneWidget);

    // Switch to B while B's load is still pending: A's data must be gone.
    final gateB = Completer<List<Expense>>();
    final gateBCats = Completer<List<Category>>();
    expenses.onList = () => gateB.future;
    categories.onList = () => gateBCats.future;
    service.emit(const SessionUser(id: _userB, email: 'b@example.com'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Bodega A'), findsNothing);
    expect(find.text('Privada A'), findsNothing);

    // B completes: only B's data renders.
    gateB.complete([_expense(id: 'exp-b', merchant: 'Bodega B')]);
    gateBCats.complete(const [
      Category(id: 'cat-own-b', name: 'Privada B', userId: 'user-b'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Bodega B'), findsOneWidget);
    expect(find.text('Bodega A'), findsNothing);
  });

  testWidgets('logout leaves no financial state renderable', (tester) async {
    final service = FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    addTearDown(service.dispose);
    final expenses = GatedExpenseRepository();
    final categories = GatedCategoryRepository();
    expenses.onList = () async => [_expense(id: 'exp-a', merchant: 'Bodega A')];
    await tester.pumpWidget(
      SomaApp(
        authController: auth,
        expenseRepository: expenses,
        categoryRepository: categories,
      ),
    );

    service.emit(const SessionUser(id: _userA, email: 'a@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('Bodega A'), findsOneWidget);

    service.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Bodega A'), findsNothing);
    expect(find.text('Gastos'), findsNothing);
  });

  testWidgets('same email with different id still resets the session', (
    tester,
  ) async {
    final service = FakeAuthService();
    final auth = AuthController(service);
    addTearDown(auth.dispose);
    addTearDown(service.dispose);
    final expenses = GatedExpenseRepository();
    final categories = GatedCategoryRepository();
    await tester.pumpWidget(
      SomaApp(
        authController: auth,
        expenseRepository: expenses,
        categoryRepository: categories,
      ),
    );

    final gateFirst = Completer<List<Expense>>();
    expenses.onList = () => gateFirst.future;
    service.emit(const SessionUser(id: _userA, email: 'same@example.com'));
    await tester.pump();
    await tester.pump();
    gateFirst.complete([_expense(id: 'exp-first', merchant: 'Bodega Primera')]);
    await tester.pumpAndSettle();
    expect(find.text('Bodega Primera'), findsOneWidget);

    // Same visible email, different canonical id, load still pending.
    final gateSecond = Completer<List<Expense>>();
    expenses.onList = () => gateSecond.future;
    service.emit(const SessionUser(id: _userB, email: 'same@example.com'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Bodega Primera'), findsNothing);

    gateSecond.complete([
      _expense(id: 'exp-second', merchant: 'Bodega Segunda'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Bodega Segunda'), findsOneWidget);
    expect(find.text('Bodega Primera'), findsNothing);
  });
}

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/configuration/app_environment.dart';
import 'package:soma_app/infrastructure/auth/supabase_auth_service.dart';
import 'package:soma_app/infrastructure/categories/supabase_category_repository.dart';
import 'package:soma_app/infrastructure/categories/supabase_category_store.dart';
import 'package:soma_app/infrastructure/expenses/supabase_expense_repository.dart';
import 'package:soma_app/infrastructure/expenses/supabase_expense_store.dart';
import 'package:soma_app/infrastructure/supabase/supabase_initializer.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await SupabaseInitializer.initialize(config);

  final client = Supabase.instance.client;
  final authController = AuthController(
    SupabaseAuthService(
      client,
      webRedirectUrl: config.supabaseRedirectUrl.isEmpty
          ? null
          : config.supabaseRedirectUrl,
    ),
  );
  final expensesController = ExpensesController(
    SupabaseExpenseRepository(SupabaseExpenseStore(client)),
  );
  final categoriesController = CategoriesController(
    SupabaseCategoryRepository(SupabaseCategoryStore(client)),
  );

  runApp(
    SomaApp(
      authController: authController,
      expensesController: expensesController,
      categoriesController: categoriesController,
    ),
  );
}

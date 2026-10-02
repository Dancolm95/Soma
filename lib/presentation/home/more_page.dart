import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/categories/categories_page.dart';

/// "Más" tab: account, categories management and sign out.
class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.authController,
    required this.categoriesController,
  });

  final AuthController authController;
  final CategoriesController categoriesController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListenableBuilder(
            listenable: authController,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(authController.user?.email ?? 'Sesión iniciada'),
                  subtitle: const Text('Cuenta'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categorías'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoriesPage(controller: categoriesController),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => authController.signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

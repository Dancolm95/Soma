import 'package:flutter/material.dart';

import 'package:soma_app/application/categories/category.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key, required this.controller});

  final CategoriesController controller;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  Future<void> _showUpsert({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            category == null ? 'Agregar categoría' : 'Renombrar categoría',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Mercado',
              ),
              maxLength: 60,
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty || trimmed.length > 60) {
                  return 'El nombre no es válido. Usa entre 1 y 60 caracteres.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      final ok = category == null
                          ? await widget.controller.createCategory(
                              nameController.text,
                            )
                          : await widget.controller.renameCategory(
                              id: category.id,
                              name: nameController.text,
                            );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.controller.errorMessage ?? 'No se pudo completar la operación. Inténtalo nuevamente.',
                            ),
                          ),
                        );
                      }
                    },
              child: Text(category == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null ? 'Categoría creada.' : 'Categoría actualizada.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta categoría?'),
        content: Text(
          'Se eliminará "${category.name}". Los gastos que la usan impiden eliminarla.',
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
    final ok = await widget.controller.deleteCategory(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Categoría eliminada.'
              : (widget.controller.errorMessage ??
                    'No se pudo completar la operación. Inténtalo nuevamente.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              if (controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage != null &&
                  controller.categories.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.errorMessage!),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: controller.load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle('Del sistema'),
                  if (controller.system.isEmpty)
                    const ListTile(title: Text('Sin categorías del sistema.'))
                  else
                    for (final c in controller.system)
                      ListTile(
                        title: Text(c.name),
                        subtitle: const Text('Solo lectura'),
                      ),
                  const SizedBox(height: 8),
                  const _SectionTitle('Mis categorías'),
                  if (controller.private.isEmpty)
                    const ListTile(
                      title: Text('Aún no tienes categorías propias.'),
                    )
                  else
                    for (final c in controller.private)
                      ListTile(
                        title: Text(c.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Renombrar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showUpsert(category: c),
                            ),
                            IconButton(
                              tooltip: 'Eliminar categoría',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(c),
                            ),
                          ],
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUpsert(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar categoría'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

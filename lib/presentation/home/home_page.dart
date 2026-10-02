import 'package:flutter/material.dart';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/presentation/categories/categories_controller.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';
import 'package:soma_app/presentation/expenses/expenses_controller.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';
import 'package:soma_app/presentation/theme/category_colors.dart';

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _shortMonthLabel(DateTime month) =>
    '${_months[month.month - 1].substring(0, 3)} ${month.year}';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.expensesController,
    required this.categoriesController,
    required this.metricsController,
    required this.onCapture,
    required this.onSeeAll,
    required this.onOpenMetrics,
  });

  final ExpensesController expensesController;
  final CategoriesController categoriesController;
  final MetricsController metricsController;
  final void Function(String? categoryId) onCapture;
  final VoidCallback onSeeAll;
  final VoidCallback onOpenMetrics;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.expensesController.load();
      widget.categoriesController.load();
      widget.metricsController.load();
    });
  }

  Future<void> _reload() async {
    await widget.expensesController.load();
    await widget.categoriesController.load();
    await widget.metricsController.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.expensesController,
        widget.categoriesController,
        widget.metricsController,
      ]),
      builder: (context, _) {
        final expenses = widget.expensesController;
        final metrics = widget.metricsController;
        if (expenses.loading && expenses.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (expenses.errorMessage != null &&
            expenses.expenses.isEmpty &&
            metrics.snapshot == null) {
          return _HomeError(message: expenses.errorMessage!, onRetry: _reload);
        }
        if (expenses.expenses.isEmpty && metrics.snapshot == null) {
          return _HomeEmpty(onAdd: () => widget.onCapture(null));
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeaderRow(
                monthLabel: _shortMonthLabel(metrics.selectedMonth),
                onOpenMetrics: widget.onOpenMetrics,
              ),
              const SizedBox(height: 8),
              if (metrics.snapshot case final snapshot?)
                _BalanceHero(snapshot: snapshot),
              const SizedBox(height: 8),
              _TilesSection(
                snapshot: metrics.snapshot,
                categoryIds: {
                  for (final c in widget.categoriesController.categories)
                    c.id: c.name,
                },
                onCapture: widget.onCapture,
              ),
              _RecentsSection(
                controller: expenses,
                categoryNames: {
                  for (final c in widget.categoriesController.categories)
                    c.id: c.name,
                },
                onSeeAll: widget.onSeeAll,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.monthLabel, required this.onOpenMetrics});

  final String monthLabel;
  final VoidCallback onOpenMetrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Soma', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        ActionChip(label: Text(monthLabel), onPressed: onOpenMetrics),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final month = _months[snapshot.month.month - 1];
    final comparison = snapshot.comparison;
    final change = comparison.percentageChange?.value.replaceAll('.', ',');
    final previous = _months[comparison.previousPeriodStart.month - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastado en $month',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            formatPen(snapshot.total.totalMinor),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$change % vs. $previous · en PEN',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TilesSection extends StatelessWidget {
  const _TilesSection({
    required this.snapshot,
    required this.categoryIds,
    required this.onCapture,
  });

  final MetricsSnapshot? snapshot;
  final Map<String, String> categoryIds;
  final void Function(String? categoryId) onCapture;

  @override
  Widget build(BuildContext context) {
    final breakdown = snapshot?.breakdown ?? const <CategorySpending>[];
    final monthTotal = snapshot?.total.totalMinor ?? 0;
    final tiles = breakdown.isNotEmpty
        ? breakdown
        : [
            for (final entry in categoryIds.entries)
              CategorySpending(
                categoryId: entry.key,
                categoryName: entry.value,
                totalMinor: 0,
              ),
          ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            'Categorías',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.84,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            final colors = SomaCategoryColors.of(context, tile.categoryId);
            final percent = monthTotal > 0
                ? '${(100 * tile.totalMinor / monthTotal).round()} %'
                : null;
            return Material(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onCapture(tile.categoryId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.foreground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tile.categoryName.isEmpty
                              ? '?'
                              : tile.categoryName[0].toUpperCase(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tile.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (percent != null)
                        Text(
                          percent,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.foreground.withValues(
                                  alpha: 0.75,
                                ),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentsSection extends StatelessWidget {
  const _RecentsSection({
    required this.controller,
    required this.categoryNames,
    required this.onSeeAll,
  });

  final ExpensesController controller;
  final Map<String, String> categoryNames;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final recent = controller.expenses.take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 4),
          child: Row(
            children: [
              Text('Recientes', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
            ],
          ),
        ),
        for (final expense in recent)
          Builder(
            builder: (context) {
              final colors = SomaCategoryColors.of(context, expense.categoryId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.background,
                    foregroundColor: colors.foreground,
                    child: Text(
                      expense.merchant.isEmpty
                          ? '?'
                          : expense.merchant[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(expense.merchant),
                  subtitle: Text(
                    '${categoryNames[expense.categoryId] ?? 'Sin categoría'} · ${formatDateLabel(expense.expenseDate)}',
                  ),
                  trailing: Text(
                    formatPen(expense.amountMinor),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Aún no hay movimientos este mes.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAdd, child: const Text('Registrar gasto')),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

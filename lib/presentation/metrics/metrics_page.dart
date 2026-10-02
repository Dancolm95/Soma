import 'package:flutter/material.dart';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/presentation/expenses/amount_input.dart';
import 'package:soma_app/presentation/metrics/metrics_controller.dart';

const _spanishMonths = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

String metricsMonthLabel(DateTime month) =>
    '${_spanishMonths[month.month - 1]} ${month.year}';

String metricsShortMonthLabel(DateTime month) {
  final mm = month.month.toString().padLeft(2, '0');
  return '$mm/${month.year}';
}

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key, required this.controller});

  final MetricsController controller;

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.snapshot == null &&
          !widget.controller.loading &&
          widget.controller.errorMessage == null) {
        widget.controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            tooltip: 'Actualizar resumen',
            icon: const Icon(Icons.refresh),
            onPressed: widget.controller.refresh,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              return Column(
                children: [
                  _MonthSelector(controller: controller),
                  Expanded(child: _Body(controller: controller)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.controller});

  final MetricsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.loading ? null : controller.previousMonth,
          ),
          Expanded(
            child: Text(
              metricsMonthLabel(controller.selectedMonth),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.loading || controller.isAtCurrentMonth
                ? null
                : controller.nextMonth,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final MetricsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && controller.snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.errorMessage!),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.refresh,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final snapshot = controller.snapshot;
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          _TotalCard(snapshot: snapshot),
          const SizedBox(height: 8),
          _ComparisonCard(snapshot: snapshot),
          const SizedBox(height: 8),
          _TrendCard(snapshot: snapshot),
          const SizedBox(height: 8),
          _BreakdownCard(snapshot: snapshot),
          const SizedBox(height: 8),
          _TopCategoriesCard(snapshot: snapshot),
          const SizedBox(height: 8),
          _TopMerchantsCard(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total del mes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              formatPen(snapshot.total.totalMinor),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final comparison = snapshot.comparison;
    final difference = comparison.differenceMinor;
    final direction = difference > 0
        ? 'Aumento respecto a ${metricsMonthLabel(comparison.previousPeriodStart)}'
        : difference < 0
        ? 'Disminución respecto a ${metricsMonthLabel(comparison.previousPeriodStart)}'
        : 'Sin cambio respecto a ${metricsMonthLabel(comparison.previousPeriodStart)}';
    final icon = difference > 0
        ? Icons.trending_up
        : difference < 0
        ? Icons.trending_down
        : Icons.trending_flat;
    final percentage = comparison.percentageChange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparación', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('vs ${metricsMonthLabel(comparison.previousPeriodStart)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, semanticLabel: direction),
                const SizedBox(width: 8),
                Expanded(child: Text(direction)),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatPen(difference)),
            const SizedBox(height: 4),
            if (percentage == null)
              const Text('Sin base de comparación')
            else
              Text('${percentage.value}%'),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final trend = snapshot.trend;
    var max = 0;
    for (final point in trend) {
      if (point.totalMinor > max) max = point.totalMinor;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución — 6 meses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final point in trend) _TrendRow(point: point, max: max),
          ],
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.point, required this.max});

  final MonthlyTrendPoint point;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : point.totalMinor / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(metricsShortMonthLabel(point.periodStart)),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(formatPen(point.totalMinor)),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final breakdown = snapshot.breakdown;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (breakdown.isEmpty)
              const Text('Sin gastos en este mes.')
            else
              for (final row in breakdown)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.categoryName),
                  trailing: Text(formatPen(row.totalMinor)),
                ),
          ],
        ),
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top categorías',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snapshot.topCategories.isEmpty)
              const Text('Sin gastos en este mes.')
            else
              for (final row in snapshot.topCategories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.categoryName),
                  trailing: Text(formatPen(row.totalMinor)),
                ),
          ],
        ),
      ),
    );
  }
}

class _TopMerchantsCard extends StatelessWidget {
  const _TopMerchantsCard({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top comercios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snapshot.topMerchants.isEmpty)
              const Text('Sin gastos en este mes.')
            else
              for (final row in snapshot.topMerchants)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.merchant),
                  trailing: Text(formatPen(row.totalMinor)),
                ),
          ],
        ),
      ),
    );
  }
}

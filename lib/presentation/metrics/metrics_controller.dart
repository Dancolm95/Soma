import 'package:flutter/foundation.dart';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';

class MetricsSnapshot {
  const MetricsSnapshot({
    required this.month,
    required this.total,
    required this.breakdown,
    required this.topCategories,
    required this.topMerchants,
    required this.trend,
    required this.comparison,
  });

  final DateTime month;
  final MonthlyTotal total;
  final List<CategorySpending> breakdown;
  final List<CategorySpending> topCategories;
  final List<MerchantSpending> topMerchants;
  final List<MonthlyTrendPoint> trend;
  final MonthlyComparison comparison;
}

class MetricsController extends ChangeNotifier {
  MetricsController(
    this._repository, {
    DateTime? initialMonth,
    DateTime? currentMonth,
  }) : selectedMonth = canonicalMetricsMonth(initialMonth ?? DateTime.now()),
       _currentMonth = canonicalMetricsMonth(currentMonth ?? DateTime.now());

  final MetricsRepository _repository;

  DateTime selectedMonth;
  final DateTime _currentMonth;

  bool loading = false;
  MetricsSnapshot? snapshot;
  String? errorMessage;

  int _requestId = 0;

  bool get isAtCurrentMonth =>
      _monthIndex(selectedMonth) >= _monthIndex(_currentMonth);

  static int _monthIndex(DateTime month) => month.year * 12 + month.month;

  Future<void> load() async {
    final request = ++_requestId;
    final month = selectedMonth;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final total = await _repository.monthlyTotal(month);
      final breakdown = await _repository.spendingByCategory(month);
      final topCategories = await _repository.topCategories(month);
      final topMerchants = await _repository.topMerchants(month);
      final trend = await _repository.monthlyTrend(month);
      final comparison = await _repository.monthlyComparison(month);
      if (request != _requestId) return;
      snapshot = MetricsSnapshot(
        month: month,
        total: total,
        breakdown: breakdown,
        topCategories: topCategories,
        topMerchants: topMerchants,
        trend: trend,
        comparison: comparison,
      );
      errorMessage = null;
    } on MetricsException catch (e) {
      if (request != _requestId) return;
      snapshot = null;
      errorMessage = metricsErrorMessage(e.error);
    } catch (_) {
      if (request != _requestId) return;
      snapshot = null;
      errorMessage = metricsErrorMessage(MetricsError.unexpected);
    }
    if (request != _requestId) return;
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> selectMonth(DateTime month) {
    final canonical = canonicalMetricsMonth(month);
    if (_monthIndex(canonical) > _monthIndex(_currentMonth)) {
      return Future.value();
    }
    if (canonical == selectedMonth) {
      return load();
    }
    selectedMonth = canonical;
    return load();
  }

  Future<void> previousMonth() =>
      selectMonth(addMetricsMonths(selectedMonth, -1));

  Future<void> nextMonth() {
    if (isAtCurrentMonth) return Future.value();
    return selectMonth(addMetricsMonths(selectedMonth, 1));
  }
}

import 'package:soma_app/application/metrics/metrics.dart';

enum MetricsError { invalidResponse, unauthorized, unexpected }

class MetricsException implements Exception {
  const MetricsException(this.error);

  final MetricsError error;
}

String metricsErrorMessage(MetricsError error) {
  switch (error) {
    case MetricsError.invalidResponse:
      return 'No se pudieron cargar las métricas. Inténtalo de nuevo.';
    case MetricsError.unauthorized:
      return 'No tienes permiso para ver estas métricas.';
    case MetricsError.unexpected:
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}

abstract class MetricsRepository {
  Future<MonthlyTotal> monthlyTotal(DateTime month);

  Future<List<CategorySpending>> spendingByCategory(DateTime month);

  Future<List<CategorySpending>> topCategories(DateTime month);

  Future<List<MerchantSpending>> topMerchants(DateTime month);

  Future<List<MonthlyTrendPoint>> monthlyTrend(DateTime month);

  Future<MonthlyComparison> monthlyComparison(DateTime month);
}

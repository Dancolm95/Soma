import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/metrics/metrics.dart';
import 'package:soma_app/application/metrics/metrics_repository.dart';
import 'package:soma_app/infrastructure/metrics/metrics_store.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

class SupabaseMetricsRepository implements MetricsRepository {
  SupabaseMetricsRepository(this._store);

  final MetricsStore _store;

  @override
  Future<MonthlyTotal> monthlyTotal(DateTime month) async {
    final requested = canonicalMetricsMonth(month);
    try {
      final rows = await _store.monthlyTotal(formatMetricsMonth(month));
      if (rows.length != 1) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      final row = rows.first;
      final periodStart = _periodStart(row['period_start']);
      if (periodStart != requested) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      return MonthlyTotal(
        periodStart: periodStart,
        totalMinor: parseMetricsAmount(row['total']),
      );
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  @override
  Future<List<CategorySpending>> spendingByCategory(DateTime month) async {
    try {
      final rows = await _store.spendingByCategory(formatMetricsMonth(month));
      return [for (final row in rows) _categoryRow(row)];
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  @override
  Future<List<CategorySpending>> topCategories(DateTime month) async {
    try {
      final rows = await _store.topCategories(formatMetricsMonth(month));
      if (rows.length > 5) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      return [for (final row in rows) _categoryRow(row)];
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  @override
  Future<List<MerchantSpending>> topMerchants(DateTime month) async {
    try {
      final rows = await _store.topMerchants(formatMetricsMonth(month));
      if (rows.length > 5) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      return [for (final row in rows) _merchantRow(row)];
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  @override
  Future<List<MonthlyTrendPoint>> monthlyTrend(DateTime month) async {
    final requested = canonicalMetricsMonth(month);
    try {
      final rows = await _store.monthlyTrend(formatMetricsMonth(month));
      if (rows.length != 6) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      final points = <MonthlyTrendPoint>[];
      for (var i = 0; i < 6; i++) {
        final expected = addMetricsMonths(requested, i - 5);
        final row = rows[i];
        final periodStart = _periodStart(row['period_start']);
        if (periodStart != expected) {
          throw const MetricsException(MetricsError.invalidResponse);
        }
        points.add(
          MonthlyTrendPoint(
            periodStart: periodStart,
            totalMinor: parseMetricsAmount(row['total']),
          ),
        );
      }
      return points;
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  @override
  Future<MonthlyComparison> monthlyComparison(DateTime month) async {
    final requested = canonicalMetricsMonth(month);
    final previous = addMetricsMonths(requested, -1);
    try {
      final rows = await _store.monthlyComparison(formatMetricsMonth(month));
      if (rows.length != 1) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      final row = rows.first;
      final periodStart = _periodStart(row['period_start']);
      final previousStart = _periodStart(row['previous_period_start']);
      if (periodStart != requested || previousStart != previous) {
        throw const MetricsException(MetricsError.invalidResponse);
      }
      final rawPercentage = row['percentage_change'];
      return MonthlyComparison(
        periodStart: periodStart,
        currentTotalMinor: parseMetricsAmount(row['current_total']),
        previousPeriodStart: previousStart,
        previousTotalMinor: parseMetricsAmount(row['previous_total']),
        differenceMinor: parseMetricsAmount(row['difference']),
        percentageChange: rawPercentage == null
            ? null
            : PercentageChange.parse(rawPercentage),
      );
    } on PostgrestException catch (error) {
      throw MetricsException(_translate(error.code, error.message));
    } on MetricsException {
      rethrow;
    } on FormatException {
      throw const MetricsException(MetricsError.invalidResponse);
    } catch (_) {
      throw const MetricsException(MetricsError.unexpected);
    }
  }

  static CategorySpending _categoryRow(Map<String, dynamic> row) {
    final id = row['category_id'];
    final name = row['category_name'];
    if (id is! String || !_uuidPattern.hasMatch(id)) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    if (name is! String || name.isEmpty) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    if (!row.containsKey('total')) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    return CategorySpending(
      categoryId: id,
      categoryName: name,
      totalMinor: parseMetricsAmount(row['total']),
    );
  }

  static MerchantSpending _merchantRow(Map<String, dynamic> row) {
    final merchant = row['merchant'];
    if (merchant is! String || merchant.isEmpty) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    if (!row.containsKey('total')) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    return MerchantSpending(
      merchant: merchant,
      totalMinor: parseMetricsAmount(row['total']),
    );
  }

  static DateTime _periodStart(dynamic raw) {
    if (raw is! String) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    if (day.day != 1) {
      throw const MetricsException(MetricsError.invalidResponse);
    }
    return DateTime(day.year, day.month, 1);
  }

  static MetricsError _translate(String? code, String message) {
    switch (code) {
      case '42501':
      case 'PGRST301':
      case '401':
      case '403':
        return MetricsError.unauthorized;
      default:
        final text = message.toLowerCase();
        if (text.contains('not authenticated') ||
            text.contains('jwt') ||
            text.contains('permission denied')) {
          return MetricsError.unauthorized;
        }
        return MetricsError.unexpected;
    }
  }
}

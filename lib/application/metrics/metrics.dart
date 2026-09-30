DateTime canonicalMetricsMonth(DateTime month) =>
    DateTime(month.year, month.month, 1);

String formatMetricsMonth(DateTime month) {
  final canonical = canonicalMetricsMonth(month);
  final mm = canonical.month.toString().padLeft(2, '0');
  return '${canonical.year}-$mm-01';
}

DateTime addMetricsMonths(DateTime monthStart, int delta) {
  final total = monthStart.year * 12 + (monthStart.month - 1) + delta;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  return DateTime(year, month, 1);
}

int parseMetricsAmount(dynamic value) {
  if (value is int) return value * 100;
  final text = value.toString().trim();
  if (text.isEmpty || text == '-') {
    throw const FormatException('invalid amount');
  }
  final negative = text.startsWith('-');
  final unsigned = negative ? text.substring(1) : text;
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(unsigned) &&
      !RegExp(r'^\.\d{1,2}$').hasMatch(unsigned)) {
    throw const FormatException('invalid amount');
  }
  final parts = unsigned.split('.');
  if (parts.length > 2) throw const FormatException('invalid amount');
  final whole = int.parse(parts[0].isEmpty ? '0' : parts[0]);
  var cents = 0;
  if (parts.length == 2) {
    final frac = parts[1];
    if (frac.length > 2) throw const FormatException('invalid amount');
    if (frac.isEmpty) {
      cents = 0;
    } else if (frac.length == 1) {
      cents = int.parse('${frac}0');
    } else {
      cents = int.parse(frac);
    }
  }
  final minor = whole * 100 + cents;
  return negative ? -minor : minor;
}

final _percentagePattern = RegExp(r'^-?\d+(\.\d+)?$');

class PercentageChange {
  const PercentageChange(this.value);

  final String value;

  factory PercentageChange.parse(dynamic raw) {
    final text = raw.toString().trim();
    if (!_percentagePattern.hasMatch(text)) {
      throw const FormatException('invalid percentage');
    }
    return PercentageChange(text);
  }

  @override
  bool operator ==(Object other) =>
      other is PercentageChange && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PercentageChange($value)';
}

class MonthlyTotal {
  const MonthlyTotal({required this.periodStart, required this.totalMinor});

  final DateTime periodStart;
  final int totalMinor;
}

class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.totalMinor,
  });

  final String categoryId;
  final String categoryName;
  final int totalMinor;
}

class MerchantSpending {
  const MerchantSpending({required this.merchant, required this.totalMinor});

  final String merchant;
  final int totalMinor;
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.periodStart,
    required this.totalMinor,
  });

  final DateTime periodStart;
  final int totalMinor;
}

class MonthlyComparison {
  const MonthlyComparison({
    required this.periodStart,
    required this.currentTotalMinor,
    required this.previousPeriodStart,
    required this.previousTotalMinor,
    required this.differenceMinor,
    required this.percentageChange,
  });

  final DateTime periodStart;
  final int currentTotalMinor;
  final DateTime previousPeriodStart;
  final int previousTotalMinor;
  final int differenceMinor;
  final PercentageChange? percentageChange;
}

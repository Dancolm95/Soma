const kMinExpenseAmountMinor = 1;
const kMaxExpenseAmountMinor = 999999999999;

String expenseAmountToDb(int amountMinor) {
  final whole = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return '$whole.$cents';
}

int parseExpenseAmount(dynamic value) {
  if (value is int) return value * 100;
  final text = value.toString().trim();
  final negative = text.startsWith('-');
  final unsigned = negative ? text.substring(1) : text;
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

String formatExpenseDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class Expense {
  const Expense({
    required this.id,
    required this.amountMinor,
    required this.expenseDate,
    required this.merchant,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int amountMinor;
  final DateTime expenseDate;
  final String merchant;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amountMinor: parseExpenseAmount(json['amount']),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      merchant: json['merchant'] as String,
      categoryId: json['category_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

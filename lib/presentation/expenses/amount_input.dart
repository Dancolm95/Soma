int? tryParseAmountMinor(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('-') || trimmed.startsWith('+')) return null;
  final normalized = trimmed.replaceAll(',', '.');
  if ('.'.allMatches(normalized).length > 1) return null;
  final parts = normalized.split('.');
  if (parts.length > 2) return null;
  final wholePart = parts[0];
  final fracPart = parts.length == 2 ? parts[1] : '';
  if (fracPart.length > 2) return null;
  if (wholePart.isEmpty && fracPart.isEmpty) return null;
  if (!_isDigitsOrEmpty(wholePart) || !_isDigitsOrEmpty(fracPart)) {
    return null;
  }
  if (wholePart.length > 10) return null;
  final whole = wholePart.isEmpty ? 0 : int.parse(wholePart);
  var cents = 0;
  if (fracPart.isNotEmpty) {
    cents = fracPart.length == 1
        ? int.parse('${fracPart}0')
        : int.parse(fracPart);
  }
  return whole * 100 + cents;
}

bool _isDigitsOrEmpty(String value) {
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if (code < 48 || code > 57) return false;
  }
  return true;
}

String formatPen(int amountMinor) {
  final whole = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return 'S/ $whole.$cents';
}

String formatDateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

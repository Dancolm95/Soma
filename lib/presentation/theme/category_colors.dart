import 'package:flutter/material.dart';

/// Decidida category palette: eight hues sharing chroma and lightness
/// steps, only hue varies (see soma tokens `--cat-h-0…7`).
///
/// Colors are derived deterministically from the category id, so the
/// [Category] model needs no icon or color field and no migration.
class SomaCategoryPalette {
  const SomaCategoryPalette({
    required this.background,
    required this.foreground,
    required this.darkBackground,
    required this.darkForeground,
  });

  final Color background;
  final Color foreground;
  final Color darkBackground;
  final Color darkForeground;
}

class SomaCategoryColors {
  const SomaCategoryColors._();

  static const List<SomaCategoryPalette> palette = [
    SomaCategoryPalette(
      background: Color(0xFFDFE7FB),
      foreground: Color(0xFF3B63D8),
      darkBackground: Color(0xFF1E2C5C),
      darkForeground: Color(0xFF9DB4F5),
    ),
    SomaCategoryPalette(
      background: Color(0xFFD9EFEE),
      foreground: Color(0xFF0B6E6D),
      darkBackground: Color(0xFF123836),
      darkForeground: Color(0xFF5BC4C0),
    ),
    SomaCategoryPalette(
      background: Color(0xFFD8F0E3),
      foreground: Color(0xFF0E7F56),
      darkBackground: Color(0xFF0F3826),
      darkForeground: Color(0xFF5FCE9F),
    ),
    SomaCategoryPalette(
      background: Color(0xFFF6EAC8),
      foreground: Color(0xFF7A4A00),
      darkBackground: Color(0xFF3A2A0C),
      darkForeground: Color(0xFFE5B94E),
    ),
    SomaCategoryPalette(
      background: Color(0xFFFADFD6),
      foreground: Color(0xFFA63A22),
      darkBackground: Color(0xFF3D1B12),
      darkForeground: Color(0xFFEE9780),
    ),
    SomaCategoryPalette(
      background: Color(0xFFEDE3F7),
      foreground: Color(0xFF6D3FC0),
      darkBackground: Color(0xFF2A2140),
      darkForeground: Color(0xFFC4A9F2),
    ),
    SomaCategoryPalette(
      background: Color(0xFFE3F0D2),
      foreground: Color(0xFF527A1F),
      darkBackground: Color(0xFF22301A),
      darkForeground: Color(0xFFA8CD7D),
    ),
    SomaCategoryPalette(
      background: Color(0xFFF7DCE8),
      foreground: Color(0xFFA6245C),
      darkBackground: Color(0xFF3A1A2A),
      darkForeground: Color(0xFFED9BC3),
    ),
  ];

  static int indexFor(String seed) {
    var hash = 5381;
    for (var i = 0; i < seed.length; i++) {
      hash = ((hash << 5) + hash + seed.codeUnitAt(i)) & 0x7fffffff;
    }
    return hash % palette.length;
  }

  static ({Color background, Color foreground}) of(
    BuildContext context,
    String seed,
  ) {
    final entry = palette[indexFor(seed)];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (
      background: dark ? entry.darkBackground : entry.background,
      foreground: dark ? entry.darkForeground : entry.foreground,
    );
  }
}

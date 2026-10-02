import 'package:flutter/material.dart';

/// Soma "Ágil" theme (canonical direction B).
///
/// Maps `opendesign/design-systems/soma/tokens/colors_and_type.css` to
/// Material 3: cobalt accent as [ColorScheme.primary], cool-slate
/// neutrals as surfaces, compact 8–16 radii. Typography stays Material
/// default (no bundled font dependency).
class SomaTheme {
  const SomaTheme._();

  static const _primaryLight = Color(0xFF3B63D8);
  static const _onPrimaryLight = Color(0xFFFFFFFF);
  static const _primaryContainerLight = Color(0xFFDFE7FB);
  static const _onPrimaryContainerLight = Color(0xFF1D2F6E);

  static const _primaryDark = Color(0xFF9DB4F5);
  static const _onPrimaryDark = Color(0xFF131F4D);
  static const _primaryContainerDark = Color(0xFF1E2C5C);
  static const _onPrimaryContainerDark = Color(0xFFCFDBFA);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: _onPrimaryLight,
      primaryContainer: _primaryContainerLight,
      onPrimaryContainer: _onPrimaryContainerLight,
      secondary: Color(0xFF44566A),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF16202A),
      surfaceContainerLowest: Color(0xFFF4F6F8),
      surfaceContainerLow: Color(0xFFE9EDF1),
      error: Color(0xFFB3261E),
      outline: Color(0xFFC3CEDB),
      outlineVariant: Color(0xFFDCE3EA),
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: _onPrimaryDark,
      primaryContainer: _primaryContainerDark,
      onPrimaryContainer: _onPrimaryContainerDark,
      secondary: Color(0xFFB4C2D2),
      surface: Color(0xFF141C25),
      onSurface: Color(0xFFE8EEF4),
      surfaceContainerLowest: Color(0xFF0D1319),
      surfaceContainerLow: Color(0xFF1C2632),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF410002),
      outline: Color(0xFF35465A),
      outlineVariant: Color(0xFF263241),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}

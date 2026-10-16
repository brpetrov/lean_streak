import 'package:flutter/material.dart';

/// One set of colours for a theme. Light is "warm paper"; dark is the same
/// idea in warm charcoal, never pure black, with the teal lifted so it stays
/// readable on dark surfaces.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.veryGood,
    required this.bad,
    required this.veryBad,
    required this.divider,
    required this.error,
    required this.shadow,
    required this.info,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color veryGood;
  final Color bad;
  final Color veryBad;
  final Color divider;
  final Color error;
  final Color shadow;
  final Color info;

  static const light = AppPalette(
    primary: Color(0xFF2E7D6E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE1EFEC),
    onPrimaryContainer: Color(0xFF2E7D6E),
    background: Color(0xFFF6F4EF),
    surface: Color(0xFFFDFCF9),
    surfaceVariant: Color(0xFFF0EDE6),
    outline: Color(0xFFCFC9BE),
    textPrimary: Color(0xFF1F1D1A),
    textSecondary: Color(0xFF6E6A63),
    textDisabled: Color(0xFFA8A39A),
    veryGood: Color(0xFF2E7D6E),
    bad: Color(0xFFE8A75B),
    veryBad: Color(0xFFD64045),
    divider: Color(0xFFE8E4DC),
    error: Color(0xFFD64045),
    shadow: Color(0x0A1F1D1A),
    info: Color(0xFF3B82F6),
  );

  static const dark = AppPalette(
    primary: Color(0xFF5FB3A3),
    onPrimary: Color(0xFF0F1F1B),
    primaryContainer: Color(0xFF1E3B35),
    onPrimaryContainer: Color(0xFF9FDCCF),
    background: Color(0xFF171513),
    surface: Color(0xFF211E1B),
    surfaceVariant: Color(0xFF2A2623),
    outline: Color(0xFF4A443E),
    textPrimary: Color(0xFFF2EEE8),
    textSecondary: Color(0xFFB3ACA3),
    textDisabled: Color(0xFF7A736A),
    veryGood: Color(0xFF5FB3A3),
    bad: Color(0xFFF0B96A),
    veryBad: Color(0xFFE8666A),
    divider: Color(0xFF332E2A),
    error: Color(0xFFE8666A),
    shadow: Color(0x66000000),
    info: Color(0xFF6FA6F8),
  );
}

/// The app's colour tokens. They read from the palette for the current
/// brightness, which `LeanStreakApp` sets before anything builds.
class AppColors {
  AppColors._();

  static bool isDark = false;

  static AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;

  static Color get primary => palette.primary;
  static Color get onPrimary => palette.onPrimary;
  static Color get primaryContainer => palette.primaryContainer;
  static Color get onPrimaryContainer => palette.onPrimaryContainer;

  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceVariant => palette.surfaceVariant;
  static Color get outline => palette.outline;

  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textDisabled => palette.textDisabled;

  static Color get veryGood => palette.veryGood;
  static Color get bad => palette.bad;
  static Color get veryBad => palette.veryBad;

  static Color get divider => palette.divider;
  static Color get error => palette.error;
  static Color get shadow => palette.shadow;
  static Color get info => palette.info;
}

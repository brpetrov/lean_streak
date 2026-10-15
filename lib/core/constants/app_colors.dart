import 'package:flutter/material.dart';

/// Light-only "warm paper" palette: off-white page, cream cards with a thin
/// warm edge, and the logo teal as the accent.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D6E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE1EFEC);

  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFDFCF9);
  static const Color surfaceVariant = Color(0xFFF0EDE6);

  static const Color textPrimary = Color(0xFF1F1D1A);
  static const Color textSecondary = Color(0xFF6E6A63);
  static const Color textDisabled = Color(0xFFA8A39A);

  static const Color veryGood = Color(0xFF2E7D6E);
  static const Color bad = Color(0xFFE8A75B);
  static const Color veryBad = Color(0xFFD64045);

  static const Color tagPositive = veryGood;
  static const Color tagPositiveBg = Color(0xFFE3F2EF);

  static const Color tagNeutral = textSecondary;
  static const Color tagNeutralBg = Color(0xFFEFF3F1);

  static const Color tagWarning = bad;
  static const Color tagWarningBg = Color(0xFFFDF3E7);

  static const Color divider = Color(0xFFE8E4DC);
  static const Color error = Color(0xFFD64045);
  static const Color shadow = Color(0x0A1F1D1A);
}

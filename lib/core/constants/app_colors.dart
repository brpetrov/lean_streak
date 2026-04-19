import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDark = false;

  static Color get primary =>
      isDark ? const Color(0xFFF7F7F7) : const Color(0xFF111111);
  static Color get primaryDark =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get primaryLight =>
      isDark ? const Color(0xFFD4D4D8) : const Color(0xFF444444);

  static Color get background =>
      isDark ? const Color(0xFF09090B) : const Color(0xFFFFFFFF);
  static Color get surface =>
      isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant =>
      isDark ? const Color(0xFF27272A) : const Color(0xFFF2F3F5);

  static Color get textPrimary =>
      isDark ? const Color(0xFFF7F7F7) : const Color(0xFF111111);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA1A1AA) : const Color(0xFF666666);
  static Color get textDisabled =>
      isDark ? const Color(0xFF71717A) : const Color(0xFFA8A8A8);

  static Color get veryGood =>
      isDark ? const Color(0xFF55BFA8) : const Color(0xFF2E7D6E);
  static Color get good =>
      isDark ? const Color(0xFF8AD5B0) : const Color(0xFF78B89A);
  static Color get bad =>
      isDark ? const Color(0xFFF0B768) : const Color(0xFFE8A75B);
  static Color get veryBad =>
      isDark ? const Color(0xFFFF6B70) : const Color(0xFFD64045);

  static Color get tagPositive => veryGood;
  static Color get tagPositiveBg =>
      isDark ? const Color(0xFF143A34) : const Color(0xFFE3F2EF);

  static Color get tagNeutral => textSecondary;
  static Color get tagNeutralBg =>
      isDark ? const Color(0xFF27272A) : const Color(0xFFEFF3F1);

  static Color get tagWarning => bad;
  static Color get tagWarningBg =>
      isDark ? const Color(0xFF3F2E15) : const Color(0xFFFDF3E7);

  static Color get divider =>
      isDark ? const Color(0xFF2F2F34) : const Color(0xFFE4E4E7);
  static Color get error =>
      isDark ? const Color(0xFFFF6B70) : const Color(0xFFD64045);
  static Color get shadow =>
      isDark ? const Color(0x66000000) : const Color(0x0F111111);
}

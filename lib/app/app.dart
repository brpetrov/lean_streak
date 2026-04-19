import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/theme_controller.dart';

class LeanStreakApp extends ConsumerWidget {
  const LeanStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityScaleMigrationProvider);
    final themeMode =
        ref.watch(themeControllerProvider).valueOrNull ?? ThemeMode.light;
    AppColors.isDark = themeMode == ThemeMode.dark;
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'LeanStreak',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

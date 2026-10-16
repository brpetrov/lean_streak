import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';

class LeanStreakApp extends ConsumerWidget {
  const LeanStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityScaleMigrationProvider);
    ref.watch(reminderSyncProvider);
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'LeanStreak',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: appShellBuilder,
    );
  }
}

/// Widest the app gets. Wider browser windows show it as one centred column,
/// so the app bar, pages, dialogs and the bottom bar all line up.
const double appMaxWidth = 760;

Widget appShellBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  if (mediaQuery.size.width <= appMaxWidth) return child!;

  final theme = Theme.of(context);
  // A slightly deeper margin with a hairline edge makes the column read as a
  // page, so dialogs dimming only the column look intentional.
  return ColoredBox(
    color: AppColors.surfaceVariant,
    child: Center(
      child: Container(
        width: appMaxWidth,
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border.symmetric(
            vertical: BorderSide(color: AppColors.divider),
          ),
        ),
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(
              math.min(mediaQuery.size.width, appMaxWidth),
              mediaQuery.size.height,
            ),
          ),
          child: Theme(
            // Keep floating snackbars phone-sized inside the column.
            data: theme.copyWith(
              snackBarTheme: theme.snackBarTheme.copyWith(width: 480),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
}

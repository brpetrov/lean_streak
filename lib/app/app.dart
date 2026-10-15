import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/activity_scale_migration_provider.dart';

class LeanStreakApp extends ConsumerWidget {
  const LeanStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityScaleMigrationProvider);
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'LeanStreak',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Floating snackbars otherwise stretch across wide browser windows.
        // A fixed theme width would overflow phones, so apply it only here.
        if (MediaQuery.sizeOf(context).width < 600) return child!;
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            snackBarTheme: theme.snackBarTheme.copyWith(width: 480),
          ),
          child: child!,
        );
      },
    );
  }
}

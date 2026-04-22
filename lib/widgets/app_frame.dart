import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/password_confirm_dialog.dart';

enum AppFrameTab { today, review, summary }

class AppFrame extends ConsumerWidget {
  const AppFrame({
    super.key,
    required this.title,
    required this.currentTab,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final AppFrameTab currentTab;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final accountState = ref.watch(accountControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: _AppDrawer(authState: authState, accountState: accountState),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) =>
            _handleTabSelection(context, AppFrameTab.values[index]),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Summary',
          ),
        ],
      ),
    );
  }

  void _handleTabSelection(BuildContext context, AppFrameTab tab) {
    if (tab == currentTab) return;

    switch (tab) {
      case AppFrameTab.today:
        context.go(AppRoutes.dashboard);
      case AppFrameTab.review:
        context.go(AppRoutes.review);
      case AppFrameTab.summary:
        context.go(AppRoutes.summary);
    }
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.authState, required this.accountState});

  final AsyncValue<AuthStatus> authState;
  final AsyncValue<void> accountState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorking = authState.isLoading || accountState.isLoading;
    final themeMode = ref.watch(themeControllerProvider).valueOrNull;
    final isDarkMode = themeMode == ThemeMode.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const AppLogoMark(size: 28),
                  SizedBox(width: 10),
                  Text(
                    'LeanStreak',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.assignment_outlined),
              title: Text('Plan Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.planSettings);
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts_outlined),
              title: Text('Account Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile);
              },
            ),
            SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
              ),
              title: Text('Dark theme'),
              value: isDarkMode,
              onChanged: themeMode == null
                  ? null
                  : (value) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .setDarkMode(value);
                    },
            ),
            const ListTile(
              enabled: false,
              leading: Icon(Icons.star_outline_rounded),
              title: Text('Rate this app'),
            ),
            const Spacer(),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.restart_alt_rounded),
              title: Text('Reset Progress'),
              enabled: !isWorking,
              onTap: isWorking
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      final password = await showPasswordConfirmDialog(
                        context,
                        title: 'Reset progress?',
                        description:
                            'This deletes your meals, summaries, check-ins, and AI usage. Your profile stays.',
                        confirmLabel: 'Reset progress',
                        destructive: true,
                      );

                      if (password == null || !context.mounted) return;

                      try {
                        await ref
                            .read(accountControllerProvider.notifier)
                            .resetProgress(password: password);
                      } catch (error) {
                        if (!context.mounted) return;
                        final message = error is AccountActionException
                            ? error.message
                            : 'Could not reset progress right now.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded),
              title: Text(authState.isLoading ? 'Signing out...' : 'Log out'),
              enabled: !isWorking,
              onTap: isWorking
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

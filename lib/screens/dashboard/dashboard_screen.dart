import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/check_in_controller.dart';
import 'package:lean_streak/providers/check_in_state_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/check_in_dialog.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/services/check_in_service.dart';
import 'package:lean_streak/widgets/password_confirm_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  String? _scheduledPromptPeriodKey;
  late DateTime _activeDate;
  Timer? _midnightRefreshTimer;

  @override
  void initState() {
    super.initState();
    _activeDate = _normalizeDate(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshActiveDateIfNeeded();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightRefreshTimer = Timer(delay, _refreshActiveDateIfNeeded);
  }

  void _refreshActiveDateIfNeeded() {
    final nextDate = _normalizeDate(DateTime.now());
    if (!_isSameDate(_activeDate, nextDate)) {
      ref.invalidate(currentCheckInAvailabilityProvider);
      ref.invalidate(reviewPeriodsProvider);
      setState(() {
        _activeDate = nextDate;
      });
    }
    _scheduleMidnightRefresh();
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final accountActionState = ref.watch(accountControllerProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final checkInAvailabilityAsync = ref.watch(
      currentCheckInAvailabilityProvider,
    );
    final today = _activeDate;
    final dateKey = DateFormat('yyyy-MM-dd').format(today);

    ref.listen<AsyncValue<CheckInAvailability?>>(
      currentCheckInAvailabilityProvider,
      (_, next) {
        final availability = next.valueOrNull;
        final period = availability?.period;
        if (availability == null ||
            period == null ||
            !availability.isDue ||
            availability.isCompleted ||
            availability.hasPromptBeenShown ||
            _scheduledPromptPeriodKey == period.key) {
          return;
        }

        _scheduledPromptPeriodKey = period.key;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref
              .read(checkInControllerProvider.notifier)
              .markPromptShown(
                periodKey: period.key,
                periodStart: period.startDate,
                periodEnd: period.endDate,
              );
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A 2-week check-in is ready.'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => _openCheckInFlow(context, availability),
              ),
            ),
          );
        });
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('LeanStreak'),
        actions: [
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'More options',
            onSelected: (action) async {
              switch (action) {
                case _DashboardMenuAction.checkIn:
                  await _openCheckInFlow(
                    context,
                    checkInAvailabilityAsync.valueOrNull,
                  );
                case _DashboardMenuAction.profile:
                  context.push(AppRoutes.profile);
                case _DashboardMenuAction.review:
                  context.push(AppRoutes.review);
                case _DashboardMenuAction.summary:
                  context.push(AppRoutes.summary);
                case _DashboardMenuAction.resetProgress:
                  await _confirmAndResetProgress(context);
                case _DashboardMenuAction.signOut:
                  if (authState.isLoading || accountActionState.isLoading) {
                    return;
                  }
                  await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _DashboardMenuAction.checkIn,
                child: Text('Check-in'),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.profile,
                child: Text('Edit Profile'),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.review,
                child: Text('Review'),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.summary,
                child: Text('Summary'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.resetProgress,
                enabled: !accountActionState.isLoading,
                child: accountActionState.isLoading
                    ? const Text('Working...')
                    : const Text('Reset Progress'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.signOut,
                enabled: !authState.isLoading && !accountActionState.isLoading,
                child: authState.isLoading
                    ? const Text('Signing out...')
                    : const Text('Log out'),
              ),
            ],
            icon: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLogMealSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Could not load your profile right now.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final mealsAsync = ref.watch(mealsForDateProvider(dateKey));
          final savedSummary = ref
              .watch(dailySummaryForDateProvider(dateKey))
              .valueOrNull;

          return mealsAsync.when(
            data: (meals) {
              final summary =
                  savedSummary ??
                  ref
                      .read(dailySummaryServiceProvider)
                      .buildSummary(
                        date: dateKey,
                        meals: meals,
                        dailyCalorieTarget: profile.dailyCalorieTarget,
                      );

              return _DashboardContent(
                date: today,
                profile: profile,
                meals: meals,
                summary: summary,
                onOpenReview: () => context.push(AppRoutes.review),
                onEditMeal: (meal) =>
                    showLogMealSheet(context, existingMeal: meal),
                onDeleteMeal: (meal) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete meal?'),
                        content: const Text('Remove this meal from today?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true || !context.mounted) return;

                  try {
                    await ref
                        .read(logMealControllerProvider.notifier)
                        .delete(meal);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not delete meal right now.'),
                      ),
                    );
                  }
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, _) => const Center(
              child: Text(
                'Could not load meals right now.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(
          child: Text(
            'Could not load your profile right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Future<void> _openCheckInFlow(
    BuildContext context,
    CheckInAvailability? availability,
  ) async {
    if (availability == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in is not ready yet.')),
      );
      return;
    }

    if (!availability.isDue || availability.period == null) {
      await showCheckInUnavailableDialog(
        context,
        nextAvailableDate: availability.nextAvailableDate,
      );
      return;
    }

    final result = await showCheckInDialog(context, availability: availability);
    if (!context.mounted || result == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Check-in saved.')));

    if (result == CheckInDialogResult.savedAndOpenProfile) {
      context.push(AppRoutes.profile);
    }
  }

  Future<void> _confirmAndResetProgress(BuildContext context) async {
    final password = await showPasswordConfirmDialog(
      context,
      title: 'Reset progress?',
      description:
          'This deletes your meals, daily summaries, check-ins, and AI usage. Your profile and login stay.',
      confirmLabel: 'Reset',
      destructive: true,
    );

    if (password == null || !context.mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .resetProgress(password: password);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress reset.')));
    } catch (error) {
      if (!context.mounted) return;
      final message = error is AccountActionException
          ? error.message
          : 'Could not reset progress right now.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.date,
    required this.profile,
    required this.meals,
    required this.summary,
    required this.onOpenReview,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final DateTime date;
  final UserProfile profile;
  final List<Meal> meals;
  final DailySummary summary;
  final VoidCallback onOpenReview;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      children: [
        _HeaderSection(date: date, name: profile.name),
        const SizedBox(height: 20),
        _MonthPreviewCard(date: date, onOpenReview: onOpenReview),
        const SizedBox(height: 16),
        _CalorieOverviewCard(summary: summary),
        const SizedBox(height: 16),
        _StatusCard(summary: summary),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Today\'s Meals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${meals.length} logged',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (meals.isEmpty)
          const _EmptyMealsState()
        else
          ..._buildMealCards(meals),
      ],
    );
  }

  List<Widget> _buildMealCards(List<Meal> meals) {
    final widgets = <Widget>[];
    for (var index = 0; index < meals.length; index++) {
      widgets.add(
        _MealCard(
          meal: meals[index],
          onEdit: () => onEditMeal(meals[index]),
          onDelete: () => onDeleteMeal(meals[index]),
        ),
      );
      if (index < meals.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.date, required this.name});

  final DateTime date;
  final String name;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMMM').format(date),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hi, $firstName',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CalorieOverviewCard extends StatelessWidget {
  const _CalorieOverviewCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final remainingCalories = summary.targetCalories - summary.totalCalories;
    final remainingLabel = remainingCalories >= 0 ? 'Remaining' : 'Over target';
    final remainingValue = remainingCalories >= 0
        ? '$remainingCalories kcal'
        : '${remainingCalories.abs()} kcal';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalCalories} logged against ${summary.targetCalories} kcal target',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Target',
                  value: '${summary.targetCalories}',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: 'Logged',
                  value: '${summary.totalCalories}',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: remainingLabel,
                  value: remainingValue,
                  highlight: remainingCalories >= 0
                      ? AppColors.primary
                      : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthPreviewCard extends ConsumerWidget {
  const _MonthPreviewCard({required this.date, required this.onOpenReview});

  final DateTime date;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final today = DateTime(date.year, date.month, date.day);
    final range = ReviewRange(startDate: startOfMonth, endDate: today);
    final summariesAsync = ref.watch(reviewSummariesProvider(range));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: summariesAsync.when(
        data: (summariesByDate) {
          final days = List.generate(
            today.day,
            (index) => DateTime(date.year, date.month, index + 1),
          );
          final summaries = days
              .map(
                (day) => summariesByDate[DateFormat('yyyy-MM-dd').format(day)],
              )
              .whereType<DailySummary>()
              .toList();
          final greenDays = summaries
              .where((summary) => summary.status == DailyStatus.green)
              .length;
          final yellowDays = summaries
              .where((summary) => summary.status == DailyStatus.yellow)
              .length;
          final redDays = summaries
              .where((summary) => summary.status == DailyStatus.red)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Month Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMMM').format(date)} so far',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenReview,
                    child: const Text('Open'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((day) {
                    final summary =
                        summariesByDate[DateFormat('yyyy-MM-dd').format(day)];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: _MonthPreviewBar(summary: summary),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summaries.isEmpty
                          ? 'No logged days yet this month.'
                          : '${summaries.length} logged days this month.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MiniStatusChip(
                    label: '$greenDays',
                    color: AppColors.veryGood,
                  ),
                  const SizedBox(width: 6),
                  _MiniStatusChip(label: '$yellowDays', color: AppColors.bad),
                  const SizedBox(width: 6),
                  _MiniStatusChip(label: '$redDays', color: AppColors.veryBad),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 148,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, _) => const SizedBox(
          height: 148,
          child: Center(
            child: Text(
              'Could not load month preview.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthPreviewBar extends StatelessWidget {
  const _MonthPreviewBar({required this.summary});

  final DailySummary? summary;

  @override
  Widget build(BuildContext context) {
    final color = summary == null
        ? AppColors.divider
        : _statusColor(summary!.status);
    final heightFactor = summary == null
        ? 0.08
        : ((summary!.totalCalories / summary!.targetCalories.clamp(1, 100000))
                      .clamp(0.15, 1.25) /
                  1.25)
              .toDouble();

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(summary.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today\'s Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.status.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _statusMessage(summary),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMealsState extends StatelessWidget {
  const _EmptyMealsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first meal to see calories and day status update automatically.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(meal.timestamp);
    final mealName = (meal.name?.trim().isNotEmpty ?? false)
        ? meal.name!.trim()
        : 'Unnamed meal';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${meal.calories.round()} kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              PopupMenuButton<_MealAction>(
                onSelected: (action) {
                  if (action == _MealAction.edit) {
                    onEdit();
                    return;
                  }
                  onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _MealAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _MealAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          if (meal.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.tags.map((tag) {
                final color = tag.isPositive
                    ? AppColors.tagPositive
                    : tag.isNeutral
                    ? AppColors.tagNeutral
                    : AppColors.tagWarning;
                final background = tag.isPositive
                    ? AppColors.tagPositiveBg
                    : tag.isNeutral
                    ? AppColors.tagNeutralBg
                    : AppColors.tagWarningBg;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (meal.note != null) ...[
            const SizedBox(height: 12),
            Text(
              meal.note!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MealAction { edit, delete }

enum _DashboardMenuAction {
  checkIn,
  profile,
  review,
  summary,
  resetProgress,
  signOut,
}

Color _statusColor(DailyStatus status) {
  return switch (status) {
    DailyStatus.green => AppColors.veryGood,
    DailyStatus.yellow => AppColors.bad,
    DailyStatus.red => AppColors.veryBad,
  };
}

String _statusMessage(DailySummary summary) {
  if (summary.mealCount == 0) {
    return 'No meals logged yet.';
  }
  if (summary.status == DailyStatus.green) {
    return 'You stayed within 10% of your calorie target today.';
  }
  if (summary.status == DailyStatus.yellow) {
    return summary.calorieDelta > 0
        ? 'You finished 10% to 20% above target today.'
        : 'You finished 10% to 20% below target today.';
  }
  return summary.calorieDelta > 0
      ? 'You finished more than 20% above target today.'
      : 'You finished more than 20% below target today.';
}

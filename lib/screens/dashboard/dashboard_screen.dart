import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/score_info_dialog.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('LeanStreak'),
        actions: [
          IconButton(
            tooltip: 'Log meal',
            onPressed: () => showLogMealSheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'More options',
            onSelected: (_DashboardMenuAction action) async {
              switch (action) {
                case _DashboardMenuAction.scoreInfo:
                  showScoreInfoDialog(context);
                case _DashboardMenuAction.history:
                  context.push(AppRoutes.history);
                case _DashboardMenuAction.weeklyReview:
                  context.push(AppRoutes.weeklyReview);
                case _DashboardMenuAction.signOut:
                  if (authState.isLoading) return;
                  await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _DashboardMenuAction.scoreInfo,
                child: Text('How scoring works'),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.history,
                child: Text('History'),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.weeklyReview,
                child: Text('Weekly Review'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.signOut,
                enabled: !authState.isLoading,
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
          final savedSummary =
              ref.watch(dailySummaryForDateProvider(dateKey)).valueOrNull;

          return mealsAsync.when(
            data: (meals) {
              final summary = savedSummary ??
                  ref.read(dailySummaryServiceProvider).buildSummary(
                        date: dateKey,
                        meals: meals,
                        dailyCalorieTarget: profile.dailyCalorieTarget,
                      );

              return _DashboardContent(
                date: today,
                profile: profile,
                meals: meals,
                summary: summary,
                onOpenScoreInfo: () => showScoreInfoDialog(context),
                onLogMeal: () => showLogMealSheet(context),
                onEditMeal: (meal) {
                  showLogMealSheet(context, existingMeal: meal);
                },
                onDeleteMeal: (meal) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete meal?'),
                        content: Text(
                          'Remove this ${meal.mealType.label.toLowerCase()} entry from today?',
                        ),
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
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.date,
    required this.profile,
    required this.meals,
    required this.summary,
    required this.onOpenScoreInfo,
    required this.onLogMeal,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final DateTime date;
  final UserProfile profile;
  final List<Meal> meals;
  final DailySummary summary;
  final VoidCallback onOpenScoreInfo;
  final VoidCallback onLogMeal;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _HeaderSection(
          date: date,
          name: profile.name,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onLogMeal,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text(
            'Log Meal',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _CalorieOverviewCard(summary: summary),
        const SizedBox(height: 16),
        _ScoreCard(
          summary: summary,
          onOpenScoreInfo: onOpenScoreInfo,
        ),
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
  const _HeaderSection({
    required this.date,
    required this.name,
  });

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
        const SizedBox(height: 8),
        const Text(
          'Your home screen shows today\'s calories, score, and what to improve next.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
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
    final remainingLabel =
        remainingCalories >= 0 ? 'Remaining' : 'Over target';
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.summary,
    required this.onOpenScoreInfo,
  });

  final DailySummary summary;
  final VoidCallback onOpenScoreInfo;

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (summary.category) {
      DailyCategory.veryGood => AppColors.veryGood,
      DailyCategory.good => AppColors.good,
      DailyCategory.bad => AppColors.bad,
      DailyCategory.veryBad => AppColors.veryBad,
    };

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
                  'Today\'s Score',
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
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.category.label,
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${summary.score}/${summary.maxScore}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onOpenScoreInfo,
                tooltip: 'How scoring works',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'How today\'s result was built:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...summary.explanation.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
            'Add your first meal to see calories, score, and category update automatically.',
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
                      meal.mealType.label,
                      style: const TextStyle(
                        fontSize: 18,
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
                  PopupMenuItem(
                    value: _MealAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _MealAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.tags.map((tag) {
              final color =
                  tag.isPositive ? AppColors.tagPositive : AppColors.tagWarning;
              final background = tag.isPositive
                  ? AppColors.tagPositiveBg
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

enum _MealAction {
  edit,
  delete,
}

enum _DashboardMenuAction {
  scoreInfo,
  history,
  weeklyReview,
  signOut,
}

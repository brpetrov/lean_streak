import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/daily_summary.dart';
import '../../meals/data/models/meal.dart';
import '../../meals/presentation/log_meal_sheet.dart';
import '../../meals/presentation/providers/log_meal_controller.dart';
import '../../meals/presentation/providers/meal_provider.dart';
import '../presentation/providers/daily_summary_provider.dart';

/// Minimal Phase 6 dashboard.
/// Phase 8 can expand this into the full home summary screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);
    final mealsAsync = ref.watch(mealsForDateProvider(dateKey));
    final summary = ref.watch(dailySummaryForDateProvider(dateKey)).valueOrNull;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('LeanStreak'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
            icon: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: mealsAsync.when(
          data: (meals) => _DashboardContent(
            date: today,
            meals: meals,
            summary: summary,
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

              final uid = ref.read(currentUidProvider);
              if (uid == null) return;

              try {
                await ref.read(logMealControllerProvider.notifier).delete(meal);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not delete meal right now.'),
                  ),
                );
              }
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => const Center(
            child: Text(
              'Could not load meals right now.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogMealSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Meal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.date,
    required this.meals,
    required this.summary,
    required this.onEditMeal,
    required this.onDeleteMeal,
  });

  final DateTime date;
  final List<Meal> meals;
  final DailySummary? summary;
  final ValueChanged<Meal> onEditMeal;
  final Future<void> Function(Meal meal) onDeleteMeal;

  @override
  Widget build(BuildContext context) {
    final totalCalories = meals.fold<double>(0, (sum, meal) {
      return sum + meal.calories;
    });

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
        const Text(
          'Today\'s Meals',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (summary != null) ...[
          _DailySummaryCard(summary: summary!),
          const SizedBox(height: 16),
        ],
        _TodaySummaryCard(
          mealCount: meals.length,
          totalCalories: totalCalories,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: meals.isEmpty
              ? const _EmptyMealsState()
              : ListView.separated(
                  itemCount: meals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _MealCard(
                      meal: meals[index],
                      onEdit: () => onEditMeal(meals[index]),
                      onDelete: () => onDeleteMeal(meals[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.mealCount,
    required this.totalCalories,
  });

  final int mealCount;
  final double totalCalories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(
              label: 'Meals logged',
              value: mealCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: AppColors.divider,
          ),
          Expanded(
            child: _SummaryValue(
              label: 'Calories today',
              value: '${totalCalories.round()} kcal',
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (summary.category) {
      DailyCategory.veryGood => AppColors.veryGood,
      DailyCategory.good => AppColors.good,
      DailyCategory.bad => AppColors.bad,
      DailyCategory.veryBad => AppColors.veryBad,
    };

    final deltaText = summary.calorieDelta == 0
        ? 'On target'
        : summary.calorieDelta > 0
            ? '+${summary.calorieDelta} kcal'
            : '${summary.calorieDelta} kcal';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
              Text(
                '${summary.score}/${summary.maxScore}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          Text(
            '${summary.totalCalories} of ${summary.targetCalories} kcal, $deltaText',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
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

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
        mainAxisSize: MainAxisSize.min,
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
            'Use the Log Meal button to add your first meal for today.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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

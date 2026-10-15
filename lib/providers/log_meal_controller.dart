import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';

class LogMealController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    Meal? existingMeal,
    String? name,
    required double calories,
    double? proteinGrams,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final repo = ref.read(mealRepositoryProvider);
      final now = DateTime.now();
      final date = existingMeal?.date ?? DateFormat('yyyy-MM-dd').format(now);
      final docRef = existingMeal == null ? repo.newMealRef(uid) : null;
      final mealName = (name?.trim().isEmpty ?? true) ? null : name!.trim();

      // Only named meals get an AI protein estimate; calorie-only entries
      // stay uncounted.
      final protein =
          proteinGrams ??
          (mealName == null
              ? null
              : await _estimateProtein(mealName, calories));

      final meal = Meal(
        id: existingMeal?.id ?? docRef!.id,
        date: date,
        timestamp: existingMeal?.timestamp ?? now,
        name: mealName,
        calories: calories,
        proteinGrams: protein,
        createdAt: existingMeal?.createdAt ?? now,
        updatedAt: now,
      );

      if (existingMeal == null) {
        await repo.addMeal(uid, meal);
      } else {
        await repo.updateMeal(uid, meal);
      }

      await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, date);
      ref.invalidate(dailySummaryRepositoryProvider);
    });
  }

  Future<double?> _estimateProtein(String name, double calories) async {
    try {
      final grams = await ref
          .read(calorieEstimateServiceProvider)
          .estimateProtein(name, calories.round());
      return grams?.toDouble();
    } catch (_) {
      // Protein is optional; never block saving the meal.
      return null;
    }
  }

  Future<void> delete(Meal meal) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      await ref.read(mealRepositoryProvider).deleteMeal(uid, meal.id);
      await ref
          .read(dailySummaryServiceProvider)
          .recomputeForDate(uid, meal.date);
      ref.invalidate(dailySummaryRepositoryProvider);
    });
  }
}

final logMealControllerProvider =
    AsyncNotifierProvider<LogMealController, void>(LogMealController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';

class LogMealController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    Meal? existingMeal,
    required double calories,
    required List<MealTag> tags,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final repo = ref.read(mealRepositoryProvider);
      final now = DateTime.now();
      final date = existingMeal?.date ?? DateFormat('yyyy-MM-dd').format(now);
      final docRef = existingMeal == null ? repo.newMealRef(uid) : null;

      final meal = Meal(
        id: existingMeal?.id ?? docRef!.id,
        date: date,
        timestamp: existingMeal?.timestamp ?? now,
        calories: calories,
        tags: tags,
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        createdAt: existingMeal?.createdAt ?? now,
        updatedAt: now,
      );

      if (existingMeal == null) {
        await repo.addMeal(uid, meal);
      } else {
        await repo.updateMeal(uid, meal);
      }

      await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, date);
    });
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
    });
  }
}

final logMealControllerProvider =
    AsyncNotifierProvider<LogMealController, void>(LogMealController.new);

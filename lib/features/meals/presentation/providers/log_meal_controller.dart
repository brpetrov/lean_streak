import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/meal.dart';
import 'meal_provider.dart';

class LogMealController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required MealType mealType,
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
      final date = DateFormat('yyyy-MM-dd').format(now);

      // Let Firestore generate a stable document ID before creating the model.
      final docRef = repo.newMealRef(uid);

      final meal = Meal(
        id: docRef.id,
        date: date,
        timestamp: now,
        mealType: mealType,
        calories: calories,
        tags: tags,
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await repo.addMeal(uid, meal);
    });
  }
}

final logMealControllerProvider =
    AsyncNotifierProvider<LogMealController, void>(LogMealController.new);

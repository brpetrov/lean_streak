import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';

class EditLimitExceededException implements Exception {
  const EditLimitExceededException();
}

final dayEditRepositoryProvider = Provider<DayEditRepository>((ref) {
  return DayEditRepository(FirebaseFirestore.instance);
});

String _currentMonthKey() => DateFormat('yyyy-MM').format(DateTime.now());

/// Streams the number of past-day calorie edits used in the current calendar
/// month for the signed-in user. Emits 0 while loading or unauthenticated.
final dayEditsThisMonthProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref
      .watch(dayEditRepositoryProvider)
      .watchCount(uid, _currentMonthKey());
});

/// Applies manual calorie adjustments to past days, enforcing the monthly
/// edit limit. The adjustment is stored as a dedicated meal so the day's
/// summary stays derived from meals (consistent with the rest of the app).
class PastDayEditController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> adjustCalories({
    required String date,
    required double delta,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final editRepo = ref.read(dayEditRepositoryProvider);
      final monthKey = _currentMonthKey();
      final used = await editRepo.fetchCount(uid, monthKey);
      if (used >= DayEditRepository.monthlyLimit) {
        throw const EditLimitExceededException();
      }

      final mealRepo = ref.read(mealRepositoryProvider);
      final now = DateTime.now();
      final docRef = mealRepo.newMealRef(uid);

      // Anchor the adjustment to the chosen day (parsed as midnight) so it
      // belongs to that date when summaries are recomputed.
      final dayTimestamp = DateTime.tryParse(date) ?? now;

      final meal = Meal(
        id: docRef.id,
        date: date,
        timestamp: dayTimestamp,
        name: delta >= 0 ? 'Calorie adjustment (+)' : 'Calorie adjustment (−)',
        calories: delta,
        tags: const [],
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await mealRepo.addMeal(uid, meal);
      await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, date);
      await editRepo.increment(uid, monthKey);

      // Refresh derived views so the calendar and day sheet reflect the change.
      ref.invalidate(dailySummaryRepositoryProvider);
      ref.invalidate(reviewSummariesProvider);
      ref.invalidate(reviewPeriodsProvider);
    });
  }
}

final pastDayEditControllerProvider =
    AsyncNotifierProvider<PastDayEditController, void>(
      PastDayEditController.new,
    );

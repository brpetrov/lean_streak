import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/check_in_provider.dart';
import 'package:lean_streak/providers/check_in_state_provider.dart';
import 'package:lean_streak/services/check_in_service.dart';

class CheckInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markPromptShown({
    required String periodKey,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    await ref
        .read(checkInRepositoryProvider)
        .markPromptShown(
          uid,
          periodKey: periodKey,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );

    ref.invalidate(currentCheckInAvailabilityProvider);
  }

  Future<CheckInRecommendationResult?> submit({
    required String periodKey,
    required DateTime periodStart,
    required DateTime periodEnd,
    required CheckInWeightTrend weightTrend,
    required CheckInDifficulty targetDifficulty,
    required CheckInHunger hunger,
    required CheckInPlanFit planFit,
    double? updatedWeightKg,
    String? recommendationReason,
  }) async {
    state = const AsyncLoading();

    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final recommendation = ref
          .read(checkInServiceProvider)
          .buildRecommendation(
            weightTrend: weightTrend,
            targetDifficulty: targetDifficulty,
            hunger: hunger,
            planFit: planFit,
            updatedWeightKg: updatedWeightKg,
          );

      final now = DateTime.now();
      final checkIn = CheckIn(
        periodKey: periodKey,
        periodStart: periodStart,
        periodEnd: periodEnd,
        weightTrend: weightTrend,
        targetDifficulty: targetDifficulty,
        hunger: hunger,
        planFit: planFit,
        recommendation: recommendation.recommendation,
        updatedWeightKg: updatedWeightKg,
        recommendationReason: recommendationReason ?? recommendation.reason,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(checkInRepositoryProvider).saveCheckIn(uid, checkIn);
      ref.invalidate(currentCheckInAvailabilityProvider);
      state = const AsyncData(null);
      return recommendation;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final checkInControllerProvider =
    AsyncNotifierProvider<CheckInController, void>(CheckInController.new);

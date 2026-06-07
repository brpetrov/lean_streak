import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/check_in_provider.dart';
import 'package:lean_streak/providers/check_in_state_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
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

      // A weight entered during the check-in flows into the shared weight
      // history and triggers the same automatic plan recalculation as an
      // ad-hoc log.
      if (updatedWeightKg != null) {
        final profile = ref.read(userProfileProvider).valueOrNull;
        if (profile != null) {
          await ref
              .read(weightLogServiceProvider)
              .logWeight(
                profile: profile,
                weightKg: updatedWeightKg,
                source: WeightSource.checkIn,
              );
        }
      }

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

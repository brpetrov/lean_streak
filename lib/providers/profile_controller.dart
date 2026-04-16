import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> saveProfile({
    required UserProfile currentProfile,
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
    required double? targetWeightKg,
    required ActivityLevel activityLevel,
    required WeightLossPace weightLossPace,
  }) async {
    state = const AsyncLoading();

    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final bmi = HealthCalculator.bmi(currentWeightKg, heightCm);
      final bmr = HealthCalculator.bmr(currentWeightKg, heightCm, age, gender);
      final tdee = HealthCalculator.tdee(bmr, activityLevel);
      final isMaintaining = weightLossPace == WeightLossPace.maintain;
      final resolvedTargetWeight = isMaintaining
          ? currentWeightKg
          : (targetWeightKg ?? currentWeightKg);
      final pace = HealthCalculator.goalPaceFromWeightLossPace(weightLossPace);
      final targetDate = isMaintaining
          ? DateTime.now()
          : HealthCalculator.targetDateFromWeightLossPace(
              currentWeightKg,
              resolvedTargetWeight,
              weightLossPace,
            );
      final paceLevel = isMaintaining
          ? GoalPaceLevel.safe
          : HealthCalculator.goalPaceLevel(pace);
      final calories = isMaintaining
          ? HealthCalculator.maintenanceCalories(tdee)
          : HealthCalculator.dailyCalorieTargetFromPace(
              tdee: tdee,
              paceKgPerWeek: pace,
              gender: gender,
            ).calories;

      final updatedProfile = currentProfile.copyWith(
        name: name.trim(),
        age: age,
        gender: gender,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        targetWeightKg: resolvedTargetWeight,
        activityLevel: activityLevel,
        weightLossPace: weightLossPace,
        targetDate: targetDate,
        bmi: bmi,
        bmr: bmr,
        tdee: tdee,
        dailyCalorieTarget: calories,
        goalPaceKgPerWeek: pace,
        goalPaceLevel: paceLevel,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(userProfileRepositoryProvider)
          .createProfile(updatedProfile);

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, today);

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

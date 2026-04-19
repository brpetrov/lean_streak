import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

final activityScaleMigrationProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;

  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return;
  if (profile.activityScaleVersion >= currentActivityScaleVersion) return;

  final migratedProfile = _migrateProfile(profile);
  await ref.read(userProfileRepositoryProvider).createProfile(migratedProfile);

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await ref.read(dailySummaryServiceProvider).recomputeForDate(uid, today);
});

UserProfile _migrateProfile(UserProfile profile) {
  final bmi = HealthCalculator.bmi(profile.currentWeightKg, profile.heightCm);
  final bmr = HealthCalculator.bmr(
    profile.currentWeightKg,
    profile.heightCm,
    profile.age,
    profile.gender,
  );
  final tdee = HealthCalculator.tdee(bmr, profile.activityLevel);
  final isMaintaining = profile.weightLossPace == WeightLossPace.maintain;
  final resolvedTargetWeight = isMaintaining
      ? profile.currentWeightKg
      : profile.targetWeightKg;
  final pace = HealthCalculator.goalPaceFromWeightLossPace(
    profile.weightLossPace,
  );
  final targetDate = isMaintaining
      ? DateTime.now()
      : HealthCalculator.targetDateFromWeightLossPace(
          profile.currentWeightKg,
          resolvedTargetWeight,
          profile.weightLossPace,
        );
  final paceLevel = isMaintaining
      ? GoalPaceLevel.safe
      : HealthCalculator.goalPaceLevel(pace);
  final calories = isMaintaining
      ? HealthCalculator.maintenanceCalories(tdee)
      : HealthCalculator.dailyCalorieTargetFromPace(
          tdee: tdee,
          paceKgPerWeek: pace,
          gender: profile.gender,
        ).calories;

  return profile.copyWith(
    targetWeightKg: resolvedTargetWeight,
    activityScaleVersion: currentActivityScaleVersion,
    targetDate: targetDate,
    bmi: bmi,
    bmr: bmr,
    tdee: tdee,
    dailyCalorieTarget: calories,
    goalPaceKgPerWeek: pace,
    goalPaceLevel: paceLevel,
    updatedAt: DateTime.now(),
  );
}

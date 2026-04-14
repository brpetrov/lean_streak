import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
    required double targetWeightKg,
    required ActivityLevel activityLevel,
    required WeightLossPace weightLossPace,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      final email = ref.read(authStateProvider).valueOrNull?.email ?? '';
      if (uid == null) throw Exception('Not authenticated');

      final pace = HealthCalculator.goalPaceFromWeightLossPace(weightLossPace);
      final targetDate = HealthCalculator.targetDateFromWeightLossPace(
          currentWeightKg, targetWeightKg, weightLossPace);

      final calcBmi = HealthCalculator.bmi(currentWeightKg, heightCm);
      final calcBmr =
          HealthCalculator.bmr(currentWeightKg, heightCm, age, gender);
      final calcTdee = HealthCalculator.tdee(calcBmr, activityLevel);
      final paceLevel = HealthCalculator.goalPaceLevel(pace);
      final (:calories, clamped: _) =
          HealthCalculator.dailyCalorieTargetFromPace(
        tdee: calcTdee,
        paceKgPerWeek: pace,
        gender: gender,
      );

      final now = DateTime.now();
      final profile = UserProfile(
        uid: uid,
        email: email,
        name: name.trim(),
        age: age,
        gender: gender,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        activityLevel: activityLevel,
        weightLossPace: weightLossPace,
        targetDate: targetDate,
        bmi: calcBmi,
        bmr: calcBmr,
        tdee: calcTdee,
        dailyCalorieTarget: calories,
        goalPaceKgPerWeek: pace,
        goalPaceLevel: paceLevel,
        onboardingCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(userProfileRepositoryProvider).createProfile(profile);
    });
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(
  OnboardingController.new,
);

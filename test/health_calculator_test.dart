import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';

void main() {
  group('activity multipliers', () {
    test('uses daily movement plus structured training', () {
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.sedentary),
        1.25,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.lightlyActive),
        1.35,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.moderatelyActive),
        1.45,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.veryActive),
        1.60,
      );
      expect(
        HealthCalculator.activityMultiplier(
          ActivityLevel.sedentary,
          TrainingFrequency.threeToFour,
        ),
        1.35,
      );
      expect(
        HealthCalculator.activityMultiplier(
          ActivityLevel.veryActive,
          TrainingFrequency.fivePlus,
        ),
        1.75,
      );
    });
  });

  group('activity level parsing', () {
    test('maps legacy stored values to the new 4-level scale', () {
      expect(ActivityLevel.fromString('light'), ActivityLevel.sedentary);
      expect(ActivityLevel.fromString('medium'), ActivityLevel.lightlyActive);
      expect(ActivityLevel.fromString('hard'), ActivityLevel.moderatelyActive);
    });

    test('parses new stored values', () {
      expect(ActivityLevel.fromString('sedentary'), ActivityLevel.sedentary);
      expect(
        ActivityLevel.fromString('lightly_active'),
        ActivityLevel.lightlyActive,
      );
      expect(
        ActivityLevel.fromString('moderately_active'),
        ActivityLevel.moderatelyActive,
      );
      expect(ActivityLevel.fromString('very_active'), ActivityLevel.veryActive);
    });

    test('defaults old activity-only profiles to matching training levels', () {
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.sedentary),
        TrainingFrequency.none,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.lightlyActive),
        TrainingFrequency.oneToTwo,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.moderatelyActive),
        TrainingFrequency.threeToFour,
      );
      expect(
        TrainingFrequency.legacyDefaultFor(ActivityLevel.veryActive),
        TrainingFrequency.fivePlus,
      );
    });
  });

  group('health plan calculation', () {
    test('activity changes maintenance and target when not clamped', () {
      final sedentary = HealthCalculator.calculatePlan(
        currentWeightKg: 100,
        targetWeightKg: 90,
        heightCm: 180,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.sedentary,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.slow,
        now: DateTime(2026, 4, 21),
      );
      final lightlyActive = HealthCalculator.calculatePlan(
        currentWeightKg: 100,
        targetWeightKg: 90,
        heightCm: 180,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.lightlyActive,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.slow,
        now: DateTime(2026, 4, 21),
      );

      expect(sedentary.bmr, closeTo(1980, 0.001));
      expect(sedentary.tdee, closeTo(2475, 0.001));
      expect(lightlyActive.tdee, closeTo(2673, 0.001));
      expect(sedentary.dailyCalorieTarget, closeTo(2200, 0.001));
      expect(lightlyActive.dailyCalorieTarget, closeTo(2398, 0.001));
      expect(sedentary.calorieTargetClamped, isFalse);
      expect(lightlyActive.calorieTargetClamped, isFalse);
    });

    test(
      'slow pace stays moderate for a sedentary lower-maintenance woman',
      () {
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 72,
          targetWeightKg: 65,
          heightCm: 165,
          age: 27,
          gender: Gender.female,
          activityLevel: ActivityLevel.sedentary,
          trainingFrequency: TrainingFrequency.none,
          weightLossPace: WeightLossPace.slow,
          now: DateTime(2026, 4, 21),
        );

        expect(plan.bmr, closeTo(1455.25, 0.001));
        expect(plan.tdee, closeTo(1819.0625, 0.001));
        expect(plan.dailyCalorieTarget, closeTo(1544.0625, 0.001));
        expect(plan.goalPaceKgPerWeek, closeTo(0.25, 0.001));
        expect(plan.targetDate, DateTime(2026, 11, 3));
        expect(plan.calorieTargetClamped, isFalse);
        expect(plan.goalPaceLevel, GoalPaceLevel.safe);
      },
    );

    test('floor can keep target equal while activity still changes TDEE', () {
      final sedentary = HealthCalculator.calculatePlan(
        currentWeightKg: 60,
        targetWeightKg: 50,
        heightCm: 160,
        age: 30,
        gender: Gender.female,
        activityLevel: ActivityLevel.sedentary,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.fast,
        now: DateTime(2026, 4, 21),
      );
      final lightlyActive = HealthCalculator.calculatePlan(
        currentWeightKg: 60,
        targetWeightKg: 50,
        heightCm: 160,
        age: 30,
        gender: Gender.female,
        activityLevel: ActivityLevel.lightlyActive,
        trainingFrequency: TrainingFrequency.none,
        weightLossPace: WeightLossPace.fast,
        now: DateTime(2026, 4, 21),
      );

      expect(sedentary.tdee, isNot(lightlyActive.tdee));
      expect(sedentary.dailyCalorieTarget, 1200);
      expect(lightlyActive.dailyCalorieTarget, 1200);
      expect(sedentary.calorieTargetClamped, isTrue);
      expect(lightlyActive.calorieTargetClamped, isTrue);
      expect(sedentary.goalPaceLevel, GoalPaceLevel.warning);
      expect(lightlyActive.goalPaceLevel, GoalPaceLevel.warning);
      expect(sedentary.goalPaceKgPerWeek, closeTo(0.374, 0.001));
      expect(lightlyActive.goalPaceKgPerWeek, closeTo(0.491, 0.001));
    });

    test(
      'desk lifestyle with regular training does not use old moderate TDEE',
      () {
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 80,
          targetWeightKg: 73,
          heightCm: 170,
          age: 29,
          gender: Gender.male,
          activityLevel: ActivityLevel.sedentary,
          trainingFrequency: TrainingFrequency.threeToFour,
          weightLossPace: WeightLossPace.fast,
          now: DateTime(2026, 4, 21),
        );

        expect(plan.bmr, closeTo(1722.5, 0.001));
        expect(plan.activityMultiplier, closeTo(1.35, 0.001));
        expect(plan.tdee, closeTo(2325.375, 0.001));
        expect(plan.dailyCalorieTarget, closeTo(1500.375, 0.001));
        expect(plan.calorieTargetClamped, isFalse);
      },
    );

    test(
      'maintain uses current weight, maintenance calories, and no deficit',
      () {
        final now = DateTime(2026, 4, 21);
        final plan = HealthCalculator.calculatePlan(
          currentWeightKg: 80,
          targetWeightKg: null,
          heightCm: 170,
          age: 30,
          gender: Gender.female,
          activityLevel: ActivityLevel.lightlyActive,
          trainingFrequency: TrainingFrequency.none,
          weightLossPace: WeightLossPace.maintain,
          now: now,
        );

        expect(plan.isMaintaining, isTrue);
        expect(plan.targetWeightKg, 80);
        expect(plan.goalPaceKgPerWeek, 0);
        expect(plan.targetDate, now);
        expect(plan.dailyCalorieTarget, plan.tdee);
        expect(plan.calorieTargetClamped, isFalse);
      },
    );

    test('maintain target date does not divide by zero', () {
      final now = DateTime(2026, 4, 21);

      expect(
        HealthCalculator.targetDateFromWeightLossPace(
          80,
          70,
          WeightLossPace.maintain,
          now: now,
        ),
        now,
      );
    });
  });
}

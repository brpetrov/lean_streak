import 'package:lean_streak/models/user_profile.dart';

/// Pure functions for health and calorie calculations.
///
/// All formulas are defined in the build spec (Section 9).
class HealthCalculator {
  HealthCalculator._();

  /// BMI = weight(kg) / height(m)^2
  static double bmi(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Male:   BMR = 10w + 6.25h - 5a + 5
  /// Female: BMR = 10w + 6.25h - 5a - 161
  /// Other:  average of male and female offsets (-78)
  static double bmr(double weightKg, double heightCm, int age, Gender gender) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78,
    };
  }

  /// Converts general daily movement to a base TDEE multiplier.
  static double lifestyleMultiplier(ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => 1.25,
      ActivityLevel.lightlyActive => 1.35,
      ActivityLevel.moderatelyActive => 1.45,
      ActivityLevel.veryActive => 1.60,
    };
  }

  /// Adds structured training on top of the user's normal daily movement.
  static double trainingMultiplierBonus(TrainingFrequency frequency) {
    return switch (frequency) {
      TrainingFrequency.none => 0.0,
      TrainingFrequency.oneToTwo => 0.05,
      TrainingFrequency.threeToFour => 0.10,
      TrainingFrequency.fivePlus => 0.15,
    };
  }

  static double activityMultiplier(
    ActivityLevel level, [
    TrainingFrequency trainingFrequency = TrainingFrequency.none,
  ]) {
    final combined =
        lifestyleMultiplier(level) + trainingMultiplierBonus(trainingFrequency);
    return combined.clamp(1.20, 1.75).toDouble();
  }

  static double tdee(
    double bmr,
    ActivityLevel level, [
    TrainingFrequency trainingFrequency = TrainingFrequency.none,
  ]) {
    return bmr * activityMultiplier(level, trainingFrequency);
  }

  static double maintenanceCalories(double tdee) {
    return tdee;
  }

  /// Converts the user's chosen weight-loss pace to kg/week.
  static double goalPaceFromWeightLossPace(WeightLossPace pace) {
    return switch (pace) {
      WeightLossPace.slow => 0.25,
      WeightLossPace.moderate => 0.50,
      WeightLossPace.fast => 0.75,
      WeightLossPace.maintain => 0.0,
    };
  }

  static DateTime targetDateFromPaceKgPerWeek(
    double currentWeightKg,
    double targetWeightKg,
    double paceKgPerWeek, {
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final totalKgToLose = (currentWeightKg - targetWeightKg).clamp(
      0,
      double.infinity,
    );
    if (paceKgPerWeek <= 0 || totalKgToLose <= 0) return anchor;
    final daysNeeded = ((totalKgToLose / paceKgPerWeek) * 7).ceil();
    return DateTime(anchor.year, anchor.month, anchor.day + daysNeeded);
  }

  /// Calculates the estimated target date from the user's chosen pace.
  static DateTime targetDateFromWeightLossPace(
    double currentWeightKg,
    double targetWeightKg,
    WeightLossPace pace, {
    DateTime? now,
  }) {
    return targetDateFromPaceKgPerWeek(
      currentWeightKg,
      targetWeightKg,
      goalPaceFromWeightLossPace(pace),
      now: now,
    );
  }

  /// <= 0.50 kg/week -> safe
  /// <= 0.75 kg/week -> caution
  /// > 0.75 kg/week -> warning
  static GoalPaceLevel goalPaceLevel(double kgPerWeek) {
    if (kgPerWeek <= 0.50) return GoalPaceLevel.safe;
    if (kgPerWeek <= 0.75) return GoalPaceLevel.caution;
    return GoalPaceLevel.warning;
  }

  static double calorieFloor(Gender gender) {
    return switch (gender) {
      Gender.male => 1500,
      Gender.female => 1200,
      Gender.other => 1350,
    };
  }

  /// 1 kg fat ~= 7700 kcal -> daily deficit = pace * 1100
  static ({double calories, bool clamped}) dailyCalorieTargetFromPace({
    required double tdee,
    required double paceKgPerWeek,
    required Gender gender,
  }) {
    final dailyDeficit = paceKgPerWeek * 1100;
    final raw = tdee - dailyDeficit;
    final floor = calorieFloor(gender);
    if (raw < floor) return (calories: floor, clamped: true);
    return (calories: raw, clamped: false);
  }

  static double effectivePaceKgPerWeek({
    required double tdee,
    required double dailyCalorieTarget,
  }) {
    final dailyDeficit = (tdee - dailyCalorieTarget)
        .clamp(0, double.infinity)
        .toDouble();
    return dailyDeficit / 1100;
  }

  static HealthPlanCalculation calculatePlan({
    required double currentWeightKg,
    required double? targetWeightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required TrainingFrequency trainingFrequency,
    required WeightLossPace weightLossPace,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final calcBmi = bmi(currentWeightKg, heightCm);
    final calcBmr = bmr(currentWeightKg, heightCm, age, gender);
    final lifestyle = lifestyleMultiplier(activityLevel);
    final trainingBonus = trainingMultiplierBonus(trainingFrequency);
    final multiplier = activityMultiplier(activityLevel, trainingFrequency);
    final calcTdee = tdee(calcBmr, activityLevel, trainingFrequency);
    final isMaintaining = weightLossPace == WeightLossPace.maintain;
    final resolvedTargetWeight = isMaintaining
        ? currentWeightKg
        : (targetWeightKg ?? currentWeightKg);
    final requestedPace = goalPaceFromWeightLossPace(weightLossPace);
    final calorieResult = isMaintaining
        ? (calories: maintenanceCalories(calcTdee), clamped: false)
        : dailyCalorieTargetFromPace(
            tdee: calcTdee,
            paceKgPerWeek: requestedPace,
            gender: gender,
          );
    final effectivePace = isMaintaining
        ? 0.0
        : effectivePaceKgPerWeek(
            tdee: calcTdee,
            dailyCalorieTarget: calorieResult.calories,
          );
    final calcTargetDate = isMaintaining
        ? anchor
        : targetDateFromPaceKgPerWeek(
            currentWeightKg,
            resolvedTargetWeight,
            effectivePace,
            now: anchor,
          );
    final paceLevel = isMaintaining
        ? GoalPaceLevel.safe
        : calorieResult.clamped
        ? GoalPaceLevel.warning
        : goalPaceLevel(requestedPace);

    return HealthPlanCalculation(
      bmi: calcBmi,
      bmr: calcBmr,
      lifestyleMultiplier: lifestyle,
      trainingMultiplierBonus: trainingBonus,
      activityMultiplier: multiplier,
      tdee: calcTdee,
      dailyCalorieTarget: calorieResult.calories,
      calorieTargetClamped: calorieResult.clamped,
      goalPaceKgPerWeek: effectivePace,
      goalPaceLevel: paceLevel,
      targetWeightKg: resolvedTargetWeight,
      targetDate: calcTargetDate,
      isMaintaining: isMaintaining,
    );
  }
}

class HealthPlanCalculation {
  const HealthPlanCalculation({
    required this.bmi,
    required this.bmr,
    required this.lifestyleMultiplier,
    required this.trainingMultiplierBonus,
    required this.activityMultiplier,
    required this.tdee,
    required this.dailyCalorieTarget,
    required this.calorieTargetClamped,
    required this.goalPaceKgPerWeek,
    required this.goalPaceLevel,
    required this.targetWeightKg,
    required this.targetDate,
    required this.isMaintaining,
  });

  final double bmi;
  final double bmr;
  final double lifestyleMultiplier;
  final double trainingMultiplierBonus;
  final double activityMultiplier;
  final double tdee;
  final double dailyCalorieTarget;
  final bool calorieTargetClamped;
  final double goalPaceKgPerWeek;
  final GoalPaceLevel goalPaceLevel;
  final double targetWeightKg;
  final DateTime targetDate;
  final bool isMaintaining;
}

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

  /// Converts physical activity level to a TDEE multiplier.
  static double activityMultiplier(ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => 1.20,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
    };
  }

  static double tdee(double bmr, ActivityLevel level) {
    return bmr * activityMultiplier(level);
  }

  static double maintenanceCalories(double tdee) {
    return tdee;
  }

  /// Converts the user's chosen weight-loss pace to kg/week.
  static double goalPaceFromWeightLossPace(WeightLossPace pace) {
    return switch (pace) {
      WeightLossPace.slow => 0.50,
      WeightLossPace.moderate => 0.75,
      WeightLossPace.fast => 1.00,
      WeightLossPace.maintain => 0.0,
    };
  }

  /// Calculates the estimated target date from the user's chosen pace.
  static DateTime targetDateFromWeightLossPace(
    double currentWeightKg,
    double targetWeightKg,
    WeightLossPace pace,
  ) {
    final paceKgPerWeek = goalPaceFromWeightLossPace(pace);
    final totalKgToLose = (currentWeightKg - targetWeightKg).clamp(
      0,
      double.infinity,
    );
    final daysNeeded = ((totalKgToLose / paceKgPerWeek) * 7).ceil();
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// <= 0.75 kg/week -> safe
  /// <= 1.00 kg/week -> caution
  /// > 1.00 kg/week -> warning
  static GoalPaceLevel goalPaceLevel(double kgPerWeek) {
    if (kgPerWeek <= 0.75) return GoalPaceLevel.safe;
    if (kgPerWeek <= 1.00) return GoalPaceLevel.caution;
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
}

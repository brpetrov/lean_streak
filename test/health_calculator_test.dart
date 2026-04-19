import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';

void main() {
  group('activity multipliers', () {
    test('uses the 4-level activity scale', () {
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.sedentary),
        1.20,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.lightlyActive),
        1.375,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.moderatelyActive),
        1.55,
      );
      expect(
        HealthCalculator.activityMultiplier(ActivityLevel.veryActive),
        1.725,
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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/helpers/weight_reminder.dart';

void main() {
  group('nextWeightReminder', () {
    test('is seven days after the weigh-in, at 09:00', () {
      expect(
        nextWeightReminder(
          lastWeighIn: DateTime(2026, 6, 1, 18, 30),
          now: DateTime(2026, 6, 2),
        ),
        DateTime(2026, 6, 8, 9),
      );
    });

    test('rolls forward in whole weeks when overdue', () {
      expect(
        nextWeightReminder(
          lastWeighIn: DateTime(2026, 6, 1),
          now: DateTime(2026, 6, 20, 10),
        ),
        DateTime(2026, 6, 22, 9),
      );
    });

    test('the due day counts until 09:00 has passed', () {
      expect(
        nextWeightReminder(
          lastWeighIn: DateTime(2026, 6, 1),
          now: DateTime(2026, 6, 8, 8, 59),
        ),
        DateTime(2026, 6, 8, 9),
      );
      expect(
        nextWeightReminder(
          lastWeighIn: DateTime(2026, 6, 1),
          now: DateTime(2026, 6, 8, 9),
        ),
        DateTime(2026, 6, 15, 9),
      );
    });

    test('crosses a month end', () {
      expect(
        nextWeightReminder(
          lastWeighIn: DateTime(2026, 6, 27),
          now: DateTime(2026, 6, 28),
        ),
        DateTime(2026, 7, 4, 9),
      );
    });
  });

  group('launch actions', () {
    test('maps widget and shortcut URIs', () {
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/voice')),
        LaunchAction.voiceLog,
      );
      expect(
        launchActionForUri(Uri.parse('leanstreak://log/weight')),
        LaunchAction.logWeight,
      );
      expect(launchActionForUri(Uri.parse('leanstreak://other')), isNull);
      expect(launchActionForUri(null), isNull);
    });

    test('maps notification payloads', () {
      expect(launchActionForPayload('log_weight'), LaunchAction.logWeight);
      expect(launchActionForPayload('log_meals'), isNull);
      expect(launchActionForPayload(null), isNull);
    });
  });
}

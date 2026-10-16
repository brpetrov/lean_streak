import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';

class _FakeWeightLogController extends WeightLogController {
  int resets = 0;

  @override
  Future<bool> resetHistory() async {
    resets++;
    return true;
  }
}

WeightEntry _entry(String day, double kg) => WeightEntry(
  dateKey: day,
  weightKg: kg,
  loggedAt: DateTime.parse(day),
  source: WeightSource.manual,
);

void main() {
  testWidgets('Reset progress asks first, then clears the weight history', (
    tester,
  ) async {
    final controller = _FakeWeightLogController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _entry('2026-10-01', 86.0),
              _entry('2026-10-08', 85.2),
            ]),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(null),
          ),
          weightLogControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reset progress'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.resets, 0);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(controller.resets, 1);
    expect(find.text('Weight history cleared.'), findsOneWidget);
  });
}

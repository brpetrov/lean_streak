import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_card.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

class _FakeLogMealController extends LogMealController {
  final saved = <({String? name, double calories, double? protein})>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? name,
    required double calories,
    double? proteinGrams,
    required List<MealTag> tags,
    String? note,
  }) async {
    saved.add((name: name, calories: calories, protein: proteinGrams));
  }
}

class _FakeEstimateService implements CalorieEstimateService {
  int estimateCalls = 0;

  @override
  Future<CalorieEstimate> estimate(String uid, String description) async {
    estimateCalls++;
    return (kcal: 520, protein: 32, note: 'Typical wrap.');
  }

  @override
  Future<VoiceMealParsed> parseVoice(String transcript) async =>
      (name: 'Lunch', kcal: 400, protein: null);

  @override
  Future<int?> estimateProtein(String name, int kcal) async => 30;
}

void main() {
  late _FakeLogMealController controller;
  late _FakeEstimateService estimateService;

  Future<void> pumpCard(WidgetTester tester) async {
    controller = _FakeLogMealController();
    estimateService = _FakeEstimateService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logMealControllerProvider.overrideWith(() => controller),
          calorieEstimateServiceProvider.overrideWithValue(estimateService),
          currentUidProvider.overrideWithValue('user-1'),
        ],
        child: const MaterialApp(home: Scaffold(body: QuickLogCard())),
      ),
    );
  }

  String boxText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('saves typed name and calories without calling the AI', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), 'chicken wrap 450');
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();

    // Protein for typed meals is filled in by the controller, not the box.
    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: null),
    ]);
    expect(estimateService.estimateCalls, 0);
    expect(boxText(tester), isEmpty);
  });

  testWidgets('estimates calories when none are typed, then waits for Save', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), 'chicken wrap');
    await tester.pump();

    await tester.tap(find.text('Estimate'));
    await tester.pump();
    await tester.pump();

    expect(boxText(tester), 'chicken wrap 520 kcal 32g protein');
    expect(find.text('Chicken wrap · 520 kcal · 32 g protein'), findsOneWidget);
    expect(find.text('Typical wrap.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(controller.saved, isEmpty);
  });

  testWidgets('keyboard done saves when calories are present', (tester) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), '450 kcal porridge');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.saved, [
      (name: 'Porridge', calories: 450.0, protein: null),
    ]);
  });

  testWidgets('saves protein typed into the box', (tester) async {
    await pumpCard(tester);
    await tester.enterText(
      find.byType(TextField),
      'chicken wrap 450 35g protein',
    );
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal · 35 g protein'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 35.0),
    ]);
  });
}

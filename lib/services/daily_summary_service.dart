import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';

class DailySummaryService {
  DailySummaryService({
    required MealRepository mealRepository,
    required UserProfileRepository userProfileRepository,
    required DailySummaryRepository dailySummaryRepository,
  }) : _mealRepository = mealRepository,
       _userProfileRepository = userProfileRepository,
       _dailySummaryRepository = dailySummaryRepository;

  final MealRepository _mealRepository;
  final UserProfileRepository _userProfileRepository;
  final DailySummaryRepository _dailySummaryRepository;

  Future<void> recomputeForDate(String uid, String date) async {
    final profile = await _userProfileRepository.fetchProfile(uid);
    if (profile == null) {
      throw Exception('User profile not found');
    }

    final meals = await _mealRepository.fetchMealsForDate(uid, date);
    if (meals.isEmpty) {
      await _dailySummaryRepository.deleteSummary(uid, date);
      return;
    }

    final summary = buildSummary(
      date: date,
      meals: meals,
      dailyCalorieTarget: profile.dailyCalorieTarget,
    );

    await _dailySummaryRepository.saveSummary(uid, summary);
  }

  DailySummary buildSummary({
    required String date,
    required List<Meal> meals,
    required double dailyCalorieTarget,
  }) {
    final targetCalories = dailyCalorieTarget.round();

    final totalCalories = meals.fold<int>(0, (sum, meal) {
      return sum + meal.calories.round();
    });
    final calorieDelta = totalCalories - targetCalories;
    final tagCounts = _buildTagCounts(meals);

    return DailySummary(
      date: date,
      totalCalories: totalCalories,
      targetCalories: targetCalories,
      calorieDelta: calorieDelta,
      mealCount: meals.length,
      tagCounts: tagCounts,
      status: _statusForCalories(
        totalCalories: totalCalories,
        targetCalories: targetCalories,
      ),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, int> _buildTagCounts(List<Meal> meals) {
    final counts = <String, int>{};

    for (final meal in meals) {
      for (final tag in meal.tags) {
        counts[tag.value] = (counts[tag.value] ?? 0) + 1;
      }
    }

    return counts;
  }

  DailyStatus _statusForCalories({
    required int totalCalories,
    required int targetCalories,
  }) {
    if (targetCalories <= 0) return DailyStatus.red;

    final ratio = (totalCalories - targetCalories).abs() / targetCalories;
    if (ratio <= 0.10) return DailyStatus.green;
    if (ratio <= 0.20) return DailyStatus.yellow;
    return DailyStatus.red;
  }
}

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
  })  : _mealRepository = mealRepository,
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

    if (meals.isEmpty) {
      return DailySummary(
        date: date,
        totalCalories: 0,
        targetCalories: targetCalories,
        calorieDelta: -targetCalories,
        mealCount: 0,
        tagCounts: const {},
        score: 0,
        maxScore: 10,
        category: DailyCategory.veryBad,
        explanation: const ['No meals logged'],
        updatedAt: DateTime.now(),
      );
    }

    final totalCalories = meals.fold<int>(0, (sum, meal) {
      return sum + meal.calories.round();
    });
    final calorieDelta = totalCalories - targetCalories;
    final calorieRatio =
        targetCalories == 0 ? 0.0 : totalCalories / targetCalories;
    final tagCounts = _buildTagCounts(meals);
    final explanation = <String>[];
    var score = 5;

    if ((calorieRatio - 1).abs() <= 0.05) {
      score += 2;
      explanation.add('Stayed close to calorie target');
    } else if ((calorieRatio - 1).abs() <= 0.10) {
      score += 1;
      explanation.add('Stayed fairly close to calorie target');
    } else if (calorieRatio > 1.10 && calorieRatio <= 1.20) {
      score -= 1;
      explanation.add('Went moderately above calorie target');
    } else if (calorieRatio > 1.20) {
      score -= 2;
      explanation.add('Went well above calorie target');
    } else if (calorieRatio < 0.75) {
      score -= 1;
      explanation.add('Ate well below calorie target');
    } else {
      explanation.add('Calories were off target, but not enough to change the score');
    }

    if ((tagCounts[MealTag.highProtein.value] ?? 0) >= 1) {
      score += 1;
      explanation.add('Included at least one high protein meal');
    }

    if ((tagCounts[MealTag.balanced.value] ?? 0) >= 1) {
      score += 1;
      explanation.add('Included at least one balanced meal');
    }

    if ((tagCounts[MealTag.fruitVeg.value] ?? 0) >= 2) {
      score += 1;
      explanation.add('Included fruit and veg more than once');
    }

    if ((tagCounts[MealTag.overate.value] ?? 0) >= 1) {
      score -= 2;
      explanation.add('Had an overeating meal');
    }

    if ((tagCounts[MealTag.processed.value] ?? 0) >= 2) {
      score -= 1;
      explanation.add('Processed meals showed up multiple times');
    }

    if ((tagCounts[MealTag.sugary.value] ?? 0) >= 2) {
      score -= 1;
      explanation.add('Sugary meals showed up multiple times');
    }

    if ((tagCounts[MealTag.alcohol.value] ?? 0) >= 1 &&
        (tagCounts[MealTag.overate.value] ?? 0) >= 1) {
      score -= 1;
      explanation.add('Alcohol and overeating happened on the same day');
    }

    final clampedScore = score.clamp(0, 10);

    return DailySummary(
      date: date,
      totalCalories: totalCalories,
      targetCalories: targetCalories,
      calorieDelta: calorieDelta,
      mealCount: meals.length,
      tagCounts: tagCounts,
      score: clampedScore,
      maxScore: 10,
      category: _categoryForScore(clampedScore),
      explanation: explanation,
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

  DailyCategory _categoryForScore(int score) {
    if (score >= 8) return DailyCategory.veryGood;
    if (score >= 6) return DailyCategory.good;
    if (score >= 3) return DailyCategory.bad;
    return DailyCategory.veryBad;
  }
}

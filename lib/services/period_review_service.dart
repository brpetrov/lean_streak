import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/period_review.dart';

class PeriodReviewService {
  PeriodReview buildReview({
    required DateTime startDate,
    required DateTime endDate,
    required List<DailySummary> summaries,
    List<CheckIn> checkIns = const [],
  }) {
    final sortedSummaries = [...summaries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final sortedCheckIns = [...checkIns]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    final daysInPeriod = endDate.difference(startDate).inDays + 1;
    final loggedDays = sortedSummaries.length;
    final totalCalories = sortedSummaries.fold<int>(
      0,
      (sum, summary) => sum + summary.totalCalories,
    );
    final totalMeals = sortedSummaries.fold<int>(
      0,
      (sum, summary) => sum + summary.mealCount,
    );
    final averageCaloriesPerDay = daysInPeriod == 0
        ? 0.0
        : totalCalories / daysInPeriod.toDouble();

    final greenDays = sortedSummaries
        .where((summary) => summary.status == DailyStatus.green)
        .length;
    final yellowDays = sortedSummaries
        .where((summary) => summary.status == DailyStatus.yellow)
        .length;
    final redDays = sortedSummaries
        .where((summary) => summary.status == DailyStatus.red)
        .length;
    final calorieConsistencyRate = loggedDays == 0
        ? 0.0
        : greenDays / loggedDays.toDouble();

    final aggregatedTags = <String, int>{};
    for (final summary in sortedSummaries) {
      for (final entry in summary.tagCounts.entries) {
        aggregatedTags[entry.key] =
            (aggregatedTags[entry.key] ?? 0) + entry.value;
      }
    }

    final bestDay = sortedSummaries.isEmpty
        ? null
        : sortedSummaries.reduce((best, current) {
            if (current.deltaRatio < best.deltaRatio) return current;
            return current.date.compareTo(best.date) > 0 ? current : best;
          });
    final worstDay = sortedSummaries.isEmpty
        ? null
        : sortedSummaries.reduce((worst, current) {
            if (current.deltaRatio > worst.deltaRatio) return current;
            return current.date.compareTo(worst.date) > 0 ? current : worst;
          });

    return PeriodReview(
      startDate: startDate,
      endDate: endDate,
      daysInPeriod: daysInPeriod,
      loggedDays: loggedDays,
      summaries: sortedSummaries,
      totalCalories: totalCalories,
      averageCaloriesPerDay: averageCaloriesPerDay,
      totalMeals: totalMeals,
      greenDays: greenDays,
      yellowDays: yellowDays,
      redDays: redDays,
      calorieConsistencyRate: calorieConsistencyRate,
      bestDay: bestDay,
      worstDay: worstDay,
      topHelpfulTags: _topTags(aggregatedTags, positive: true),
      topRiskyTags: _topTags(aggregatedTags, positive: false),
      checkIns: sortedCheckIns,
      guidance: _buildGuidance(
        calorieConsistencyRate: calorieConsistencyRate,
        daysInPeriod: daysInPeriod,
        loggedDays: loggedDays,
        aggregatedTags: aggregatedTags,
      ),
    );
  }

  List<PeriodTagCount> _topTags(
    Map<String, int> tagCounts, {
    required bool positive,
  }) {
    final tags =
        tagCounts.entries
            .where((entry) {
              final tag = MealTag.values.cast<MealTag?>().firstWhere(
                (value) => value?.value == entry.key,
                orElse: () => null,
              );
              return tag != null &&
                  (positive
                      ? tag.tone == MealTagTone.healthy
                      : tag.tone == MealTagTone.unhealthy);
            })
            .map((entry) {
              final tag = MealTag.fromString(entry.key);
              return PeriodTagCount(
                key: entry.key,
                label: tag.label,
                count: entry.value,
              );
            })
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return tags.take(3).toList();
  }

  List<String> _buildGuidance({
    required double calorieConsistencyRate,
    required int daysInPeriod,
    required int loggedDays,
    required Map<String, int> aggregatedTags,
  }) {
    final guidance = <String>[];

    if (calorieConsistencyRate >= 0.70) {
      guidance.add('Most logged days stayed close to target.');
    } else if (calorieConsistencyRate >= 0.40) {
      guidance.add(
        'Some logged days stayed close to target. Tightening a few outliers will help.',
      );
    } else {
      guidance.add('Most logged days were well above or below target.');
    }

    if ((aggregatedTags[MealTag.highProtein.value] ?? 0) >= 3) {
      guidance.add('High protein choices showed up often.');
    }

    if ((aggregatedTags[MealTag.fruitVeg.value] ?? 0) >= 4) {
      guidance.add('Fruit and veg showed up consistently.');
    }

    if ((aggregatedTags[MealTag.sugary.value] ?? 0) >= 3 ||
        (aggregatedTags[MealTag.processed.value] ?? 0) >= 3 ||
        (aggregatedTags[MealTag.fried.value] ?? 0) >= 3) {
      guidance.add(
        'High sugar, fried, or highly processed meals were frequent.',
      );
    }

    final minimumLoggedDays = daysInPeriod <= 7
        ? 4
        : (daysInPeriod * 0.5).ceil();
    if (loggedDays < minimumLoggedDays) {
      guidance.add(
        'Logging was inconsistent. More complete logging will make the review more useful.',
      );
    }

    return guidance.take(4).toList();
  }
}

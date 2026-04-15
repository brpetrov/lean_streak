import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/period_review.dart';

class PeriodReviewService {
  PeriodReview buildReview({
    required DateTime startDate,
    required DateTime endDate,
    required List<DailySummary> summaries,
  }) {
    final sortedSummaries = [...summaries]
      ..sort((a, b) => a.date.compareTo(b.date));
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
    final averageScore = loggedDays == 0
        ? 0.0
        : sortedSummaries.fold<int>(0, (sum, summary) => sum + summary.score) /
              loggedDays.toDouble();
    final averageCaloriesPerDay = daysInPeriod == 0
        ? 0.0
        : totalCalories / daysInPeriod.toDouble();
    final categoryCounts = <DailyCategory, int>{
      for (final category in DailyCategory.values) category: 0,
    };
    final aggregatedTags = <String, int>{};

    for (final summary in sortedSummaries) {
      categoryCounts[summary.category] =
          (categoryCounts[summary.category] ?? 0) + 1;

      for (final entry in summary.tagCounts.entries) {
        aggregatedTags[entry.key] =
            (aggregatedTags[entry.key] ?? 0) + entry.value;
      }
    }

    final bestDay = sortedSummaries.isEmpty
        ? null
        : sortedSummaries.reduce((best, current) {
            if (current.score > best.score) return current;
            return current.date.compareTo(best.date) > 0 ? current : best;
          });
    final worstDay = sortedSummaries.isEmpty
        ? null
        : sortedSummaries.reduce((worst, current) {
            if (current.score < worst.score) return current;
            return current.date.compareTo(worst.date) > 0 ? current : worst;
          });

    final topHelpfulTags = _topTags(aggregatedTags, positive: true);
    final topRiskyTags = _topTags(aggregatedTags, positive: false);
    final guidance = _buildGuidance(
      averageScore: averageScore,
      daysInPeriod: daysInPeriod,
      loggedDays: loggedDays,
      aggregatedTags: aggregatedTags,
    );

    return PeriodReview(
      startDate: startDate,
      endDate: endDate,
      daysInPeriod: daysInPeriod,
      loggedDays: loggedDays,
      summaries: sortedSummaries,
      averageScore: averageScore,
      totalCalories: totalCalories,
      averageCaloriesPerDay: averageCaloriesPerDay,
      totalMeals: totalMeals,
      categoryCounts: categoryCounts,
      bestDay: bestDay,
      worstDay: worstDay,
      topHelpfulTags: topHelpfulTags,
      topRiskyTags: topRiskyTags,
      guidance: guidance,
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
              return tag != null && tag.isPositive == positive;
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
    required double averageScore,
    required int daysInPeriod,
    required int loggedDays,
    required Map<String, int> aggregatedTags,
  }) {
    final guidance = <String>[];

    if (averageScore >= 8) {
      guidance.add('Excellent period. Keep repeating what worked.');
    } else if (averageScore >= 6) {
      guidance.add('Solid period. Focus on trimming a few weaker meals.');
    } else {
      guidance.add(
        'This period had some struggles. Focus on staying closer to your calorie target.',
      );
    }

    if ((aggregatedTags[MealTag.highProtein.value] ?? 0) >= 3) {
      guidance.add('High protein choices showed up often. Keep that up.');
    }

    if ((aggregatedTags[MealTag.sugary.value] ?? 0) >= 3 ||
        (aggregatedTags[MealTag.processed.value] ?? 0) >= 3 ||
        (aggregatedTags[MealTag.fried.value] ?? 0) >= 3) {
      guidance.add(
        'High sugar, fried, or highly processed meals were frequent. Replacing a few will help.',
      );
    }

    if ((aggregatedTags[MealTag.fruitVeg.value] ?? 0) >= 4) {
      guidance.add('Fruit and veg showed up consistently. That is helping.');
    }

    final minimumLoggedDays = daysInPeriod <= 7
        ? 4
        : (daysInPeriod * 0.5).ceil();
    if (loggedDays < minimumLoggedDays) {
      guidance.add(
        'Logging was inconsistent. More complete logging will make this review more useful.',
      );
    }

    return guidance.take(4).toList();
  }
}

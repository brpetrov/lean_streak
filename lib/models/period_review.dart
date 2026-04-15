import 'package:lean_streak/models/daily_summary.dart';

class PeriodTagCount {
  const PeriodTagCount({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class PeriodReview {
  const PeriodReview({
    required this.startDate,
    required this.endDate,
    required this.daysInPeriod,
    required this.loggedDays,
    required this.summaries,
    required this.averageScore,
    required this.totalCalories,
    required this.averageCaloriesPerDay,
    required this.totalMeals,
    required this.categoryCounts,
    required this.bestDay,
    required this.worstDay,
    required this.topHelpfulTags,
    required this.topRiskyTags,
    required this.guidance,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int daysInPeriod;
  final int loggedDays;
  final List<DailySummary> summaries;
  final double averageScore;
  final int totalCalories;
  final double averageCaloriesPerDay;
  final int totalMeals;
  final Map<DailyCategory, int> categoryCounts;
  final DailySummary? bestDay;
  final DailySummary? worstDay;
  final List<PeriodTagCount> topHelpfulTags;
  final List<PeriodTagCount> topRiskyTags;
  final List<String> guidance;
}

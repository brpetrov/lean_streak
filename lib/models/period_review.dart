import 'package:lean_streak/models/check_in.dart';
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
    required this.totalCalories,
    required this.averageCaloriesPerDay,
    required this.totalMeals,
    required this.greenDays,
    required this.yellowDays,
    required this.redDays,
    required this.calorieConsistencyRate,
    required this.bestDay,
    required this.worstDay,
    required this.topHelpfulTags,
    required this.topRiskyTags,
    required this.checkIns,
    required this.guidance,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int daysInPeriod;
  final int loggedDays;
  final List<DailySummary> summaries;
  final int totalCalories;
  final double averageCaloriesPerDay;
  final int totalMeals;
  final int greenDays;
  final int yellowDays;
  final int redDays;
  final double calorieConsistencyRate;
  final DailySummary? bestDay;
  final DailySummary? worstDay;
  final List<PeriodTagCount> topHelpfulTags;
  final List<PeriodTagCount> topRiskyTags;
  final List<CheckIn> checkIns;
  final List<String> guidance;
}

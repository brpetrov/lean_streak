import 'package:intl/intl.dart';

import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/models/user_profile.dart';

class CheckInPeriod {
  const CheckInPeriod({
    required this.key,
    required this.startDate,
    required this.endDate,
    required this.nextAvailableDate,
  });

  final String key;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextAvailableDate;
}

class CheckInAvailability {
  const CheckInAvailability({
    required this.period,
    required this.review,
    required this.targetCalories,
    required this.nextAvailableDate,
    required this.existingCheckIn,
    required this.promptShownAt,
    required this.isDue,
  });

  final CheckInPeriod? period;
  final PeriodReview? review;
  final int targetCalories;
  final DateTime nextAvailableDate;
  final CheckIn? existingCheckIn;
  final DateTime? promptShownAt;
  final bool isDue;

  bool get isCompleted => existingCheckIn != null;
  bool get hasPromptBeenShown => promptShownAt != null;
}

class CheckInRecommendationResult {
  const CheckInRecommendationResult({
    required this.recommendation,
    required this.title,
    required this.reason,
  });

  final CheckInRecommendation recommendation;
  final String title;
  final String reason;
}

class CheckInService {
  CheckInPeriod? currentPeriod({
    required UserProfile profile,
    DateTime? now,
  }) {
    final current = _startOfDay(now ?? DateTime.now());
    final anchor = _startOfDay(profile.createdAt);
    final daysSinceStart = current.difference(anchor).inDays;
    final completedPeriodCount = daysSinceStart ~/ 14;

    if (completedPeriodCount <= 0) {
      return null;
    }

    final latestCompletedIndex = completedPeriodCount - 1;
    final startDate = anchor.add(Duration(days: latestCompletedIndex * 14));
    final endDate = startDate.add(const Duration(days: 13));
    final nextAvailableDate = endDate.add(const Duration(days: 14));
    final formatter = DateFormat('yyyy-MM-dd');

    return CheckInPeriod(
      key: '${formatter.format(startDate)}_${formatter.format(endDate)}',
      startDate: startDate,
      endDate: endDate,
      nextAvailableDate: nextAvailableDate,
    );
  }

  CheckInAvailability buildAvailability({
    required UserProfile profile,
    required PeriodReview? review,
    required CheckIn? existingCheckIn,
    required DateTime? promptShownAt,
    DateTime? now,
  }) {
    final period = currentPeriod(profile: profile, now: now);

    return CheckInAvailability(
      period: period,
      review: review,
      targetCalories: profile.dailyCalorieTarget.round(),
      nextAvailableDate: nextAvailableDate(profile, now: now),
      existingCheckIn: existingCheckIn,
      promptShownAt: promptShownAt,
      isDue: period != null,
    );
  }

  CheckInRecommendationResult buildRecommendation({
    required CheckInWeightTrend weightTrend,
    required CheckInDifficulty targetDifficulty,
    required CheckInHunger hunger,
    required CheckInPlanFit planFit,
    double? updatedWeightKg,
  }) {
    if (hunger == CheckInHunger.high &&
        targetDifficulty == CheckInDifficulty.hard) {
      return const CheckInRecommendationResult(
        recommendation: CheckInRecommendation.reviewPace,
        title: 'Review your pace',
        reason:
            'High hunger and a hard target usually means the plan is feeling too aggressive.',
      );
    }

    if (weightTrend != CheckInWeightTrend.down &&
        targetDifficulty == CheckInDifficulty.hard) {
      return const CheckInRecommendationResult(
        recommendation: CheckInRecommendation.reviewTargets,
        title: 'Review your targets',
        reason:
            'If progress feels off and the target feels hard, it is worth reviewing your current weight and calorie target.',
      );
    }

    if (planFit == CheckInPlanFit.no || updatedWeightKg != null) {
      return const CheckInRecommendationResult(
        recommendation: CheckInRecommendation.reviewTargets,
        title: 'Update your plan details',
        reason:
            'Your answers suggest it is worth reviewing your saved details so the plan stays accurate.',
      );
    }

    return const CheckInRecommendationResult(
      recommendation: CheckInRecommendation.stayTheCourse,
      title: 'Stay the course',
      reason:
          'Your answers suggest the current plan is still a reasonable fit. Keep going and reassess at the next check-in.',
    );
  }

  DateTime nextAvailableDate(UserProfile profile, {DateTime? now}) {
    final current = _startOfDay(now ?? DateTime.now());
    final anchor = _startOfDay(profile.createdAt);
    final daysSinceStart = current.difference(anchor).inDays;
    final completedPeriodCount = daysSinceStart ~/ 14;
    final nextStart = anchor.add(Duration(days: completedPeriodCount * 14));
    return nextStart.add(const Duration(days: 14));
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

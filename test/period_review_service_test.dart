import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/services/period_review_service.dart';

void main() {
  group('PeriodReviewService', () {
    test('averages calories across logged days, not every calendar day', () {
      final review = PeriodReviewService().buildReview(
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 12),
        summaries: [
          _summary('2026-04-06', calories: 2000),
          _summary('2026-04-07', calories: 1900),
          _summary('2026-04-08', calories: 1800),
          _summary('2026-04-09', calories: 2000),
        ],
      );

      expect(review.daysInPeriod, 7);
      expect(review.loggedDays, 4);
      expect(review.totalCalories, 7700);
      expect(review.averageCaloriesPerDay, 1925);
    });

    test('ignores legacy empty daily summaries in activity metrics', () {
      final review = PeriodReviewService().buildReview(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
        summaries: [
          _summary(
            '2026-04-01',
            calories: 0,
            mealCount: 0,
            status: DailyStatus.red,
          ),
          _summary('2026-04-02', calories: 2000),
          _summary('2026-04-03', calories: 1800),
        ],
      );

      expect(review.daysInPeriod, 30);
      expect(review.loggedDays, 2);
      expect(review.summaries.map((summary) => summary.date), [
        '2026-04-02',
        '2026-04-03',
      ]);
      expect(review.totalCalories, 3800);
      expect(review.averageCaloriesPerDay, 1900);
    });
  });
}

DailySummary _summary(
  String date, {
  required int calories,
  int targetCalories = 1900,
  int mealCount = 3,
  DailyStatus? status,
}) {
  return DailySummary(
    date: date,
    totalCalories: calories,
    targetCalories: targetCalories,
    calorieDelta: calories - targetCalories,
    mealCount: mealCount,
    tagCounts: const {},
    status: status ?? DailyStatus.green,
    updatedAt: DateTime(2026, 4, 20),
  );
}

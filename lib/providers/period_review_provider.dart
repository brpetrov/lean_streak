import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/services/period_review_service.dart';

final periodReviewServiceProvider = Provider<PeriodReviewService>((ref) {
  return PeriodReviewService();
});

class PeriodReviewRange {
  const PeriodReviewRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    return other is PeriodReviewRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

final periodReviewProvider = FutureProvider.autoDispose
    .family<PeriodReview, PeriodReviewRange>((ref, range) async {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      final formatter = DateFormat('yyyy-MM-dd');
      final summaries = await ref
          .watch(dailySummaryRepositoryProvider)
          .fetchSummariesInRange(
            uid,
            startDate: formatter.format(range.startDate),
            endDate: formatter.format(range.endDate),
          );

      return ref
          .watch(periodReviewServiceProvider)
          .buildReview(
            startDate: range.startDate,
            endDate: range.endDate,
            summaries: summaries,
          );
    });

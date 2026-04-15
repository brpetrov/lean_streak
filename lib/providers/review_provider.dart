import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';

class ReviewRange {
  const ReviewRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    return other is ReviewRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

class ReviewPeriods {
  const ReviewPeriods({required this.weekStarts, required this.monthStarts});

  final List<DateTime> weekStarts;
  final List<DateTime> monthStarts;

  bool get isEmpty => weekStarts.isEmpty && monthStarts.isEmpty;
}

final reviewPeriodsProvider = FutureProvider.autoDispose<ReviewPeriods>((
  ref,
) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return const ReviewPeriods(weekStarts: [], monthStarts: []);
  }

  final dates = await ref
      .watch(dailySummaryRepositoryProvider)
      .fetchSummaryDates(uid);

  final weekStarts = <DateTime>[];
  final monthStarts = <DateTime>[];
  final seenWeeks = <String>{};
  final seenMonths = <String>{};

  for (final date in dates) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final monthStart = DateTime(date.year, date.month, 1);
    final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);
    final monthKey = DateFormat('yyyy-MM').format(monthStart);

    if (seenWeeks.add(weekKey)) {
      weekStarts.add(weekStart);
    }

    if (seenMonths.add(monthKey)) {
      monthStarts.add(monthStart);
    }
  }

  return ReviewPeriods(weekStarts: weekStarts, monthStarts: monthStarts);
});

final reviewSummariesProvider = FutureProvider.autoDispose
    .family<Map<String, DailySummary>, ReviewRange>((ref, range) async {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return const {};

      final formatter = DateFormat('yyyy-MM-dd');
      final summaries = await ref
          .watch(dailySummaryRepositoryProvider)
          .fetchSummariesInRange(
            uid,
            startDate: formatter.format(range.startDate),
            endDate: formatter.format(range.endDate),
          );

      return {for (final summary in summaries) summary.date: summary};
    });

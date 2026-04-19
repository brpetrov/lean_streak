import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/check_in_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/services/check_in_service.dart';

final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService();
});

final currentCheckInAvailabilityProvider =
    FutureProvider.autoDispose<CheckInAvailability?>((ref) async {
      final uid = ref.watch(currentUidProvider);
      final profile = ref.watch(userProfileProvider).valueOrNull;
      if (uid == null || profile == null) return null;

      final service = ref.watch(checkInServiceProvider);
      final period = service.currentPeriod(profile: profile);
      if (period == null) {
        return service.buildAvailability(
          profile: profile,
          review: null,
          existingCheckIn: null,
          promptShownAt: null,
        );
      }

      final formatter = DateFormat('yyyy-MM-dd');
      final summaries = await ref
          .watch(dailySummaryRepositoryProvider)
          .fetchSummariesInRange(
            uid,
            startDate: formatter.format(period.startDate),
            endDate: formatter.format(period.endDate),
          );
      final review = ref
          .watch(periodReviewServiceProvider)
          .buildReview(
            startDate: period.startDate,
            endDate: period.endDate,
            summaries: summaries,
          );
      final repository = ref.watch(checkInRepositoryProvider);
      final existingCheckIn = await repository.fetchCheckIn(uid, period.key);
      final promptShownAt = await repository.fetchPromptShownAt(
        uid,
        period.key,
      );

      return service.buildAvailability(
        profile: profile,
        review: review,
        existingCheckIn: existingCheckIn,
        promptShownAt: promptShownAt,
      );
    });

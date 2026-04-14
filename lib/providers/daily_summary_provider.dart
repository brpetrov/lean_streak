import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/services/daily_summary_service.dart';

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  return DailySummaryRepository(FirebaseFirestore.instance);
});

final dailySummaryServiceProvider = Provider<DailySummaryService>((ref) {
  return DailySummaryService(
    mealRepository: ref.watch(mealRepositoryProvider),
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    dailySummaryRepository: ref.watch(dailySummaryRepositoryProvider),
  );
});

final dailySummaryForDateProvider = StreamProvider.autoDispose
    .family<DailySummary?, String>((ref, date) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return Stream.value(null);
      return ref.watch(dailySummaryRepositoryProvider).watchSummary(uid, date);
    });

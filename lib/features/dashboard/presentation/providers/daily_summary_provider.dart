import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../meals/presentation/providers/meal_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/models/daily_summary.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../domain/daily_summary_service.dart';

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

final dailySummaryForDateProvider =
    StreamProvider.autoDispose.family<DailySummary?, String>((ref, date) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(dailySummaryRepositoryProvider).watchSummary(uid, date);
});

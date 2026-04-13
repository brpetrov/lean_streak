import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/ai_usage_repository.dart';
import '../../data/services/calorie_estimate_service.dart';

final aiUsageRepositoryProvider = Provider<AiUsageRepository>((ref) {
  return AiUsageRepository(FirebaseFirestore.instance);
});

final calorieEstimateServiceProvider = Provider<CalorieEstimateService>((ref) {
  return CalorieEstimateService(ref.watch(aiUsageRepositoryProvider));
});

/// Streams today's AI estimate usage count for the current user.
/// Emits 0 while loading or if the user is unauthenticated.
final aiUsageTodayProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.watch(aiUsageRepositoryProvider).watchCount(uid, today);
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(FirebaseFirestore.instance);
});

/// Streams meals for the current user on [date] (yyyy-MM-dd).
final mealsForDateProvider =
    StreamProvider.autoDispose.family<List<Meal>, String>((ref, date) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(mealRepositoryProvider).watchMealsForDate(uid, date);
});

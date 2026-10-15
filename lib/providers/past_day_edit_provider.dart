import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/repositories/day_edit_repository.dart';

/// Thrown when a past day can't be changed because this month's allowance
/// ([DayEditRepository.monthlyLimit]) is used up.
class EditLimitExceededException implements Exception {
  const EditLimitExceededException();
}

final dayEditRepositoryProvider = Provider<DayEditRepository>((ref) {
  return DayEditRepository(FirebaseFirestore.instance);
});

/// The allowance resets with the calendar month the change is made in.
String currentEditMonthKey() => DateFormat('yyyy-MM').format(DateTime.now());

/// True when [date] (yyyy-MM-dd) is before [now]'s day, i.e. changing it
/// uses one of the month's past-day changes.
bool isPastDay(String date, DateTime now) =>
    date.compareTo(DateFormat('yyyy-MM-dd').format(now)) < 0;

/// Streams the number of past-day changes used this calendar month for the
/// signed-in user. Emits 0 while loading or unauthenticated.
final dayEditsThisMonthProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref
      .watch(dayEditRepositoryProvider)
      .watchCount(uid, currentEditMonthKey());
});

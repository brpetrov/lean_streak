import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks how many times the user has manually adjusted a past day's calories
/// within a calendar month.
///
/// Document path: `users/{uid}/day_edits/{yyyy-MM}`
/// The month in the path acts as a natural monthly reset —
/// a new month means a new document, no cron job needed.
class DayEditRepository {
  DayEditRepository(this._db);
  final FirebaseFirestore _db;

  static const int monthlyLimit = 3;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String monthKey) =>
      _db.collection('users').doc(uid).collection('day_edits').doc(monthKey);

  /// Streams this month's edit count. Emits 0 if no document exists yet.
  Stream<int> watchCount(String uid, String monthKey) => _doc(uid, monthKey)
      .snapshots()
      .map((snap) => snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0);

  /// Reads the current edit count for [monthKey] once.
  Future<int> fetchCount(String uid, String monthKey) async {
    final snap = await _doc(uid, monthKey).get();
    return snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0;
  }

  /// Atomically increments the edit count for [monthKey].
  Future<void> increment(String uid, String monthKey) => _doc(
    uid,
    monthKey,
  ).set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/daily_summary.dart';

class DailySummaryRepository {
  DailySummaryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _dailySummaries(String uid) {
    return _db.collection('users').doc(uid).collection('daily_summaries');
  }

  Future<void> saveSummary(String uid, DailySummary summary) async {
    await _dailySummaries(uid).doc(summary.date).set(summary.toFirestore());
  }

  Future<List<DailySummary>> fetchSummariesPage(
    String uid, {
    String? startAfterDate,
    int limit = 14,
  }) async {
    Query<Map<String, dynamic>> query = _dailySummaries(
      uid,
    ).orderBy('date', descending: true).limit(limit);

    if (startAfterDate != null) {
      query = query.startAfter([startAfterDate]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => DailySummary.fromFirestore(doc)).toList();
  }

  Future<List<DailySummary>> fetchSummariesInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async {
    final snapshot = await _dailySummaries(uid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) => DailySummary.fromFirestore(doc)).toList();
  }

  Future<List<DateTime>> fetchSummaryDates(String uid) async {
    final snapshot = await _dailySummaries(uid).orderBy('date').get();

    return snapshot.docs.map((doc) {
      return DateTime.parse(doc.data()['date'] as String);
    }).toList();
  }

  Stream<DailySummary?> watchSummary(String uid, String date) {
    return _dailySummaries(uid).doc(date).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return DailySummary.fromFirestore(snapshot);
    });
  }
}

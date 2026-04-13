import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_summary.dart';

class DailySummaryRepository {
  DailySummaryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _dailySummaries(String uid) {
    return _db.collection('users').doc(uid).collection('daily_summaries');
  }

  Future<void> saveSummary(String uid, DailySummary summary) async {
    await _dailySummaries(uid).doc(summary.date).set(summary.toFirestore());
  }

  Stream<DailySummary?> watchSummary(String uid, String date) {
    return _dailySummaries(uid).doc(date).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return DailySummary.fromFirestore(snapshot);
    });
  }
}

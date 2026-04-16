import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/check_in.dart';

class CheckInRepository {
  CheckInRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _checkIns(String uid) {
    return _db.collection('users').doc(uid).collection('check_ins');
  }

  CollectionReference<Map<String, dynamic>> _promptStatus(String uid) {
    return _db.collection('users').doc(uid).collection('check_in_prompt_status');
  }

  Future<void> saveCheckIn(String uid, CheckIn checkIn) async {
    await _checkIns(uid).doc(checkIn.periodKey).set(checkIn.toFirestore());
  }

  Future<CheckIn?> fetchCheckIn(String uid, String periodKey) async {
    final snapshot = await _checkIns(uid).doc(periodKey).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return CheckIn.fromFirestore(snapshot);
  }

  Stream<CheckIn?> watchCheckIn(String uid, String periodKey) {
    return _checkIns(uid).doc(periodKey).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return CheckIn.fromFirestore(snapshot);
    });
  }

  Future<DateTime?> fetchPromptShownAt(String uid, String periodKey) async {
    final snapshot = await _promptStatus(uid).doc(periodKey).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final shownAt = snapshot.data()!['shownAt'];
    if (shownAt is! Timestamp) return null;
    return shownAt.toDate();
  }

  Future<void> markPromptShown(
    String uid, {
    required String periodKey,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    await _promptStatus(uid).doc(periodKey).set({
      'periodKey': periodKey,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'shownAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}

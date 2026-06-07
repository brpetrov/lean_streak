import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/weight_entry.dart';

class WeightEntryRepository {
  WeightEntryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    return _db.collection('users').doc(uid).collection('weight_entries');
  }

  /// Creates or overwrites the entry for its day (doc id is the date key).
  Future<void> upsertEntry(String uid, WeightEntry entry) {
    return _entries(uid).doc(entry.dateKey).set(entry.toFirestore());
  }

  /// Real-time stream of all entries, oldest first — ready to plot.
  Stream<List<WeightEntry>> watchEntries(String uid) {
    return _entries(uid).orderBy('dateKey').snapshots().map((snapshot) {
      return snapshot.docs.map(WeightEntry.fromFirestore).toList();
    });
  }

  Future<WeightEntry?> latestEntry(String uid) async {
    final snapshot = await _entries(uid)
        .orderBy('dateKey', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return WeightEntry.fromFirestore(snapshot.docs.first);
  }
}

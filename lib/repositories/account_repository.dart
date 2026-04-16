import 'package:cloud_firestore/cloud_firestore.dart';

class AccountRepository {
  AccountRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  Future<void> resetProgress(String uid) async {
    final userDoc = _userDoc(uid);

    await _deleteCollection(userDoc.collection('meals'));
    await _deleteCollection(userDoc.collection('daily_summaries'));
    await _deleteCollection(userDoc.collection('check_ins'));
    await _deleteCollection(userDoc.collection('check_in_prompt_status'));
    await _deleteCollection(userDoc.collection('ai_usage'));
  }

  Future<void> deleteAccountData(String uid) async {
    await resetProgress(uid);
    await _userDoc(uid).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(200).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}

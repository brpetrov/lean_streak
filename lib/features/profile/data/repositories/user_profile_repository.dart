import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// One-time fetch. Returns null if the document does not exist yet.
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(snap);
  }

  /// Real-time stream. Emits null when the document does not exist.
  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap);
    });
  }

  /// Creates (or overwrites) the user's profile document.
  Future<void> createProfile(UserProfile profile) {
    return _doc(profile.uid).set(profile.toFirestore());
  }

  /// Partially updates the user's profile document.
  /// Always stamps [updatedAt] via server timestamp.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

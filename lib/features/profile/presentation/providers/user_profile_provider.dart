import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

/// Singleton repository backed by Firestore.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
});

/// Real-time stream of the current user's profile.
/// Emits null when unauthenticated or when the document does not exist yet.
final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchProfile(uid);
});

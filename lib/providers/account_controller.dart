import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/account_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/check_in_state_provider.dart';

class AccountActionException implements Exception {
  const AccountActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> resetProgress({required String password}) async {
    state = const AsyncLoading();

    try {
      final user = await _reauthenticate(password);
      await ref.read(accountRepositoryProvider).resetProgress(user.uid);
      ref.invalidate(currentCheckInAvailabilityProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    state = const AsyncLoading();

    try {
      final user = await _reauthenticate(password);
      await ref.read(accountRepositoryProvider).deleteAccountData(user.uid);
      await user.delete();
      await FirebaseAuth.instance.signOut();
      ref.invalidate(currentCheckInAvailabilityProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<User> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = ref.read(currentUidProvider);

    if (user == null || uid == null) {
      throw const AccountActionException('You are not signed in.');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AccountActionException(
        'This account cannot confirm with a password.',
      );
    }

    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) {
      throw const AccountActionException('Please enter your password.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: trimmedPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return user;
    } on FirebaseAuthException catch (error) {
      throw AccountActionException(_mapAuthError(error));
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Could not verify your password.';
    }
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);

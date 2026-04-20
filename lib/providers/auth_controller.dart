import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { idle, verificationSent }

/// Thrown when a user tries to sign in before verifying their email.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();
}

class AuthController extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async => AuthStatus.idle;

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (!(credential.user?.emailVerified ?? false)) {
        await FirebaseAuth.instance.signOut();
        throw const EmailNotVerifiedException();
      }
      return AuthStatus.idle;
    });
    state = nextState;
    return !nextState.hasError;
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await credential.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      return AuthStatus.verificationSent;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await FirebaseAuth.instance.signOut();
    state = const AsyncData(AuthStatus.idle);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthStatus>(AuthController.new);

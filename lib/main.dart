import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lean_streak/app/app.dart';
import 'package:lean_streak/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Guard against double-init (can happen on hot-restart in web where the
  // Flutter Dart state resets but the Firebase JS SDK stays alive).
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const ProviderScope(child: LeanStreakApp()));
}

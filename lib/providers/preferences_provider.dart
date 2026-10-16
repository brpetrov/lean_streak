import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings (theme, reminders, voice language). Overridden in
/// main() with the real instance so readers never wait on it.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Overridden in main()'),
);

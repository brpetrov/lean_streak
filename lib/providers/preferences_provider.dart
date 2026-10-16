import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings (theme, reminders, voice language). Overridden in
/// main() with the real instance so readers never wait on it.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Overridden in main()'),
);

/// Which language the mic listens for. [system] follows the device.
enum VoiceLanguage {
  system('System', null),
  english('English', 'en_GB'),
  bulgarian('Bulgarian', 'bg_BG');

  const VoiceLanguage(this.label, this.localeId);

  final String label;

  /// The speech recogniser's locale, or null for the device default.
  final String? localeId;
}

class VoiceLanguageNotifier extends Notifier<VoiceLanguage> {
  static const _key = 'voice_language';

  @override
  VoiceLanguage build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return VoiceLanguage.values.asNameMap()[stored] ?? VoiceLanguage.system;
  }

  Future<void> set(VoiceLanguage language) async {
    state = language;
    await ref.read(sharedPreferencesProvider).setString(_key, language.name);
  }
}

final voiceLanguageProvider =
    NotifierProvider<VoiceLanguageNotifier, VoiceLanguage>(
      VoiceLanguageNotifier.new,
    );

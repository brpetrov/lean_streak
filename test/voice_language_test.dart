import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'follows the device until a language is chosen, then remembers it',
    () async {
      final container = await containerWith({});
      expect(container.read(voiceLanguageProvider), VoiceLanguage.system);
      expect(VoiceLanguage.system.localeId, isNull);

      await container
          .read(voiceLanguageProvider.notifier)
          .set(VoiceLanguage.bulgarian);

      expect(container.read(voiceLanguageProvider), VoiceLanguage.bulgarian);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('voice_language'), 'bulgarian');
    },
  );

  test('reads a stored choice and ignores unknown values', () async {
    expect(
      (await containerWith({
        'voice_language': 'english',
      })).read(voiceLanguageProvider),
      VoiceLanguage.english,
    );
    expect(
      (await containerWith({
        'voice_language': 'klingon',
      })).read(voiceLanguageProvider),
      VoiceLanguage.system,
    );
  });
}

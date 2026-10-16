import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/preferences_provider.dart';

/// System / light / dark, stored on the device. Seeded synchronously from
/// preferences so the first frame already has the right theme.
class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.where((mode) => mode.name == stored).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

/// The OS light/dark setting, kept current so "System" follows it live.
class PlatformBrightnessNotifier extends Notifier<Brightness>
    with WidgetsBindingObserver {
  @override
  Brightness build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}

final platformBrightnessProvider =
    NotifierProvider<PlatformBrightnessNotifier, Brightness>(
      PlatformBrightnessNotifier.new,
    );

/// The brightness actually in use: the stored choice, or the OS setting for
/// "System".
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  final mode = ref.watch(themeControllerProvider);
  final platform = ref.watch(platformBrightnessProvider);
  return switch (mode) {
    ThemeMode.dark => Brightness.dark,
    ThemeMode.light => Brightness.light,
    ThemeMode.system => platform,
  };
});

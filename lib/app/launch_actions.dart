import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/services/notification_service.dart';

/// Something the user asked for from outside the app: a notification tap, the
/// app-icon shortcut or the home-screen widget. Set by [bindLaunchActions] and
/// consumed once by the screen that can do it.
enum LaunchAction { logWeight, voiceLog }

/// The app-icon shortcut's id.
const shortcutLogVoice = 'log_voice';

class LaunchActionNotifier extends Notifier<LaunchAction?> {
  @override
  LaunchAction? build() => null;

  void set(LaunchAction action) => state = action;

  void clear() => state = null;
}

final launchActionProvider =
    NotifierProvider<LaunchActionNotifier, LaunchAction?>(
      LaunchActionNotifier.new,
    );

/// `leanstreak://log/voice` and `leanstreak://log/weight`.
LaunchAction? launchActionForUri(Uri? uri) => switch ((uri?.host, uri?.path)) {
  ('log', '/voice') => LaunchAction.voiceLog,
  ('log', '/weight') => LaunchAction.logWeight,
  _ => null,
};

LaunchAction? launchActionForPayload(String? payload) =>
    payload == NotificationService.payloadLogWeight
    ? LaunchAction.logWeight
    : null;

/// Hooks every entry point up to [launchActionProvider]. Runs first thing in
/// main(): the handlers only need [container], so a cold-start tap never
/// waits behind Firebase.
Future<void> bindLaunchActions(ProviderContainer container) async {
  if (!NotificationService.isSupported) return;

  void dispatch(LaunchAction action) {
    container.read(launchActionProvider.notifier).set(action);
    // With another page on top (Review, Progress...), come back to Today so
    // the action is visible. On a cold start the router doesn't exist yet and
    // the redirects land on Today anyway.
    if (container.exists(goRouterProvider)) {
      container.read(goRouterProvider).go(AppRoutes.dashboard);
    }
  }

  // Long-press the app icon → "Log by voice". Registered before anything
  // else is awaited, so a cold start from the shortcut is not missed.
  final quickActions = QuickActions();
  await quickActions.initialize((type) {
    if (type == shortcutLogVoice) dispatch(LaunchAction.voiceLog);
  });
  await quickActions.setShortcutItems(const [
    ShortcutItem(type: shortcutLogVoice, localizedTitle: 'Log by voice'),
  ]);

  // The Android home-screen widget opens the app with leanstreak://log/voice.
  // Taps while the app is running arrive on the stream, which must stay
  // subscribed; a tap that started the app is only reported by
  // initiallyLaunchedFromHomeWidget.
  if (defaultTargetPlatform == TargetPlatform.android) {
    HomeWidget.widgetClicked.listen((uri) {
      final action = launchActionForUri(uri);
      if (action != null) dispatch(action);
    });
    final widgetLaunch = launchActionForUri(
      await HomeWidget.initiallyLaunchedFromHomeWidget(),
    );
    if (widgetLaunch != null) dispatch(widgetLaunch);
  }

  // Taps while the app is running arrive in the callback; a tap that started
  // the app is only reported by launchPayload.
  await NotificationService.initialize(
    onTap: (payload) {
      final action = launchActionForPayload(payload);
      if (action != null) dispatch(action);
    },
  );
  final launch = launchActionForPayload(
    await NotificationService.launchPayload(),
  );
  if (launch != null) dispatch(launch);
}

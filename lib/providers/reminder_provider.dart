import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/helpers/weight_reminder.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/services/notification_service.dart';

class ReminderSettings {
  const ReminderSettings({required this.dailyMeal, required this.weeklyWeight});

  final bool dailyMeal;
  final bool weeklyWeight;

  ReminderSettings copyWith({bool? dailyMeal, bool? weeklyWeight}) {
    return ReminderSettings(
      dailyMeal: dailyMeal ?? this.dailyMeal,
      weeklyWeight: weeklyWeight ?? this.weeklyWeight,
    );
  }
}

/// The two reminder switches, stored on the device (reminders are per device).
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _dailyKey = 'reminders.daily_meal';
  static const _weeklyKey = 'reminders.weekly_weight';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderSettings(
      dailyMeal: prefs.getBool(_dailyKey) ?? true,
      weeklyWeight: prefs.getBool(_weeklyKey) ?? true,
    );
  }

  /// Nothing stored yet: startup may show the permission prompt this once.
  bool get isFirstRun =>
      !ref.read(sharedPreferencesProvider).containsKey(_dailyKey);

  Future<void> markFirstRunDone() => _persist(state);

  /// Returns false, leaving the switch off, when the system denies permission.
  Future<bool> setDailyMeal(bool on) =>
      _set(on, (settings) => settings.copyWith(dailyMeal: on));

  Future<bool> setWeeklyWeight(bool on) =>
      _set(on, (settings) => settings.copyWith(weeklyWeight: on));

  Future<bool> _set(
    bool on,
    ReminderSettings Function(ReminderSettings) update,
  ) async {
    if (on && !await NotificationService.requestPermission()) return false;
    state = update(state);
    await _persist(state);
    return true;
  }

  Future<void> _persist(ReminderSettings settings) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_dailyKey, settings.dailyMeal);
    await prefs.setBool(_weeklyKey, settings.weeklyWeight);
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

/// Keeps the scheduled notifications in step with the switches and the
/// latest weigh-in. Re-runs when a switch flips, the user changes, or the
/// latest weigh-in day changes.
final reminderSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);
  final uid = ref.watch(currentUidProvider);
  // null while loading, '' when there are no entries, else the latest day.
  final latestKey = ref.watch(
    weightEntriesProvider.select(
      (entries) =>
          entries.hasValue ? (entries.value!.lastOrNull?.dateKey ?? '') : null,
    ),
  );
  final createdAt = ref.watch(
    userProfileProvider.select((profile) => profile.valueOrNull?.createdAt),
  );

  final notifier = ref.read(reminderSettingsProvider.notifier);
  if (notifier.isFirstRun) {
    await NotificationService.requestPermission();
    await notifier.markFirstRunDone();
  }
  if (!await NotificationService.hasPermission()) return;

  if (settings.dailyMeal) {
    await NotificationService.scheduleDailyMealReminder();
  } else {
    await NotificationService.cancelDailyMealReminder();
  }

  if (!settings.weeklyWeight || uid == null) {
    await NotificationService.cancelWeeklyWeightReminder();
    return;
  }
  if (latestKey == null) return;
  final anchor = latestKey.isEmpty ? createdAt : DateTime.parse(latestKey);
  if (anchor == null) return;
  await NotificationService.scheduleWeeklyWeightReminder(
    firstFireAt: nextWeightReminder(lastWeighIn: anchor, now: DateTime.now()),
  );
});

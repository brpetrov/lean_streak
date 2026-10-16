import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/helpers/weight_reminder.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/services/notification_service.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.dailyMeal,
    required this.weeklyWeight,
    required this.weeklyDay,
    required this.weeklyTime,
  });

  final bool dailyMeal;
  final bool weeklyWeight;

  /// [DateTime.monday] to [DateTime.sunday].
  final int weeklyDay;
  final TimeOfDay weeklyTime;

  ReminderSettings copyWith({
    bool? dailyMeal,
    bool? weeklyWeight,
    int? weeklyDay,
    TimeOfDay? weeklyTime,
  }) {
    return ReminderSettings(
      dailyMeal: dailyMeal ?? this.dailyMeal,
      weeklyWeight: weeklyWeight ?? this.weeklyWeight,
      weeklyDay: weeklyDay ?? this.weeklyDay,
      weeklyTime: weeklyTime ?? this.weeklyTime,
    );
  }
}

/// The two reminder switches and the weigh-in slot (Saturday 20:00 unless
/// changed), stored on the device since reminders are per device.
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _dailyKey = 'reminders.daily_meal';
  static const _weeklyKey = 'reminders.weekly_weight';
  static const _weeklyDayKey = 'reminders.weekly_weight_day';
  static const _weeklyHourKey = 'reminders.weekly_weight_hour';
  static const _weeklyMinuteKey = 'reminders.weekly_weight_minute';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderSettings(
      dailyMeal: prefs.getBool(_dailyKey) ?? true,
      weeklyWeight: prefs.getBool(_weeklyKey) ?? true,
      weeklyDay: prefs.getInt(_weeklyDayKey) ?? DateTime.saturday,
      weeklyTime: TimeOfDay(
        hour: prefs.getInt(_weeklyHourKey) ?? 20,
        minute: prefs.getInt(_weeklyMinuteKey) ?? 0,
      ),
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

  Future<void> setWeeklySchedule({
    required int day,
    required TimeOfDay time,
  }) async {
    state = state.copyWith(weeklyDay: day, weeklyTime: time);
    await _persist(state);
  }

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
    await prefs.setInt(_weeklyDayKey, settings.weeklyDay);
    await prefs.setInt(_weeklyHourKey, settings.weeklyTime.hour);
    await prefs.setInt(_weeklyMinuteKey, settings.weeklyTime.minute);
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

/// Keeps the scheduled notifications in step with the settings. Re-runs
/// whenever a switch flips or the weigh-in slot changes.
final reminderSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);

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

  if (!settings.weeklyWeight) {
    await NotificationService.cancelWeeklyWeightReminder();
    return;
  }
  await NotificationService.scheduleWeeklyWeightReminder(
    firstFireAt: nextWeekdayAt(
      weekday: settings.weeklyDay,
      hour: settings.weeklyTime.hour,
      minute: settings.weeklyTime.minute,
      now: DateTime.now(),
    ),
  );
});

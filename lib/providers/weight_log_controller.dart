import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/services/weight_log_service.dart';

class WeightLogController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Logs a weight reading and triggers the automatic plan recalculation.
  /// Returns the result (old/new target) or null on failure.
  Future<WeightLogResult?> logWeight({
    required double weightKg,
    WeightSource source = WeightSource.manual,
  }) async {
    state = const AsyncLoading();

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Profile not loaded');

      final result = await ref
          .read(weightLogServiceProvider)
          .logWeight(profile: profile, weightKg: weightKg, source: source);

      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final weightLogControllerProvider =
    AsyncNotifierProvider<WeightLogController, void>(WeightLogController.new);

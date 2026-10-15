import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/quick_log_parser.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// The log composer pinned to the bottom of Today, under the thumb.
/// "chicken wrap 450" saves straight away; a meal without calories can be
/// estimated by the AI. With the box empty the main button is the mic.
class QuickLogBar extends ConsumerStatefulWidget {
  const QuickLogBar({super.key});

  @override
  ConsumerState<QuickLogBar> createState() => _QuickLogBarState();
}

class _QuickLogBarState extends ConsumerState<QuickLogBar> {
  final _controller = TextEditingController();
  final _speechToText = SpeechToText();

  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool _listening = false;
  bool _working = false;
  String? _aiNote;
  String? _error;

  QuickLogEntry get _entry => parseQuickLog(_controller.text);

  // Touch devices choose between typing and the mic, so only desktop
  // (including desktop browsers, which have no on-screen keyboard) focuses
  // the box on open.
  bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux =>
      true,
    _ => false,
  };

  @override
  void dispose() {
    _speechToText.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _aiNote = null;
      _error = null;
    });
  }

  void _submit() {
    if (_working || _listening) return;
    if (_entry.kcal != null) {
      _save();
    } else {
      _estimate();
    }
  }

  Future<void> _save() async {
    final entry = _entry;
    setState(() => _working = true);

    await ref
        .read(logMealControllerProvider.notifier)
        .submit(
          name: entry.name,
          calories: entry.kcal!.toDouble(),
          proteinGrams: entry.protein?.toDouble(),
          tags: const [],
        );
    if (!mounted) return;

    setState(() => _working = false);
    if (ref.read(logMealControllerProvider).hasError) {
      setState(() => _error = 'Could not save meal. Try again.');
      return;
    }
    _reset();
  }

  Future<void> _estimate() async {
    final text = _controller.text.trim();
    final uid = ref.read(currentUidProvider);
    if (text.isEmpty || uid == null) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimate(uid, text);
      if (!mounted) return;
      _setText('$text ${_amounts(result.kcal, result.protein)}');
      _aiNote = result.note;
    });
  }

  String _amounts(int kcal, int? protein) =>
      protein == null ? '$kcal kcal' : '$kcal kcal ${protein}g protein';

  /// Shared busy and error handling for the estimate and voice AI calls.
  Future<void> _runAi(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _error = null;
    });

    try {
      await action();
    } on DailyLimitExceededException {
      _error =
          'Daily AI limit reached. Add the calories yourself, e.g. "wrap 450".';
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Could not reach the AI right now.';
    }

    if (mounted) setState(() => _working = false);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speechToText.stop();
      _finishListening();
      return;
    }

    if (!_speechInitialized) {
      _speechAvailable = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _finishListening();
          }
        },
        onError: _onSpeechError,
      );
      _speechInitialized = true;
    }
    if (!mounted) return;
    if (!_speechAvailable) {
      setState(() => _error = 'Speech input is not available on this device.');
      return;
    }

    _setText('');
    setState(() {
      _listening = true;
      _aiNote = null;
      _error = null;
    });

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        _setText(result.recognizedWords);
        if (result.finalResult) _finishListening();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  /// Runs once per recording, whichever of final result, status change or
  /// manual stop arrives first.
  void _finishListening() {
    if (!mounted || !_listening) return;
    setState(() => _listening = false);

    final transcript = _controller.text.trim();
    if (transcript.isEmpty) return;

    _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .parseVoice(transcript);
      if (!mounted) return;
      _setText('${result.name} ${_amounts(result.kcal, result.protein)}');
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _listening = false;
      _error = error.errorMsg == 'error_no_match'
          ? 'No speech detected. Tap the mic to try again.'
          : 'Speech input failed. Try again.';
    });
  }

  Future<void> _openDetails() async {
    final entry = _entry;
    final saved = await showLogMealSheet(
      context,
      initialName: entry.name,
      initialCalories: entry.kcal,
      initialProtein: entry.protein,
    );
    if (saved == true && mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final hasText = _controller.text.trim().isNotEmpty;
    final showStatus = hasText || _listening || _working || _error != null;

    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showStatus) ...[
                      _buildStatus(entry, hasText),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: _isDesktop,
                            readOnly: _working || _listening,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {
                              _aiNote = null;
                              _error = null;
                            }),
                            onSubmitted: (_) => _submit(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'What did you eat? e.g. wrap 450',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildAction(entry, hasText),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One thumb-sized button that changes with the box: mic when empty,
  /// save or estimate once there is text, stop while listening.
  Widget _buildAction(QuickLogEntry entry, bool hasText) {
    final (IconData icon, String tooltip, VoidCallback? onPressed) =
        _listening
        ? (Icons.stop_rounded, 'Stop', _toggleListening)
        : _working
        ? (Icons.more_horiz_rounded, 'Working', null)
        : !hasText
        ? (Icons.mic_rounded, 'Speak', _toggleListening)
        : entry.kcal != null
        ? (Icons.check_rounded, 'Save', _submit)
        : (Icons.auto_awesome_rounded, 'Estimate with AI', _submit);

    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 26,
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        backgroundColor: _listening ? AppColors.veryBad : AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      icon: Icon(icon),
    );
  }

  Widget _buildStatus(QuickLogEntry entry, bool hasText) {
    final (message, color, emphasise) = switch (entry) {
      _ when _listening => (
        'Listening... tap stop when you\'re done.',
        AppColors.textSecondary,
        false,
      ),
      _ when _working => ('Working...', AppColors.textSecondary, false),
      _ when _error != null => (_error!, AppColors.error, false),
      (name: final name, kcal: null, protein: _) => (
        '${name ?? 'Meal'} · no calories yet. Add a number or estimate with AI.',
        AppColors.textSecondary,
        false,
      ),
      (name: final name, kcal: final kcal, protein: final protein) => (
        [
          ?name,
          '$kcal kcal',
          if (protein != null) '$protein g protein',
        ].join(' · '),
        AppColors.textPrimary,
        true,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (_aiNote != null && !_working) ...[
                  const SizedBox(height: 2),
                  Text(
                    _aiNote!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasText && !_working && !_listening)
          TextButton(onPressed: _openDetails, child: const Text('More details')),
      ],
    );
  }
}

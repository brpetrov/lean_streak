import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/providers/check_in_controller.dart';
import 'package:lean_streak/providers/check_in_state_provider.dart';
import 'package:lean_streak/services/check_in_service.dart';

enum CheckInDialogResult { saved, savedAndOpenProfile }

Future<CheckInDialogResult?> showCheckInDialog(
  BuildContext context, {
  required CheckInAvailability availability,
}) {
  return showDialog<CheckInDialogResult>(
    context: context,
    builder: (context) => _CheckInDialog(availability: availability),
  );
}

Future<void> showCheckInUnavailableDialog(
  BuildContext context, {
  required DateTime nextAvailableDate,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Check-in not due yet'),
        content: Text(
          'Your next 2-week check-in will be available on ${DateFormat('d MMM yyyy').format(nextAvailableDate)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _CheckInDialog extends ConsumerStatefulWidget {
  const _CheckInDialog({required this.availability});

  final CheckInAvailability availability;

  @override
  ConsumerState<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends ConsumerState<_CheckInDialog> {
  late CheckInWeightTrend _weightTrend;
  late CheckInDifficulty _targetDifficulty;
  late CheckInHunger _hunger;
  late CheckInPlanFit _planFit;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.availability.existingCheckIn;
    _weightTrend = existing?.weightTrend ?? CheckInWeightTrend.same;
    _targetDifficulty =
        existing?.targetDifficulty ?? CheckInDifficulty.manageable;
    _hunger = existing?.hunger ?? CheckInHunger.normal;
    _planFit = existing?.planFit ?? CheckInPlanFit.yes;
    _weightCtrl = TextEditingController(
      text: existing?.updatedWeightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.availability.period!;
    final review = widget.availability.review;
    final controllerState = ref.watch(checkInControllerProvider);
    final recommendation = ref
        .watch(checkInServiceProvider)
        .buildRecommendation(
          weightTrend: _weightTrend,
          targetDifficulty: _targetDifficulty,
          hunger: _hunger,
          planFit: _planFit,
          updatedWeightKg: double.tryParse(_weightCtrl.text),
        );
    final shouldOfferProfileAction =
        recommendation.recommendation != CheckInRecommendation.stayTheCourse ||
        _weightCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2-week check-in'),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('d MMM').format(period.startDate)} to ${DateFormat('d MMM yyyy').format(period.endDate)}',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CheckInContextCard(
                targetCalories: widget.availability.targetCalories,
                loggedDays: review?.loggedDays ?? 0,
                greenDays: review?.greenDays ?? 0,
              ),
              const SizedBox(height: 16),
              _QuestionSection<CheckInWeightTrend>(
                title: 'How has your weight changed recently?',
                value: _weightTrend,
                options: CheckInWeightTrend.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => setState(() => _weightTrend = value),
              ),
              const SizedBox(height: 16),
              _QuestionSection<CheckInDifficulty>(
                title: 'How difficult does your calorie target feel?',
                value: _targetDifficulty,
                options: CheckInDifficulty.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => setState(() => _targetDifficulty = value),
              ),
              const SizedBox(height: 16),
              _QuestionSection<CheckInHunger>(
                title: 'How has your hunger been?',
                value: _hunger,
                options: CheckInHunger.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => setState(() => _hunger = value),
              ),
              const SizedBox(height: 16),
              _QuestionSection<CheckInPlanFit>(
                title: 'Do you think your current plan still fits you?',
                value: _planFit,
                options: CheckInPlanFit.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => setState(() => _planFit = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current weight (optional)',
                  suffixText: 'kg',
                  helperText:
                      'If you want to update this, we will save the check-in and let you review your profile next.',
                ),
              ),
              const SizedBox(height: 16),
              _RecommendationCard(recommendation: recommendation),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: controllerState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (shouldOfferProfileAction)
          OutlinedButton(
            onPressed: controllerState.isLoading
                ? null
                : () => _save(CheckInDialogResult.savedAndOpenProfile),
            child: const Text('Save and open profile'),
          ),
        FilledButton(
          onPressed: controllerState.isLoading
              ? null
              : () => _save(CheckInDialogResult.saved),
          child: controllerState.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save check-in'),
        ),
      ],
    );
  }

  Future<void> _save(CheckInDialogResult result) async {
    final period = widget.availability.period!;
    final recommendation = await ref
        .read(checkInControllerProvider.notifier)
        .submit(
          periodKey: period.key,
          periodStart: period.startDate,
          periodEnd: period.endDate,
          weightTrend: _weightTrend,
          targetDifficulty: _targetDifficulty,
          hunger: _hunger,
          planFit: _planFit,
          updatedWeightKg: double.tryParse(_weightCtrl.text),
        );

    if (!mounted || recommendation == null) return;
    Navigator.of(context).pop(result);
  }
}

class _CheckInContextCard extends StatelessWidget {
  const _CheckInContextCard({
    required this.targetCalories,
    required this.loggedDays,
    required this.greenDays,
  });

  final int targetCalories;
  final int loggedDays;
  final int greenDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ContextMetric(
              label: 'Daily target',
              value: '$targetCalories kcal',
            ),
          ),
          Expanded(
            child: _ContextMetric(
              label: 'Logged days',
              value: '$loggedDays / 14',
            ),
          ),
          Expanded(
            child: _ContextMetric(
              label: 'On track days',
              value: '$greenDays',
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMetric extends StatelessWidget {
  const _ContextMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionSection<T> extends StatelessWidget {
  const _QuestionSection({
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = option == value;
            return ChoiceChip(
              label: Text(labelBuilder(option)),
              selected: selected,
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final CheckInRecommendationResult recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.reason,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

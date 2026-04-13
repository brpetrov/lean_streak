import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/models/meal.dart';
import '../data/repositories/ai_usage_repository.dart';
import '../data/services/calorie_estimate_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/ai_usage_provider.dart';
import 'providers/log_meal_controller.dart';

/// Opens the log-meal bottom sheet from any screen.
Future<void> showLogMealSheet(
  BuildContext context, {
  Meal? existingMeal,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LogMealSheet(existingMeal: existingMeal),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _LogMealSheet extends ConsumerStatefulWidget {
  const _LogMealSheet({this.existingMeal});

  final Meal? existingMeal;

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet> {
  // Meal form state
  MealType? _mealType;
  final _caloriesController = TextEditingController();
  final Set<MealTag> _selectedTags = {};
  final _noteController = TextEditingController();
  String? _errorMessage;

  // AI estimator state
  bool _showEstimator = false;
  final _descriptionController = TextEditingController();
  bool _estimating = false;
  CalorieEstimate? _estimate;
  String? _estimateError;

  bool get _isEditing => widget.existingMeal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.existingMeal;
    if (meal == null) return;

    _mealType = meal.mealType;
    _caloriesController.text = meal.calories.round().toString();
    _selectedTags.addAll(meal.tags);
    _noteController.text = meal.note ?? '';
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final calories = double.tryParse(_caloriesController.text.trim());

    setState(() {
      if (_mealType == null) {
        _errorMessage = 'Please select a meal type.';
      } else if (calories == null || calories <= 0) {
        _errorMessage = 'Please enter a valid calorie count.';
      } else if (_selectedTags.isEmpty) {
        _errorMessage = 'Please select at least one tag.';
      } else {
        _errorMessage = null;
      }
    });

    if (_errorMessage != null) return;

    await ref
        .read(logMealControllerProvider.notifier)
        .submit(
          existingMeal: widget.existingMeal,
          mealType: _mealType!,
          calories: calories!,
          tags: _selectedTags.toList(),
          note: _noteController.text,
        );

    if (!mounted) return;

    final controllerState = ref.read(logMealControllerProvider);
    if (controllerState.hasError) {
      setState(() => _errorMessage = 'Failed to save meal. Please try again.');
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _runEstimate() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() {
      _estimating = true;
      _estimateError = null;
      _estimate = null;
    });

    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) throw Exception('Not authenticated');

      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimate(uid, description);

      if (mounted) {
        setState(() {
          _estimate = result;
          _estimating = false;
        });
      }
    } on DailyLimitExceededException {
      if (mounted) {
        setState(() {
          _estimateError = 'Daily limit reached — resets tomorrow.';
          _estimating = false;
        });
      }
    } on CalorieEstimateException catch (e) {
      if (mounted) {
        setState(() {
          _estimateError = 'Could not get an estimate — ${e.message}';
          _estimating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimateError = 'Unexpected error: $e';
          _estimating = false;
        });
      }
    }
  }

  void _useEstimate() {
    if (_estimate == null) return;
    _caloriesController.text = _estimate!.kcal.toString();
    setState(() {
      _showEstimator = false;
      _estimate = null;
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(logMealControllerProvider).isLoading;
    final usageCount = ref.watch(aiUsageTodayProvider).valueOrNull ?? 0;
    final remaining = (AiUsageRepository.dailyLimit - usageCount).clamp(
      0,
      AiUsageRepository.dailyLimit,
    );
    final limitReached = remaining == 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing ? 'Edit Meal' : 'Log Meal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Meal type ──────────────────────────────────────────
                  const _SectionLabel('MEAL TYPE'),
                  const SizedBox(height: 10),
                  _MealTypeSelector(
                    selected: _mealType,
                    onChanged: (t) => setState(() => _mealType = t),
                  ),
                  const SizedBox(height: 24),

                  // ── Calories ───────────────────────────────────────────
                  const _SectionLabel('CALORIES'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDisabled,
                      ),
                      suffixText: 'kcal',
                      suffixStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── AI estimator ───────────────────────────────────────
                  _AiEstimatorSection(
                    show: _showEstimator,
                    limitReached: limitReached,
                    remaining: remaining,
                    descriptionController: _descriptionController,
                    estimating: _estimating,
                    estimate: _estimate,
                    estimateError: _estimateError,
                    onToggle: () => setState(() {
                      _showEstimator = !_showEstimator;
                      _estimate = null;
                      _estimateError = null;
                    }),
                    onEstimate: _runEstimate,
                    onUse: _useEstimate,
                  ),
                  const SizedBox(height: 20),

                  // ── Tags ───────────────────────────────────────────────
                  const _SectionLabel('TAGS'),
                  const SizedBox(height: 4),
                  const Text(
                    'Select at least one — pick all that apply.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TagsSection(
                    selected: _selectedTags,
                    onToggle: (tag) => setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    }),
                  ),
                  const SizedBox(height: 24),

                  // ── Note (optional) ────────────────────────────────────
                  const _SectionLabel('NOTE  (OPTIONAL)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Chicken wrap from the cafe',
                      hintStyle: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  // ── Error banner ───────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Save button ────────────────────────────────────────
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Update Meal' : 'Save Meal',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI estimator section
// ---------------------------------------------------------------------------

class _AiEstimatorSection extends StatelessWidget {
  const _AiEstimatorSection({
    required this.show,
    required this.limitReached,
    required this.remaining,
    required this.descriptionController,
    required this.estimating,
    required this.estimate,
    required this.estimateError,
    required this.onToggle,
    required this.onEstimate,
    required this.onUse,
  });

  final bool show;
  final bool limitReached;
  final int remaining;
  final TextEditingController descriptionController;
  final bool estimating;
  final CalorieEstimate? estimate;
  final String? estimateError;
  final VoidCallback onToggle;
  final VoidCallback onEstimate;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button / limit message
        GestureDetector(
          onTap: limitReached ? null : onToggle,
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: limitReached
                    ? AppColors.textDisabled
                    : AppColors.primaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                limitReached
                    ? 'Daily AI limit reached — resets tomorrow'
                    : 'Not sure? Estimate with AI',
                style: TextStyle(
                  fontSize: 13,
                  color: limitReached
                      ? AppColors.textDisabled
                      : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!limitReached) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$remaining left today',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Expanded estimator panel
        if (show && !limitReached) ...[
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Describe your meal, e.g. "grilled chicken with rice and salad"',
              hintStyle: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Estimate button or spinner
          if (estimating)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onEstimate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Estimate',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          // Result card
          if (estimate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tagPositiveBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tagPositive),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '~${estimate!.kcal} kcal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tagPositive,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estimate!.note,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onUse,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.tagPositive,
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Use this',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error message
          if (estimateError != null) ...[
            const SizedBox(height: 10),
            Text(
              estimateError!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.selected, required this.onChanged});
  final MealType? selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MealType.values.map((type) {
        final isSelected = selected == type;
        return ChoiceChip(
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceVariant,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.selected, required this.onToggle});
  final Set<MealTag> selected;
  final ValueChanged<MealTag> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TagGroup(
          label: 'Positive',
          tags: MealTag.positive,
          selected: selected,
          onToggle: onToggle,
          activeColor: AppColors.tagPositive,
          activeBg: AppColors.tagPositiveBg,
        ),
        const SizedBox(height: 14),
        _TagGroup(
          label: 'Caution',
          tags: MealTag.warning,
          selected: selected,
          onToggle: onToggle,
          activeColor: AppColors.tagWarning,
          activeBg: AppColors.tagWarningBg,
        ),
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.label,
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.activeColor,
    required this.activeBg,
  });

  final String label;
  final List<MealTag> tags;
  final Set<MealTag> selected;
  final ValueChanged<MealTag> onToggle;
  final Color activeColor;
  final Color activeBg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activeColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: tags.map((tag) {
            final isSelected = selected.contains(tag);
            return FilterChip(
              label: Text(tag.label),
              selected: isSelected,
              onSelected: (_) => onToggle(tag),
              selectedColor: activeBg,
              backgroundColor: AppColors.surfaceVariant,
              checkmarkColor: activeColor,
              labelStyle: TextStyle(
                color: isSelected ? activeColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? activeColor : AppColors.divider,
              ),
              showCheckmark: true,
            );
          }).toList(),
        ),
      ],
    );
  }
}

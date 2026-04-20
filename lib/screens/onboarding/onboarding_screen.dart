import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ── Live preview ─────────────────────────────────────────────────────────

  _GoalPreview? get _preview {
    final currentWeight = double.tryParse(_currentWeightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);

    if (currentWeight == null ||
        height == null ||
        age == null ||
        _gender == null) {
      return null;
    }

    final calcBmr = HealthCalculator.bmr(currentWeight, height, age, _gender!);
    final calcTdee = HealthCalculator.tdee(calcBmr, _activityLevel);
    if (_weightLossPace == WeightLossPace.maintain) {
      return _GoalPreview(
        isMaintaining: true,
        calories: HealthCalculator.maintenanceCalories(calcTdee),
        pace: 0,
        paceLevel: GoalPaceLevel.safe,
        targetDate: DateTime.now(),
        tdee: calcTdee,
        clamped: false,
      );
    }

    final targetWeight = double.tryParse(_targetWeightCtrl.text);
    if (targetWeight == null || targetWeight >= currentWeight) {
      return null;
    }

    final pace = HealthCalculator.goalPaceFromWeightLossPace(_weightLossPace);
    final targetDate = HealthCalculator.targetDateFromWeightLossPace(
      currentWeight,
      targetWeight,
      _weightLossPace,
    );
    final paceLevel = HealthCalculator.goalPaceLevel(pace);
    final (:calories, :clamped) = HealthCalculator.dailyCalorieTargetFromPace(
      tdee: calcTdee,
      paceKgPerWeek: pace,
      gender: _gender!,
    );

    return _GoalPreview(
      isMaintaining: false,
      calories: calories,
      pace: pace,
      paceLevel: paceLevel,
      targetDate: targetDate,
      tdee: calcTdee,
      clamped: clamped,
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showSnack('Please select your gender.');
      return;
    }

    await ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          name: _nameCtrl.text,
          age: int.parse(_ageCtrl.text),
          gender: _gender!,
          heightCm: double.parse(_heightCtrl.text),
          currentWeightKg: double.parse(_currentWeightCtrl.text),
          targetWeightKg: _weightLossPace == WeightLossPace.maintain
              ? null
              : double.parse(_targetWeightCtrl.text),
          activityLevel: _activityLevel,
          weightLossPace: _weightLossPace,
        );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(onboardingControllerProvider, (_, next) {
      if (next.hasError) {
        _showSnack('Something went wrong. Please try again.');
      }
    });

    final isLoading = ref.watch(onboardingControllerProvider).isLoading;
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final preview = _preview;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: isLoading || isSigningOut
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(
                      isSigningOut ? 'Signing out...' : 'Back to sign in',
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Let\'s get started',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tell us about yourself so we can build your personal plan.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32),

                // ── About you ──────────────────────────────────────────
                const _SectionLabel('ABOUT YOU'),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name.'
                      : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Please enter your age.';
                    if (n < 13 || n > 120) return 'Valid age: 13–120.';
                    return null;
                  },
                ),
                SizedBox(height: 14),
                Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _GenderButton(
                      label: 'Male',
                      selected: _gender == Gender.male,
                      onTap: () => setState(() => _gender = Gender.male),
                    ),
                    SizedBox(width: 8),
                    _GenderButton(
                      label: 'Female',
                      selected: _gender == Gender.female,
                      onTap: () => setState(() => _gender = Gender.female),
                    ),
                    SizedBox(width: 8),
                    _GenderButton(
                      label: 'Other',
                      selected: _gender == Gender.other,
                      onTap: () => setState(() => _gender = Gender.other),
                    ),
                  ],
                ),
                SizedBox(height: 28),

                // ── Your body ──────────────────────────────────────────
                const _SectionLabel('YOUR BODY'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}\.?\d{0,1}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 100 || n > 250) return '100–250 cm';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currentWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}\.?\d{0,1}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Current weight',
                          suffixText: 'kg',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 30 || n > 300) return '30–300 kg';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),

                // ── Your goal ──────────────────────────────────────────
                const _SectionLabel('YOUR GOAL'),
                Text(
                  'Choose how quickly you want to lose weight, or maintain instead.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                ...WeightLossPace.values.map(
                  (pace) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaceCard(
                      pace: pace,
                      selected: _weightLossPace == pace,
                      onTap: () => setState(() => _weightLossPace = pace),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (_weightLossPace != WeightLossPace.maintain) ...[
                  TextFormField(
                    controller: _targetWeightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}\.?\d{0,1}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Target weight',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (v) {
                      if (_weightLossPace == WeightLossPace.maintain) {
                        return null;
                      }
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 30 || n > 300) return '30-300 kg';
                      final current = double.tryParse(_currentWeightCtrl.text);
                      if (current != null && n >= current) {
                        return 'Must be less than your current weight';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'We will aim for a daily calorie target close to your maintenance calories.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 28),

                // ── Activity level ─────────────────────────────────────
                const _SectionLabel('HOW ACTIVE ARE YOU?'),
                Text(
                  'Used to estimate how many calories you burn each day.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                ...ActivityLevel.values.map(
                  (level) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(
                      level: level,
                      selected: _activityLevel == level,
                      onTap: () => setState(() => _activityLevel = level),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // ── Weight loss pace ───────────────────────────────────

                // ── Plan preview ───────────────────────────────────────
                if (preview != null) ...[
                  _PlanPreviewCard(preview: preview),
                  SizedBox(height: 20),
                ],

                // ── Submit ─────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Get My Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview data class
// ---------------------------------------------------------------------------

class _GoalPreview {
  const _GoalPreview({
    required this.isMaintaining,
    required this.calories,
    required this.pace,
    required this.paceLevel,
    required this.targetDate,
    required this.tdee,
    required this.clamped,
  });

  final bool isMaintaining;
  final double calories;
  final double pace;
  final GoalPaceLevel paceLevel;
  final DateTime targetDate;
  final double tdee;
  final bool clamped;
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Activity level card ────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });
  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  static String _title(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.lightlyActive => 'Lightly active',
    ActivityLevel.moderatelyActive => 'Moderately active',
    ActivityLevel.veryActive => 'Very active',
  };

  static String _description(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary =>
      'Desk job, low steps, little structured exercise.',
    ActivityLevel.lightlyActive =>
      'Some walking, light exercise 1-3 days per week.',
    ActivityLevel.moderatelyActive =>
      'Regular training 3-5 days per week or active daily routine.',
    ActivityLevel.veryActive =>
      'Hard training 6-7 days per week, physical job, or high movement.',
  };

  static IconData _icon(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary => Icons.weekend_outlined,
    ActivityLevel.lightlyActive => Icons.directions_walk_outlined,
    ActivityLevel.moderatelyActive => Icons.directions_run_outlined,
    ActivityLevel.veryActive => Icons.fitness_center_outlined,
  };

  @override
  Widget build(BuildContext context) => _SelectionCard(
    title: _title(level),
    description: _description(level),
    icon: _icon(level),
    selected: selected,
    onTap: onTap,
  );
}

// ── Weight loss pace card ──────────────────────────────────────────────────

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pace,
    required this.selected,
    required this.onTap,
  });
  final WeightLossPace pace;
  final bool selected;
  final VoidCallback onTap;

  static String _title(WeightLossPace p) => switch (p) {
    WeightLossPace.slow => 'Slow - 0.5 kg/week',
    WeightLossPace.moderate => 'Moderate - 0.75 kg/week',
    WeightLossPace.fast => 'Fast - 1.0 kg/week',
    WeightLossPace.maintain => 'Maintain weight',
  };

  static String _description(WeightLossPace p) => switch (p) {
    WeightLossPace.slow =>
      'Gentle and easy to maintain. Takes longer but less restriction.',
    WeightLossPace.moderate =>
      'Good balance of speed and sustainability. Recommended for most.',
    WeightLossPace.fast =>
      'Faster results. Requires more discipline and consistency.',
    WeightLossPace.maintain =>
      'Keeps your calories around maintenance instead of creating a deficit.',
  };

  static IconData _icon(WeightLossPace p) => switch (p) {
    WeightLossPace.slow => Icons.hourglass_bottom_rounded,
    WeightLossPace.moderate => Icons.trending_down_rounded,
    WeightLossPace.fast => Icons.bolt_rounded,
    WeightLossPace.maintain => Icons.horizontal_rule_rounded,
  };

  @override
  Widget build(BuildContext context) => _SelectionCard(
    title: _title(pace),
    description: _description(pace),
    icon: _icon(pace),
    selected: selected,
    onTap: onTap,
  );
}

// ── Shared selection card ──────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Plan preview card ──────────────────────────────────────────────────────

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({required this.preview});
  final _GoalPreview preview;

  Color get _color => switch (preview.paceLevel) {
    GoalPaceLevel.safe => AppColors.veryGood,
    GoalPaceLevel.caution => AppColors.bad,
    GoalPaceLevel.warning => AppColors.veryBad,
  };

  String get _paceLabel => switch (preview.paceLevel) {
    GoalPaceLevel.safe => 'Safe pace',
    GoalPaceLevel.caution => 'Caution — fast pace',
    GoalPaceLevel.warning => 'Very aggressive',
  };

  String get _paceMessage => switch (preview.paceLevel) {
    GoalPaceLevel.safe => 'Healthy and sustainable.',
    GoalPaceLevel.caution =>
      'Faster than average. Stay consistent with your nutrition.',
    GoalPaceLevel.warning =>
      'Very aggressive. Make sure you stay fuelled and healthy.',
  };

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(preview.targetDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _color, size: 18),
              SizedBox(width: 8),
              Text(
                'Your plan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Daily target',
                  value: '${preview.calories.round()} kcal',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Loss per week',
                  value: '${preview.pace.toStringAsFixed(2)} kg',
                ),
              ),
              Expanded(
                child: _Stat(label: 'Goal by', value: dateStr),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                preview.paceLevel == GoalPaceLevel.safe
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                color: _color,
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _paceMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (preview.clamped) ...[
                      SizedBox(height: 4),
                      Text(
                        'Calorie target set to safe minimum floor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

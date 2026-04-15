import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  String? _loadedProfileUid;
  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.light;
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

  _GoalPreview? get _preview {
    final currentWeight = double.tryParse(_currentWeightCtrl.text);
    final targetWeight = double.tryParse(_targetWeightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);

    if (currentWeight == null ||
        targetWeight == null ||
        height == null ||
        age == null ||
        _gender == null ||
        targetWeight >= currentWeight) {
      return null;
    }

    final pace = HealthCalculator.goalPaceFromWeightLossPace(_weightLossPace);
    final targetDate = HealthCalculator.targetDateFromWeightLossPace(
      currentWeight,
      targetWeight,
      _weightLossPace,
    );
    final bmr = HealthCalculator.bmr(currentWeight, height, age, _gender!);
    final tdee = HealthCalculator.tdee(bmr, _activityLevel);
    final paceLevel = HealthCalculator.goalPaceLevel(pace);
    final (:calories, :clamped) = HealthCalculator.dailyCalorieTargetFromPace(
      tdee: tdee,
      paceKgPerWeek: pace,
      gender: _gender!,
    );

    return _GoalPreview(
      calories: calories,
      pace: pace,
      paceLevel: paceLevel,
      targetDate: targetDate,
      clamped: clamped,
    );
  }

  void _seedForm(UserProfile profile) {
    if (_loadedProfileUid == profile.uid) return;

    _loadedProfileUid = profile.uid;
    _nameCtrl.text = profile.name;
    _ageCtrl.text = profile.age.toString();
    _heightCtrl.text = _formatDouble(profile.heightCm);
    _currentWeightCtrl.text = _formatDouble(profile.currentWeightKg);
    _targetWeightCtrl.text = _formatDouble(profile.targetWeightKg);
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _weightLossPace = profile.weightLossPace;
  }

  Future<void> _submit(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showSnack('Please select your gender.');
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(
          currentProfile: profile,
          name: _nameCtrl.text,
          age: int.parse(_ageCtrl.text),
          gender: _gender!,
          heightCm: double.parse(_heightCtrl.text),
          currentWeightKg: double.parse(_currentWeightCtrl.text),
          targetWeightKg: double.parse(_targetWeightCtrl.text),
          activityLevel: _activityLevel,
          weightLossPace: _weightLossPace,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      return;
    }

    _showSnack('Could not update your profile right now.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final isSaving = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Could not load your profile right now.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          _seedForm(profile);
          final preview = _preview;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Update your details',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We will recalculate your calorie target and goal date based on these changes.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionLabel('ABOUT YOU'),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null) return 'Please enter your age.';
                        if (age < 13 || age > 120) return 'Valid age: 13-120.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _GenderButton(
                          label: 'Male',
                          selected: _gender == Gender.male,
                          onTap: () => setState(() => _gender = Gender.male),
                        ),
                        const SizedBox(width: 8),
                        _GenderButton(
                          label: 'Female',
                          selected: _gender == Gender.female,
                          onTap: () => setState(() => _gender = Gender.female),
                        ),
                        const SizedBox(width: 8),
                        _GenderButton(
                          label: 'Other',
                          selected: _gender == Gender.other,
                          onTap: () => setState(() => _gender = Gender.other),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
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
                            decoration: const InputDecoration(
                              labelText: 'Height',
                              suffixText: 'cm',
                            ),
                            validator: (value) {
                              final height = double.tryParse(value ?? '');
                              if (height == null) return 'Required';
                              if (height < 100 || height > 250) {
                                return '100-250 cm';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            decoration: const InputDecoration(
                              labelText: 'Current weight',
                              suffixText: 'kg',
                            ),
                            validator: (value) {
                              final weight = double.tryParse(value ?? '');
                              if (weight == null) return 'Required';
                              if (weight < 30 || weight > 300) {
                                return '30-300 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _SectionLabel('YOUR GOAL'),
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
                      decoration: const InputDecoration(
                        labelText: 'Target weight',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (value) {
                        final target = double.tryParse(value ?? '');
                        if (target == null) return 'Required';
                        if (target < 30 || target > 300) return '30-300 kg';
                        final current = double.tryParse(
                          _currentWeightCtrl.text,
                        );
                        if (current != null && target >= current) {
                          return 'Must be less than your current weight';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    const _SectionLabel('HOW ACTIVE ARE YOU?'),
                    const Text(
                      'Used to estimate how many calories you burn each day.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    const _SectionLabel('HOW FAST DO YOU WANT TO LOSE WEIGHT?'),
                    const Text(
                      'This changes your daily calorie target and estimated finish date.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    if (preview != null) ...[
                      _PlanPreviewCard(preview: preview),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () => _submit(profile),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(
          child: Text(
            'Could not load your profile right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _GoalPreview {
  const _GoalPreview({
    required this.calories,
    required this.pace,
    required this.paceLevel,
    required this.targetDate,
    required this.clamped,
  });

  final double calories;
  final double pace;
  final GoalPaceLevel paceLevel;
  final DateTime targetDate;
  final bool clamped;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
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
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  static String _title(ActivityLevel level) => switch (level) {
    ActivityLevel.light => 'Mostly sedentary',
    ActivityLevel.medium => 'Lightly active',
    ActivityLevel.hard => 'Very active',
  };

  static String _description(ActivityLevel level) => switch (level) {
    ActivityLevel.light => 'Desk job, little exercise, low daily movement.',
    ActivityLevel.medium =>
      'Some walking or light exercise a few times per week.',
    ActivityLevel.hard => 'Regular training, physical job, or high movement.',
  };

  static IconData _icon(ActivityLevel level) => switch (level) {
    ActivityLevel.light => Icons.weekend_outlined,
    ActivityLevel.medium => Icons.directions_walk_outlined,
    ActivityLevel.hard => Icons.fitness_center_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: _title(level),
      description: _description(level),
      icon: _icon(level),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pace,
    required this.selected,
    required this.onTap,
  });

  final WeightLossPace pace;
  final bool selected;
  final VoidCallback onTap;

  static String _title(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow => 'Slow - 0.5 kg/week',
    WeightLossPace.moderate => 'Moderate - 0.75 kg/week',
    WeightLossPace.fast => 'Fast - 1.0 kg/week',
  };

  static String _description(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow =>
      'Gentle and easier to maintain over a longer period.',
    WeightLossPace.moderate =>
      'Best balance of speed and sustainability for most people.',
    WeightLossPace.fast =>
      'Faster results, but requires more consistency and restriction.',
  };

  static IconData _icon(WeightLossPace pace) => switch (pace) {
    WeightLossPace.slow => Icons.hourglass_bottom_rounded,
    WeightLossPace.moderate => Icons.trending_down_rounded,
    WeightLossPace.fast => Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      title: _title(pace),
      description: _description(pace),
      icon: _icon(pace),
      selected: selected,
      onTap: onTap,
    );
  }
}

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
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
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
    GoalPaceLevel.caution => 'Caution - fast pace',
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
    final dateString = DateFormat('d MMM yyyy').format(preview.targetDate);

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
              const SizedBox(width: 8),
              Text(
                'Updated plan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                child: _Stat(label: 'Goal by', value: dateString),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 6),
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
                    const SizedBox(height: 2),
                    Text(
                      _paceMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (preview.clamped) ...[
                      const SizedBox(height: 4),
                      const Text(
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
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

String _formatDouble(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum Gender {
  male('male'),
  female('female'),
  other('other');

  const Gender(this.value);
  final String value;

  static Gender fromString(String s) =>
      Gender.values.firstWhere((e) => e.value == s);
}

/// How physically active the user is — used for TDEE calculation.
enum ActivityLevel {
  sedentary('sedentary'),
  lightlyActive('lightly_active'),
  moderatelyActive('moderately_active'),
  veryActive('very_active');

  const ActivityLevel(this.value);
  final String value;

  static ActivityLevel fromString(String s) {
    return switch (s) {
      'sedentary' || 'light' => ActivityLevel.sedentary,
      'lightly_active' ||
      'lightlyActive' ||
      'medium' => ActivityLevel.lightlyActive,
      'moderately_active' ||
      'moderatelyActive' ||
      'hard' => ActivityLevel.moderatelyActive,
      'very_active' || 'veryActive' => ActivityLevel.veryActive,
      _ => throw ArgumentError.value(s, 's', 'Unknown activity level'),
    };
  }
}

const currentActivityScaleVersion = 2;

/// How quickly the user wants to lose weight — determines target date & deficit.
enum WeightLossPace {
  slow('slow'),
  moderate('moderate'),
  fast('fast'),
  maintain('maintain');

  const WeightLossPace(this.value);
  final String value;

  static WeightLossPace fromString(String s) =>
      WeightLossPace.values.firstWhere((e) => e.value == s);
}

enum GoalPaceLevel {
  safe('safe'),
  caution('caution'),
  warning('warning');

  const GoalPaceLevel(this.value);
  final String value;

  static GoalPaceLevel fromString(String s) =>
      GoalPaceLevel.values.firstWhere((e) => e.value == s);
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.activityScaleVersion,
    required this.weightLossPace,
    required this.targetDate,
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.dailyCalorieTarget,
    required this.goalPaceKgPerWeek,
    required this.goalPaceLevel,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String email;
  final String name;
  final int age;
  final Gender gender;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;

  /// Physical activity level — used to compute TDEE.
  final ActivityLevel activityLevel;
  final int activityScaleVersion;

  /// Desired weight loss pace — used to compute target date and daily deficit.
  final WeightLossPace weightLossPace;

  final DateTime targetDate;

  // Calculated fields — derived during onboarding, stored for quick reads.
  final double bmi;
  final double bmr;
  final double tdee;
  final double dailyCalorieTarget;
  final double goalPaceKgPerWeek;
  final GoalPaceLevel goalPaceLevel;

  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialisation ──────────────────────────────────────────────────────

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return UserProfile(
      uid: d['uid'] as String,
      email: d['email'] as String,
      name: d['name'] as String,
      age: d['age'] as int,
      gender: Gender.fromString(d['gender'] as String),
      heightCm: (d['heightCm'] as num).toDouble(),
      currentWeightKg: (d['currentWeightKg'] as num).toDouble(),
      targetWeightKg: (d['targetWeightKg'] as num).toDouble(),
      activityLevel: ActivityLevel.fromString(d['activityLevel'] as String),
      activityScaleVersion: (d['activityScaleVersion'] as num?)?.round() ?? 1,
      weightLossPace: WeightLossPace.fromString(d['weightLossPace'] as String),
      targetDate: (d['targetDate'] as Timestamp).toDate(),
      bmi: (d['bmi'] as num).toDouble(),
      bmr: (d['bmr'] as num).toDouble(),
      tdee: (d['tdee'] as num).toDouble(),
      dailyCalorieTarget: (d['dailyCalorieTarget'] as num).toDouble(),
      goalPaceKgPerWeek: (d['goalPaceKgPerWeek'] as num).toDouble(),
      goalPaceLevel: GoalPaceLevel.fromString(d['goalPaceLevel'] as String),
      onboardingCompleted: d['onboardingCompleted'] as bool,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'name': name,
    'age': age,
    'gender': gender.value,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'activityLevel': activityLevel.value,
    'activityScaleVersion': activityScaleVersion,
    'weightLossPace': weightLossPace.value,
    'targetDate': Timestamp.fromDate(targetDate),
    'bmi': bmi,
    'bmr': bmr,
    'tdee': tdee,
    'dailyCalorieTarget': dailyCalorieTarget,
    'goalPaceKgPerWeek': goalPaceKgPerWeek,
    'goalPaceLevel': goalPaceLevel.value,
    'onboardingCompleted': onboardingCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  // ── copyWith ───────────────────────────────────────────────────────────

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    int? activityScaleVersion,
    WeightLossPace? weightLossPace,
    DateTime? targetDate,
    double? bmi,
    double? bmr,
    double? tdee,
    double? dailyCalorieTarget,
    double? goalPaceKgPerWeek,
    GoalPaceLevel? goalPaceLevel,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      activityScaleVersion: activityScaleVersion ?? this.activityScaleVersion,
      weightLossPace: weightLossPace ?? this.weightLossPace,
      targetDate: targetDate ?? this.targetDate,
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      goalPaceKgPerWeek: goalPaceKgPerWeek ?? this.goalPaceKgPerWeek,
      goalPaceLevel: goalPaceLevel ?? this.goalPaceLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

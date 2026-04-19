import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckInWeightTrend {
  down('down', 'Down'),
  same('same', 'About the same'),
  up('up', 'Up');

  const CheckInWeightTrend(this.value, this.label);

  final String value;
  final String label;

  static CheckInWeightTrend fromString(String value) {
    return CheckInWeightTrend.values.firstWhere((item) {
      return item.value == value;
    });
  }
}

enum CheckInDifficulty {
  easy('easy', 'Easy'),
  manageable('manageable', 'Manageable'),
  hard('hard', 'Hard');

  const CheckInDifficulty(this.value, this.label);

  final String value;
  final String label;

  static CheckInDifficulty fromString(String value) {
    return CheckInDifficulty.values.firstWhere((item) {
      return item.value == value;
    });
  }
}

enum CheckInHunger {
  low('low', 'Low'),
  normal('normal', 'Normal'),
  high('high', 'High');

  const CheckInHunger(this.value, this.label);

  final String value;
  final String label;

  static CheckInHunger fromString(String value) {
    return CheckInHunger.values.firstWhere((item) {
      return item.value == value;
    });
  }
}

enum CheckInPlanFit {
  yes('yes', 'Yes'),
  notSure('not_sure', 'Not sure'),
  no('no', 'No');

  const CheckInPlanFit(this.value, this.label);

  final String value;
  final String label;

  static CheckInPlanFit fromString(String value) {
    return CheckInPlanFit.values.firstWhere((item) {
      return item.value == value;
    });
  }
}

enum CheckInRecommendation {
  stayTheCourse('stay_the_course', 'Stay the course'),
  reviewTargets('review_targets', 'Review targets'),
  reviewPace('review_pace', 'Review pace');

  const CheckInRecommendation(this.value, this.label);

  final String value;
  final String label;

  static CheckInRecommendation fromString(String value) {
    return CheckInRecommendation.values.firstWhere((item) {
      return item.value == value;
    });
  }
}

class CheckIn {
  const CheckIn({
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
    required this.weightTrend,
    required this.targetDifficulty,
    required this.hunger,
    required this.planFit,
    required this.recommendation,
    this.updatedWeightKg,
    this.recommendationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String periodKey;
  final DateTime periodStart;
  final DateTime periodEnd;
  final CheckInWeightTrend weightTrend;
  final CheckInDifficulty targetDifficulty;
  final CheckInHunger hunger;
  final CheckInPlanFit planFit;
  final CheckInRecommendation recommendation;
  final double? updatedWeightKg;
  final String? recommendationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CheckIn.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return CheckIn(
      periodKey: data['periodKey'] as String,
      periodStart: (data['periodStart'] as Timestamp).toDate(),
      periodEnd: (data['periodEnd'] as Timestamp).toDate(),
      weightTrend: CheckInWeightTrend.fromString(data['weightTrend'] as String),
      targetDifficulty: CheckInDifficulty.fromString(
        data['targetDifficulty'] as String,
      ),
      hunger: CheckInHunger.fromString(data['hunger'] as String),
      planFit: CheckInPlanFit.fromString(data['planFit'] as String),
      recommendation: CheckInRecommendation.fromString(
        data['recommendation'] as String,
      ),
      updatedWeightKg: (data['updatedWeightKg'] as num?)?.toDouble(),
      recommendationReason: data['recommendationReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'periodKey': periodKey,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'weightTrend': weightTrend.value,
      'targetDifficulty': targetDifficulty.value,
      'hunger': hunger.value,
      'planFit': planFit.value,
      'recommendation': recommendation.value,
      'updatedWeightKg': updatedWeightKg,
      'recommendationReason': recommendationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

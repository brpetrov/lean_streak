import 'package:cloud_firestore/cloud_firestore.dart';

enum DailyCategory {
  veryGood('very_good', 'Very good'),
  good('good', 'Good'),
  bad('bad', 'Bad'),
  veryBad('very_bad', 'Very bad');

  const DailyCategory(this.value, this.label);

  final String value;
  final String label;

  static DailyCategory fromString(String value) {
    return DailyCategory.values.firstWhere((category) {
      return category.value == value;
    });
  }
}

class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.targetCalories,
    required this.calorieDelta,
    required this.mealCount,
    required this.tagCounts,
    required this.score,
    required this.maxScore,
    required this.category,
    required this.explanation,
    required this.updatedAt,
  });

  final String date;
  final int totalCalories;
  final int targetCalories;
  final int calorieDelta;
  final int mealCount;
  final Map<String, int> tagCounts;
  final int score;
  final int maxScore;
  final DailyCategory category;
  final List<String> explanation;
  final DateTime updatedAt;

  factory DailySummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return DailySummary(
      date: data['date'] as String,
      totalCalories: (data['totalCalories'] as num).round(),
      targetCalories: (data['targetCalories'] as num).round(),
      calorieDelta: (data['calorieDelta'] as num).round(),
      mealCount: data['mealCount'] as int,
      tagCounts: (data['tagCounts'] as Map<String, dynamic>).map((key, value) {
        return MapEntry(key, (value as num).round());
      }),
      score: data['score'] as int,
      maxScore: data['maxScore'] as int,
      category: DailyCategory.fromString(data['category'] as String),
      explanation: List<String>.from(data['explanation'] as List<dynamic>),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'targetCalories': targetCalories,
      'calorieDelta': calorieDelta,
      'mealCount': mealCount,
      'tagCounts': tagCounts,
      'score': score,
      'maxScore': maxScore,
      'category': category.value,
      'explanation': explanation,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

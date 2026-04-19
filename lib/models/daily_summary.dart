import 'package:cloud_firestore/cloud_firestore.dart';

enum DailyStatus {
  green('green', 'On track'),
  yellow('yellow', 'Close'),
  red('red', 'Off track');

  const DailyStatus(this.value, this.label);

  final String value;
  final String label;

  static DailyStatus fromString(String value) {
    return DailyStatus.values.firstWhere((status) => status.value == value);
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
    required this.status,
    required this.updatedAt,
  });

  final String date;
  final int totalCalories;
  final int targetCalories;
  final int calorieDelta;
  final int mealCount;
  final Map<String, int> tagCounts;
  final DailyStatus status;
  final DateTime updatedAt;

  double get deltaRatio {
    if (targetCalories <= 0) return 0;
    return calorieDelta.abs() / targetCalories;
  }

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
      tagCounts: (data['tagCounts'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, (value as num).round()),
      ),
      status: _statusFromFirestore(data),
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
      'status': status.value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DailyStatus _statusFromFirestore(Map<String, dynamic> data) {
    final storedStatus = data['status'] as String?;
    if (storedStatus != null) {
      return DailyStatus.fromString(storedStatus);
    }

    final targetCalories = (data['targetCalories'] as num?)?.round() ?? 0;
    final totalCalories = (data['totalCalories'] as num?)?.round() ?? 0;
    if (targetCalories <= 0) return DailyStatus.red;

    final ratio = (totalCalories - targetCalories).abs() / targetCalories;
    if (ratio <= 0.10) return DailyStatus.green;
    if (ratio <= 0.20) return DailyStatus.yellow;
    return DailyStatus.red;
  }
}

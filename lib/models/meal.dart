import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.timestamp,
    this.name,
    required this.calories,
    this.proteinGrams,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final DateTime timestamp;
  final String? name;
  final double calories;

  /// Null when unknown, e.g. calorie-only entries with no meal name.
  final double? proteinGrams;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Older meals may still carry `tags` and `note` fields; they are ignored.
  factory Meal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Meal(
      id: data['id'] as String,
      date: data['date'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      name: data['name'] as String?,
      calories: (data['calories'] as num).toDouble(),
      proteinGrams: (data['proteinGrams'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': date,
      'timestamp': Timestamp.fromDate(timestamp),
      'name': name,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

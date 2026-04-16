import 'package:cloud_firestore/cloud_firestore.dart';

enum MealTag {
  balanced('balanced', 'Balanced', true),
  highProtein('high_protein', 'High Protein', true),
  fruitVeg('fruit_veg', 'Fruit & Veg', true),
  sugary('sugary', 'High Sugar', false),
  fried('fried', 'Fried', false),
  processed('processed', 'Highly Processed', false),

  // Legacy values kept so older saved meals still load cleanly.
  homeCooked('home_cooked', 'Home Cooked', true, isSelectable: false),
  filling('filling', 'Filling', true, isSelectable: false),
  alcohol('alcohol', 'Alcohol', false, isSelectable: false),
  overate('overate', 'Overate', false, isSelectable: false);

  const MealTag(
    this.value,
    this.label,
    this.isPositive, {
    this.isSelectable = true,
  });

  final String value;
  final String label;
  final bool isPositive;
  final bool isSelectable;

  static MealTag fromString(String value) {
    return MealTag.values.firstWhere((tag) => tag.value == value);
  }

  static List<MealTag> get positive {
    return MealTag.values
        .where((tag) => tag.isPositive && tag.isSelectable)
        .toList();
  }

  static List<MealTag> get warning {
    return MealTag.values
        .where((tag) => !tag.isPositive && tag.isSelectable)
        .toList();
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.timestamp,
    required this.calories,
    required this.tags,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final DateTime timestamp;
  final double calories;
  final List<MealTag> tags;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Meal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Meal(
      id: data['id'] as String,
      date: data['date'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      calories: (data['calories'] as num).toDouble(),
      tags: (data['tags'] as List<dynamic>)
          .map((value) => MealTag.fromString(value as String))
          .toList(),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': date,
      'timestamp': Timestamp.fromDate(timestamp),
      'calories': calories,
      'tags': tags.map((tag) => tag.value).toList(),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

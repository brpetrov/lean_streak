import 'package:cloud_firestore/cloud_firestore.dart';

enum MealTagTone { healthy, neutral, unhealthy }

enum MealTag {
  balanced('balanced', 'Balanced', MealTagTone.healthy),
  highProtein('high_protein', 'High Protein', MealTagTone.healthy),
  fruitVeg('fruit_veg', 'Fruit & Veg', MealTagTone.healthy),
  baked('baked', 'Baked', MealTagTone.neutral),
  pastry('pastry', 'Pastry', MealTagTone.neutral),
  dairy('dairy', 'Dairy', MealTagTone.neutral),
  vegetarian('vegetarian', 'Vegetarian', MealTagTone.neutral),
  sugary('sugary', 'High Sugar', MealTagTone.unhealthy),
  fried('fried', 'Fried', MealTagTone.unhealthy),
  processed('processed', 'Highly Processed', MealTagTone.unhealthy),

  // Legacy values kept so older saved meals still load cleanly.
  homeCooked(
    'home_cooked',
    'Home Cooked',
    MealTagTone.healthy,
    isSelectable: false,
  ),
  filling('filling', 'Filling', MealTagTone.healthy, isSelectable: false),
  alcohol('alcohol', 'Alcohol', MealTagTone.unhealthy, isSelectable: false),
  overate('overate', 'Overate', MealTagTone.unhealthy, isSelectable: false);

  const MealTag(
    this.value,
    this.label,
    this.tone, {
    this.isSelectable = true,
  });

  final String value;
  final String label;
  final MealTagTone tone;
  final bool isSelectable;

  bool get isPositive => tone == MealTagTone.healthy;
  bool get isNeutral => tone == MealTagTone.neutral;
  bool get isWarning => tone == MealTagTone.unhealthy;

  static MealTag fromString(String value) {
    return MealTag.values.firstWhere((tag) => tag.value == value);
  }

  static List<MealTag> get positive {
    return MealTag.values
        .where((tag) => tag.tone == MealTagTone.healthy && tag.isSelectable)
        .toList();
  }

  static List<MealTag> get neutral {
    return MealTag.values
        .where((tag) => tag.tone == MealTagTone.neutral && tag.isSelectable)
        .toList();
  }

  static List<MealTag> get warning {
    return MealTag.values
        .where((tag) => tag.tone == MealTagTone.unhealthy && tag.isSelectable)
        .toList();
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.timestamp,
    this.name,
    required this.calories,
    required this.tags,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final DateTime timestamp;
  final String? name;
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
      name: data['name'] as String?,
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
      'name': name,
      'calories': calories,
      'tags': tags.map((tag) => tag.value).toList(),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

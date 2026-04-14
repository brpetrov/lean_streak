import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum MealType {
  breakfast('breakfast', 'Breakfast'),
  lunch('lunch', 'Lunch'),
  dinner('dinner', 'Dinner'),
  snack('snack', 'Snack');

  const MealType(this.value, this.label);
  final String value;
  final String label;

  static MealType fromString(String s) =>
      MealType.values.firstWhere((e) => e.value == s);
}

enum MealTag {
  // Positive
  balanced('balanced', 'Balanced', true),
  highProtein('high_protein', 'High Protein', true),
  fruitVeg('fruit_veg', 'Fruit & Veg', true),
  homeCooked('home_cooked', 'Home Cooked', true),
  filling('filling', 'Filling', true),
  // Warning
  processed('processed', 'Processed', false),
  sugary('sugary', 'Sugary', false),
  fried('fried', 'Fried', false),
  alcohol('alcohol', 'Alcohol', false),
  overate('overate', 'Overate', false);

  const MealTag(this.value, this.label, this.isPositive);
  final String value;
  final String label;
  final bool isPositive;

  static MealTag fromString(String s) =>
      MealTag.values.firstWhere((e) => e.value == s);

  static List<MealTag> get positive =>
      MealTag.values.where((t) => t.isPositive).toList();

  static List<MealTag> get warning =>
      MealTag.values.where((t) => !t.isPositive).toList();
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.timestamp,
    required this.mealType,
    required this.calories,
    required this.tags,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Date string in yyyy-MM-dd format.
  final String date;
  final DateTime timestamp;
  final MealType mealType;
  final double calories;
  final List<MealTag> tags;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialisation ──────────────────────────────────────────────────────

  factory Meal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Meal(
      id: d['id'] as String,
      date: d['date'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      mealType: MealType.fromString(d['mealType'] as String),
      calories: (d['calories'] as num).toDouble(),
      tags: (d['tags'] as List<dynamic>)
          .map((t) => MealTag.fromString(t as String))
          .toList(),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'date': date,
        'timestamp': Timestamp.fromDate(timestamp),
        'mealType': mealType.value,
        'calories': calories,
        'tags': tags.map((t) => t.value).toList(),
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

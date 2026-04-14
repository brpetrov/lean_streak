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

  // Warning
  sugary('sugary', 'High Sugar', false),
  fried('fried', 'Fried', false),
  processed('processed', 'Highly Processed', false),

  // Legacy tags kept so old saved meals still load.
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

  static MealTag fromString(String s) =>
      MealTag.values.firstWhere((e) => e.value == s);

  static List<MealTag> get positive =>
      MealTag.values.where((t) => t.isPositive && t.isSelectable).toList();

  static List<MealTag> get warning =>
      MealTag.values.where((t) => !t.isPositive && t.isSelectable).toList();
}

enum MealFeeling {
  satisfied('satisfied', 'Satisfied'),
  stillHungry('still_hungry', 'Still Hungry'),
  tooFull('too_full', 'Too Full');

  const MealFeeling(this.value, this.label);
  final String value;
  final String label;

  static MealFeeling fromString(String s) =>
      MealFeeling.values.firstWhere((e) => e.value == s);
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
    this.afterMealFeeling,
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
  final MealFeeling? afterMealFeeling;
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
      afterMealFeeling: d['afterMealFeeling'] == null
          ? null
          : MealFeeling.fromString(d['afterMealFeeling'] as String),
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
    'afterMealFeeling': afterMealFeeling?.value,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

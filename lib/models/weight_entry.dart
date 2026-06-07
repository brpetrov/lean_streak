import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a weight reading came from — lets the chart distinguish ad-hoc logs
/// from the readings captured during a 2-week check-in.
enum WeightSource {
  manual('manual'),
  checkIn('check_in');

  const WeightSource(this.value);

  final String value;

  static WeightSource fromString(String value) {
    return WeightSource.values.firstWhere(
      (item) => item.value == value,
      orElse: () => WeightSource.manual,
    );
  }
}

/// A single weight reading. Stored at `/users/{uid}/weight_entries/{dateKey}`
/// with the date as the document id, so at most one entry exists per day
/// (a second log on the same day overwrites the first).
class WeightEntry {
  const WeightEntry({
    required this.dateKey,
    required this.weightKg,
    required this.loggedAt,
    required this.source,
  });

  /// `yyyy-MM-dd` — also the Firestore document id.
  final String dateKey;
  final double weightKg;
  final DateTime loggedAt;
  final WeightSource source;

  DateTime get date => DateTime.parse(dateKey);

  factory WeightEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return WeightEntry(
      dateKey: data['dateKey'] as String? ?? doc.id,
      weightKg: (data['weightKg'] as num).toDouble(),
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
      source: WeightSource.fromString(data['source'] as String? ?? 'manual'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateKey': dateKey,
      'weightKg': weightKg,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'source': source.value,
    };
  }
}

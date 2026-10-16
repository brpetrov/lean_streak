import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

void main() {
  group('parseEstimateItems', () {
    test('reads the model items', () {
      expect(
        parseEstimateItems([
          {'item': 'Musaka', 'kcal': 520, 'protein_g': 28},
          {'item': ' Bread ', 'kcal': 80.4, 'protein_g': null},
        ]),
        [
          (name: 'Musaka', kcal: 520, protein: 28),
          (name: 'Bread', kcal: 80, protein: null),
        ],
      );
    });

    test('skips malformed entries and tolerates missing lists', () {
      expect(
        parseEstimateItems([
          {'item': 'Oil', 'kcal': 120},
          {'item': '', 'kcal': 50},
          {'kcal': 50},
          {'item': 'Mystery', 'kcal': 'lots'},
          'not a map',
        ]),
        [(name: 'Oil', kcal: 120, protein: null)],
      );
      expect(parseEstimateItems(null), isEmpty);
      expect(parseEstimateItems('items'), isEmpty);
    });
  });
}

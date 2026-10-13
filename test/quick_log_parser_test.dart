import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/quick_log_parser.dart';

void main() {
  group('parseQuickLog', () {
    test('reads a trailing number as calories', () {
      expect(parseQuickLog('chicken wrap 450'), (
        name: 'Chicken wrap',
        kcal: 450,
      ));
    });

    test('reads a number with a calorie unit anywhere', () {
      expect(parseQuickLog('450 kcal chicken wrap'), (
        name: 'Chicken wrap',
        kcal: 450,
      ));
      expect(parseQuickLog('porridge 320kcal'), (
        name: 'Porridge',
        kcal: 320,
      ));
      expect(parseQuickLog('apple 80 cal'), (
        name: 'Apple',
        kcal: 80,
      ));
      expect(parseQuickLog('Pizza slice 300 Calories'), (
        name: 'Pizza slice',
        kcal: 300,
      ));
    });

    test('keeps leading quantities in the name', () {
      expect(parseQuickLog('2 eggs on toast 300'), (
        name: '2 eggs on toast',
        kcal: 300,
      ));
      expect(parseQuickLog('2 eggs on toast'), (
        name: '2 eggs on toast',
        kcal: null,
      ));
    });

    test('handles thousands separators', () {
      expect(parseQuickLog('sunday roast 1,200 kcal'), (
        name: 'Sunday roast',
        kcal: 1200,
      ));
    });

    test('strips separators left around the number', () {
      expect(parseQuickLog('chicken wrap - 450'), (
        name: 'Chicken wrap',
        kcal: 450,
      ));
      expect(parseQuickLog('chicken wrap, 450 kcal'), (
        name: 'Chicken wrap',
        kcal: 450,
      ));
    });

    test('does not treat words starting with "cal" as a unit', () {
      expect(parseQuickLog('2 calzones'), (
        name: '2 calzones',
        kcal: null,
      ));
    });

    test('allows calories without a name', () {
      expect(parseQuickLog('450'), (name: null, kcal: 450));
      expect(parseQuickLog('450 kcal'), (name: null, kcal: 450));
    });

    test('returns nothing for empty input or zero calories', () {
      expect(parseQuickLog('   '), (name: null, kcal: null));
      expect(parseQuickLog('water 0'), (
        name: 'Water',
        kcal: null,
      ));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/quick_log_parser.dart';

void main() {
  group('parseQuickLog', () {
    test('reads a trailing number as calories', () {
      expect(parseQuickLog('chicken wrap 450'), (
        name: 'Chicken wrap',
        kcal: 450,
        protein: null,
      ));
    });

    test('reads a number with a calorie unit anywhere', () {
      expect(parseQuickLog('450 kcal chicken wrap'), (
        name: 'Chicken wrap',
        kcal: 450,
        protein: null,
      ));
      expect(parseQuickLog('porridge 320kcal'), (
        name: 'Porridge',
        kcal: 320,
        protein: null,
      ));
      expect(parseQuickLog('apple 80 cal'), (
        name: 'Apple',
        kcal: 80,
        protein: null,
      ));
      expect(parseQuickLog('Pizza slice 300 Calories'), (
        name: 'Pizza slice',
        kcal: 300,
        protein: null,
      ));
    });

    test('keeps leading quantities in the name', () {
      expect(parseQuickLog('2 eggs on toast 300'), (
        name: '2 eggs on toast',
        kcal: 300,
        protein: null,
      ));
      expect(parseQuickLog('2 eggs on toast'), (
        name: '2 eggs on toast',
        kcal: null,
        protein: null,
      ));
    });

    test('handles thousands separators', () {
      expect(parseQuickLog('sunday roast 1,200 kcal'), (
        name: 'Sunday roast',
        kcal: 1200,
        protein: null,
      ));
    });

    test('strips separators left around the number', () {
      expect(parseQuickLog('chicken wrap - 450'), (
        name: 'Chicken wrap',
        kcal: 450,
        protein: null,
      ));
      expect(parseQuickLog('chicken wrap, 450 kcal'), (
        name: 'Chicken wrap',
        kcal: 450,
        protein: null,
      ));
    });

    test('does not treat words starting with "cal" as a unit', () {
      expect(parseQuickLog('2 calzones'), (
        name: '2 calzones',
        kcal: null,
        protein: null,
      ));
    });

    test('allows calories without a name', () {
      expect(parseQuickLog('450'), (name: null, kcal: 450, protein: null));
      expect(parseQuickLog('450 kcal'), (name: null, kcal: 450, protein: null));
    });

    test('returns nothing for empty input or zero calories', () {
      expect(parseQuickLog('   '), (name: null, kcal: null, protein: null));
      expect(parseQuickLog('water 0'), (
        name: 'Water',
        kcal: null,
        protein: null,
      ));
    });

    test('reads protein written either way round', () {
      expect(parseQuickLog('chicken wrap 450 35g protein'), (
        name: 'Chicken wrap',
        kcal: 450,
        protein: 35,
      ));
      expect(parseQuickLog('musaka 640 kcal 31 g protein'), (
        name: 'Musaka',
        kcal: 640,
        protein: 31,
      ));
      expect(parseQuickLog('shake 250 protein 30g'), (
        name: 'Shake',
        kcal: 250,
        protein: 30,
      ));
      expect(parseQuickLog('chicken salad 350 kcal 40 grams of protein'), (
        name: 'Chicken salad',
        kcal: 350,
        protein: 40,
      ));
    });

    test('understands Bulgarian units', () {
      expect(parseQuickLog('мусака 450 ккал'), (
        name: 'Мусака',
        kcal: 450,
        protein: null,
      ));
      expect(parseQuickLog('450 калории мусака'), (
        name: 'Мусака',
        kcal: 450,
        protein: null,
      ));
      expect(parseQuickLog('мусака 450 кал 30г протеин'), (
        name: 'Мусака',
        kcal: 450,
        protein: 30,
      ));
      expect(parseQuickLog('пиле 350 ККАЛ 40 гр белтък'), (
        name: 'Пиле',
        kcal: 350,
        protein: 40,
      ));
      expect(parseQuickLog('шейк 250 протеин 30'), (
        name: 'Шейк',
        kcal: 250,
        protein: 30,
      ));
      expect(parseQuickLog('2 калцоне'), (
        name: '2 калцоне',
        kcal: null,
        protein: null,
      ));
    });

    test('does not mistake a weight for protein', () {
      expect(parseQuickLog('chicken 200g 330'), (
        name: 'Chicken 200g',
        kcal: 330,
        protein: null,
      ));
    });
  });
}

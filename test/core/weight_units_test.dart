import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/weight_units.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  group('kilogram/pound conversion', () {
    test('a pound is the defined 0.45359237 kg', () {
      expect(poundsToKilograms(1), kilogramsPerPound);
      expect(kilogramsToPounds(kilogramsPerPound), closeTo(1, 1e-12));
    });

    test('round trips without drifting', () {
      expect(poundsToKilograms(kilogramsToPounds(72.57)), closeTo(72.57, 1e-12));
    });

    test('converts a familiar weight both ways', () {
      expect(poundsToKilograms(160), closeTo(72.5748, 1e-4));
      expect(kilogramsToPounds(72.5748), closeTo(160, 1e-3));
    });
  });

  group('WeightUnit conversion', () {
    test('kilograms is the identity in both directions', () {
      expect(WeightUnit.kilograms.fromKilograms(72.57), 72.57);
      expect(WeightUnit.kilograms.toKilograms(72.57), 72.57);
    });

    test('pounds converts in both directions', () {
      expect(WeightUnit.pounds.fromKilograms(72.5748), closeTo(160, 1e-3));
      expect(WeightUnit.pounds.toKilograms(160), closeTo(72.5748, 1e-4));
    });

    test('format renders one decimal and the unit symbol', () {
      expect(WeightUnit.kilograms.format(72.5748), '72.6 kg');
      expect(WeightUnit.pounds.format(72.5748), '160.0 lbs');
    });

    test('format keeps the sign of a change', () {
      expect(WeightUnit.pounds.format(-0.9071847), '-2.0 lbs');
    });
  });
}

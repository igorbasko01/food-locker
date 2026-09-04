import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';

void main() {
  group('inch conversions', () {
    test('an inch is exactly 2.54 cm, both ways', () {
      expect(inchesToCentimetres(1), 2.54);
      expect(centimetresToInches(2.54), 1);
    });

    test('a centimetre survives a round trip', () {
      expect(centimetresToInches(inchesToCentimetres(70.5)), closeTo(70.5, 1e-9));
      expect(inchesToCentimetres(centimetresToInches(178)), closeTo(178, 1e-9));
    });
  });

  group('feet and inches', () {
    test('splits centimetres into whole feet and the remainder', () {
      final split = centimetresToFeetInches(177.8);

      expect(split.feet, 5);
      expect(split.inches, closeTo(10, 1e-9));
    });

    test('a height under a foot has no feet', () {
      final split = centimetresToFeetInches(20.32);

      expect(split.feet, 0);
      expect(split.inches, closeTo(8, 1e-9));
    });

    test('recombines into the centimetres it came from', () {
      final split = centimetresToFeetInches(183.4);

      expect(
        feetInchesToCentimetres(split.feet, split.inches),
        closeTo(183.4, 1e-9),
      );
    });

    test('five foot ten is 177.8 cm', () {
      expect(feetInchesToCentimetres(5, 10), closeTo(177.8, 1e-9));
    });
  });

  group('formatHeight', () {
    test('metric drops a trailing zero but keeps a real decimal', () {
      expect(formatHeight(178, MeasurementSystem.metric), '178 cm');
      expect(formatHeight(177.5, MeasurementSystem.metric), '177.5 cm');
    });

    test('imperial reads as feet and whole inches', () {
      expect(formatHeight(177.8, MeasurementSystem.imperial), "5' 10\"");
    });

    test('inches rounding up to twelve carry into the next foot', () {
      // 182.7 cm is 5' 11.93", which must not print as 5' 12".
      expect(formatHeight(182.7, MeasurementSystem.imperial), "6' 0\"");
    });
  });

  group('formatLengthValue', () {
    test('trims a whole number and rounds to one decimal', () {
      expect(formatLengthValue(178), '178');
      expect(formatLengthValue(177.66), '177.7');
      expect(formatLengthValue(0), '0');
    });
  });
}

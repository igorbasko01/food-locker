import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/bmi.dart';

void main() {
  group('bodyMassIndex', () {
    test('is the weight in kilograms over the height in metres squared', () {
      expect(
        bodyMassIndex(kilograms: 70.0, heightCm: 175.0),
        closeTo(22.857, 0.001),
      );
    });

    test('reads a height in centimetres, not metres', () {
      expect(
        bodyMassIndex(kilograms: 81.0, heightCm: 180.0),
        closeTo(25.0, 0.000001),
      );
    });
  });

  group('bmiCategory', () {
    test('the bands are half-open, so a boundary belongs to the band above', () {
      expect(bmiCategory(18.49), BmiCategory.underweight);
      expect(bmiCategory(18.5), BmiCategory.healthy);
      expect(bmiCategory(24.99), BmiCategory.healthy);
      expect(bmiCategory(25.0), BmiCategory.overweight);
      expect(bmiCategory(29.99), BmiCategory.overweight);
      expect(bmiCategory(30.0), BmiCategory.obese);
    });

    test('the open ends keep their bands', () {
      expect(bmiCategory(9.0), BmiCategory.underweight);
      expect(bmiCategory(75.0), BmiCategory.obese);
    });
  });

  group('BmiBand.all', () {
    test('covers every value exactly once, in order', () {
      expect(
        BmiBand.all.map((band) => band.category),
        BmiCategory.values,
      );
      for (var i = 1; i < BmiBand.all.length; i++) {
        expect(BmiBand.all[i].from, BmiBand.all[i - 1].to);
      }
      expect(BmiBand.all.first.from, double.negativeInfinity);
      expect(BmiBand.all.last.to, double.infinity);
    });

    test('each band holds the values it claims', () {
      for (final band in BmiBand.all) {
        final inside = band.from.isFinite ? band.from : band.to - 1;
        expect(bmiCategory(inside), band.category);
      }
    });
  });
}

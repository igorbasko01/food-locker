import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  const codec = WeightBackupCodec();

  group('WeightBackupCodec CSV Logic', () {
    test('generateWeightCsv creates valid CSV', () {
      final date = DateTime(2023, 10, 27);
      final weight = Weight(date: date, value: 75.5, unit: WeightUnit.kilograms);

      final csv = codec.generateWeightCsv([weight]);

      expect(csv, contains('date,value,unit'));
      expect(csv, contains('2023-10-27T00:00:00.000,75.5,kilograms'));
    });

    test('parseWeightCsv parses CSV and returns list of weights', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,75.5,kilograms';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.length, 1);
      expect(weights.first.date, DateTime(2023, 10, 27));
      expect(weights.first.value, 75.5);
      expect(weights.first.unit, WeightUnit.kilograms);
    });
  });

  group('WeightBackupCodec edge cases', () {
    test('encoding an empty list decodes back to an empty list', () {
      final decoded = codec.decode(codec.encode([]));
      expect(decoded, isEmpty);
    });

    test('parseWeightCsv skips a row missing its value', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,,kilograms';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv skips a row missing its date', () {
      const csv = 'date,value,unit\r\n,75.5,kilograms';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv skips a row with a non-numeric value', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,abc,kilograms';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv keeps valid rows and drops invalid ones', () {
      const csv = 'date,value,unit\r\n'
          '2023-10-27T00:00:00.000,75.5,kilograms\r\n'
          '2023-10-28T00:00:00.000,,kilograms\r\n'
          '2023-10-29T00:00:00.000,74.0,kilograms';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.map((w) => w.value), [75.5, 74.0]);
    });

    test('parseWeightCsv falls back to kilograms for an unknown unit', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,75.5,stones';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.unit, WeightUnit.kilograms);
      expect(weights.single.value, 75.5);
    });

    test('parseWeightCsv defaults to kilograms when the unit column is absent',
        () {
      // Backward compatibility: older exports may omit the unit column.
      const csv = 'date,value\r\n2023-10-27T00:00:00.000,75.5';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.unit, WeightUnit.kilograms);
    });

    test('parseWeightCsv preserves the pounds unit', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,166.0,pounds';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.unit, WeightUnit.pounds);
    });
  });

  group('WeightBackupCodec Zip Encode/Decode Round-Trip', () {
    test('encode and decode preserves exact data', () {
      final weights = [
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
        Weight(date: DateTime(2023, 10, 28), value: 75.0),
      ];

      final zipBytes = codec.encode(weights);

      expect(zipBytes, isNotNull);
      expect(zipBytes.isNotEmpty, isTrue);

      final decodedWeights = codec.decode(zipBytes);

      expect(decodedWeights.length, 2);

      final weight1 = decodedWeights.firstWhere(
        (w) => w.date == DateTime(2023, 10, 27),
      );
      expect(weight1.value, 75.5);

      final weight2 = decodedWeights.firstWhere(
        (w) => w.date == DateTime(2023, 10, 28),
      );
      expect(weight2.value, 75.0);
    });
  });
}

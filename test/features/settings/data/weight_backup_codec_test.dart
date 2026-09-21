import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  const codec = WeightBackupCodec();

  group('WeightBackupCodec CSV Logic', () {
    test('generateWeightCsv drops the unit column', () {
      final weight = Weight(date: DateTime(2023, 10, 27), value: 75.5);

      final csv = codec.generateWeightCsv([weight]);

      // The column name is unchanged, so an older build still reads the file.
      expect(csv, contains('date,value'));
      expect(csv, isNot(contains('unit')));
      expect(csv, contains('2023-10-27T00:00:00.000,75.5'));
    });

    test('parseWeightCsv parses CSV and returns list of weights', () {
      const csv = 'date,value\r\n2023-10-27T00:00:00.000,75.5';
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
      const csv = 'date,value\r\n2023-10-27T00:00:00.000,';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv skips a row missing its date', () {
      const csv = 'date,value\r\n,75.5';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv skips a row with a non-numeric value', () {
      const csv = 'date,value\r\n2023-10-27T00:00:00.000,abc';
      expect(codec.parseWeightCsv(csv), isEmpty);
    });

    test('parseWeightCsv keeps valid rows and drops invalid ones', () {
      const csv = 'date,value\r\n'
          '2023-10-27T00:00:00.000,75.5\r\n'
          '2023-10-28T00:00:00.000,\r\n'
          '2023-10-29T00:00:00.000,74.0';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.map((w) => w.value), [75.5, 74.0]);
    });

    test('an archive still carrying a unit column imports unchanged', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,75.5,kilograms';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.value, 75.5);
      expect(weights.single.unit, WeightUnit.kilograms);
    });

    test('a pounds row restores as that same number in kilograms', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,166.0,pounds';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.value, 166.0);
      expect(weights.single.unit, WeightUnit.kilograms);
    });

    test('parseWeightCsv ignores a unit column it cannot name', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,75.5,stones';
      final weights = codec.parseWeightCsv(csv);

      expect(weights.single.unit, WeightUnit.kilograms);
      expect(weights.single.value, 75.5);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';

void main() {
  late SerializationService service;
  late InMemoryWeightRepository weightRepo;

  setUp(() {
    weightRepo = InMemoryWeightRepository();
    service = SerializationService();
  });

  group('SerializationService CSV Logic', () {
    test('generateWeightCsv creates valid CSV', () {
      final date = DateTime(2023, 10, 27);
      final weight = Weight(date: date, value: 75.5, unit: WeightUnit.kilograms);
      weightRepo.saveWeight(weight);

      final csv = service.generateWeightCsv(weightRepo.getAllWeights());

      expect(csv, contains('date,value,unit'));
      expect(csv, contains('2023-10-27T00:00:00.000,75.5,kilograms'));
    });

    test('importWeightFromCsv parses CSV and populates repo', () {
      const csv = 'date,value,unit\r\n2023-10-27T00:00:00.000,75.5,kilograms';
      service.importWeightFromCsv(csv, weightRepo);

      final weights = weightRepo.getAllWeights();
      expect(weights.length, 1);
      expect(weights.first.date, DateTime(2023, 10, 27));
      expect(weights.first.value, 75.5);
      expect(weights.first.unit, WeightUnit.kilograms);
    });
  });

  group('SerializationService Zip File Name', () {
    test('generateZipFileName creates timestamped filename', () {
      final timestamp = DateTime(2026, 3, 7, 21, 59, 30);
      final fileName = SerializationService.generateZipFileName(timestamp);
      expect(fileName, 'food_locker_20260307215930.zip');
    });

    test('generateZipFileName pads single digit values', () {
      final timestamp = DateTime(2026, 1, 5, 3, 2, 1);
      final fileName = SerializationService.generateZipFileName(timestamp);
      expect(fileName, 'food_locker_20260105030201.zip');
    });
  });

  group('SerializationService End-to-End Logic', () {
    test('export and direct import preserves exact data', () async {
      // 1. Populate initial data
      final initialWeightRepo = InMemoryWeightRepository();
      await initialWeightRepo.saveWeight(
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
      );
      await initialWeightRepo.saveWeight(
        Weight(date: DateTime(2023, 10, 28), value: 75.0),
      );

      // 2. Perform export
      final zipBytes = service.createExportArchive(
        initialWeightRepo.getAllWeights(),
      );

      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      // 3. Prepare fresh repository for import
      final importWeightRepo = InMemoryWeightRepository();

      // Ensure it is truly clean
      expect(importWeightRepo.getAllWeights().isEmpty, isTrue);

      // 4. Perform import
      await service.importFromArchive(
        zipBytes,
        importWeightRepo,
      );

      // 5. Assertions on restored Weight
      final importedWeights = importWeightRepo.getAllWeights();
      expect(importedWeights.length, 2);

      final weight1 = importedWeights.firstWhere(
        (w) => w.date == DateTime(2023, 10, 27),
      );
      expect(weight1.value, 75.5);

      final weight2 = importedWeights.firstWhere(
        (w) => w.date == DateTime(2023, 10, 28),
      );
      expect(weight2.value, 75.0);
    });
  });
}

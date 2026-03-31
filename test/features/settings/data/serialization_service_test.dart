import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/in_memory_food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/in_memory_food_config_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';

void main() {
  late SerializationService service;
  late InMemoryFoodConfigRepository configRepo;
  late InMemoryFoodDayRepository dayRepo;
  late InMemoryWeightRepository weightRepo;

  setUp(() {
    configRepo = InMemoryFoodConfigRepository([]);
    dayRepo = InMemoryFoodDayRepository();
    weightRepo = InMemoryWeightRepository();
    service = SerializationService(
      // Mocking context/file picking/sharing is not needed for CSV logic tests
      // exportData and importData will be tested partially via unit logic tests
    );
  });

  group('SerializationService CSV Logic', () {
    test('generateConfigCsv creates valid CSV', () {
      configRepo.add(FoodConfig(name: 'Apple', type: FoodType.snack));
      configRepo.add(FoodConfig(name: 'Chicken', type: FoodType.meal));

      final csv = service.generateConfigCsv(configRepo.foodConfigs);

      const expected = 'name,type\r\nApple,snack\r\nChicken,meal';
      expect(csv.trim(), expected);
    });

    test('generateHistoryCsv creates valid CSV', () {
      final date = DateTime(2023, 10, 27);
      final day = FoodDay(
        date: date,
        meals: [
          Food(name: 'Chicken', eatenTime: DateTime(2023, 10, 27, 12, 0)),
        ],
        snacks: [Food(name: 'Apple')],
      );
      dayRepo.saveDay(day);

      final csv = service.generateHistoryCsv(dayRepo.getAllDays());

      expect(csv, contains('date,type,name,eatenAt,overate'));
      expect(
        csv,
        contains(
          '2023-10-27T00:00:00.000,meal,Chicken,2023-10-27T12:00:00.000,false',
        ),
      );
      expect(csv, contains('2023-10-27T00:00:00.000,snack,Apple,,false'));
    });

    test('importConfigFromCsv parses CSV and populates repo', () {
      const csv = 'name,type\r\nBanana,snack\r\nBeef,meal';
      service.importConfigFromCsv(csv, configRepo);

      expect(configRepo.foodConfigs.length, 2);
      expect(configRepo.foodConfigs[0].name, 'Banana');
      expect(configRepo.foodConfigs[0].type, FoodType.snack);
      expect(configRepo.foodConfigs[1].name, 'Beef');
      expect(configRepo.foodConfigs[1].type, FoodType.meal);
    });

    test('importHistoryFromCsv parses CSV and populates repo', () {
      const csv =
          'date,type,name,eatenAt,overate\r\n'
          '2023-10-27T00:00:00.000,meal,Fish,2023-10-27T13:00:00.000,false\r\n'
          '2023-10-27T00:00:00.000,snack,Cookie,,false';

      service.importHistoryFromCsv(csv, dayRepo);

      final days = dayRepo.getAllDays();
      expect(days.length, 1);

      final day = days.first;
      expect(day.date, DateTime(2023, 10, 27));
      expect(day.meals.length, 1);
      expect(day.meals[0].name, 'Fish');
      expect(day.meals[0].eatenAt, DateTime(2023, 10, 27, 13, 0));
      expect(day.snacks.length, 1);
      expect(day.snacks[0].name, 'Cookie');
      expect(day.snacks[0].eatenAt, null);
      expect(day.overate, isFalse);
    });

    test('importHistoryFromCsv parses overate=true correctly', () {
      const csv =
          'date,type,name,eatenAt,overate\r\n'
          '2023-10-27T00:00:00.000,meal,Fish,2023-10-27T13:00:00.000,true';

      service.importHistoryFromCsv(csv, dayRepo);

      final days = dayRepo.getAllDays();
      expect(days.length, 1);
      expect(days.first.overate, isTrue);
    });

    test('importHistoryFromCsv handles old CSV without overate column', () {
      const csv =
          'date,type,name,eatenAt\r\n'
          '2023-10-27T00:00:00.000,meal,Fish,2023-10-27T13:00:00.000';

      service.importHistoryFromCsv(csv, dayRepo);

      final days = dayRepo.getAllDays();
      expect(days.length, 1);
      expect(days.first.overate, isFalse);
    });

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
      final initialConfigRepo = InMemoryFoodConfigRepository([]);
      initialConfigRepo.add(FoodConfig(name: 'Apple', type: FoodType.snack));
      initialConfigRepo.add(FoodConfig(name: 'Chicken', type: FoodType.meal));

      final initialDayRepo = InMemoryFoodDayRepository();
      final day1 = FoodDay(
        date: DateTime(2023, 10, 27),
        meals: [
          Food(name: 'Chicken', eatenTime: DateTime(2023, 10, 27, 12, 0)),
        ],
        snacks: [Food(name: 'Apple')],
        overate: true,
      );
      final day2 = FoodDay(
        date: DateTime(2023, 10, 28),
        meals: [],
        snacks: [
          Food(name: 'Banana', eatenTime: DateTime(2023, 10, 28, 15, 0)),
        ],
      );
      await initialDayRepo.saveDay(day1);
      await initialDayRepo.saveDay(day2);

      final initialWeightRepo = InMemoryWeightRepository();
      await initialWeightRepo.saveWeight(
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
      );
      await initialWeightRepo.saveWeight(
        Weight(date: DateTime(2023, 10, 28), value: 75.0),
      );

      // 2. Perform export
      final zipBytes = service.createExportArchive(
        initialConfigRepo.foodConfigs,
        initialDayRepo.getAllDays(),
        initialWeightRepo.getAllWeights(),
      );

      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      // 3. Prepare fresh repositories for import
      final importConfigRepo = InMemoryFoodConfigRepository([]);
      final importDayRepo = InMemoryFoodDayRepository();
      final importWeightRepo = InMemoryWeightRepository();

      // Ensure they are truly clean
      expect(importConfigRepo.foodConfigs.isEmpty, isTrue);
      expect(importDayRepo.getAllDays().isEmpty, isTrue);
      expect(importWeightRepo.getAllWeights().isEmpty, isTrue);

      // 4. Perform import
      await service.importFromArchive(
        zipBytes,
        importConfigRepo,
        importDayRepo,
        importWeightRepo,
      );

      // 5. Assertions on restored Configs
      expect(importConfigRepo.foodConfigs.length, 2);
      expect(
        importConfigRepo.foodConfigs.any(
          (c) => c.name == 'Apple' && c.type == FoodType.snack,
        ),
        isTrue,
      );
      expect(
        importConfigRepo.foodConfigs.any(
          (c) => c.name == 'Chicken' && c.type == FoodType.meal,
        ),
        isTrue,
      );

      // 6. Assertions on restored History
      final importedDays = importDayRepo.getAllDays();
      expect(importedDays.length, 2);

      final importedDay1 = importedDays.firstWhere(
        (d) => d.date == DateTime(2023, 10, 27),
      );
      expect(importedDay1.meals.length, 1);
      expect(importedDay1.meals.first.name, 'Chicken');
      expect(importedDay1.meals.first.eatenAt, DateTime(2023, 10, 27, 12, 0));
      expect(importedDay1.snacks.length, 1);
      expect(importedDay1.snacks.first.name, 'Apple');
      expect(importedDay1.snacks.first.eatenAt, isNull);
      expect(importedDay1.overate, isTrue);

      final importedDay2 = importedDays.firstWhere(
        (d) => d.date == DateTime(2023, 10, 28),
      );
      expect(importedDay2.meals.isEmpty, isTrue);
      expect(importedDay2.snacks.length, 1);
      expect(importedDay2.snacks.first.name, 'Banana');
      expect(importedDay2.snacks.first.eatenAt, DateTime(2023, 10, 28, 15, 0));
      expect(importedDay2.overate, isFalse);

      // 7. Assertions on restored Weight
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

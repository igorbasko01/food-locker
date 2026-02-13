import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/persistent_food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:hive/hive.dart';

void main() {
  late PersistentFoodDayRepository repository;
  late Box<FoodDay> box;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FoodAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FoodDayAdapter());
    }
    box = await Hive.openBox<FoodDay>('test_box');
    repository = PersistentFoodDayRepository(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('test_box');
    await tempDir.delete(recursive: true);
  });

  group('PersistentFoodDayRepository', () {
    test('saveDay and getDay persist data correctly', () async {
      final now = DateTime(2023, 10, 26);
      final day = FoodDay(
        date: now,
        meals: [Food(name: 'Pizza')],
        snacks: [
          Food(name: 'Apple'),
          Food(name: 'Banana'),
        ],
      );

      await repository.saveDay(day);

      // Verify it's in the box
      final retrievedDay = repository.getDay(now);

      expect(retrievedDay, isNotNull);
      expect(retrievedDay!.date.year, day.date.year);
      expect(retrievedDay.date.month, day.date.month);
      expect(retrievedDay.date.day, day.date.day);
      expect(retrievedDay.meals.length, 1);
      expect(retrievedDay.meals.first.name, 'Pizza');
      expect(retrievedDay.snacks.length, 2);
    });

    test('getDay returns null if day not found', () async {
      final now = DateTime(2023, 10, 27);
      final retrievedDay = repository.getDay(now);
      expect(retrievedDay, isNull);
    });
  });
}

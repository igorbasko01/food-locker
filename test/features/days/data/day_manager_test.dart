import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_manager.dart';
import 'package:food_locker/features/food/data/food_type.dart';

void main() {
  late FoodDayManager dayManager;
  late FoodConfigManager foodConfigManager;
  late List<FoodConfig> foodConfigs;

  setUp(() {
    foodConfigs = [
      FoodConfig(name: 'Apple', type: FoodType.snack),
      FoodConfig(name: 'Banana', type: FoodType.snack),
      FoodConfig(name: 'Chicken', type: FoodType.meal),
      FoodConfig(name: 'Rice', type: FoodType.meal),
    ];
    foodConfigManager = FoodConfigManager(foodConfigs);
  });

  group('FoodDayManager', () {
    test('getMeals returns meals from existing day', () {
      final now = DateTime(2023, 10, 26, 10, 0);
      final existingDay = FoodDay(
        date: now,
        meals: [Food(name: 'Pizza')],
        snacks: [],
      );
      dayManager = FoodDayManager(existingDay, foodConfigManager);

      final meals = dayManager.getMeals(now);

      expect(meals.length, 1);
      expect(meals.first.name, 'Pizza');
    });

    test('getSnacks returns snacks from existing day', () {
      final now = DateTime(2023, 10, 26, 10, 0);
      final existingDay = FoodDay(
        date: now,
        meals: [],
        snacks: [Food(name: 'Chips')],
      );
      dayManager = FoodDayManager(existingDay, foodConfigManager);

      final snacks = dayManager.getSnacks(now);

      expect(snacks.length, 1);
      expect(snacks.first.name, 'Chips');
    });

    test('getMeals initializes new day from config if current day is null', () {
      final now = DateTime(2023, 10, 26, 10, 0);
      dayManager = FoodDayManager(null, foodConfigManager);

      final meals = dayManager.getMeals(now);

      expect(meals.length, 2);
      expect(meals.map((m) => m.name), containsAll(['Chicken', 'Rice']));
      // Verify snacks were also initialized implicitly if we accessed getSnacks next
      final snacks = dayManager.getSnacks(now);
      expect(snacks.length, 2);
    });

    test(
      'getSnacks initializes new day from config if current day is null',
      () {
        final now = DateTime(2023, 10, 26, 10, 0);
        dayManager = FoodDayManager(null, foodConfigManager);

        final snacks = dayManager.getSnacks(now);

        expect(snacks.length, 2);
        expect(snacks.map((s) => s.name), containsAll(['Apple', 'Banana']));
      },
    );

    test(
      'day progression: creates new day if current day is from yesterday',
      () {
        final yesterday = DateTime(2023, 10, 25, 10, 0);
        final today = DateTime(2023, 10, 26, 10, 0);

        final previousDay = FoodDay(
          date: yesterday,
          meals: [Food(name: 'Old Meal')],
          snacks: [],
        );

        dayManager = FoodDayManager(previousDay, foodConfigManager);

        // Verify initial state
        expect(dayManager.getMeals(yesterday).first.name, 'Old Meal');

        // Move to today
        final meals = dayManager.getMeals(today);

        // Should be new meals from config, not the old meal
        expect(meals.length, 2);
        expect(meals.map((m) => m.name), containsAll(['Chicken', 'Rice']));

        final snacks = dayManager.getSnacks(today);
        expect(snacks.length, 2);
      },
    );

    test('day progression: does NOT create new day if same day', () {
      final morning = DateTime(2023, 10, 26, 8, 0);
      final evening = DateTime(2023, 10, 26, 18, 0);

      dayManager = FoodDayManager(null, foodConfigManager);

      // Initialize with morning call
      final morningMeals = dayManager.getMeals(morning);
      // Mark something as eaten to differentiate
      morningMeals.first.eat(morning);

      // Call in evening
      final eveningMeals = dayManager.getMeals(evening);

      // Should be the same objects
      expect(eveningMeals.first.wasEaten, isTrue);
      expect(eveningMeals, same(morningMeals));
    });
  });
}

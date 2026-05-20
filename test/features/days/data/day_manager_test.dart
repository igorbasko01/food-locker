import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/days/data/in_memory_food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/in_memory_food_config_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';

void main() {
  late FoodDayManager dayManager;
  late FoodConfigRepository foodConfigRepository;
  late FoodDayRepository foodDayRepository;
  late List<FoodConfig> foodConfigs;

  setUp(() {
    foodConfigs = [
      FoodConfig(name: 'Apple', type: FoodType.snack),
      FoodConfig(name: 'Banana', type: FoodType.snack),
      FoodConfig(name: 'Chicken', type: FoodType.meal),
      FoodConfig(name: 'Rice', type: FoodType.meal),
    ];
    foodConfigRepository = InMemoryFoodConfigRepository(foodConfigs);
    foodDayRepository = InMemoryFoodDayRepository();
  });

  group('FoodDayManager', () {
    test('getMeals returns meals from existing day', () {
      final now = DateTime(2023, 10, 26, 10, 0);
      final existingDay = FoodDay(
        date: now,
        meals: [Food(name: 'Pizza')],
        snacks: [],
      );
      dayManager = FoodDayManager(
        existingDay,
        foodConfigRepository,
        foodDayRepository,
      );

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
      dayManager = FoodDayManager(
        existingDay,
        foodConfigRepository,
        foodDayRepository,
      );

      final snacks = dayManager.getSnacks(now);

      expect(snacks.length, 1);
      expect(snacks.first.name, 'Chips');
    });

    test('getMeals initializes new day from config if current day is null', () {
      final now = DateTime(2023, 10, 26, 10, 0);
      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );

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
        dayManager = FoodDayManager(
          null,
          foodConfigRepository,
          foodDayRepository,
        );

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

        dayManager = FoodDayManager(
          previousDay,
          foodConfigRepository,
          foodDayRepository,
        );

        // Verify initial state
        expect(dayManager.getMeals(yesterday).first.name, 'Old Meal');

        // Move to today
        final meals = dayManager.getMeals(today);

        // Verify previous day was saved
        final savedYesterday = foodDayRepository.getDay(yesterday);
        expect(savedYesterday, isNotNull);
        expect(savedYesterday!.date, yesterday);
        expect(savedYesterday.meals.first.name, 'Old Meal');

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

      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );

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

    test('toggleFoodStatus toggles eaten state and saves day', () async {
      final now = DateTime(2023, 10, 26, 10, 0);
      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );
      await dayManager.initialize(now);

      final meal = dayManager.getMeals(now).first;
      expect(meal.wasEaten, isFalse);

      dayManager.toggleFoodStatus(meal, now);

      expect(meal.wasEaten, isTrue);
      expect(meal.eatenAt, now);

      // Verify save was called (in memory repo stores it)
      final savedDay = foodDayRepository.getDay(now);
      expect(savedDay!.meals.first.wasEaten, isTrue);

      // Toggle back
      dayManager.toggleFoodStatus(meal, now);
      expect(meal.wasEaten, isFalse);
      expect(meal.eatenAt, isNull);

      final savedDay2 = foodDayRepository.getDay(now);
      expect(savedDay2!.meals.first.wasEaten, isFalse);
    });

    test('syncs day when config changes', () async {
      final now = DateTime(2023, 10, 26, 10, 0);
      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );
      await dayManager.initialize(now);

      // Verify initial state (Chicken, Rice)
      expect(dayManager.getMeals(now).length, 2);
      expect(
        dayManager.getMeals(now).map((m) => m.name),
        containsAll(['Chicken', 'Rice']),
      );

      // Add a new meal
      foodConfigRepository.add(FoodConfig(name: 'Pizza', type: FoodType.meal));

      // Verify new meal is added
      expect(dayManager.getMeals(now).length, 3);
      expect(dayManager.getMeals(now).map((m) => m.name), contains('Pizza'));

      // Remove a meal
      final chickenConfig = foodConfigs.firstWhere((c) => c.name == 'Chicken');
      foodConfigRepository.remove(chickenConfig);

      // Verify meal is removed
      expect(dayManager.getMeals(now).length, 2);
      expect(
        dayManager.getMeals(now).map((m) => m.name),
        isNot(contains('Chicken')),
      );

      // Verify persistence
      final savedDay = foodDayRepository.getDay(now);
      expect(savedDay!.meals.length, 2);
    });

    test('history returns sorted days', () async {
      final day1 = FoodDay(
        date: DateTime(2023, 10, 26),
        meals: [],
        snacks: [],
      );
      final day2 = FoodDay(
        date: DateTime(2023, 10, 27),
        meals: [],
        snacks: [],
      );
      final day3 = FoodDay(
        date: DateTime(2023, 10, 25),
        meals: [],
        snacks: [],
      );

      await foodDayRepository.saveDay(day1);
      await foodDayRepository.saveDay(day2);
      await foodDayRepository.saveDay(day3);

      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );

      final history = dayManager.history;

      expect(history.length, 3);
      expect(history[0].date, day2.date);
      expect(history[1].date, day1.date);
      expect(history[2].date, day3.date);
    });


    test('toggleHistoricalFoodStatus toggles food status for specific day',
        () async {
      final then = DateTime(2023, 10, 20);
      final food = Food(name: 'Pizza');
      final historicalDay = FoodDay(
        date: then,
        meals: [food],
        snacks: [],
      );
      await foodDayRepository.saveDay(historicalDay);

      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );

      final eatenAt = DateTime(2023, 10, 20, 12, 0);
      dayManager.toggleHistoricalFoodStatus(historicalDay, food, eatenAt);

      expect(food.wasEaten, isTrue);
      expect(food.eatenAt, eatenAt);

      final savedDay = foodDayRepository.getDay(then);
      expect(savedDay!.meals.first.wasEaten, isTrue);

      // Toggle off
      dayManager.toggleHistoricalFoodStatus(historicalDay, food, null);
      expect(food.wasEaten, isFalse);
      expect(foodDayRepository.getDay(then)!.meals.first.wasEaten, isFalse);
    });


    test('deleteDay removes day from history and persists', () async {
      final then = DateTime(2023, 10, 20);
      final historicalDay = FoodDay(
        date: then,
        meals: [],
        snacks: [],
      );
      await foodDayRepository.saveDay(historicalDay);

      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );

      expect(dayManager.history.length, 1);

      await dayManager.deleteDay(historicalDay);

      expect(dayManager.history.length, 0);
      expect(foodDayRepository.getDay(then), isNull);
    });

    test('deleteDay re-initializes current day if it was deleted', () async {
      final now = DateTime(2023, 10, 26);
      dayManager = FoodDayManager(
        null,
        foodConfigRepository,
        foodDayRepository,
      );
      await dayManager.initialize(now);
      
      final currentDayBefore = dayManager.currentDay!;
      await foodDayRepository.saveDay(currentDayBefore);

      await dayManager.deleteDay(currentDayBefore);

      expect(dayManager.currentDay, isNotNull);
      expect(dayManager.currentDay, isNot(same(currentDayBefore)));
    });

    group('getOvereatingStats', () {
      late WeightManager weightManager;
      late InMemoryWeightRepository weightRepository;

      setUp(() {
        weightRepository = InMemoryWeightRepository();
        weightManager = WeightManager(weightRepository);
        dayManager = FoodDayManager(
          null,
          foodConfigRepository,
          foodDayRepository,
        );
      });

      Future<void> _createFoodDay(DateTime date) async {
        await foodDayRepository.saveDay(FoodDay(
          date: date,
          meals: [],
          snacks: [],
        ));
      }

      test('continuous weight loss increases clean streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await _createFoodDay(threeDaysAgo);
        await _createFoodDay(dayBefore);
        await _createFoodDay(yesterday);
        await _createFoodDay(today);

        await weightManager.addWeight(threeDaysAgo, 80.0);
        await weightManager.addWeight(dayBefore, 79.0);
        await weightManager.addWeight(yesterday, 78.0);
        await weightManager.addWeight(today, 77.0);

        final stats = dayManager.getOvereatingStats(weightManager);
        
        expect(stats.cleanStreak, 3);
        expect(stats.overeatingStreak, 0);
        expect(stats.longestCleanStreak, 3);
      });

      test('continuous weight gain increases overeating streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await _createFoodDay(threeDaysAgo);
        await _createFoodDay(dayBefore);
        await _createFoodDay(yesterday);
        await _createFoodDay(today);

        await weightManager.addWeight(threeDaysAgo, 80.0);
        await weightManager.addWeight(dayBefore, 81.0);
        await weightManager.addWeight(yesterday, 82.0);
        await weightManager.addWeight(today, 83.0);

        final stats = dayManager.getOvereatingStats(weightManager);
        
        expect(stats.cleanStreak, 0);
        expect(stats.overeatingStreak, 3);
        expect(stats.longestCleanStreak, 0);
      });

      test('same weight is considered a clean day', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        
        await _createFoodDay(dayBefore);
        await _createFoodDay(yesterday);
        await _createFoodDay(today);

        await weightManager.addWeight(dayBefore, 80.0);
        await weightManager.addWeight(yesterday, 80.0);
        await weightManager.addWeight(today, 80.0);

        final stats = dayManager.getOvereatingStats(weightManager);
        
        expect(stats.cleanStreak, 2);
        expect(stats.overeatingStreak, 0);
        expect(stats.longestCleanStreak, 2);
      });

      test('missing today breaks the current streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        
        await _createFoodDay(dayBefore);
        await _createFoodDay(yesterday);
        // today food day is missing!

        await weightManager.addWeight(dayBefore, 80.0);
        await weightManager.addWeight(yesterday, 79.0);
        // today weight is missing!

        final stats = dayManager.getOvereatingStats(weightManager);
        
        expect(stats.cleanStreak, 0);
        // Longest clean streak is still 1 from dayBefore -> yesterday
        expect(stats.longestCleanStreak, 1);
      });
      
      test('missing a day in the middle breaks longest streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));
        
        await _createFoodDay(threeDaysAgo);
        await _createFoodDay(twoDaysAgo);
        // yesterday food day is missing!
        await _createFoodDay(today);

        await weightManager.addWeight(threeDaysAgo, 80.0);
        await weightManager.addWeight(twoDaysAgo, 79.0);
        // yesterday is missing!
        await weightManager.addWeight(today, 78.0);

        final stats = dayManager.getOvereatingStats(weightManager);
        
        expect(stats.cleanStreak, 0);
        // The streak from 3 days ago to 2 days ago is 1.
        expect(stats.longestCleanStreak, 1);
      });
    });
  });
}

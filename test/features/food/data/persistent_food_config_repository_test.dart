import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/persistent_food_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PersistentFoodConfigRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = PersistentFoodConfigRepository(prefs);
  });

  group('PersistentFoodConfigRepository', () {
    test('add adds config and persists it', () async {
      final config = FoodConfig(name: 'Apple', type: FoodType.snack);
      repository.add(config);

      expect(repository.foodConfigs.map((c) => c.name), contains('Apple'));

      // Verify persistence by creating a new repository instance
      final prefs = await SharedPreferences.getInstance();
      final newRepository = PersistentFoodConfigRepository(prefs);
      expect(newRepository.foodConfigs.map((c) => c.name), contains('Apple'));
    });

    test('remove removes config and updates persistence', () async {
      final config = FoodConfig(name: 'Apple', type: FoodType.snack);
      repository.add(config);

      // We need to retrieve the object from the list to remove it correctly if reference equality is not guaranteed
      // But here we are using the same instance for removal in the same test scope, assuming equality works or checks
      // In Persistent repo, we are loading from JSON, so the objects are new instances.
      // However, for this test 'add' adds to the in-memory list _and_ saves.
      // So 'config' IS in _foodConfigs (reference wise) until we reload.

      repository.remove(config);

      expect(repository.foodConfigs, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final newRepository = PersistentFoodConfigRepository(prefs);
      expect(newRepository.foodConfigs, isEmpty);
    });

    test('clear removes all configs and updates persistence', () async {
      repository.add(FoodConfig(name: 'Apple', type: FoodType.snack));
      repository.clear();

      expect(repository.foodConfigs, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final newRepository = PersistentFoodConfigRepository(prefs);
      expect(newRepository.foodConfigs, isEmpty);
    });

    test(
      'loads existing data from SharedPreferences on initialization',
      () async {
        // Setup existing data
        SharedPreferences.setMockInitialValues({
          'food_configs': '[{"name":"Burger","type":"meal"}]',
        });

        final prefs = await SharedPreferences.getInstance();
        repository = PersistentFoodConfigRepository(prefs);

        expect(repository.foodConfigs.length, 1);
        expect(repository.foodConfigs.first.name, 'Burger');
        expect(repository.foodConfigs.first.type, FoodType.meal);
      },
    );

    test('getFoodConfigsByType returns correct configs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = PersistentFoodConfigRepository(prefs);

      final meal = FoodConfig(name: 'Burger', type: FoodType.meal);
      final snack = FoodConfig(name: 'Apple', type: FoodType.snack);
      repository.add(meal);
      repository.add(snack);

      final meals = repository.getFoodConfigsByType(FoodType.meal);
      final snacks = repository.getFoodConfigsByType(FoodType.snack);

      // We check names because getFoodConfigsByType returns new objects from _foodConfigs which are populated from _load or add
      // Since add puts the object in, equality is fine if reference based.
      expect(meals.length, 1);
      expect(meals.first, meal);
      expect(snacks.length, 1);
      expect(snacks.first, snack);
    });
  });
}

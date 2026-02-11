import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/in_memory_food_config_repository.dart';

void main() {
  late InMemoryFoodConfigRepository repository;

  setUp(() {
    repository = InMemoryFoodConfigRepository([]);
  });

  group('InMemoryFoodConfigRepository', () {
    test('add adds config to list', () {
      final config = FoodConfig(name: 'Apple', type: FoodType.snack);
      repository.add(config);

      expect(repository.foodConfigs, contains(config));
    });

    test('remove removes config from list', () {
      final config = FoodConfig(name: 'Apple', type: FoodType.snack);
      repository.add(config);
      repository.remove(config);

      expect(repository.foodConfigs, isNot(contains(config)));
    });

    test('clear removes all configs', () {
      repository.add(FoodConfig(name: 'Apple', type: FoodType.snack));
      repository.add(FoodConfig(name: 'Rice', type: FoodType.meal));

      repository.clear();

      expect(repository.foodConfigs, isEmpty);
    });

    test('getFoodConfigsByType returns only matching types', () {
      repository.add(FoodConfig(name: 'Apple', type: FoodType.snack));
      repository.add(FoodConfig(name: 'Rice', type: FoodType.meal));
      repository.add(FoodConfig(name: 'Banana', type: FoodType.snack));

      final snacks = repository.getFoodConfigsByType(FoodType.snack);

      expect(snacks.length, 2);
      expect(snacks.map((c) => c.name), containsAll(['Apple', 'Banana']));
      expect(snacks.any((c) => c.type == FoodType.meal), isFalse);
    });
  });
}

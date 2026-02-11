import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class InMemoryFoodConfigRepository implements FoodConfigRepository {
  @override
  List<FoodConfig> get foodConfigs => _foodConfigs;

  final List<FoodConfig> _foodConfigs;

  InMemoryFoodConfigRepository(this._foodConfigs);

  @override
  void add(FoodConfig foodConfig) {
    _foodConfigs.add(foodConfig);
  }

  @override
  void remove(FoodConfig foodConfig) {
    _foodConfigs.remove(foodConfig);
  }

  @override
  void clear() {
    _foodConfigs.clear();
  }

  @override
  List<FoodConfig> getFoodConfigsByType(FoodType foodType) {
    return _foodConfigs
        .where((foodConfig) => foodConfig.type == foodType)
        .toList();
  }
}

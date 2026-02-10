import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class FoodConfigManager {
  List<FoodConfig> get foodConfigs => _foodConfigs;

  final List<FoodConfig> _foodConfigs;

  FoodConfigManager(this._foodConfigs);

  void add(FoodConfig foodConfig) {
    _foodConfigs.add(foodConfig);
  }

  void remove(FoodConfig foodConfig) {
    _foodConfigs.remove(foodConfig);
  }

  void clear() {
    _foodConfigs.clear();
  }

  List<FoodConfig> getFoodConfigsByType(FoodType foodType) {
    return _foodConfigs
        .where((foodConfig) => foodConfig.type == foodType)
        .toList();
  }
}

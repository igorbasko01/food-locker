import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class InMemoryFoodConfigRepository extends FoodConfigRepository {
  @override
  List<FoodConfig> get foodConfigs => _foodConfigs;

  final List<FoodConfig> _foodConfigs;

  InMemoryFoodConfigRepository(this._foodConfigs);

  @override
  void add(FoodConfig foodConfig) {
    _foodConfigs.add(foodConfig);
    notifyListeners();
  }

  @override
  void remove(FoodConfig foodConfig) {
    _foodConfigs.remove(foodConfig);
    notifyListeners();
  }

  @override
  void clear() {
    _foodConfigs.clear();
    notifyListeners();
  }

  @override
  List<FoodConfig> getFoodConfigsByType(FoodType foodType) {
    return _foodConfigs
        .where((foodConfig) => foodConfig.type == foodType)
        .toList();
  }
}

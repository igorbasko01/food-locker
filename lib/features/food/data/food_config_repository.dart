import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';

abstract class FoodConfigRepository {
  List<FoodConfig> get foodConfigs;

  void add(FoodConfig foodConfig);

  void remove(FoodConfig foodConfig);

  void clear();

  List<FoodConfig> getFoodConfigsByType(FoodType foodType);
}

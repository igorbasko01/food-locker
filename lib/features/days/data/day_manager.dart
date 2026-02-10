import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config_manager.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class FoodDayManager {
  FoodDay? _currentDay;
  final FoodConfigManager _foodConfigManager;

  FoodDayManager(this._currentDay, this._foodConfigManager);

  List<Food> getMeals(DateTime now) {
    _handleDayProgression(now);
    return _currentDay?.meals ?? [];
  }

  List<Food> getSnacks(DateTime now) {
    _handleDayProgression(now);
    return _currentDay?.snacks ?? [];
  }

  void _handleDayProgression(DateTime now) {
    if (_shouldStartNewDay(now)) {
      var meals = _foodConfigManager.getFoodConfigsByType(FoodType.meal);
      var snacks = _foodConfigManager.getFoodConfigsByType(FoodType.snack);
      _currentDay = FoodDay(
        date: now,
        meals: meals.map((foodConfig) => Food(name: foodConfig.name)).toList(),
        snacks: snacks
            .map((foodConfig) => Food(name: foodConfig.name))
            .toList(),
      );
    }
  }

  bool _shouldStartNewDay(DateTime now) {
    if (_currentDay == null) {
      return true;
    }
    // Check if distinct days (ignoring time if desired, but typically day difference)
    // Assuming simple day check: year, month, day must match
    final current = _currentDay!.date;
    return current.year != now.year ||
        current.month != now.month ||
        current.day != now.day;
  }
}

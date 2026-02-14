import 'package:flutter/foundation.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class FoodDayManager extends ChangeNotifier {
  FoodDay? _currentDay;
  final FoodConfigRepository _foodConfigRepository;
  final FoodDayRepository _foodDayRepository;

  FoodDayManager(
    this._currentDay,
    this._foodConfigRepository,
    this._foodDayRepository,
  ) {
    _foodConfigRepository.addListener(_onFoodConfigsChanged);
  }

  @override
  void dispose() {
    _foodConfigRepository.removeListener(_onFoodConfigsChanged);
    super.dispose();
  }

  FoodDay? get currentDay => _currentDay;

  Future<void> initialize(DateTime now) async {
    _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
    _handleDayProgression(now);
    notifyListeners();
  }

  List<Food> getMeals(DateTime now) {
    _handleDayProgression(now);
    return _currentDay?.meals ?? [];
  }

  List<Food> getSnacks(DateTime now) {
    _handleDayProgression(now);
    return _currentDay?.snacks ?? [];
  }

  void toggleFoodStatus(Food food, DateTime now) {
    if (_currentDay == null) return;

    if (food.wasEaten) {
      food.unEat();
    } else {
      food.eat(now);
    }
    _foodDayRepository.saveDay(_currentDay!);
    notifyListeners();
  }

  void _handleDayProgression(DateTime now) {
    if (_shouldStartNewDay(now)) {
      if (_currentDay != null) {
        _foodDayRepository.saveDay(_currentDay!);
      }
      _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
      _foodDayRepository.saveDay(_currentDay!);
      notifyListeners();
    }
  }

  void _onFoodConfigsChanged() {
    if (_currentDay == null) return;

    final mealConfigs = _foodConfigRepository.getFoodConfigsByType(
      FoodType.meal,
    );
    final snackConfigs = _foodConfigRepository.getFoodConfigsByType(
      FoodType.snack,
    );

    _syncFoodList(_currentDay!.meals, mealConfigs);
    _syncFoodList(_currentDay!.snacks, snackConfigs);

    _foodDayRepository.saveDay(_currentDay!);
    notifyListeners();
  }

  void _syncFoodList(List<Food> currentFoods, List<FoodConfig> newConfigs) {
    final newConfigNames = newConfigs.map((c) => c.name).toSet();

    // Remove foods not in new configs
    currentFoods.removeWhere((food) => !newConfigNames.contains(food.name));

    // Add new foods
    final currentFoodNames = currentFoods.map((f) => f.name).toSet();
    for (final config in newConfigs) {
      if (!currentFoodNames.contains(config.name)) {
        currentFoods.add(Food(name: config.name));
      }
    }
  }

  FoodDay _createDay(DateTime now) {
    var meals = _foodConfigRepository.getFoodConfigsByType(FoodType.meal);
    var snacks = _foodConfigRepository.getFoodConfigsByType(FoodType.snack);
    return FoodDay(
      date: now,
      meals: meals.map((foodConfig) => Food(name: foodConfig.name)).toList(),
      snacks: snacks.map((foodConfig) => Food(name: foodConfig.name)).toList(),
    );
  }

  bool _shouldStartNewDay(DateTime now) {
    if (_currentDay == null) {
      return true;
    }
    final current = _currentDay!.date;
    return current.year != now.year ||
        current.month != now.month ||
        current.day != now.day;
  }
}

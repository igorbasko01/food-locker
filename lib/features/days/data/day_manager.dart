import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class FoodDayManager {
  FoodDay? _currentDay;
  final FoodConfigRepository _foodConfigRepository;
  final FoodDayRepository _foodDayRepository;

  FoodDayManager(
    this._currentDay,
    this._foodConfigRepository,
    this._foodDayRepository,
  );

  Future<void> initialize(DateTime now) async {
    _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
    _handleDayProgression(now);
  }

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
      if (_currentDay != null) {
        _foodDayRepository.saveDay(_currentDay!);
      }
      _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
      _foodDayRepository.saveDay(_currentDay!);
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

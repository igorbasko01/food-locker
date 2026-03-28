import 'package:flutter/foundation.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class OvereatingStats {
  final int streakDays;
  final bool overateYesterday;
  final int overeatingLast7;
  final int totalPastDays;

  OvereatingStats({
    required this.streakDays,
    required this.overateYesterday,
    required this.overeatingLast7,
    required this.totalPastDays,
  });
}

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

  bool get overate => _currentDay?.overate ?? false;

  List<FoodDay> get history {
    final days = _foodDayRepository.getAllDays();
    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  OvereatingStats getOvereatingStats() {
    final allHistory = history;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter out today for stats calculation
    final pastDays = allHistory.where((d) {
      final dDate = DateTime(d.date.year, d.date.month, d.date.day);
      return dDate.isBefore(today);
    }).toList();

    if (pastDays.isEmpty) {
      return OvereatingStats(
        streakDays: 0,
        overateYesterday: false,
        overeatingLast7: 0,
        totalPastDays: 0,
      );
    }

    bool overateYesterday = false;
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayDay = pastDays.firstWhere(
      (d) => DateTime(d.date.year, d.date.month, d.date.day) == yesterday,
      orElse: () => FoodDay(date: yesterday, meals: [], snacks: []),
    );
    overateYesterday = yesterdayDay.overate;

    int streak = 0;
    for (final day in pastDays) {
      if (!day.overate) {
        streak++;
      } else {
        break;
      }
    }

    int last7Count = 0;
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    for (final day in pastDays) {
      final dDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (dDate.isAfter(sevenDaysAgo.subtract(const Duration(seconds: 1))) && day.overate) {
        last7Count++;
      }
    }

    return OvereatingStats(
      streakDays: streak,
      overateYesterday: overateYesterday,
      overeatingLast7: last7Count,
      totalPastDays: pastDays.length,
    );
  }

  Future<void> initialize(DateTime now) async {
    _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
    _handleDayProgression(now);
    notifyListeners();
  }

  void refresh() {
    _handleDayProgression(DateTime.now());
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

  void toggleOverate() {
    if (_currentDay == null) return;
    _currentDay!.overate = !_currentDay!.overate;
    _foodDayRepository.saveDay(_currentDay!);
    notifyListeners();
  }

  void toggleHistoricalFoodStatus(FoodDay day, Food food, DateTime? eatenAt) {
    if (eatenAt != null) {
      food.eat(eatenAt);
    } else {
      food.unEat();
    }
    _foodDayRepository.saveDay(day);
    notifyListeners();
  }

  void toggleHistoricalOverate(FoodDay day) {
    day.overate = !day.overate;
    _foodDayRepository.saveDay(day);
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

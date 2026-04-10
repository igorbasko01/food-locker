import 'package:flutter/foundation.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';

class OvereatingStats {
  final int cleanStreak;
  final int overeatingStreak;
  final int longestCleanStreak;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;
  final DateTime? currentStreakStart;
  final DateTime? currentStreakEnd;

  OvereatingStats({
    required this.cleanStreak,
    required this.overeatingStreak,
    required this.longestCleanStreak,
    this.longestStreakStart,
    this.longestStreakEnd,
    this.currentStreakStart,
    this.currentStreakEnd,
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
        cleanStreak: 0,
        overeatingStreak: 0,
        longestCleanStreak: 0,
      );
    }

    int cleanStreak = 0;
    int overeatingStreak = 0;
    DateTime? currentStreakStart;
    DateTime? currentStreakEnd;
    
    // Calculate current streaks
    for (int i = 0; i < pastDays.length; i++) {
      final day = pastDays[i];
      if (!day.overate) {
        if (overeatingStreak > 0) break;
        if (cleanStreak == 0) currentStreakEnd = day.date;
        cleanStreak++;
        currentStreakStart = day.date;
      } else {
        if (cleanStreak > 0) break;
        if (overeatingStreak == 0) currentStreakEnd = day.date;
        overeatingStreak++;
        currentStreakStart = day.date;
      }
    }

    // Calculate longest clean streak
    int longestCleanStreak = 0;
    DateTime? longestStreakStart;
    DateTime? longestStreakEnd;

    int currentCleanStreakTemp = 0;
    DateTime? currentStreakStartTemp;

    // We need to iterate over all past days from oldest to newest or newest to oldest.
    // pastDays is sorted newest to oldest because history is "date.compareTo(a.date)".
    // Let's reverse it to iterate oldest to newest, which is easier for calculating streaks.
    final oldestToNewest = pastDays.reversed.toList();
    for (final day in oldestToNewest) {
      if (!day.overate) {
        if (currentCleanStreakTemp == 0) {
          currentStreakStartTemp = day.date;
        }
        currentCleanStreakTemp++;
        if (currentCleanStreakTemp > longestCleanStreak) {
          longestCleanStreak = currentCleanStreakTemp;
          longestStreakStart = currentStreakStartTemp;
          longestStreakEnd = day.date;
        }
      } else {
        currentCleanStreakTemp = 0;
        currentStreakStartTemp = null;
      }
    }

    return OvereatingStats(
      cleanStreak: cleanStreak,
      overeatingStreak: overeatingStreak,
      longestCleanStreak: longestCleanStreak,
      longestStreakStart: longestStreakStart,
      longestStreakEnd: longestStreakEnd,
      currentStreakStart: currentStreakStart,
      currentStreakEnd: currentStreakEnd,
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

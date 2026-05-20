import 'package:flutter/foundation.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
class OvereatingStats {
  final int cleanStreak;
  final int overeatingStreak;
  final int longestCleanStreak;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;
  final DateTime? currentStreakStart;
  final DateTime? currentStreakEnd;
  final bool hasHistory;

  OvereatingStats({
    required this.cleanStreak,
    required this.overeatingStreak,
    required this.longestCleanStreak,
    this.longestStreakStart,
    this.longestStreakEnd,
    this.currentStreakStart,
    this.currentStreakEnd,
    required this.hasHistory,
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

  List<FoodDay> get history {
    final days = _foodDayRepository.getAllDays();
    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  OvereatingStats getOvereatingStats(WeightManager weightManager) {
    final allHistory = history;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter out today for stats calculation
    final pastDays = allHistory.where((d) {
      final dDate = DateTime(d.date.year, d.date.month, d.date.day);
      return dDate.isBefore(today);
    }).toList();

    final hasHistory = pastDays.isNotEmpty || weightManager.history.any((w) => w.date.isBefore(today));

    if (pastDays.isEmpty && weightManager.history.isEmpty) {
      return OvereatingStats(
        cleanStreak: 0,
        overeatingStreak: 0,
        longestCleanStreak: 0,
        hasHistory: false,
      );
    }

    int cleanStreak = 0;
    int overeatingStreak = 0;
    DateTime? currentStreakStart;
    DateTime? currentStreakEnd;
    
    // Calculate current streaks backwards day-by-day starting from yesterday
    DateTime currentDate = DateTime(today.year, today.month, today.day - 1);
    while (true) {
      final overeaten = isOvereaten(currentDate, weightManager);
      
      if (overeaten == null) {
        break; // N/A state breaks the continuous streak
      } else if (!overeaten) {
        if (overeatingStreak > 0) break;
        if (cleanStreak == 0) currentStreakEnd = currentDate;
        cleanStreak++;
        currentStreakStart = currentDate;
      } else {
        if (cleanStreak > 0) break;
        if (overeatingStreak == 0) currentStreakEnd = currentDate;
        overeatingStreak++;
        currentStreakStart = currentDate;
      }
      currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day - 1);
    }

    // Calculate longest clean streak
    int longestCleanStreak = 0;
    DateTime? longestStreakStart;
    DateTime? longestStreakEnd;

    int currentCleanStreakTemp = 0;
    DateTime? currentStreakStartTemp;

    final pastWeights = weightManager.history.where((w) {
      final wDate = DateTime(w.date.year, w.date.month, w.date.day);
      return wDate.isBefore(today);
    }).toList();

    // Iterate over calendar days from the oldest weight up to yesterday
    if (pastWeights.isNotEmpty) {
      final oldestWeightDate = pastWeights.last.date;
      DateTime iterDate = DateTime(oldestWeightDate.year, oldestWeightDate.month, oldestWeightDate.day);

      while (iterDate.isBefore(today)) {
        final overeaten = isOvereaten(iterDate, weightManager);
        
        if (overeaten == false) {
          if (currentCleanStreakTemp == 0) {
            currentStreakStartTemp = iterDate;
          }
          currentCleanStreakTemp++;
          if (currentCleanStreakTemp > longestCleanStreak) {
            longestCleanStreak = currentCleanStreakTemp;
            longestStreakStart = currentStreakStartTemp;
            longestStreakEnd = iterDate;
          }
        } else {
          currentCleanStreakTemp = 0;
          currentStreakStartTemp = null;
        }
        iterDate = DateTime(iterDate.year, iterDate.month, iterDate.day + 1);
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
      hasHistory: hasHistory,
    );
  }

  Future<void> initialize(DateTime now) async {
    _currentDay = _foodDayRepository.getDay(now) ?? _createDay(now);
    _handleDayProgression(now);
    notifyListeners();
  }

  bool? isOvereaten(DateTime date, WeightManager weightManager) {
    final hasFoodDay = _foodDayRepository.getDay(date) != null;
    if (!hasFoodDay) return null;

    final weightOnDay = weightManager.getWeightForDate(date);
    final weightNextDay = weightManager.getWeightForDate(DateTime(date.year, date.month, date.day + 1));

    if (weightOnDay != null && weightNextDay != null) {
      return weightNextDay.value > weightOnDay.value;
    }
    return null;
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

  void toggleHistoricalFoodStatus(FoodDay day, Food food, DateTime? eatenAt) {
    if (eatenAt != null) {
      food.eat(eatenAt);
    } else {
      food.unEat();
    }
    _foodDayRepository.saveDay(day);
    notifyListeners();
  }

  Future<void> deleteDay(FoodDay day) async {
    await _foodDayRepository.deleteDay(day.date);

    // If we deleted the current day, we need to re-initialize it
    if (_currentDay != null &&
        _currentDay!.date.year == day.date.year &&
        _currentDay!.date.month == day.date.month &&
        _currentDay!.date.day == day.date.day) {
      _currentDay = _foodDayRepository.getDay(day.date) ?? _createDay(day.date);
    }

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

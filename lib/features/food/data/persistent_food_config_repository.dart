import 'dart:convert';

import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentFoodConfigRepository implements FoodConfigRepository {
  static const String _storageKey = 'food_configs';
  final SharedPreferences _prefs;
  List<FoodConfig> _foodConfigs = [];

  PersistentFoodConfigRepository(this._prefs) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _foodConfigs = jsonList.map((j) => FoodConfig.fromJson(j)).toList();
    }
  }

  void _save() {
    final jsonString = jsonEncode(_foodConfigs.map((c) => c.toJson()).toList());
    _prefs.setString(_storageKey, jsonString);
  }

  @override
  List<FoodConfig> get foodConfigs => _foodConfigs;

  @override
  void add(FoodConfig foodConfig) {
    _foodConfigs.add(foodConfig);
    _save();
  }

  @override
  void remove(FoodConfig foodConfig) {
    _foodConfigs.remove(foodConfig);
    _save();
  }

  @override
  void clear() {
    _foodConfigs.clear();
    _save();
  }

  @override
  List<FoodConfig> getFoodConfigsByType(FoodType foodType) {
    return _foodConfigs
        .where((foodConfig) => foodConfig.type == foodType)
        .toList();
  }
}

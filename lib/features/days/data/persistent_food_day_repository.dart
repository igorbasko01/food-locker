import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:hive/hive.dart';

class PersistentFoodDayRepository implements FoodDayRepository {
  final Box<FoodDay> _box;

  PersistentFoodDayRepository(this._box);

  String _getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  FoodDay? getDay(DateTime date) {
    return _box.get(_getKey(date));
  }

  @override
  Future<void> saveDay(FoodDay day) async {
    await _box.put(_getKey(day.date), day);
  }

  @override
  List<FoodDay> getAllDays() {
    return _box.values.toList();
  }
}

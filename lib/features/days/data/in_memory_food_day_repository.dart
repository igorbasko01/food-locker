import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';

class InMemoryFoodDayRepository implements FoodDayRepository {
  final Map<String, FoodDay> _days = {};

  String _getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  FoodDay? getDay(DateTime date) {
    return _days[_getKey(date)];
  }

  @override
  Future<void> saveDay(FoodDay day) async {
    _days[_getKey(day.date)] = day;
  }

  @override
  List<FoodDay> getAllDays() {
    return _days.values.toList();
  }

  @override
  Future<void> clear() async {
    _days.clear();
  }
  
  @override
  Future<void> deleteDay(DateTime date) async {
    _days.remove(_getKey(date));
  }
}

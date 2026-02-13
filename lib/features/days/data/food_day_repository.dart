import 'package:food_locker/features/days/data/day.dart';

abstract class FoodDayRepository {
  FoodDay? getDay(DateTime date);
  Future<void> saveDay(FoodDay day);
}

import 'package:food_locker/features/food/data/food.dart';

class FoodDay {
  final DateTime date;
  final List<Food> meals;
  final List<Food> snacks;

  FoodDay({required this.date, required this.meals, required this.snacks});
}

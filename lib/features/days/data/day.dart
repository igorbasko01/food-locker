import 'package:food_locker/features/food/data/food.dart';
import 'package:hive/hive.dart';

part 'day.g.dart';

@HiveType(typeId: 1)
class FoodDay {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final List<Food> meals;
  @HiveField(2)
  final List<Food> snacks;
  @HiveField(3)
  bool? _overate;

  bool get overate => _overate ?? false;
  set overate(bool value) => _overate = value;

  FoodDay({
    required this.date,
    required this.meals,
    required this.snacks,
    bool? overate,
  }) : _overate = overate ?? false;
}

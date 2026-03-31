import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/food/data/food.dart';

/// Shows a time picker for [food] on [day] and returns the resulting [DateTime],
/// or `null` if the user dismissed the picker.
Future<DateTime?> pickFoodTime(
  BuildContext context,
  FoodDay day,
  Food food,
) async {
  final initialTime = food.wasEaten
      ? TimeOfDay.fromDateTime(food.eatenAt!)
      : TimeOfDay.now();

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );

  if (pickedTime == null) return null;

  return DateTime(
    day.date.year,
    day.date.month,
    day.date.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

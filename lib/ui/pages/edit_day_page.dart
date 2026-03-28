import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/widgets/food_day_view.dart';
import 'package:provider/provider.dart';

class EditDayPage extends StatelessWidget {
  final FoodDay day;

  const EditDayPage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final dayManager = context.watch<FoodDayManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_formatDate(day.date)}'),
      ),
      body: FoodDayView(
        day: day,
        onOverateToggled: () => dayManager.toggleHistoricalOverate(day),
        onFoodToggled: (food) async {
          if (food.wasEaten) {
            dayManager.toggleHistoricalFoodStatus(day, food, null);
          } else {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (pickedTime != null) {
              final eatenAt = DateTime(
                day.date.year,
                day.date.month,
                day.date.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              dayManager.toggleHistoricalFoodStatus(day, food, eatenAt);
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/utils/food_time_picker.dart';
import 'package:food_locker/ui/widgets/day_date_text.dart';
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
        title: Text('Edit ${DayDateText.format(day.date)}'),
      ),
      body: FoodDayView(
        day: day,
        onFoodToggled: (food) async {
          if (food.wasEaten) {
            dayManager.toggleHistoricalFoodStatus(day, food, null);
          } else {
            final eatenAt = await pickFoodTime(context, day, food);
            if (eatenAt != null) {
              dayManager.toggleHistoricalFoodStatus(day, food, eatenAt);
            }
          }
        },
        onFoodTimeAdjusted: (food, eatenAt) {
          dayManager.toggleHistoricalFoodStatus(day, food, eatenAt);
        },
      ),
    );
  }

}

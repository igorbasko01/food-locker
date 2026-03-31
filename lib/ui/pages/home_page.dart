import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/widgets/day_date_text.dart';
import 'package:food_locker/ui/widgets/food_day_view.dart';
import 'package:food_locker/ui/widgets/streak_banner.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayManager = context.watch<FoodDayManager>();
    final now = DateTime.now();
    
    // Ensure current day is properly loaded (triggers progression)
    dayManager.getMeals(now);
    final day = dayManager.currentDay;

    if (day == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: FoodDayView(
        day: day,
        onOverateToggled: () => dayManager.toggleOverate(),
        onFoodToggled: (food) async {
          dayManager.toggleFoodStatus(food, DateTime.now());
        },
        onFoodLongPressed: (food) async {
          final initialTime = food.wasEaten 
              ? TimeOfDay.fromDateTime(food.eatenAt!)
              : TimeOfDay.now();
          
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
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
        },
        sliversBefore: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.home_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text('Today\'s Food', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DayDateText(
                        date: day.date,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => dayManager.refresh(),
                        tooltip: 'Refresh day',
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreakBanner(stats: dayManager.getOvereatingStats()),
          ),
        ],
      ),
    );
  }

}

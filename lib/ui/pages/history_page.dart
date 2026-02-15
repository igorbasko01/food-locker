import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodDayManager>(
      builder: (context, manager, child) {
        final history = manager.history;

        if (history.isEmpty) {
          return const Center(child: Text('No history available'));
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final day = history[index];
            final consumedFoods = [
              ...day.meals.where((f) => f.wasEaten),
              ...day.snacks.where((f) => f.wasEaten),
            ];
            consumedFoods.sort((a, b) => a.eatenAt!.compareTo(b.eatenAt!));

            return ExpansionTile(
              key: ValueKey(day.date),
              title: Text(_formatDate(day.date)),
              children: consumedFoods.map((food) {
                return ListTile(
                  title: Text(food.name),
                  trailing: Text(_formatTime(food.eatenAt!)),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/pages/edit_day_page.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  static const int pageSize = 7;

  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _visibleCount = HistoryPage.pageSize;

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodDayManager>(
      builder: (context, manager, child) {
        final history = manager.history;

        if (history.isEmpty) {
          return const Center(child: Text('No history available'));
        }

        final itemsToShow = history.length > _visibleCount
            ? _visibleCount
            : history.length;
        final hasMore = history.length > _visibleCount;

        return ListView.builder(
          itemCount: itemsToShow + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == itemsToShow) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _visibleCount += HistoryPage.pageSize;
                      });
                    },
                    child: const Text('Load More'),
                  ),
                ),
              );
            }

            final day = history[index];
            final consumedFoods = [
              ...day.meals.where((f) => f.wasEaten),
              ...day.snacks.where((f) => f.wasEaten),
            ];
            consumedFoods.sort((a, b) => a.eatenAt!.compareTo(b.eatenAt!));

            return ExpansionTile(
              key: ValueKey(day.date),
              title: Row(
                children: [
                  Text(_formatDate(day.date)),
                  if (day.overate) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.warning_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDayPage(day: day),
                    ),
                  );
                },
              ),
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

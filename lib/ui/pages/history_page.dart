import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/pages/edit_day_page.dart';
import 'package:food_locker/ui/utils/food_time_picker.dart';
import 'package:food_locker/ui/widgets/day_date_text.dart';
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
        final weightManager = context.watch<WeightManager>();

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
                  DayDateText(date: day.date),
                  if (day.overate) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.warning_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                  ],
                  const Spacer(),
                  () {
                    final weight = weightManager.getWeightForDate(day.date);
                    if (weight != null) {
                      return Text(
                        '${weight.value.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 14,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }(),
                  const SizedBox(width: 8),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDayPage(day: day),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Day'),
                        content: const Text(
                          'Are you sure you want to delete this day from your history?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      manager.deleteDay(day);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              children: consumedFoods.map((food) {
                return ListTile(
                  title: Text(food.name),
                  trailing: Text(_formatTime(food.eatenAt!)),
                  onLongPress: () async {
                    final eatenAt = await pickFoodTime(context, day, food);
                    if (eatenAt != null) {
                      manager.toggleHistoricalFoodStatus(day, food, eatenAt);
                    }
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }


  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

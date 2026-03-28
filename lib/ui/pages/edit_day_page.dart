import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:provider/provider.dart';

class EditDayPage extends StatelessWidget {
  final FoodDay day;

  const EditDayPage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayManager = context.watch<FoodDayManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${ _formatDate(day.date)}'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: day.overate
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: SwitchListTile(
                  title: Text(
                    'Overate?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: day.overate
                          ? theme.colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                  secondary: Icon(
                    day.overate
                        ? Icons.warning_rounded
                        : Icons.check_circle_outline_rounded,
                    color: day.overate
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  value: day.overate,
                  onChanged: (_) => dayManager.toggleHistoricalOverate(day),
                ),
              ),
            ),
          ),
          if (day.meals.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildHeader(context, 'Meals')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildFoodItem(context, day.meals[index], dayManager),
                childCount: day.meals.length,
              ),
            ),
          ],
          if (day.snacks.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildHeader(context, 'Snacks')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildFoodItem(context, day.snacks[index], dayManager),
                childCount: day.snacks.length,
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFoodItem(
    BuildContext context,
    Food food,
    FoodDayManager manager,
  ) {
    final theme = Theme.of(context);
    final isEaten = food.wasEaten;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isEaten ? 0 : 1,
      color: isEaten
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      child: InkWell(
        onLongPress: () async {
          if (isEaten) {
            manager.toggleHistoricalFoodStatus(day, food, null);
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
              manager.toggleHistoricalFoodStatus(day, food, eatenAt);
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  food.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: isEaten ? TextDecoration.lineThrough : null,
                    color: isEaten ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              if (isEaten) ...[
                Text(
                  TimeOfDay.fromDateTime(food.eatenAt!).format(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/ui/utils/food_time_picker.dart';

class FoodDayView extends StatelessWidget {
  final FoodDay day;
  final Future<void> Function(Food) onFoodToggled;
  final void Function(Food, DateTime)? onFoodTimeAdjusted;
  final List<Widget>? sliversBefore;
  final List<Widget>? sliversAfter;

  const FoodDayView({
    super.key,
    required this.day,
    required this.onFoodToggled,
    this.onFoodTimeAdjusted,
    this.sliversBefore,
    this.sliversAfter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        ...?sliversBefore,
        if (day.meals.isEmpty && day.snacks.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No food configured. Go to Settings!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (day.meals.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildHeader(context, 'Meals')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFoodItem(context, day.meals[index]),
              childCount: day.meals.length,
            ),
          ),
        ],
        if (day.snacks.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildHeader(context, 'Snacks')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFoodItem(context, day.snacks[index]),
              childCount: day.snacks.length,
            ),
          ),
        ],
        ...?sliversAfter,
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
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

  Widget _buildFoodItem(BuildContext context, Food food) {
    final theme = Theme.of(context);
    final isEaten = food.wasEaten;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isEaten ? 0 : 1,
      color: isEaten
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: () => onFoodToggled(food),
        onLongPress: onFoodTimeAdjusted != null
            ? () async {
                final eatenAt = await pickFoodTime(context, day, food);
                if (eatenAt != null) {
                  onFoodTimeAdjusted!(food, eatenAt);
                }
              }
            : null,
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

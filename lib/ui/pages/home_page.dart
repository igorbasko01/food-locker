import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We can use watch here directly or Consumer, since StatelessWidget rebuilds are cheap
    // But Consumer is more explicit about what part depends on the data if we had a complex tree
    final dayManager = context.watch<FoodDayManager>();
    // We use DateTime.now() to get the current view of meals/snacks.
    // In a real app we might want to store the "viewed date" in the manager or local state.
    // Spec assumes "current FoodDay".
    final now = DateTime.now();
    final meals = dayManager.getMeals(now);
    final snacks = dayManager.getSnacks(now);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: dayManager.overate
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: SwitchListTile(
                  title: Text(
                    'Overate today?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: dayManager.overate
                          ? theme.colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                  secondary: Icon(
                    dayManager.overate
                        ? Icons.warning_rounded
                        : Icons.check_circle_outline_rounded,
                    color: dayManager.overate
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  value: dayManager.overate,
                  onChanged: (_) => dayManager.toggleOverate(),
                ),
              ),
            ),
          ),
          if (meals.isEmpty && snacks.isEmpty)
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
          if (meals.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildHeader(context, 'Meals')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildFoodItem(context, meals[index], dayManager),
                childCount: meals.length,
              ),
            ),
          ],
          if (snacks.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildHeader(context, 'Snacks')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildFoodItem(context, snacks[index], dayManager),
                childCount: snacks.length,
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
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
        onLongPress: () {
          manager.toggleFoodStatus(food, DateTime.now());
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

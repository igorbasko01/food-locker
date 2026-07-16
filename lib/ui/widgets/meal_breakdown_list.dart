import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';

/// The meal-by-meal breakdown of a single day: one row per meal with its bite
/// count and time span, plus a trailing row for the day's snack total (every
/// bite outside a qualifying meal).
///
/// A read-only projection of [DayMealBreakdown]. When the day has no bites yet
/// — no meals and no snacks — it shows an empty state instead of blank rows.
class MealBreakdownList extends StatelessWidget {
  const MealBreakdownList({super.key, required this.breakdown});

  /// The day split into its meals and snack total.
  final DayMealBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = breakdown.meals;
    if (meals.isEmpty && breakdown.snackBites == 0) {
      return _empty(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < meals.length; i++)
          _MealRow(index: i + 1, meal: meals[i]),
        _SnackRow(bites: breakdown.snackBites),
      ],
    );
  }

  Widget _empty(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Text(
      'No bites logged today yet.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

/// A single meal: its ordinal, the span it ran over, and its bite count.
class _MealRow extends StatelessWidget {
  const _MealRow({required this.index, required this.meal});

  final int index;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Meal $index, ${meal.count} bites',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal $index', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime(meal.start)} – ${_formatTime(meal.end)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text('${meal.count} bites', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

/// The day's snack total: every bite that fell outside a qualifying meal.
class _SnackRow extends StatelessWidget {
  const _SnackRow({required this.bites});

  final int bites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Snacks, $bites bites',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Snacks',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$bites bites',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A local time as `h:mm AM/PM`, 12-hour with no leading zero on the hour.
String _formatTime(DateTime at) {
  final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  final period = at.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

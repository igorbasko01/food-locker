import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';

/// The meal-by-meal breakdown of a single day: one row per meal with its bite
/// count and time span, a row for the day's snack total (every bite outside a
/// qualifying meal), and a summary line with the day's total bites.
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
        const Divider(height: 1),
        _TotalRow(bites: breakdown.totalBites),
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
                    '${shortTime(meal.start)} – ${shortTime(meal.end)}',
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

/// Every bite logged on the day, meals and snacks together.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.bites});

  final int bites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Total, $bites bites',
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$bites bites',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class WeightChangeIndicator extends StatelessWidget {
  final double? diff;
  final WeightUnit unit;

  const WeightChangeIndicator({
    super.key,
    required this.diff,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDiff = diff;

    if (currentDiff == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Baseline',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else if (currentDiff > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward_rounded, size: 12, color: theme.colorScheme.error),
            const SizedBox(width: 2),
            Text(
              '+${currentDiff.toStringAsFixed(1)} ${unit.symbol}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (currentDiff < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.green),
            const SizedBox(width: 2),
            Text(
              '${currentDiff.toStringAsFixed(1)} ${unit.symbol}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_rounded, size: 12, color: theme.colorScheme.outline),
            const SizedBox(width: 2),
            Text(
              '0.0 ${unit.symbol}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
}

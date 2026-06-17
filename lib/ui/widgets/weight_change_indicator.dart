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

    final Color backgroundColor;
    final Color textColor;
    final IconData? icon;
    final String text;
    final FontWeight fontWeight;

    if (currentDiff == null) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = theme.colorScheme.onSurfaceVariant;
      icon = null;
      text = 'Baseline';
      fontWeight = FontWeight.normal;
    } else if (currentDiff > 0) {
      backgroundColor = theme.colorScheme.errorContainer.withValues(alpha: 0.5);
      textColor = theme.colorScheme.error;
      icon = Icons.arrow_upward_rounded;
      text = '+${currentDiff.toStringAsFixed(1)} ${unit.symbol}';
      fontWeight = FontWeight.bold;
    } else if (currentDiff < 0) {
      backgroundColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green;
      icon = Icons.arrow_downward_rounded;
      text = '${currentDiff.toStringAsFixed(1)} ${unit.symbol}';
      fontWeight = FontWeight.bold;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = theme.colorScheme.outline;
      icon = Icons.remove_rounded;
      text = '0.0 ${unit.symbol}';
      fontWeight = FontWeight.bold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

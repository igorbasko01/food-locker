import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/weight_change_indicator.dart';

class WeightHistoryTile extends StatelessWidget {
  final Weight item;
  final double? diff;

  const WeightHistoryTile({
    super.key,
    required this.item,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.value.toStringAsFixed(1)} ${item.unit.symbol}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            WeightChangeIndicator(
              diff: diff,
              unit: item.unit,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/widgets/day_date_text.dart';

class LongestStreakBanner extends StatelessWidget {
  final OvereatingStats stats;

  const LongestStreakBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.longestCleanStreak < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = Colors.amber.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_rounded, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All-Time Best: ${stats.longestCleanStreak} Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (stats.longestStreakStart != null &&
                      stats.longestStreakEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                      child: Text(
                        '${DayDateText.format(stats.longestStreakStart!)} to ${DayDateText.format(stats.longestStreakEnd!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  Text(
                    'Your longest streak of eating mindfully!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

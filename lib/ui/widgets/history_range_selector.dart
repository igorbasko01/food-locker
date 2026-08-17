import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/history_range.dart';

extension HistoryRangeLabel on HistoryRange {
  String get label => switch (this) {
    HistoryRange.week => 'Last 7 days',
    HistoryRange.month => 'Last 30 days',
    HistoryRange.quarter => 'Last 90 days',
    HistoryRange.halfYear => 'Last 6 months',
    HistoryRange.year => 'Last year',
  };
}

/// Picks how far back the weight history reaches.
///
/// A menu rather than a segmented control: the five labels don't fit a phone's
/// width side by side, and a custom range can later join as one more item.
class HistoryRangeSelector extends StatelessWidget {
  const HistoryRangeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HistoryRange selected;
  final ValueChanged<HistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<HistoryRange>(
      initialValue: selected,
      tooltip: 'Change range',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final range in HistoryRange.values)
          PopupMenuItem(value: range, child: Text(range.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

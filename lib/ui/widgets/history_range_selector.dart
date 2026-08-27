import 'package:flutter/material.dart';
import 'package:food_locker/core/date_range.dart';

/// The ranges the weight history offers, shortest first.
const historyRangePresets = <DateRange>[
  DateRange.lastDays(7),
  DateRange.lastDays(30),
  DateRange.lastDays(90),
  DateRange.lastDays(180),
  DateRange.lastDays(365),
];

extension HistoryRangeSpan on DateRange {
  /// Title-cased for headings ('Latest 30 Days of Weight'); lowercase it for
  /// prose ('the last 30 days'). Rounded to the unit the span is closest to,
  /// so 180 days reads as months.
  String get span => switch (days) {
    180 => '6 Months',
    365 => 'Year',
    _ => '$days Days',
  };
}

/// Picks how far back the weight history reaches.
class HistoryRangeSelector extends StatelessWidget {
  const HistoryRangeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DateRange selected;
  final ValueChanged<DateRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<DateRange>(
      initialValue: selected,
      tooltip: 'Change range',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final range in historyRangePresets)
          PopupMenuItem(
            value: range,
            child: Text('Last ${range.span.toLowerCase()}'),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Last ${selected.span.toLowerCase()}',
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';

/// A bar chart of total bites per calendar day over the analytics window.
///
/// One bar per day between the first and last logged day, with zero-height
/// gaps for days that had no bites. Days below [BiteAnalytics.minBitesForAverage]
/// — the ones excluded from the average — are drawn muted and sit under a faint
/// reference line at that threshold, so the chart visibly explains why they
/// don't count. Themed like `weight_chart.dart`.
class DailyBitesChart extends StatelessWidget {
  const DailyBitesChart({
    super.key,
    required this.counts,
    this.selectedDay,
    this.onDaySelected,
  });

  /// Daily totals, one entry per day that had at least one bite. Zero days are
  /// absent and rendered as gaps; the widget zero-fills between the extremes.
  final List<DailyBiteCount> counts;

  /// The calendar day whose bar is highlighted, linking the chart to the
  /// breakdown card below it. Null leaves every bar in its default treatment.
  final DateTime? selectedDay;

  /// Called with the calendar day of a tapped bar. Null makes the chart
  /// read-only (no selection).
  final ValueChanged<DateTime>? onDaySelected;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(
        child: Text(
          'No daily bites to display.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final theme = Theme.of(context);
    final fullColor = theme.colorScheme.primary;
    final mutedColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    final byDay = {
      for (final c in counts) DateTime(c.day.year, c.day.month, c.day.day): c.count,
    };
    final days = byDay.keys.toList()..sort();
    final firstDay = days.first;
    final lastDay = days.last;
    final selected = selectedDay == null
        ? null
        : DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);

    // One bar per calendar day in [firstDay, lastDay], zero-filling gap days.
    final bars = <BarChartGroupData>[];
    var x = 0;
    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final count = byDay[day] ?? 0;
      final belowThreshold = count < BiteAnalytics.minBitesForAverage;
      final isSelected = day == selected;
      bars.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              // The selected bar reads at full colour even when it's muted
              // below the threshold, so the link to the card below is visible.
              color: (belowThreshold && !isSelected) ? mutedColor : fullColor,
              width: _barWidth(days.length),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              borderSide: isSelected
                  ? BorderSide(color: theme.colorScheme.onSurface, width: 1.5)
                  : BorderSide.none,
            ),
          ],
        ),
      );
      x++;
    }
    final dayCount = bars.length;

    final maxCount = byDay.values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount * 1.1)
        .clamp(BiteAnalytics.minBitesForAverage * 1.2, double.infinity)
        .toDouble();

    // The bars are painted to a canvas fl_chart exposes no semantics for, so
    // summarise the chart for screen readers.
    final semanticsLabel =
        'Daily bites bar chart, $dayCount days. '
        'Highest day $maxCount bites.';

    return Semantics(
      label: semanticsLabel,
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: maxY,
            minY: 0,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value != value.roundToDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: _labelInterval(dayCount),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= dayCount) {
                      return const SizedBox.shrink();
                    }
                    final day = DateTime(
                      firstDay.year,
                      firstDay.month,
                      firstDay.day + index,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        shortDate(day),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: BiteAnalytics.minBitesForAverage.toDouble(),
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ],
            ),
            barTouchData: BarTouchData(
              touchCallback: (event, response) {
                if (onDaySelected == null) return;
                // Select on tap-up so a scroll/drag over the chart doesn't
                // reselect; the tooltip still shows on the same touch.
                if (event is! FlTapUpEvent) return;
                final group = response?.spot?.touchedBarGroup;
                if (group == null) return;
                onDaySelected!(
                  DateTime(firstDay.year, firstDay.month, firstDay.day + group.x),
                );
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final day = DateTime(
                    firstDay.year,
                    firstDay.month,
                    firstDay.day + group.x,
                  );
                  return BarTooltipItem(
                    '${fullDate(day)}\n${rod.toY.toInt()} bites',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            barGroups: bars,
          ),
        ),
      ),
    );
  }

  /// Narrows the bars as the window fills up so a full 30-day window stays legible.
  static double _barWidth(int dayCount) => dayCount > 20 ? 5 : 8;

  /// Labels at most ~6 days on the x-axis so tick labels never overlap.
  static double _labelInterval(int dayCount) =>
      (dayCount / 6).ceilToDouble().clamp(1, double.infinity);
}

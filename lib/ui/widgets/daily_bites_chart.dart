import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';

/// A bar chart of total bites per calendar day over the analytics window.
///
/// One bar per day between the first and last logged day, with zero-height
/// gaps for days that had no bites. Days below [BiteAnalytics.minBitesForAverage]
/// — the ones excluded from the average (§5.2) — are drawn muted and sit under a
/// faint reference line at that threshold, so the chart visibly explains why
/// they don't count. Themed like `weight_chart.dart`.
class DailyBitesChart extends StatelessWidget {
  const DailyBitesChart({super.key, required this.counts});

  /// Daily totals, one entry per day that had at least one bite. Zero days are
  /// absent and rendered as gaps; the widget zero-fills between the extremes.
  final List<DailyBiteCount> counts;

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
      bars.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: belowThreshold ? mutedColor : fullColor,
              width: _barWidth(days.length),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
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

    return Padding(
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
                      '${day.month}/${day.day}',
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
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = DateTime(
                  firstDay.year,
                  firstDay.month,
                  firstDay.day + group.x,
                );
                return BarTooltipItem(
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-'
                  '${day.day.toString().padLeft(2, '0')}\n${rod.toY.toInt()} bites',
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
    );
  }

  /// Narrows the bars as the window fills up so a full 30-day window stays legible.
  static double _barWidth(int dayCount) => dayCount > 20 ? 5 : 8;

  /// Labels at most ~6 days on the x-axis so tick labels never overlap.
  static double _labelInterval(int dayCount) =>
      (dayCount / 6).ceilToDouble().clamp(1, double.infinity);
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/weight/data/weight.dart';

/// A bar chart of total bites per calendar day over the analytics window.
///
/// One bar per day between the first and last logged day, with zero-height
/// gaps for days that had no bites. Days below [BiteAnalytics.minBitesForAverage]
/// — the ones excluded from the average — are drawn muted and sit under a faint
/// reference line at that threshold, so the chart visibly explains why they
/// don't count. Themed like `weight_chart.dart`.
///
/// When [weights] is non-empty a second bar per day carries that day's weigh-in,
/// drawn on a secondary right-hand kg axis fitted to the weight range (not from
/// zero, which would flatten the day-to-day change). Days without a weigh-in
/// show only the bite bar.
class DailyBitesChart extends StatelessWidget {
  const DailyBitesChart({
    super.key,
    required this.counts,
    this.weights = const [],
    this.selectedDay,
    this.onDaySelected,
  });

  /// Daily totals, one entry per day that had at least one bite. Zero days are
  /// absent and rendered as gaps; the widget zero-fills between the extremes.
  final List<DailyBiteCount> counts;

  /// Raw daily weigh-ins, one per weighed day, overlaid as a second bar. Empty
  /// leaves the chart bites-only with no right-hand axis.
  final List<Weight> weights;

  /// The calendar day whose bar is highlighted, linking the chart to the
  /// breakdown card below it. Null leaves every bar in its default treatment.
  final DateTime? selectedDay;

  /// Called with the calendar day of a tapped bar. Null makes the chart
  /// read-only (no selection).
  final ValueChanged<DateTime>? onDaySelected;

  /// Padding above/below the weight range so even the lightest day draws a
  /// short visible bar rather than collapsing onto the axis floor.
  static const double _weightAxisPadding = 1.0;

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
    final weightColor = theme.colorScheme.tertiary;

    final byDay = {
      for (final c in counts) DateTime(c.day.year, c.day.month, c.day.day): c.count,
    };
    final weightByDay = {
      for (final w in weights)
        DateTime(w.date.year, w.date.month, w.date.day): w.value,
    };
    final hasWeight = weightByDay.isNotEmpty;
    final selected = selectedDay == null
        ? null
        : DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);

    // The x-axis spans every day that carries a bite count or a weigh-in, so a
    // weight-only day still gets a slot.
    final allDays = {...byDay.keys, ...weightByDay.keys}.toList()..sort();
    final firstDay = allDays.first;
    final lastDay = allDays.last;
    var dayCount = 0;
    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      dayCount++;
    }

    final maxCount = byDay.values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount * 1.1)
        .clamp(BiteAnalytics.minBitesForAverage * 1.2, double.infinity)
        .toDouble();

    // The weight axis is fitted to the weight range (± padding), so the weight
    // rod's kg value is normalised into the bite chart's [0, maxY] and the
    // right axis inverts that mapping back to kg.
    final weightMin = hasWeight
        ? weightByDay.values.reduce((a, b) => a < b ? a : b) - _weightAxisPadding
        : 0.0;
    final weightMax = hasWeight
        ? weightByDay.values.reduce((a, b) => a > b ? a : b) + _weightAxisPadding
        : 1.0;
    double weightToY(double kg) =>
        (kg - weightMin) / (weightMax - weightMin) * maxY;
    double yToWeight(double y) => weightMin + (y / maxY) * (weightMax - weightMin);

    // Two rods per day need half the width to fit; a bites-only chart keeps the
    // full single-rod width.
    final rodWidth = hasWeight ? _barWidth(dayCount) / 2 : _barWidth(dayCount);

    // One group per calendar day in [firstDay, lastDay], zero-filling gap days;
    // the weight rod is added only on days that were weighed.
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
      final rods = <BarChartRodData>[
        BarChartRodData(
          toY: count.toDouble(),
          // The selected bar reads at full colour even when it's muted
          // below the threshold, so the link to the card below is visible.
          color: (belowThreshold && !isSelected) ? mutedColor : fullColor,
          width: rodWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          borderSide: isSelected
              ? BorderSide(color: theme.colorScheme.onSurface, width: 1.5)
              : BorderSide.none,
        ),
      ];
      final weight = weightByDay[day];
      if (weight != null) {
        rods.add(
          BarChartRodData(
            toY: weightToY(weight),
            color: weightColor,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        );
      }
      bars.add(BarChartGroupData(x: x, barsSpace: 2, barRods: rods));
      x++;
    }

    // The bars are painted to a canvas fl_chart exposes no semantics for, so
    // summarise the chart for screen readers.
    final semanticsLabel =
        'Daily bites bar chart, $dayCount days. '
        'Highest day $maxCount bites.';

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY,
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: hasWeight
              ? AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          yToWeight(value).toStringAsFixed(1),
                          style: TextStyle(fontSize: 10, color: weightColor),
                        ),
                      );
                    },
                  ),
                )
              : const AxisTitles(
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
              // The weight rod's toY is normalised, so read the day's kg
              // back from the source instead of the rod height.
              final isWeightRod = hasWeight && rodIndex == 1;
              final text = isWeightRod
                  ? '${fullDate(day)}\n${weightByDay[day]!.toStringAsFixed(1)} kg'
                  : '${fullDate(day)}\n${rod.toY.toInt()} bites';
              return BarTooltipItem(
                text,
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
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: hasWeight
            ? Column(
                children: [
                  _Legend(biteColor: fullColor, weightColor: weightColor),
                  const SizedBox(height: 8),
                  Expanded(child: chart),
                ],
              )
            : chart,
      ),
    );
  }

  /// Narrows the bars as the window fills up so a full 30-day window stays legible.
  static double _barWidth(int dayCount) => dayCount > 20 ? 5 : 8;

  /// Labels at most ~6 days on the x-axis so tick labels never overlap.
  static double _labelInterval(int dayCount) =>
      (dayCount / 6).ceilToDouble().clamp(1, double.infinity);
}

/// The two-swatch key for the grouped chart: bites (left axis) and weight in kg
/// (right axis). Shown only when weight bars are drawn.
class _Legend extends StatelessWidget {
  const _Legend({required this.biteColor, required this.weightColor});

  final Color biteColor;
  final Color weightColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _swatch(biteColor, 'Bites'),
        const SizedBox(width: 16),
        _swatch(weightColor, 'Weight (kg)'),
      ],
    );
  }

  Widget _swatch(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

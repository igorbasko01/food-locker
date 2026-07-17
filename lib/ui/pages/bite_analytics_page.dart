import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_analytics_controller.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/ui/widgets/daily_bites_chart.dart';
import 'package:food_locker/ui/widgets/meal_breakdown_list.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

/// The read-only Bite Analytics dashboard, reached from the chart button in the
/// Bite tab's app bar.
///
/// Self-contained: it owns its own [Scaffold]/[AppBar] (with the automatic back
/// arrow) so it does not fight the app shell's shared chrome, and loads its data
/// once through a per-screen [BiteAnalyticsController]. It shows a spinner while
/// loading and a global empty state when no bites have ever been logged.
class BiteAnalyticsPage extends StatefulWidget {
  const BiteAnalyticsPage({super.key});

  @override
  State<BiteAnalyticsPage> createState() => _BiteAnalyticsPageState();
}

class _BiteAnalyticsPageState extends State<BiteAnalyticsPage> {
  late final BiteAnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BiteAnalyticsController(context.read<BiteRepository>())
      ..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bite Analytics')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_controller.hasAnyBites) {
            return const _EmptyAnalytics();
          }
          return ListView(
            children: [
              _DailyBitesCard(
                counts: _controller.dailyCounts,
                selectedDay: _controller.selectedDay,
                onDaySelected: _controller.selectDay,
              ),
              _StatTilesRow(
                averageLast30: _controller.averageLast30,
                averageLastYear: _controller.averageLastYear,
                maxLast30: _controller.maxLast30,
              ),
              _MealsSummaryRow(
                mealsToday: _controller.mealsToday,
                averageMealsLast30: _controller.averageMealsLast30,
                averageMealSizeLast30: _controller.averageMealSizeLast30,
              ),
              _MealBreakdownCard(
                breakdown: _controller.selectedBreakdown,
                isToday: _controller.isSelectedDayToday,
                isLoading: _controller.isBreakdownLoading,
                onBackToToday: () => _controller.selectDay(DateTime.now()),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The daily-bites chart, framed in a titled card with a fixed height so the
/// bars have room without the surrounding [ListView] collapsing them.
class _DailyBitesCard extends StatelessWidget {
  const _DailyBitesCard({
    required this.counts,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<DailyBiteCount> counts;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily bites — last 30 days',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(
              height: 240,
              child: DailyBitesChart(
                counts: counts,
                selectedDay: selectedDay,
                onDaySelected: onDaySelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A band of three equal-width stat tiles: the 30-day and 1-year daily-bite
/// averages, and the 30-day max with the day it fell on.
///
/// A `—` stands in wherever there is no qualifying data: an average is 0 only
/// when no day in the window cleared [BiteAnalytics.minBitesForAverage], and the
/// max is null only when the window holds no bites.
class _StatTilesRow extends StatelessWidget {
  const _StatTilesRow({
    required this.averageLast30,
    required this.averageLastYear,
    required this.maxLast30,
  });

  final double averageLast30;
  final double averageLastYear;
  final DailyBiteCount? maxLast30;

  @override
  Widget build(BuildContext context) {
    final max = maxLast30;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      // IntrinsicHeight gives the row a bounded height (the tallest tile) so the
      // stretch keeps all three tiles the same height inside the scroll view.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatTile(
                label: '30-day average',
                value: _formatAverage(averageLast30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: '1-year average',
                value: _formatAverage(averageLastYear),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: '30-day max',
                value: max == null ? '—' : max.count.toString(),
                subLabel: max == null ? null : _formatDay(max.day),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A whole-bite figure, with `—` for the no-qualifying-day case (average 0).
  static String _formatAverage(double average) =>
      average == 0 ? '—' : average.toStringAsFixed(0);

  /// A day in the device locale's numeric order, matching the daily-bites
  /// chart's axis labels.
  static String _formatDay(DateTime day) => shortDate(day);
}

/// A meals summary: today's meal count, the 30-day average meals per day, and
/// the 30-day average meal size. A meal is a cluster of at least
/// [BiteAnalytics.minMealBites] bites no more than the meal-gap threshold
/// apart; the averages span only qualifying meals (avg size) or only days that
/// had bites (avg meals), so `—` marks a window with no meals rather than zero.
class _MealsSummaryRow extends StatelessWidget {
  const _MealsSummaryRow({
    required this.mealsToday,
    required this.averageMealsLast30,
    required this.averageMealSizeLast30,
  });

  final int mealsToday;
  final double averageMealsLast30;
  final double averageMealSizeLast30;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatTile(
                label: 'Meals today',
                value: mealsToday.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: '30-day avg meals',
                value: _formatMealAverage(averageMealsLast30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: '30-day avg meal size',
                value: _formatMealSize(averageMealSizeLast30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Meals per day to one decimal, with `—` for a window that held no meals.
  static String _formatMealAverage(double average) =>
      average == 0 ? '—' : average.toStringAsFixed(1);

  /// Mean bites per meal as a whole number, with `—` for a window that held no
  /// meal.
  static String _formatMealSize(double average) =>
      average == 0 ? '—' : average.toStringAsFixed(0);
}

/// The selected day's meal breakdown, framed in a titled card matching the
/// daily-bites card. Tapping a chart bar changes [breakdown]; the title follows
/// the day — "Today's meals" for today, the locale date otherwise — with a
/// "Back to today" action while browsing another day. The [MealBreakdownList]
/// carries its own empty state for a day with no bites, so the card is always
/// shown once the log holds any bite at all.
class _MealBreakdownCard extends StatelessWidget {
  const _MealBreakdownCard({
    required this.breakdown,
    required this.isToday,
    required this.isLoading,
    required this.onBackToToday,
  });

  final DayMealBreakdown breakdown;
  final bool isToday;
  final bool isLoading;
  final VoidCallback onBackToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isToday ? 'Today\'s meals' : shortDate(breakdown.day);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (!isToday)
                  TextButton(
                    onPressed: onBackToToday,
                    child: const Text('Back to today'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              MealBreakdownList(breakdown: breakdown),
          ],
        ),
      ),
    );
  }
}

/// Shown when the bite log is empty: there is nothing to analyse until bites
/// are logged on the Bite tab.
class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No bites logged yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log bites on the Bite tab to see your trends here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

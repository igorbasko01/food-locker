import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';

/// What a heatmap cell says about its week, one line at a time.
///
/// The period the cell covers, the two means its delta was measured across —
/// each with the number of weigh-ins behind it, so a figure resting on one
/// reading can be discounted rather than mistaken for a firm one — and the
/// signed delta. A grey cell names which side is missing, so grey never reads
/// as "nothing happened".
///
/// Weights read in [system].
///
/// [week] is null for a cell past the end of the grid.
List<String> weeklyChangeSummary(
  WeeklyWeightChange? week, {
  MeasurementSystem system = MeasurementSystem.metric,
  String? locale,
}) {
  if (week == null) return const ['No data'];

  final period =
      '${shortDateWithWeekday(week.weekStart, locale)} – '
      '${shortDateWithWeekday(week.weekEnd, locale)}';
  final mean = week.mean;
  final previousMean = week.previousMean;
  // Logging nothing and logging into a week whose predecessor is blank are
  // different situations, so they say different things.
  if (mean == null) return [period, 'No weigh-ins logged'];
  if (previousMean == null) return [period, 'No weigh-ins the week before'];

  return [
    period,
    'avg ${mean.stringify(system)} (${_weighIns(week.count)}) vs '
        '${previousMean.stringify(system)} the week before '
        '(${week.previousCount})',
    week.delta!.stringify(system),
  ];
}

String _weighIns(int count) => '$count weigh-in${count == 1 ? '' : 's'}';

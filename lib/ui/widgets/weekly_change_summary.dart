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
/// Weights read in [system]; the values themselves are kilograms.
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
      '${shortDateWithWeekday(_weekEnd(week.weekStart), locale)}';
  final mean = week.mean;
  final previousMean = week.previousMean;
  // Logging nothing and logging into a week whose predecessor is blank are
  // different situations, so they say different things.
  if (mean == null) return [period, 'No weigh-ins logged'];
  if (previousMean == null) return [period, 'No weigh-ins the week before'];

  return [
    period,
    'avg ${system.formatWeight(mean)} (${_weighIns(week.count)}) vs '
        '${system.formatWeight(previousMean)} the week before '
        '(${week.previousCount})',
    _signedChange(week.delta!, system),
  ];
}

/// The Saturday closing the week [weekStart] opens.
DateTime _weekEnd(DateTime weekStart) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

String _weighIns(int count) => '$count weigh-in${count == 1 ? '' : 's'}';

/// The delta with its sign, matching how a history row states a change.
String _signedChange(double delta, MeasurementSystem system) {
  final change = system.formatWeight(delta);
  return delta > 0 ? '+$change' : change;
}

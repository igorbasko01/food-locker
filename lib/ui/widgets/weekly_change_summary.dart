import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';

/// What a heatmap cell says about its week, one line at a time.
///
/// The period the cell covers, the two weigh-ins its delta was measured across
/// — the pair is what makes red or green make sense — and the signed delta. A
/// week that failed the span gate says so, so grey never reads as "nothing
/// happened".
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
  // Naming the rule covers both ways a week fails it: nothing logged at all,
  // and weigh-ins that sat too close together.
  if (!week.hasData) {
    return [
      period,
      'No two weigh-ins ${WeeklyWeightChange.minSpanDays} days apart',
    ];
  }

  final first = week.first!;
  final last = week.last!;
  return [
    period,
    '${shortDateWithWeekday(first.date, locale)}: '
        '${system.formatWeight(first.value)} → '
        '${shortDateWithWeekday(last.date, locale)}: '
        '${system.formatWeight(last.value)}',
    _signedChange(week.delta!, system),
  ];
}

/// The Saturday closing the week [weekStart] opens.
DateTime _weekEnd(DateTime weekStart) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

/// The delta with its sign, matching how a history row states a change.
String _signedChange(double delta, MeasurementSystem system) {
  final change = system.formatWeight(delta);
  return delta > 0 ? '+$change' : change;
}

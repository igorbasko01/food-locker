import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';

/// What a heatmap cell says about its week, one line at a time.
///
/// The period the cell covers, the two weigh-ins its delta was measured across
/// — the pair is what makes red or green make sense — and the signed delta. A
/// week that failed the span gate says so, so grey never reads as "nothing
/// happened".
///
/// [week] is null for a cell past the end of the grid.
List<String> weeklyChangeSummary(WeeklyWeightChange? week, [String? locale]) {
  if (week == null) return const ['No data'];

  final period =
      '${shortDateWithWeekday(week.weekStart, locale)} – '
      '${shortDateWithWeekday(_weekEnd(week.weekStart), locale)}';
  // True of a week with nothing logged as much as one whose weigh-ins sat
  // too close together.
  if (!week.hasData) {
    return [period, 'No weigh-ins far enough apart to compare'];
  }

  final unit = week.unit!;
  return [
    period,
    '${shortDateWithWeekday(week.firstDate!, locale)}: '
        '${_measurement(week.firstValue!, unit)} → '
        '${shortDateWithWeekday(week.lastDate!, locale)}: '
        '${_measurement(week.lastValue!, unit)}',
    _signedChange(week.delta!, unit),
  ];
}

/// The Saturday closing the week [weekStart] opens.
DateTime _weekEnd(DateTime weekStart) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

String _measurement(double value, WeightUnit unit) =>
    '${value.toStringAsFixed(1)} ${unit.symbol}';

/// The delta with its sign, matching how a history row states a change.
String _signedChange(double delta, WeightUnit unit) {
  final change = _measurement(delta, unit);
  return delta > 0 ? '+$change' : change;
}

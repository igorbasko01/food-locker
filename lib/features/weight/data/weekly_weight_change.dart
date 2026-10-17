import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weight.dart';

/// One calendar week's weight change, as the Home heatmap reads it.
///
/// A week is measured against the one immediately before it, mean to mean, so
/// consecutive cells tile the timeline instead of each measuring its own
/// interior and discarding what happened across the boundary. Means rather
/// than endpoints, as in `WeightAnalytics.weeklyChange`: averaging damps
/// day-to-day water weight, so a cell no longer turns on whichever two days
/// happened to bracket the week.
///
/// The predecessor is always the preceding calendar week, never the last week
/// that happened to hold weigh-ins, so a coloured cell always means exactly
/// one week of change. A blank week therefore costs two grey cells.
class WeeklyWeightChange {
  /// The week [weekStart] opens, measured against the week before it.
  ///
  /// [entries] are the week's own weigh-ins and [previousEntries] the
  /// preceding week's, both in any order. An empty list is a week nothing was
  /// logged in.
  factory WeeklyWeightChange({
    required DateTime weekStart,
    List<WeightEntry> entries = const [],
    List<WeightEntry> previousEntries = const [],
  }) {
    assert(
      entries.every((entry) => _fallsInWeek(entry, weekStart)),
      'every weigh-in must fall in the week weekStart opens',
    );
    assert(
      previousEntries.every(
        (entry) => _fallsInWeek(entry, _weekBefore(weekStart)),
      ),
      'every previous weigh-in must fall in the week before weekStart',
    );

    return WeeklyWeightChange._(
      weekStart: weekStart,
      mean: _meanOf(entries),
      count: entries.length,
      previousMean: _meanOf(previousEntries),
      previousCount: previousEntries.length,
    );
  }

  const WeeklyWeightChange._({
    required this.weekStart,
    required this.mean,
    required this.count,
    required this.previousMean,
    required this.previousCount,
  });

  /// The Sunday opening the week, at local midnight.
  ///
  /// The week's own identity, not something the weigh-ins could supply: a week
  /// nothing was logged in still has a cell to fill and a period to name.
  final DateTime weekStart;

  /// The mean of the week's weigh-ins, null exactly when [count] is zero. One
  /// weigh-in is enough to average: a thin week is a reading, not a blank, and
  /// [count] is there so the thinness can be shown rather than hidden.
  final Weight? mean;

  /// How many weigh-ins [mean] covers.
  final int count;

  /// The same pair for the immediately preceding calendar week.
  final Weight? previousMean;
  final int previousCount;

  /// The Saturday closing the week.
  DateTime get weekEnd => _weekEnd(weekStart);

  /// The Sunday opening the week [previousMean] covers.
  DateTime get previousWeekStart => _weekBefore(weekStart);

  /// This week's mean minus the previous week's, or null when either week
  /// holds no weigh-ins.
  WeightChange? get delta {
    final current = mean;
    final previous = previousMean;
    if (current == null || previous == null) return null;
    return current.diff(previous);
  }

  bool get hasData => delta != null;

  /// Whether the week ended heavier, as [system] prints its change: a week
  /// that reads `0.00` counts as not gained.
  bool isGain(MeasurementSystem system) => (delta?.value(system) ?? 0) > 0;

  /// The Sunday opening the week before the one [weekStart] opens.
  static DateTime _weekBefore(DateTime weekStart) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day - 7);

  /// The Saturday closing the week [weekStart] opens.
  static DateTime _weekEnd(DateTime weekStart) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  static Weight? _meanOf(List<WeightEntry> entries) =>
      Weight.mean(entries.map((entry) => entry.weight));

  /// Whether [entry] falls in the seven days [weekStart] opens.
  static bool _fallsInWeek(WeightEntry entry, DateTime weekStart) {
    final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final weekAfter = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );
    return !day.isBefore(weekStart) && day.isBefore(weekAfter);
  }

  @override
  bool operator ==(Object other) =>
      other is WeeklyWeightChange &&
      other.weekStart == weekStart &&
      other.mean == mean &&
      other.count == count &&
      other.previousMean == previousMean &&
      other.previousCount == previousCount;

  @override
  int get hashCode =>
      Object.hash(weekStart, mean, count, previousMean, previousCount);

  @override
  String toString() =>
      'WeeklyWeightChange(weekStart: $weekStart, delta: $delta, '
      'mean: $mean over $count, previousMean: $previousMean over '
      '$previousCount)';
}

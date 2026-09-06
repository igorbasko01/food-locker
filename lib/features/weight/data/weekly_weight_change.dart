import 'package:food_locker/features/weight/data/weight.dart';

/// One calendar week's weight change, as the Home heatmap reads it.
///
/// Built from the week's own weigh-ins and derives everything from them:
/// intra-week only, so nothing carries across a week boundary and every week
/// stands on its own. A week whose weigh-ins span fewer than [minSpanDays]
/// days reports no [delta] at all.
class WeeklyWeightChange {
  /// The week [weekStart] opens, measured across [entries] — the week's
  /// weigh-ins, in any order. An empty list is a week nothing was logged in.
  factory WeeklyWeightChange({
    required DateTime weekStart,
    List<Weight> entries = const [],
  }) {
    assert(
      entries.every((entry) => _fallsInWeek(entry, weekStart)),
      'every weigh-in must fall in the week weekStart opens',
    );

    if (entries.isEmpty) return WeeklyWeightChange._(weekStart: weekStart);

    var first = entries.first;
    var last = entries.first;
    for (final entry in entries) {
      if (entry.date.isBefore(first.date)) first = entry;
      if (entry.date.isAfter(last.date)) last = entry;
    }
    return WeeklyWeightChange._(
      weekStart: weekStart,
      first: first,
      last: last,
    );
  }

  const WeeklyWeightChange._({required this.weekStart, this.first, this.last});

  /// Days a week's first and last weigh-in must lie apart before it reports a
  /// [delta].
  ///
  /// The span states directly what a delta has to measure — the week, not a
  /// two-day blip: a Sunday and a Saturday qualify on two weigh-ins, a Monday
  /// and Tuesday never do. A lone weigh-in spans zero days, so its
  /// `last - first == 0` cannot render as a faint loss.
  static const int minSpanDays = 3;

  /// The Sunday opening the week, at local midnight.
  ///
  /// The week's own identity, not something [entries] could supply: a week
  /// nothing was logged in still has a cell to fill and a period to name.
  final DateTime weekStart;

  /// The week's earliest and latest weigh-in, null only for a week that holds
  /// none. They are the same weigh-in when the week holds exactly one.
  final Weight? first;
  final Weight? last;

  /// Last weigh-in of the week minus its first, or null under [minSpanDays].
  double? get delta => hasData ? last!.value - first!.value : null;

  /// The unit [delta] is expressed in; null exactly when [delta] is.
  WeightUnit? get unit => hasData ? last!.unit : null;

  bool get hasData => _spanInDays >= minSpanDays;

  /// Whether the week ended heavier. A flat week counts as not gained.
  bool get isGain => (delta ?? 0) > 0;

  /// Magnitude bucket, 1 (faintest) to 4 (strongest), or null without a
  /// [delta]. The pound bounds are the kilogram ones doubled.
  int? get level {
    final magnitude = delta?.abs();
    if (magnitude == null) return null;
    final scale = unit == WeightUnit.pounds ? 2.0 : 1.0;
    if (magnitude < 0.25 * scale) return 1;
    if (magnitude < 0.5 * scale) return 2;
    if (magnitude < 1.0 * scale) return 3;
    return 4;
  }

  /// Calendar days from the first weigh-in to the last, counted on UTC
  /// midnights so a daylight-saving shift inside the week cannot shorten it.
  int get _spanInDays {
    final from = first?.date;
    final to = last?.date;
    if (from == null || to == null) return 0;
    return DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is WeeklyWeightChange &&
      other.weekStart == weekStart &&
      _sameWeighIn(other.first, first) &&
      _sameWeighIn(other.last, last);

  @override
  int get hashCode => Object.hash(
    weekStart,
    first?.date,
    first?.value,
    last?.date,
    last?.value,
  );

  /// `Weight` compares by identity, so weigh-ins are matched on what they say.
  static bool _sameWeighIn(Weight? a, Weight? b) =>
      a?.date == b?.date && a?.value == b?.value && a?.unit == b?.unit;

  /// Whether [entry] falls in the seven days [weekStart] opens.
  static bool _fallsInWeek(Weight entry, DateTime weekStart) {
    final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final weekAfter = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );
    return !day.isBefore(weekStart) && day.isBefore(weekAfter);
  }

  @override
  String toString() =>
      'WeeklyWeightChange(weekStart: $weekStart, delta: $delta, unit: $unit, '
      'first: ${first?.value} on ${first?.date}, '
      'last: ${last?.value} on ${last?.date})';
}

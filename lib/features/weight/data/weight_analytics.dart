import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class WeightAnalytics {
  final WeightRepository _weightRepository;

  WeightAnalytics(this._weightRepository);

  /// Weeks the Home heatmap draws.
  static const int heatmapWeeks = 52;

  /// Days a window's first and last weigh-in must lie apart before it reports
  /// a figure — one rule for both week windows and the 30-day regression.
  static const int minSpanDays = 3;

  /// Days [trendPerWeek] looks back over, the day it is asked about
  /// included.
  static const int trendWindowDays = 30;

  double? get lowestAllTime => lowestEntry?.value;

  /// The most recent weigh-in, or null when the store holds none.
  Weight? get latestEntry {
    final entries = _loggedEntries;
    if (entries.isEmpty) return null;
    return entries.reduce(_newer);
  }

  /// The weigh-in holding [lowestAllTime]; the later one when the low was hit
  /// more than once, so the date reads as the last time it was reached.
  Weight? get lowestEntry {
    final entries = _loggedEntries;
    if (entries.isEmpty) return null;
    return entries.reduce(_lower);
  }

  /// How far the latest weigh-in sits above the all-time low. Never negative —
  /// the low is computed over the same entries, the latest one included.
  double? get changeFromLowest {
    final entries = _loggedEntries;
    if (entries.isEmpty) return null;
    return entries.reduce(_newer).value - entries.reduce(_lower).value;
  }

  /// Weigh-ins on or before today. A weigh-in dated ahead of today is not the
  /// weight anyone is at, so it is left out here as it is from the windows
  /// [weeklyChange], [trendPerWeek], and [weeklyChanges] measure over.
  List<Weight> get _loggedEntries {
    final today = _dayOf(DateTime.now());
    return _weightRepository
        .getAllWeights()
        .where((entry) => !_dayOf(entry.date).isAfter(today))
        .toList(growable: false);
  }

  static Weight _newer(Weight a, Weight b) => b.date.isAfter(a.date) ? b : a;

  static Weight _lower(Weight a, Weight b) {
    if (b.value < a.value) return b;
    if (b.value == a.value && b.date.isAfter(a.date)) return b;
    return a;
  }

  /// The most recent complete week's mean weight minus the week before it,
  /// over the same Sunday-to-Saturday weeks as [weeklyChanges].
  ///
  /// Means rather than endpoints: a sparse day-granular store rarely has a
  /// weigh-in on both ends of a window, and averaging damps day-to-day water
  /// weight. The week holding [asOf] is skipped so a part-week's mean is never
  /// compared against a full one, which leaves the figure up to six days stale.
  ///
  /// Null unless both weeks clear [minSpanDays].
  double? weeklyChange({DateTime? asOf}) {
    final currentWeekStart = _weekStart(asOf ?? DateTime.now());
    final recentStart = _shiftWeeks(currentWeekStart, 1);
    final previousStart = _shiftWeeks(currentWeekStart, 2);

    final recent = <Weight>[];
    final previous = <Weight>[];
    for (final weight in _weightRepository.getWeightsInRange(
      previousStart,
      currentWeekStart,
    )) {
      final start = _weekStart(weight.date);
      (start == recentStart ? recent : previous).add(weight);
    }

    final recentMean = _gatedMean(recent);
    final previousMean = _gatedMean(previous);
    if (recentMean == null || previousMean == null) return null;
    return recentMean - previousMean;
  }

  /// Least-squares slope over the last [trendWindowDays] days of weigh-ins,
  /// expressed as weight per week.
  ///
  /// Regressing value on day number rather than on position in the list, so
  /// gaps in the log stretch the x axis instead of distorting the slope.
  ///
  /// Null unless the window clears [minSpanDays].
  double? trendPerWeek({DateTime? asOf}) {
    final today = _dayOf(asOf ?? DateTime.now());
    final from = DateTime(
      today.year,
      today.month,
      today.day - (trendWindowDays - 1),
    );
    final entries = _weightRepository.getWeightsInRange(
      from,
      DateTime(today.year, today.month, today.day + 1),
    );
    if (!_spansEnough(entries)) return null;

    final days = [
      for (final entry in entries) _daysBetween(from, entry.date).toDouble(),
    ];
    final values = [for (final entry in entries) entry.value];
    final meanDay = days.reduce((a, b) => a + b) / days.length;
    final meanValue = values.reduce((a, b) => a + b) / values.length;

    var covariance = 0.0;
    var variance = 0.0;
    for (var i = 0; i < entries.length; i++) {
      final dayOffset = days[i] - meanDay;
      covariance += dayOffset * (values[i] - meanValue);
      variance += dayOffset * dayOffset;
    }
    if (variance == 0) return null;

    return covariance / variance * 7;
  }

  /// The last [weeks] Sunday-to-Saturday weeks of weight change, oldest first
  /// and ending with the week holding [asOf] — the week still in progress.
  ///
  /// Always [weeks] long: a week the store has too little for is present with
  /// no delta rather than missing, so callers can index it as a fixed grid.
  List<WeeklyWeightChange> weeklyChanges({
    int weeks = heatmapWeeks,
    DateTime? asOf,
  }) {
    assert(weeks > 0);
    final weekStarts = _weekStartsEndingAt(asOf ?? DateTime.now(), weeks);
    final entriesByWeek = <DateTime, List<Weight>>{};

    for (final weight in _weightRepository.getWeightsSince(weekStarts.first)) {
      final start = _weekStart(weight.date);
      // getWeightsSince is unbounded above, so future-dated weigh-ins arrive
      // with no cell to sit in.
      if (start.isAfter(weekStarts.last)) continue;
      entriesByWeek.putIfAbsent(start, () => []).add(weight);
    }

    return [
      for (final start in weekStarts) _change(start, entriesByWeek[start]),
    ];
  }

  static WeeklyWeightChange _change(DateTime weekStart, List<Weight>? entries) {
    if (entries == null || entries.length < WeeklyWeightChange.minEntries) {
      return WeeklyWeightChange(weekStart: weekStart);
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    final first = entries.first;
    final last = entries.last;
    return WeeklyWeightChange(
      weekStart: weekStart,
      delta: last.value - first.value,
      unit: last.unit,
    );
  }

  /// The mean of [entries], or null when they span under [minSpanDays].
  static double? _gatedMean(List<Weight> entries) {
    if (!_spansEnough(entries)) return null;
    return entries.map((e) => e.value).reduce((a, b) => a + b) / entries.length;
  }

  /// Whether [entries]' first and last weigh-in lie at least [minSpanDays]
  /// apart. An empty list, and a lone weigh-in's zero span, never do.
  static bool _spansEnough(List<Weight> entries) {
    if (entries.isEmpty) return false;
    var earliest = entries.first.date;
    var latest = entries.first.date;
    for (final entry in entries) {
      if (entry.date.isBefore(earliest)) earliest = entry.date;
      if (entry.date.isAfter(latest)) latest = entry.date;
    }
    return _daysBetween(earliest, latest) >= minSpanDays;
  }

  /// Calendar days from [from] to [to]. Compared in UTC so a daylight-saving
  /// shift inside the span cannot round a whole day away.
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  static DateTime _dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// [weekStart] moved [weeks] weeks earlier, stepping by calendar components
  /// so the walk stays on Sundays across a daylight-saving shift.
  static DateTime _shiftWeeks(DateTime weekStart, int weeks) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day - 7 * weeks);

  /// The Sunday opening [date]'s week, at local midnight. Dart counts Mon=1…
  /// Sun=7, so `% 7` maps Sunday to a zero offset.
  static DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday % 7));

  /// [weeks] consecutive week starts, oldest first, the last being [asOf]'s.
  static List<DateTime> _weekStartsEndingAt(DateTime asOf, int weeks) {
    final current = _weekStart(asOf);
    return [
      for (var back = weeks - 1; back >= 0; back--) _shiftWeeks(current, back),
    ];
  }
}

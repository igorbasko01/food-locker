import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class WeightAnalytics {
  final WeightRepository _weightRepository;

  WeightAnalytics(this._weightRepository);

  /// Weeks the Home heatmap draws.
  static const int heatmapWeeks = 52;

  double? get lowestAllTime => _weightRepository.getLowestWeight();

  double? get lowestLast30Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 30)),
  );

  double? get lowestLast7Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 7)),
  );

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

  /// The Sunday opening [date]'s week, at local midnight. Dart counts Mon=1…
  /// Sun=7, so `% 7` maps Sunday to a zero offset.
  static DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday % 7));

  /// [weeks] consecutive week starts, oldest first, the last being [asOf]'s.
  ///
  /// Stepping by calendar components rather than `Duration(days: 7)` keeps the
  /// walk on Sundays across a daylight-saving shift.
  static List<DateTime> _weekStartsEndingAt(DateTime asOf, int weeks) {
    final current = _weekStart(asOf);
    return [
      for (var back = weeks - 1; back >= 0; back--)
        DateTime(current.year, current.month, current.day - 7 * back),
    ];
  }
}

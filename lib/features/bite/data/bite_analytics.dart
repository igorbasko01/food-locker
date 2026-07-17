import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';

/// Total bites on a single local calendar day.
///
/// A read-time projection of the append-only bite log: [day] is normalised to
/// local midnight (`DateTime(y, m, d)`), so it doubles as the `[day, day.nextDay)`
/// window's lower bound and compares cleanly against other per-day metrics.
class DailyBiteCount {
  const DailyBiteCount({required this.day, required this.count});

  /// The calendar day, at local midnight.
  final DateTime day;

  /// Bites logged on [day].
  final int count;

  @override
  bool operator ==(Object other) =>
      other is DailyBiteCount && other.day == day && other.count == count;

  @override
  int get hashCode => Object.hash(day, count);

  @override
  String toString() => 'DailyBiteCount(day: $day, count: $count)';
}

/// A single meal: a cluster of bites no more than [BiteAnalytics.mealGapThreshold]
/// apart that reached [BiteAnalytics.minMealBites] bites.
///
/// A read-time projection of the bite log, never persisted. [start] and [end]
/// are the first and last bite's local instants, so a meal list can show when
/// it happened; [count] is the bites it holds.
class Meal {
  const Meal({required this.start, required this.end, required this.count});

  /// The first bite's local instant.
  final DateTime start;

  /// The last bite's local instant.
  final DateTime end;

  /// Bites in the meal (always at least [BiteAnalytics.minMealBites]).
  final int count;

  @override
  bool operator ==(Object other) =>
      other is Meal && other.start == start && other.end == end && other.count == count;

  @override
  int get hashCode => Object.hash(start, end, count);

  @override
  String toString() => 'Meal(start: $start, end: $end, count: $count)';
}

/// A day split into its meals and the bites that fell outside any meal.
///
/// [snackBites] is every bite on [day] not part of a qualifying meal — the
/// bites of sub-[BiteAnalytics.minMealBites] clusters roll into it — so
/// `Σ meals.count + snackBites` is the day's total bite count.
class DayMealBreakdown {
  const DayMealBreakdown({
    required this.day,
    required this.meals,
    required this.snackBites,
  });

  /// The calendar day, at local midnight.
  final DateTime day;

  /// The day's meals, in chronological order.
  final List<Meal> meals;

  /// Bites outside any meal (snacks), including sub-threshold clusters' bites.
  final int snackBites;

  @override
  String toString() =>
      'DayMealBreakdown(day: $day, meals: $meals, snackBites: $snackBites)';
}

/// Read-time analytics over the append-only bite log.
///
/// Mirrors `WeightAnalytics`' shape — a pure projection over the repository,
/// persisting nothing. Every method is a view of the stored `at_ms`
/// timestamps: the class holds no state and can be reconstructed freely.
class BiteAnalytics {
  BiteAnalytics(this._repository);

  final BiteRepository _repository;

  /// Days below this bite count don't count toward [averagePerDay]: a day you
  /// forgot to log — or only logged a few bites on — never dilutes the mean.
  static const int minBitesForAverage = 40;

  /// A gap longer than this between two consecutive bites closes the current
  /// meal cluster and starts a new one. Measured bite-to-bite, not from the
  /// cluster's start, so a long slow meal stays one cluster.
  static const Duration mealGapThreshold = Duration(minutes: 5);

  /// A cluster is only promoted to a meal at this many bites; smaller clusters
  /// are snacking and their bites roll into the day's snack total.
  static const int minMealBites = 10;

  /// Bites per local calendar day in the half-open window `[from, to)`, one
  /// entry per day that has at least one bite, in chronological day order.
  /// Days with no bites are absent, not zero-filled.
  Future<List<DailyBiteCount>> dailyCounts(DateTime from, DateTime to) {
    return _repository.dailyBiteCounts(from, to);
  }

  /// Mean daily bites over `[from, to)`, counting only days with at least
  /// [minBitesForAverage] bites. Zero and lightly-logged days are excluded
  /// from both numerator and denominator, so partial-logging noise never
  /// drags the mean down. Returns 0 when no day qualifies.
  Future<double> averagePerDay(DateTime from, DateTime to) async {
    final counts = await _repository.dailyBiteCounts(from, to);
    final qualifying = counts.where((c) => c.count >= minBitesForAverage);
    if (qualifying.isEmpty) return 0;
    final total = qualifying.fold<int>(0, (sum, c) => sum + c.count);
    return total / qualifying.length;
  }

  /// The single highest-bite day in `[from, to)`, or null when the window holds
  /// no bites. On a tie the earliest day wins.
  Future<DailyBiteCount?> maxDay(DateTime from, DateTime to) async {
    final counts = await _repository.dailyBiteCounts(from, to);
    if (counts.isEmpty) return null;
    var peak = counts.first;
    for (final c in counts.skip(1)) {
      if (c.count > peak.count) peak = c;
    }
    return peak;
  }

  /// The meals on [day]: bite clusters (≤ [mealGapThreshold] between consecutive
  /// bites) that reached [minMealBites], in chronological order. Clustering runs
  /// within the single local day, so a meal straddling midnight is split at the
  /// boundary and each side stands on its own.
  Future<List<Meal>> mealsForDay(DateTime day) async {
    final clusters = await _clustersForDay(day);
    return [
      for (final cluster in clusters)
        if (cluster.length >= minMealBites) _toMeal(cluster),
    ];
  }

  /// [day] split into its meals and the bites that fell outside any meal.
  /// Sub-[minMealBites] clusters are not meals; their bites count as snacks.
  Future<DayMealBreakdown> breakdownForDay(DateTime day) async {
    final clusters = await _clustersForDay(day);
    final meals = <Meal>[];
    var snackBites = 0;
    for (final cluster in clusters) {
      if (cluster.length >= minMealBites) {
        meals.add(_toMeal(cluster));
      } else {
        snackBites += cluster.length;
      }
    }
    return DayMealBreakdown(
      day: DateTime(day.year, day.month, day.day),
      meals: meals,
      snackBites: snackBites,
    );
  }

  /// Mean meals per day over `[from, to)`, averaged across only the days that
  /// have at least one bite — days you never logged don't dilute it. A logged
  /// day with no qualifying meal still counts as a 0-meal day. Returns 0 when
  /// the window holds no bites.
  Future<double> averageMealsPerDay(DateTime from, DateTime to) async {
    final window = await _mealsInWindow(from, to);
    if (window.loggedDays == 0) return 0;
    return window.meals.length / window.loggedDays;
  }

  /// Mean bites per meal over `[from, to)` — total bites in qualifying meal
  /// clusters divided by the number of those clusters. Snacks are excluded.
  /// Returns 0 when the window holds no meal.
  Future<double> averageMealSize(DateTime from, DateTime to) async {
    final window = await _mealsInWindow(from, to);
    if (window.meals.isEmpty) return 0;
    final totalBites = window.meals.fold<int>(0, (sum, m) => sum + m.length);
    return totalBites / window.meals.length;
  }

  /// The qualifying meal clusters across `[from, to)`, and the number of logged
  /// days (days with any bite). Clustering runs within each local day — as in
  /// [mealsForDay] — so a meal straddling midnight splits at the boundary. Both
  /// [averageMealsPerDay] and [averageMealSize] walk the log through here so
  /// their meal definition can't drift apart.
  Future<({List<List<Bite>> meals, int loggedDays})> _mealsInWindow(
    DateTime from,
    DateTime to,
  ) async {
    final bites = await _repository.bitesInRange(from, to);
    final byDay = _groupByLocalDay(bites);
    final meals = <List<Bite>>[];
    for (final dayBites in byDay.values) {
      for (final cluster in _clusterBites(dayBites)) {
        if (cluster.length >= minMealBites) meals.add(cluster);
      }
    }
    return (meals: meals, loggedDays: byDay.length);
  }

  /// The clusters of a single local day, meal-qualifying or not.
  Future<List<List<Bite>>> _clustersForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final startOfNextDay = DateTime(day.year, day.month, day.day + 1);
    final bites = await _repository.bitesInRange(startOfDay, startOfNextDay);
    return _clusterBites(bites);
  }

  /// Splits chronologically-ordered [bites] into clusters, breaking wherever a
  /// gap from the previous bite exceeds [mealGapThreshold].
  List<List<Bite>> _clusterBites(List<Bite> bites) {
    final clusters = <List<Bite>>[];
    for (final bite in bites) {
      final current = clusters.isEmpty ? null : clusters.last;
      if (current != null &&
          bite.atMs - current.last.atMs <= mealGapThreshold.inMilliseconds) {
        current.add(bite);
      } else {
        clusters.add([bite]);
      }
    }
    return clusters;
  }

  /// Groups [bites] by their local calendar day, preserving chronological order
  /// within each day (the input is already ordered).
  Map<DateTime, List<Bite>> _groupByLocalDay(List<Bite> bites) {
    final byDay = <DateTime, List<Bite>>{};
    for (final bite in bites) {
      final at = DateTime.fromMillisecondsSinceEpoch(bite.atMs);
      final day = DateTime(at.year, at.month, at.day);
      byDay.putIfAbsent(day, () => []).add(bite);
    }
    return byDay;
  }

  Meal _toMeal(List<Bite> cluster) => Meal(
    start: DateTime.fromMillisecondsSinceEpoch(cluster.first.atMs),
    end: DateTime.fromMillisecondsSinceEpoch(cluster.last.atMs),
    count: cluster.length,
  );
}

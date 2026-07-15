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

  /// Bites per local calendar day in the half-open window `[from, to)`, one
  /// entry per day that has at least one bite, in chronological day order.
  ///
  /// Days with no bites are absent, not zero-filled — the chart fills the gaps
  /// against its own window.
  Future<List<DailyBiteCount>> dailyCounts(DateTime from, DateTime to) {
    return _repository.dailyBiteCounts(from, to);
  }

  /// Mean daily bites over `[from, to)`, counting only days with at least
  /// [minBitesForAverage] bites (§5.2). Zero and lightly-logged days are
  /// excluded from both numerator and denominator, so partial-logging noise
  /// never drags the mean down. Returns 0 when no day qualifies.
  Future<double> averagePerDay(DateTime from, DateTime to) async {
    final counts = await _repository.dailyBiteCounts(from, to);
    final qualifying = counts.where((c) => c.count >= minBitesForAverage);
    if (qualifying.isEmpty) return 0;
    final total = qualifying.fold<int>(0, (sum, c) => sum + c.count);
    return total / qualifying.length;
  }

  /// The single highest-bite day in `[from, to)`, or null when the window holds
  /// no bites. On a tie the earliest day wins (chronological order, first max
  /// kept).
  Future<DailyBiteCount?> maxDay(DateTime from, DateTime to) async {
    final counts = await _repository.dailyBiteCounts(from, to);
    if (counts.isEmpty) return null;
    var peak = counts.first;
    for (final c in counts.skip(1)) {
      if (c.count > peak.count) peak = c;
    }
    return peak;
  }
}

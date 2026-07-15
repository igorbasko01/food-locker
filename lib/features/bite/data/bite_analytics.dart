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

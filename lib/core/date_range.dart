/// A span of calendar days reaching back from a given day, today included.
///
/// The span is stored as a day count and resolved on read, so a range held
/// across midnight still means the same thing. It has no upper bound: a date
/// past the reference day is covered, so future-dated entries stay visible.
class DateRange {
  const DateRange.lastDays(this.days) : assert(days > 0);

  final int days;

  /// The oldest calendar day in the range as of [asOf] — today's when null.
  DateTime oldestDay({DateTime? asOf}) {
    final on = asOf ?? DateTime.now();
    return DateTime(on.year, on.month, on.day - (days - 1));
  }

  /// Whether [date]'s calendar day falls in the range as of [asOf] — as of now
  /// when [asOf] is null.
  ///
  /// Pass [asOf] when judging a batch of dates, so they are all measured
  /// against one instant.
  bool contains(DateTime date, {DateTime? asOf}) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(oldestDay(asOf: asOf));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DateRange && other.days == days);

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'DateRange.lastDays($days)';
}

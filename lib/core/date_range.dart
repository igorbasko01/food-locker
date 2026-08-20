/// A span of calendar days reaching back from today, today included.
///
/// The span is stored as a day count and resolved on read, so a range held
/// across midnight still means the same thing. It has no upper bound: a future
/// day is inside the range, so future-dated entries stay visible.
class DateRange {
  const DateRange.lastDays(this.days) : assert(days > 0);

  final int days;

  /// The oldest calendar day in the range, counting back from [asOf]'s day —
  /// today's when null. Tests pin [asOf]; the app leaves it to the clock.
  DateTime oldestDay({DateTime? asOf}) {
    final on = asOf ?? DateTime.now();
    return DateTime(on.year, on.month, on.day - (days - 1));
  }

  /// Whether [date]'s calendar day falls in the range right now.
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(oldestDay());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DateRange && other.days == days);

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'DateRange.lastDays($days)';
}

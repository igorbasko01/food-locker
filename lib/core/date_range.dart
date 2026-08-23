/// A span of [days] calendar days ending at [to], or ending today and open
/// above when [to] is null.
class DateRange {
  const DateRange._(this.to, this.days) : assert(days > 0);

  const DateRange.lastDays(int days) : this._(null, days);

  factory DateRange.between(DateTime from, DateTime to) {
    final span = DateTime.utc(to.year, to.month, to.day)
            .difference(DateTime.utc(from.year, from.month, from.day))
            .inDays +
        1;
    return DateRange._(DateTime(to.year, to.month, to.day), span);
  }

  final DateTime? to;
  final int days;

  DateTime get from {
    final end = to ?? DateTime.now();
    return DateTime(end.year, end.month, end.day - (days - 1));
  }

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(from)) return false;
    final end = to;
    return end == null || !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateRange && other.days == days && other.to == to);

  @override
  int get hashCode => Object.hash(to, days);

  @override
  String toString() =>
      to == null ? 'DateRange.lastDays($days)' : 'DateRange($days days to $to)';
}

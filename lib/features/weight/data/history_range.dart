/// How far back the weight history reaches, as offered by the range selector.
///
/// A range is only ever a *start day*: it has no upper bound, so a weigh-in
/// dated in the future stays visible whichever range is picked.
enum HistoryRange {
  week,
  month,
  quarter,
  halfYear,
  year;

  /// The oldest calendar day this range includes, relative to [now].
  ///
  /// Day counts are inclusive of today — [week] starts 6 days back, so the list
  /// spans 7 days. The two long ranges step by calendar month/year rather than
  /// by a fixed day count, so they land on the same day of the month regardless
  /// of month lengths and leap days.
  DateTime startingFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      HistoryRange.week => DateTime(today.year, today.month, today.day - 6),
      HistoryRange.month => DateTime(today.year, today.month, today.day - 29),
      HistoryRange.quarter => DateTime(today.year, today.month, today.day - 89),
      HistoryRange.halfYear => DateTime(today.year, today.month - 6, today.day),
      HistoryRange.year => DateTime(today.year - 1, today.month, today.day),
    };
  }
}

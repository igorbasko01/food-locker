/// How far back the weight history reaches, as offered by the range selector.
///
/// A range is only ever a *start day*: it has no upper bound, so a weigh-in
/// dated in the future stays visible whichever range is picked.
///
/// Both methods take the current time as an argument rather than reading the
/// clock, so a range resolves to the same days under test as it does in the app.
enum HistoryRange {
  week,
  month,
  quarter,
  halfYear,
  year;

  /// The oldest calendar day this range covers, counting back from [asOf]'s day.
  ///
  /// Day counts are inclusive of that day — [week] reaches 6 days back, so it
  /// spans 7 days. The two long ranges step by calendar month/year rather than
  /// by a fixed day count, so they land on the same day of the month regardless
  /// of month lengths and leap days.
  DateTime oldestDay({required DateTime asOf}) {
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    return switch (this) {
      HistoryRange.week => DateTime(today.year, today.month, today.day - 6),
      HistoryRange.month => DateTime(today.year, today.month, today.day - 29),
      HistoryRange.quarter => DateTime(today.year, today.month, today.day - 89),
      HistoryRange.halfYear => DateTime(today.year, today.month - 6, today.day),
      HistoryRange.year => DateTime(today.year - 1, today.month, today.day),
    };
  }

  /// Whether [date]'s calendar day is covered by this range as of [asOf].
  bool covers(DateTime date, {required DateTime asOf}) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(oldestDay(asOf: asOf));
  }
}

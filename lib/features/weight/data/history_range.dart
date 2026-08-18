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

  /// The oldest calendar day this range covers, counting back from [asOf]'s
  /// day — today's when [asOf] is null.
  ///
  /// The count includes that day: [week] reaches 6 days back, spanning 7 days.
  /// The long ranges step by calendar month/year so they land on the same day
  /// of the month whatever the month lengths and leap days.
  DateTime oldestDay({DateTime? asOf}) {
    final on = asOf ?? DateTime.now();
    final today = DateTime(on.year, on.month, on.day);
    return switch (this) {
      HistoryRange.week => DateTime(today.year, today.month, today.day - 6),
      HistoryRange.month => DateTime(today.year, today.month, today.day - 29),
      HistoryRange.quarter => DateTime(today.year, today.month, today.day - 89),
      HistoryRange.halfYear => DateTime(today.year, today.month - 6, today.day),
      HistoryRange.year => DateTime(today.year - 1, today.month, today.day),
    };
  }

  /// Whether [date]'s calendar day is covered as of [asOf] — as of now when
  /// [asOf] is null.
  ///
  /// Pass [asOf] when judging a batch of dates, so they are all measured
  /// against one instant.
  bool covers(DateTime date, {DateTime? asOf}) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(oldestDay(asOf: asOf));
  }
}

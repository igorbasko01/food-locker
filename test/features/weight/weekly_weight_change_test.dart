import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';

void main() {
  // A Saturday: the week it closes opens on Sunday the 9th.
  final asOf = DateTime(2026, 8, 15);

  late InMemoryWeightRepository repository;
  late WeightAnalytics analytics;

  setUp(() {
    repository = InMemoryWeightRepository();
    analytics = WeightAnalytics(repository);
  });

  Future<void> log(DateTime date, double value) => repository.saveWeight(
    Weight(date: date, value: value, unit: WeightUnit.kilograms),
  );

  /// Logs [values] on consecutive days, one per day, beginning at [start].
  Future<void> logRun(DateTime start, List<double> values) async {
    for (var offset = 0; offset < values.length; offset++) {
      await log(
        DateTime(start.year, start.month, start.day + offset),
        values[offset],
      );
    }
  }

  group('week grid', () {
    test('returns 52 weeks, oldest first, ending with the current week', () {
      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks, hasLength(52));
      expect(weeks.last.weekStart, DateTime(2026, 8, 9));
      expect(weeks.first.weekStart, DateTime(2025, 8, 17));

      for (var i = 1; i < weeks.length; i++) {
        expect(weeks[i].weekStart.isAfter(weeks[i - 1].weekStart), isTrue);
      }
    });

    test('every week start is a Sunday', () {
      for (final week in analytics.weeklyChanges(asOf: asOf)) {
        expect(week.weekStart.weekday, DateTime.sunday);
      }
    });

    test('honours a shorter grid', () {
      final weeks = analytics.weeklyChanges(weeks: 4, asOf: asOf);

      expect(weeks, hasLength(4));
      expect(weeks.last.weekStart, DateTime(2026, 8, 9));
      expect(weeks.first.weekStart, DateTime(2026, 7, 19));
    });

    test('rejects a grid with no weeks in it', () {
      expect(
        () => analytics.weeklyChanges(weeks: 0, asOf: asOf),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a store with no weigh-ins yields 52 empty weeks', () {
      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks.every((week) => !week.hasData), isTrue);
      expect(weeks.every((week) => week.delta == null), isTrue);
    });

    test('the oldest cell can report, on the week read in behind it', () async {
      // The week before the grid opens, and the grid's own first week.
      await logRun(DateTime(2025, 8, 10), [80.0, 80.0]);
      await logRun(DateTime(2025, 8, 17), [79.0, 79.0]);

      final oldest = analytics.weeklyChanges(asOf: asOf).first;

      expect(oldest.weekStart, DateTime(2025, 8, 17));
      expect(oldest.delta, closeTo(-1.0, 1e-9));
    });
  });

  group('week delta', () {
    test('is this week\'s mean minus the previous week\'s', () async {
      await logRun(DateTime(2026, 8, 2), [80.0, 81.0, 82.0, 83.0]);
      await logRun(DateTime(2026, 8, 9), [79.0, 80.0, 81.0]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.mean, closeTo(80.0, 1e-9));
      expect(current.count, 3);
      expect(current.previousMean, closeTo(81.5, 1e-9));
      expect(current.previousCount, 4);
      expect(current.delta, closeTo(-1.5, 1e-9));
      expect(current.isGain, isFalse);
    });

    test('one weigh-in a side is enough', () async {
      await log(DateTime(2026, 8, 4), 80.0);
      await log(DateTime(2026, 8, 11), 80.6);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.hasData, isTrue);
      expect(current.delta, closeTo(0.6, 1e-9));
      expect(current.isGain, isTrue);
    });

    test('the week in progress is measured like any other', () async {
      // asOf is the Saturday, so this Sunday is the only day logged so far.
      await logRun(DateTime(2026, 8, 2), [80.0, 80.0]);
      await log(DateTime(2026, 8, 9), 79.5);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.weekStart, DateTime(2026, 8, 9));
      expect(current.count, 1);
      expect(current.delta, closeTo(-0.5, 1e-9));
    });

    test('carries the change across the week boundary', () async {
      // The grid used to read the second week as a gain off 84.3 → 85.0
      // inside it, discarding the 85.7 → 84.3 drop over the boundary.
      await logRun(DateTime(2026, 9, 6), [86.3, 85.7]);
      await logRun(DateTime(2026, 9, 13), [84.3, 85.0]);

      final weeks = analytics.weeklyChanges(asOf: DateTime(2026, 9, 19));
      final second = weeks.last;

      expect(second.weekStart, DateTime(2026, 9, 13));
      expect(second.isGain, isFalse);
      expect(second.delta, closeTo(84.65 - 86.0, 1e-9));
    });

    test('a week with no weigh-ins reports nothing', () async {
      await logRun(DateTime(2026, 8, 2), [80.0, 80.0]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.mean, isNull);
      expect(current.count, 0);
      expect(current.hasData, isFalse);
      expect(current.delta, isNull);
    });

    test('a week whose predecessor is blank reports nothing', () async {
      await logRun(DateTime(2026, 8, 9), [80.0, 79.0, 78.0]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.mean, closeTo(79.0, 1e-9));
      expect(current.previousMean, isNull);
      expect(current.hasData, isFalse);
    });

    test('never chains over a blank week', () async {
      // A fortnight's gap costs two cells rather than folding three weeks of
      // change into one.
      await logRun(DateTime(2026, 8, 2), [80.0, 80.0]);
      await logRun(DateTime(2026, 7, 19), [85.0, 85.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);
      final gap = weeks[weeks.length - 2];

      expect(gap.weekStart, DateTime(2026, 8, 2));
      expect(gap.previousMean, isNull);
      expect(gap.hasData, isFalse);
    });

    test('reads every weigh-in in the week, not just its ends', () async {
      await logRun(DateTime(2026, 8, 2), [80.0, 80.0]);
      await log(DateTime(2026, 8, 14), 76.0);
      await log(DateTime(2026, 8, 9), 84.0);
      await log(DateTime(2026, 8, 11), 80.0);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.mean, closeTo(80.0, 1e-9));
      expect(current.delta, closeTo(0.0, 1e-9));
      expect(current.isGain, isFalse);
    });

    test('ignores weigh-ins dated past the current week', () async {
      await logRun(DateTime(2026, 8, 9), [80.0, 80.0]);
      await logRun(DateTime(2026, 8, 16), [70.0, 71.0, 72.0, 73.0]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.mean, closeTo(80.0, 1e-9));
      expect(current.count, 2);
    });

    test('ignores weigh-ins older than the week behind the grid', () async {
      await logRun(DateTime(2025, 8, 3), [70.0, 71.0, 72.0, 73.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks.every((week) => !week.hasData), isTrue);
      expect(weeks.first.previousMean, isNull);
    });

    test('fills the right cell for an older week', () async {
      await logRun(DateTime(2026, 5, 31), [70.0, 70.0]);
      await logRun(DateTime(2026, 6, 7), [71.5, 71.5]);

      final weeks = analytics.weeklyChanges(asOf: asOf);
      final filled = weeks.where((week) => week.hasData).toList();

      expect(filled, hasLength(1));
      expect(filled.single.weekStart, DateTime(2026, 6, 7));
      expect(filled.single.delta, closeTo(1.5, 1e-9));
    });

    test('a flat week is not a gain', () async {
      await log(DateTime(2026, 8, 4), 80.0);
      await log(DateTime(2026, 8, 11), 80.0);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.hasData, isTrue);
      expect(current.delta, 0.0);
      expect(current.isGain, isFalse);
    });

    test('rejects a weigh-in from outside the week', () {
      expect(
        () => WeeklyWeightChange(
          weekStart: DateTime(2026, 8, 9),
          entries: [Weight(date: DateTime(2026, 8, 16), value: 80.0)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a predecessor weigh-in from outside its week', () {
      expect(
        () => WeeklyWeightChange(
          weekStart: DateTime(2026, 8, 9),
          previousEntries: [Weight(date: DateTime(2026, 7, 29), value: 80.0)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

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

  Future<void> log(DateTime date, double value, {WeightUnit? unit}) =>
      repository.saveWeight(
        Weight(
          date: date,
          value: value,
          unit: unit ?? WeightUnit.kilograms,
        ),
      );

  /// Logs [values] on consecutive days, one per day, beginning at [start].
  Future<void> logRun(DateTime start, List<double> values, {WeightUnit? unit}) async {
    for (var offset = 0; offset < values.length; offset++) {
      await log(
        DateTime(start.year, start.month, start.day + offset),
        values[offset],
        unit: unit,
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
  });

  group('week delta', () {
    test('is the last weigh-in of the week minus its first', () async {
      await logRun(DateTime(2026, 8, 9), [80.0, 79.5, 79.0, 78.4]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.delta, closeTo(-1.6, 1e-9));
      expect(current.isGain, isFalse);
    });

    test('reads chronologically, not in insertion order', () async {
      await log(DateTime(2026, 8, 12), 79.0);
      await log(DateTime(2026, 8, 9), 80.0);
      await log(DateTime(2026, 8, 14), 81.0);
      await log(DateTime(2026, 8, 10), 78.0);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.delta, closeTo(1.0, 1e-9));
      expect(current.isGain, isTrue);
    });

    test('needs the week\'s weigh-ins three days apart', () async {
      // Sunday and Monday: a two-day blip, not a week.
      await logRun(DateTime(2026, 8, 9), [80.0, 79.0]);

      expect(analytics.weeklyChanges(asOf: asOf).last.hasData, isFalse);
    });

    test('a three-day span is enough', () async {
      await log(DateTime(2026, 8, 9), 80.0);
      await log(DateTime(2026, 8, 12), 79.0);

      expect(analytics.weeklyChanges(asOf: asOf).last.hasData, isTrue);
    });

    test('a Sunday and a Saturday alone span the whole week', () async {
      await log(DateTime(2026, 8, 9), 80.0);
      await log(DateTime(2026, 8, 15), 79.0);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.hasData, isTrue);
      expect(current.delta, closeTo(-1.0, 1e-9));
    });

    test('three consecutive days fall short of the span', () async {
      // The store keeps one entry per day, so it takes four consecutive
      // entries to span three days.
      await logRun(DateTime(2026, 8, 10), [80.0, 79.0, 78.0]);

      expect(analytics.weeklyChanges(asOf: asOf).last.hasData, isFalse);
    });

    test('a lone weigh-in reports nothing rather than a flat week', () async {
      await log(DateTime(2026, 8, 12), 80.0);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.hasData, isFalse);
      expect(current.delta, isNull);
      expect(current.level, isNull);
    });

    test('never carries across a week boundary', () async {
      // Saturday closes one week, Sunday opens the next: four each side.
      await logRun(DateTime(2026, 8, 2), [90.0, 89.0, 88.0, 87.0]);
      await logRun(DateTime(2026, 8, 9), [70.0, 71.0, 72.0, 73.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);
      final previous = weeks[weeks.length - 2];
      final current = weeks.last;

      expect(previous.weekStart, DateTime(2026, 8, 2));
      expect(previous.delta, closeTo(-3.0, 1e-9));
      expect(current.weekStart, DateTime(2026, 8, 9));
      expect(current.delta, closeTo(3.0, 1e-9));
    });

    test('splits a Saturday-to-Sunday run at the boundary', () async {
      // Thursday the 6th through Tuesday the 11th splits three days either
      // side of the boundary, so neither week spans three days.
      await logRun(DateTime(2026, 8, 6), [90.0, 89.0, 88.0, 87.0, 86.0, 85.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks[weeks.length - 2].hasData, isFalse);
      expect(weeks.last.hasData, isFalse);
    });

    test('ignores weigh-ins dated past the current week', () async {
      await logRun(DateTime(2026, 8, 16), [70.0, 71.0, 72.0, 73.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks.every((week) => !week.hasData), isTrue);
    });

    test('ignores weigh-ins older than the grid', () async {
      await logRun(DateTime(2025, 8, 10), [70.0, 71.0, 72.0, 73.0]);

      final weeks = analytics.weeklyChanges(asOf: asOf);

      expect(weeks.every((week) => !week.hasData), isTrue);
    });

    test('fills the right cell for an older week', () async {
      await logRun(DateTime(2026, 6, 7), [70.0, 70.5, 71.0, 71.5]);

      final weeks = analytics.weeklyChanges(asOf: asOf);
      final filled = weeks.where((week) => week.hasData).toList();

      expect(filled, hasLength(1));
      expect(filled.single.weekStart, DateTime(2026, 6, 7));
      expect(filled.single.delta, closeTo(1.5, 1e-9));
    });

    test('carries the two weigh-ins it compared', () async {
      await log(DateTime(2026, 8, 9), 80.0);
      await log(DateTime(2026, 8, 11), 79.5);
      await log(DateTime(2026, 8, 14), 78.4);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.firstDate, DateTime(2026, 8, 9));
      expect(current.firstValue, 80.0);
      expect(current.lastDate, DateTime(2026, 8, 14));
      expect(current.lastValue, 78.4);
      expect(
        current.delta,
        closeTo(current.lastValue! - current.firstValue!, 1e-9),
      );
    });

    test('a week under the gate carries no weigh-ins either', () async {
      await logRun(DateTime(2026, 8, 9), [80.0, 79.0]);

      final current = analytics.weeklyChanges(asOf: asOf).last;

      expect(current.firstDate, isNull);
      expect(current.firstValue, isNull);
      expect(current.lastDate, isNull);
      expect(current.lastValue, isNull);
      expect(current.unit, isNull);
    });

    test('takes its unit from the week\'s last weigh-in', () async {
      await logRun(
        DateTime(2026, 8, 9),
        [180.0, 179.0, 178.0, 177.0],
        unit: WeightUnit.pounds,
      );

      expect(analytics.weeklyChanges(asOf: asOf).last.unit, WeightUnit.pounds);
    });
  });

  group('intensity levels', () {
    WeeklyWeightChange change(double? delta, [WeightUnit? unit]) {
      final weekStart = DateTime(2026, 8, 9);
      if (delta == null) return WeeklyWeightChange(weekStart: weekStart);
      return WeeklyWeightChange(
        weekStart: weekStart,
        delta: delta,
        unit: unit ?? WeightUnit.kilograms,
        firstDate: weekStart,
        firstValue: 80.0,
        lastDate: DateTime(2026, 8, 14),
        lastValue: 80.0 + delta,
      );
    }

    test('a week with no delta has no level', () {
      expect(change(null).level, isNull);
      expect(change(null).hasData, isFalse);
    });

    test('kilogram buckets run 0.25 / 0.5 / 1.0', () {
      expect(change(0.24).level, 1);
      expect(change(0.25).level, 2);
      expect(change(0.49).level, 2);
      expect(change(0.5).level, 3);
      expect(change(0.99).level, 3);
      expect(change(1.0).level, 4);
      expect(change(4.2).level, 4);
    });

    test('pound buckets are the kilogram ones doubled', () {
      const lb = WeightUnit.pounds;
      expect(change(0.49, lb).level, 1);
      expect(change(0.5, lb).level, 2);
      expect(change(0.99, lb).level, 2);
      expect(change(1.0, lb).level, 3);
      expect(change(1.99, lb).level, 3);
      expect(change(2.0, lb).level, 4);
    });

    test('a loss buckets on its magnitude, not its sign', () {
      expect(change(-1.2).level, 4);
      expect(change(-0.3).level, 2);
      expect(change(-1.2).isGain, isFalse);
    });

    test('an exact zero is the faintest loss, never a gain', () {
      expect(change(0.0).hasData, isTrue);
      expect(change(0.0).isGain, isFalse);
      expect(change(0.0).level, 1);
    });
  });
}

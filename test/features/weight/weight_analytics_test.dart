import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';

void main() {
  late InMemoryWeightRepository repository;
  late WeightAnalytics analytics;

  setUp(() {
    repository = InMemoryWeightRepository();
    analytics = WeightAnalytics(repository);
  });

  Future<void> log(DateTime date, double value) =>
      repository.saveWeight(Weight(date: date, value: value));

  group('weeklyChange', () {
    // A Wednesday: its week opens Sunday 2024-01-07, so the most recent
    // complete week is 2023-12-31..2024-01-06 and the one before it
    // 2023-12-24..2023-12-30.
    final asOf = DateTime(2024, 1, 10);

    test('has no delta with nothing logged', () {
      expect(analytics.weeklyChange(asOf: asOf).delta, isNull);
    });

    test('names the two weeks it compares', () {
      final week = analytics.weeklyChange(asOf: asOf);

      expect(week.weekStart, DateTime(2023, 12, 31));
      expect(week.previousWeekStart, DateTime(2023, 12, 24));
    });

    test('is the difference of the two weeks\' means', () async {
      await log(DateTime(2023, 12, 24), 80.0);
      await log(DateTime(2023, 12, 27), 80.0);
      await log(DateTime(2023, 12, 30), 80.0);
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 3), 79.0);
      await log(DateTime(2024, 1, 6), 79.0);

      final week = analytics.weeklyChange(asOf: asOf);

      expect(week.delta, closeTo(-1.0, 1e-9));
      expect(week.count, 3);
      expect(week.previousCount, 3);
    });

    test('averages rather than comparing endpoints', () async {
      await log(DateTime(2023, 12, 24), 81.0);
      await log(DateTime(2023, 12, 30), 79.0);
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 2), 78.0);
      await log(DateTime(2024, 1, 6), 77.0);

      // Endpoint-to-endpoint would read 77.0 - 79.0; the means read 78.0 - 80.0.
      expect(analytics.weeklyChange(asOf: asOf).delta, closeTo(-2.0, 1e-9));
    });

    test('reports a week that spans only a day or two', () async {
      await log(DateTime(2023, 12, 24), 80.0);
      await log(DateTime(2023, 12, 30), 80.0);
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 1), 79.0);

      expect(analytics.weeklyChange(asOf: asOf).delta, closeTo(-1.0, 1e-9));
    });

    test('counts the weigh-ins behind a one-a-side figure', () async {
      await log(DateTime(2023, 12, 27), 80.0);
      await log(DateTime(2024, 1, 3), 79.0);

      final week = analytics.weeklyChange(asOf: asOf);

      expect(week.delta, closeTo(-1.0, 1e-9));
      expect(week.count, 1);
      expect(week.previousCount, 1);
    });

    test('has no delta when only one week holds anything', () async {
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 3), 79.0);
      await log(DateTime(2024, 1, 6), 79.0);

      final week = analytics.weeklyChange(asOf: asOf);

      expect(week.delta, isNull);
      expect(week.count, 3);
      expect(week.previousCount, 0);
    });

    test('ignores the week in progress', () async {
      await log(DateTime(2023, 12, 24), 80.0);
      await log(DateTime(2023, 12, 27), 80.0);
      await log(DateTime(2023, 12, 30), 80.0);
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 3), 79.0);
      await log(DateTime(2024, 1, 6), 79.0);
      // Sunday to Wednesday of the current week, far off the trend.
      await log(DateTime(2024, 1, 7), 60.0);
      await log(DateTime(2024, 1, 10), 60.0);

      expect(analytics.weeklyChange(asOf: asOf).delta, closeTo(-1.0, 1e-9));
    });

    test('is the same week the heatmap draws second from the end', () async {
      await log(DateTime(2023, 12, 24), 81.0);
      await log(DateTime(2023, 12, 30), 79.0);
      await log(DateTime(2023, 12, 31), 79.0);
      await log(DateTime(2024, 1, 6), 77.0);
      await log(DateTime(2024, 1, 8), 60.0);

      final grid = analytics.weeklyChanges(asOf: asOf);

      expect(analytics.weeklyChange(asOf: asOf), grid[grid.length - 2]);
    });
  });

  group('trendPerWeek', () {
    // The 30-day window ending here opens on 2024-01-01.
    final asOf = DateTime(2024, 1, 30);

    test('is null with nothing logged', () {
      expect(analytics.trendPerWeek(asOf: asOf), isNull);
    });

    test('is the least-squares slope, per week', () async {
      await log(DateTime(2024, 1, 1), 80.0);
      await log(DateTime(2024, 1, 8), 79.0);
      await log(DateTime(2024, 1, 15), 78.0);
      await log(DateTime(2024, 1, 22), 77.0);

      expect(analytics.trendPerWeek(asOf: asOf), closeTo(-1.0, 1e-9));
    });

    test('is unmoved by irregular spacing on the same line', () async {
      await log(DateTime(2024, 1, 1), 80.0);
      await log(DateTime(2024, 1, 2), 79.0);
      await log(DateTime(2024, 1, 21), 60.0);

      // A kilogram a day, whatever the gaps between weigh-ins.
      expect(analytics.trendPerWeek(asOf: asOf), closeTo(-7.0, 1e-9));
    });

    test('fits a line through two weigh-ins a day apart', () async {
      await log(DateTime(2024, 1, 28), 80.0);
      await log(DateTime(2024, 1, 29), 79.0);

      // A kilogram a day, read off the only two points there are.
      expect(analytics.trendPerWeek(asOf: asOf), closeTo(-7.0, 1e-9));
    });

    test('is null for a lone weigh-in, which has no slope to fit', () async {
      await log(DateTime(2024, 1, 15), 80.0);

      expect(analytics.trendPerWeek(asOf: asOf), isNull);
    });

    test('ignores weigh-ins outside the 30-day window', () async {
      await log(DateTime(2024, 1, 1), 80.0);
      await log(DateTime(2024, 1, 8), 79.0);
      await log(DateTime(2024, 1, 15), 78.0);
      // The day before the window opens, and a future-dated entry.
      await log(DateTime(2023, 12, 31), 20.0);
      await log(DateTime(2024, 2, 5), 200.0);

      expect(analytics.trendPerWeek(asOf: asOf), closeTo(-1.0, 1e-9));
    });
  });

  group('latest and lowest', () {
    test('are null with nothing logged', () {
      expect(analytics.latestEntry, isNull);
      expect(analytics.lowestEntry, isNull);
      expect(analytics.changeFromLowest, isNull);
    });

    test('report the newest weigh-in and the all-time low', () async {
      await log(DateTime(2024, 1, 1), 80.0);
      await log(DateTime(2024, 1, 8), 72.5);
      await log(DateTime(2024, 1, 15), 74.0);

      expect(analytics.latestEntry?.date, DateTime(2024, 1, 15));
      expect(analytics.lowestEntry?.value, 72.5);
      expect(analytics.changeFromLowest, closeTo(1.5, 1e-9));
    });

    test('date the low at the last time it was reached', () async {
      await log(DateTime(2024, 1, 1), 72.5);
      await log(DateTime(2024, 1, 8), 75.0);
      await log(DateTime(2024, 1, 15), 72.5);

      expect(analytics.lowestEntry?.date, DateTime(2024, 1, 15));
      expect(analytics.changeFromLowest, 0.0);
    });

    test('read zero when the latest weigh-in is the low', () async {
      await log(DateTime(2024, 1, 1), 80.0);
      await log(DateTime(2024, 1, 15), 72.0);

      expect(analytics.changeFromLowest, 0.0);
    });

    test('carry a single weigh-in on their own', () async {
      await log(DateTime(2024, 1, 15), 72.0);

      expect(analytics.latestEntry?.value, 72.0);
      expect(analytics.lowestEntry?.value, 72.0);
      expect(analytics.changeFromLowest, 0.0);
    });

    test('leave out a weigh-in dated ahead of today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await log(today, 74.0);
      await log(DateTime(today.year, today.month, today.day + 3), 60.0);

      expect(analytics.latestEntry?.value, 74.0);
      expect(analytics.lowestEntry?.value, 74.0);
      expect(analytics.lowestAllTime, 74.0);
      expect(analytics.changeFromLowest, 0.0);
    });

    test('take a weigh-in dated today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await log(DateTime(today.year, today.month, today.day - 3), 80.0);
      await log(today, 74.0);

      expect(analytics.latestEntry?.value, 74.0);
    });
  });
}

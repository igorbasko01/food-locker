import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';

/// [BiteAnalytics] over an in-memory Drift store, so the real day-grouping
/// query backs the pure computation rather than a hand-rolled fake.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;
  late BiteAnalytics analytics;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
    analytics = BiteAnalytics(repo);
  });

  tearDown(() async {
    await db.close();
  });

  /// Logs [count] bites spread through [day], one per minute from 08:00.
  Future<void> logBites(DateTime day, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.logBite(DateTime(day.year, day.month, day.day, 8, i));
    }
  }

  /// Logs [count] bites starting at [start], each [gap] after the previous.
  Future<void> logEvery(DateTime start, int count, Duration gap) async {
    var at = start;
    for (var i = 0; i < count; i++) {
      await repo.logBite(at);
      at = at.add(gap);
    }
  }

  group('dailyCounts', () {
    test('surfaces one entry per day with bites, in day order', () async {
      await logBites(DateTime(2026, 7, 13), 3);
      await logBites(DateTime(2026, 7, 15), 1); // 14th has none

      final counts = await analytics.dailyCounts(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      expect(counts, [
        DailyBiteCount(day: DateTime(2026, 7, 13), count: 3),
        DailyBiteCount(day: DateTime(2026, 7, 15), count: 1),
      ]);
    });
  });

  group('averagePerDay', () {
    test('averages only days at or above the 40-bite threshold', () async {
      await logBites(DateTime(2026, 7, 13), 40); // qualifies (== threshold)
      await logBites(DateTime(2026, 7, 14), 60); // qualifies
      await logBites(DateTime(2026, 7, 15), 39); // below — excluded

      final avg = await analytics.averagePerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      // (40 + 60) / 2 — the 39-bite day is out of both sum and count.
      expect(avg, 50);
    });

    test('excludes zero days by construction (they carry no entry)', () async {
      await logBites(DateTime(2026, 7, 13), 40);
      // 14th and 15th logged nothing at all.

      final avg = await analytics.averagePerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      expect(avg, 40);
    });

    test('is 0 when no day reaches the threshold', () async {
      await logBites(DateTime(2026, 7, 13), 39);
      await logBites(DateTime(2026, 7, 14), 10);

      final avg = await analytics.averagePerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 15),
      );

      expect(avg, 0);
    });

    test('is 0 for an empty window', () async {
      final avg = await analytics.averagePerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 14),
      );

      expect(avg, 0);
    });
  });

  group('maxDay', () {
    test('returns the single highest-bite day', () async {
      await logBites(DateTime(2026, 7, 13), 20);
      await logBites(DateTime(2026, 7, 14), 55);
      await logBites(DateTime(2026, 7, 15), 30);

      final max = await analytics.maxDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      expect(max, DailyBiteCount(day: DateTime(2026, 7, 14), count: 55));
    });

    test('breaks ties toward the earliest day', () async {
      await logBites(DateTime(2026, 7, 13), 42);
      await logBites(DateTime(2026, 7, 14), 42);

      final max = await analytics.maxDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 15),
      );

      expect(max, DailyBiteCount(day: DateTime(2026, 7, 13), count: 42));
    });

    test('is null when the window holds no bites', () async {
      final max = await analytics.maxDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 14),
      );

      expect(max, isNull);
    });
  });

  group('mealsForDay', () {
    test('is empty for a day with no bites', () async {
      final meals = await analytics.mealsForDay(DateTime(2026, 7, 15));
      expect(meals, isEmpty);
    });

    test('a single bite is not a meal', () async {
      await repo.logBite(DateTime(2026, 7, 15, 8));
      final meals = await analytics.mealsForDay(DateTime(2026, 7, 15));
      expect(meals, isEmpty);
    });

    test('a 5-min gap keeps bites in one meal (threshold is inclusive)', () async {
      // 10 bites, each exactly 5 min apart: 08:00 through 08:45.
      await logEvery(DateTime(2026, 7, 15, 8), 10, const Duration(minutes: 5));

      final meals = await analytics.mealsForDay(DateTime(2026, 7, 15));

      expect(meals, [
        Meal(
          start: DateTime(2026, 7, 15, 8),
          end: DateTime(2026, 7, 15, 8, 45),
          count: 10,
        ),
      ]);
    });

    test('a gap over 5 min splits into back-to-back meals', () async {
      await logEvery(DateTime(2026, 7, 15, 8), 10, const Duration(minutes: 1));
      // 6-min gap after 08:09 opens a new cluster at 08:15.
      await logEvery(DateTime(2026, 7, 15, 8, 15), 10, const Duration(minutes: 1));

      final meals = await analytics.mealsForDay(DateTime(2026, 7, 15));

      expect(meals.map((m) => m.count), [10, 10]);
    });

    test('a cluster under 10 bites is not a meal', () async {
      await logEvery(DateTime(2026, 7, 15, 8), 9, const Duration(minutes: 1));
      final meals = await analytics.mealsForDay(DateTime(2026, 7, 15));
      expect(meals, isEmpty);
    });

    test('a meal straddling midnight splits into two days', () async {
      // 20 bites, one per minute from 23:50: ten before midnight, ten after.
      await logEvery(
        DateTime(2026, 7, 15, 23, 50),
        20,
        const Duration(minutes: 1),
      );

      final day15 = await analytics.mealsForDay(DateTime(2026, 7, 15));
      final day16 = await analytics.mealsForDay(DateTime(2026, 7, 16));

      expect(day15.map((m) => m.count), [10]);
      expect(day16.map((m) => m.count), [10]);
    });
  });

  group('breakdownForDay', () {
    test('empty day has no meals and no snacks', () async {
      final breakdown = await analytics.breakdownForDay(DateTime(2026, 7, 15));
      expect(breakdown.day, DateTime(2026, 7, 15));
      expect(breakdown.meals, isEmpty);
      expect(breakdown.snackBites, 0);
    });

    test('sub-10 clusters roll into the snack total', () async {
      await logEvery(DateTime(2026, 7, 15, 8), 5, const Duration(minutes: 1));
      // 6-min gap opens a second 5-bite cluster — both stay snacks.
      await logEvery(DateTime(2026, 7, 15, 8, 11), 5, const Duration(minutes: 1));

      final breakdown = await analytics.breakdownForDay(DateTime(2026, 7, 15));

      expect(breakdown.meals, isEmpty);
      expect(breakdown.snackBites, 10);
    });

    test('separates a meal from surrounding snacks', () async {
      await logEvery(DateTime(2026, 7, 15, 8), 12, const Duration(minutes: 1));
      // 6-min gap, then a 3-bite snack cluster.
      await logEvery(DateTime(2026, 7, 15, 8, 17), 3, const Duration(minutes: 1));

      final breakdown = await analytics.breakdownForDay(DateTime(2026, 7, 15));

      expect(breakdown.meals.map((m) => m.count), [12]);
      expect(breakdown.snackBites, 3);
    });
  });

  group('averageMealsPerDay', () {
    test('averages meals over only the days that have bites', () async {
      // 7/13: two meals.
      await logEvery(DateTime(2026, 7, 13, 8), 10, const Duration(minutes: 1));
      await logEvery(DateTime(2026, 7, 13, 8, 20), 10, const Duration(minutes: 1));
      // 7/14: one meal.
      await logEvery(DateTime(2026, 7, 14, 8), 10, const Duration(minutes: 1));
      // 7/15: bites but all snacks — a logged 0-meal day.
      await logEvery(DateTime(2026, 7, 15, 8), 5, const Duration(minutes: 1));

      final avg = await analytics.averageMealsPerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      // (2 + 1 + 0) meals over 3 logged days.
      expect(avg, closeTo(1, 1e-9));
    });

    test('is 0 for a window with no bites', () async {
      final avg = await analytics.averageMealsPerDay(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );
      expect(avg, 0);
    });
  });

  group('averageMealSize', () {
    test('averages a single meal to its own size', () async {
      await logEvery(DateTime(2026, 7, 15, 8), 12, const Duration(minutes: 1));

      final avg = await analytics.averageMealSize(
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 16),
      );

      expect(avg, 12);
    });

    test('excludes snack clusters from the mean', () async {
      // A 12-bite meal, then a 6-min gap and a 4-bite snack that must not
      // drag the average down (it would be (12 + 4) / 2 = 8 if counted).
      await logEvery(DateTime(2026, 7, 15, 8), 12, const Duration(minutes: 1));
      await logEvery(DateTime(2026, 7, 15, 8, 17), 4, const Duration(minutes: 1));

      final avg = await analytics.averageMealSize(
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 16),
      );

      expect(avg, 12);
    });

    test('averages meal bites over the meal count across several days', () async {
      // 7/13: two meals, 10 and 20 bites.
      await logEvery(DateTime(2026, 7, 13, 8), 10, const Duration(minutes: 1));
      await logEvery(DateTime(2026, 7, 13, 8, 20), 20, const Duration(minutes: 1));
      // 7/14: one meal, 15 bites, plus a 3-bite snack that is excluded.
      await logEvery(DateTime(2026, 7, 14, 8), 15, const Duration(minutes: 1));
      await logEvery(DateTime(2026, 7, 14, 8, 20), 3, const Duration(minutes: 1));

      final avg = await analytics.averageMealSize(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      // (10 + 20 + 15) bites over 3 meals.
      expect(avg, 15);
    });

    test('is 0 for a window with no meal', () async {
      // Bites logged, but every cluster is a sub-threshold snack.
      await logEvery(DateTime(2026, 7, 15, 8), 5, const Duration(minutes: 1));

      final avg = await analytics.averageMealSize(
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 16),
      );

      expect(avg, 0);
    });

    test('is 0 for an empty window', () async {
      final avg = await analytics.averageMealSize(
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
      );

      expect(avg, 0);
    });
  });
}

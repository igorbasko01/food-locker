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
}

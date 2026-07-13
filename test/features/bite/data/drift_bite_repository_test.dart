import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';

/// Phase 3 verification: the [BiteRepository] seam over Drift. An in-memory
/// drift database stands in for the on-disk store, so the seam is exercised
/// without touching the filesystem.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('logBite', () {
    test('records the bite at millisecond precision', () async {
      final at = DateTime(2026, 7, 13, 12, 30, 45, 789);

      await repo.logBite(at);

      final rows = await db.select(db.bites).get();
      expect(rows, hasLength(1));
      expect(rows.single.atMs, at.millisecondsSinceEpoch);
      expect(rows.single.atMs % 1000, 789);
    });

    test('appends — each tap is its own row', () async {
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 0));
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 30));

      final rows = await db.select(db.bites).get();
      expect(rows, hasLength(2));
    });
  });

  group('lastBite', () {
    test('is null when nothing has been logged', () async {
      expect(await repo.lastBite(), isNull);
    });

    test('returns the most recently logged bite', () async {
      final earlier = DateTime(2026, 7, 13, 12, 0, 0);
      final later = DateTime(2026, 7, 13, 12, 0, 30);

      await repo.logBite(earlier);
      await repo.logBite(later);

      final last = await repo.lastBite();
      expect(last, isNotNull);
      expect(last!.atMs, later.millisecondsSinceEpoch);
    });

    test('tracks insertion order even when a later tap has an earlier '
        'timestamp', () async {
      // Insertion order — not at_ms — defines "last": a bite logged now is the
      // reference point even if its clock reading trails a prior one.
      final wallClock = DateTime(2026, 7, 13, 12, 0, 30);
      final rewound = DateTime(2026, 7, 13, 12, 0, 0);

      await repo.logBite(wallClock);
      await repo.logBite(rewound);

      final last = await repo.lastBite();
      expect(last!.atMs, rewound.millisecondsSinceEpoch);
    });
  });

  group('bitesInRange', () {
    test('includes from, excludes to (half-open window)', () async {
      final from = DateTime(2026, 7, 13, 12, 0, 0);
      final to = DateTime(2026, 7, 13, 13, 0, 0);

      await repo.logBite(from); // on the lower bound — included
      await repo.logBite(DateTime(2026, 7, 13, 12, 30, 0)); // inside
      await repo.logBite(to); // on the upper bound — excluded
      await repo.logBite(DateTime(2026, 7, 13, 11, 59, 59)); // before

      final inRange = await repo.bitesInRange(from, to);

      expect(inRange, hasLength(2));
      expect(
        inRange.map((b) => b.atMs),
        [from.millisecondsSinceEpoch, DateTime(2026, 7, 13, 12, 30, 0).millisecondsSinceEpoch],
      );
    });

    test('returns bites in chronological order', () async {
      final from = DateTime(2026, 7, 13, 0, 0, 0);
      final to = DateTime(2026, 7, 14, 0, 0, 0);

      // Logged out of order; the query orders by at_ms.
      await repo.logBite(DateTime(2026, 7, 13, 15, 0, 0));
      await repo.logBite(DateTime(2026, 7, 13, 9, 0, 0));
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 0));

      final inRange = await repo.bitesInRange(from, to);

      expect(inRange.map((b) => b.atMs), [
        DateTime(2026, 7, 13, 9, 0, 0).millisecondsSinceEpoch,
        DateTime(2026, 7, 13, 12, 0, 0).millisecondsSinceEpoch,
        DateTime(2026, 7, 13, 15, 0, 0).millisecondsSinceEpoch,
      ]);
    });

    test('is empty when no bite falls in the window', () async {
      await repo.logBite(DateTime(2026, 7, 13, 8, 0, 0));

      final inRange = await repo.bitesInRange(
        DateTime(2026, 7, 14, 0, 0, 0),
        DateTime(2026, 7, 15, 0, 0, 0),
      );

      expect(inRange, isEmpty);
    });
  });

  group('biteCount', () {
    test('counts only bites in the half-open window', () async {
      final dayStart = DateTime(2026, 7, 13);
      final nextDayStart = DateTime(2026, 7, 14);

      await repo.logBite(dayStart); // lower bound — counted
      await repo.logBite(DateTime(2026, 7, 13, 20, 0, 0)); // counted
      await repo.logBite(nextDayStart); // upper bound — not counted
      await repo.logBite(DateTime(2026, 7, 12, 23, 59, 59)); // day before

      expect(await repo.biteCount(dayStart, nextDayStart), 2);
    });

    test('is zero for an empty window', () async {
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 0));

      expect(
        await repo.biteCount(
          DateTime(2026, 7, 14),
          DateTime(2026, 7, 15),
        ),
        0,
      );
    });
  });

  group('pacing config', () {
    test('pacingConfigAt resolves the seeded default', () async {
      final cfg = await repo.pacingConfigAt(DateTime(2026, 7, 13));

      expect(cfg, isNotNull);
      expect(cfg!.b1S, 15);
      expect(cfg.b2S, 30);
    });

    test('setPacingConfig appends a new version without regrading the '
        'past', () async {
      final retuneAt = DateTime(2026, 7, 1);
      await repo.setPacingConfig(
        PacingConfig(
          // id is assigned by the store; the value here is ignored on insert.
          id: 0,
          effectiveMs: retuneAt.millisecondsSinceEpoch,
          b1S: 10,
          b2S: 20,
        ),
      );

      // Before the retune: still the epoch-anchored default.
      final before = await repo.pacingConfigAt(DateTime(2026, 6, 30));
      expect(before!.b1S, 15);
      expect(before.b2S, 30);

      // At and after: the appended version.
      final after = await repo.pacingConfigAt(retuneAt);
      expect(after!.b1S, 10);
      expect(after.b2S, 20);

      // The default row is preserved, not overwritten.
      final all = await db.select(db.pacingConfigs).get();
      expect(all, hasLength(2));
    });
  });

  group('clearBites', () {
    test('removes every logged bite', () async {
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 0));
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 30));

      await repo.clearBites();

      expect(await db.select(db.bites).get(), isEmpty);
      expect(await repo.lastBite(), isNull);
    });

    test('leaves the pacing-config history intact', () async {
      await repo.logBite(DateTime(2026, 7, 13, 12, 0, 0));

      await repo.clearBites();

      // The seeded default must survive a bite wipe — it is not part of the
      // CSV backup and is a separate slowly-changing dimension.
      final cfg = await repo.pacingConfigAt(DateTime(2026, 7, 13));
      expect(cfg, isNotNull);
      expect(cfg!.b1S, 15);
      expect(cfg.b2S, 30);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';

/// Phase 1 verification: the Drift database opens and a bite row round-trips.
/// Phase 2 verification: `pacing_config` seeds a default and resolves by instant.
void main() {
  late BiteDatabase db;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('a bite row round-trips through the database', () async {
    final atMs = DateTime(2026, 7, 13, 12, 30, 45, 123).millisecondsSinceEpoch;

    final id = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: atMs));

    final rows = await db.select(db.bites).get();

    expect(rows, hasLength(1));
    expect(rows.single.id, id);
    expect(rows.single.atMs, atMs);
  });

  test('at_ms preserves millisecond precision', () async {
    // The whole point of storing epoch millis as a plain integer: no silent
    // truncation to whole seconds.
    final atMs = DateTime(2026, 7, 13, 0, 0, 0, 789).millisecondsSinceEpoch;
    expect(atMs % 1000, 789);

    await db.into(db.bites).insert(BitesCompanion.insert(atMs: atMs));

    final stored = await db.select(db.bites).getSingle();
    expect(stored.atMs, atMs);
    expect(stored.atMs % 1000, 789);
  });

  test('ids autoincrement in chronological (insertion) order', () async {
    final first = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: 1000));
    final second = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: 2000));

    expect(second, greaterThan(first));
  });

  group('pacing_config', () {
    test('a default row is seeded on first run (b1 = 15, b2 = 30)', () async {
      final configs = await db.select(db.pacingConfigs).get();

      expect(configs, hasLength(1));
      expect(configs.single.b1S, 15);
      expect(configs.single.b2S, 30);
      // Effective from the epoch so every bite resolves to it.
      expect(configs.single.effectiveMs, 0);
    });

    test('seeding is idempotent — no duplicate default rows', () async {
      // The database is already open (seeded) from setUp; touching it again
      // must not append a second default.
      await db.select(db.pacingConfigs).get();
      final configs = await db.select(db.pacingConfigs).get();

      expect(configs, hasLength(1));
    });

    test('pacingConfigAt returns the default for any real instant', () async {
      final cfg = await db.pacingConfigAt(DateTime(2026, 7, 13));

      expect(cfg, isNotNull);
      expect(cfg!.b1S, 15);
      expect(cfg.b2S, 30);
    });

    test('pacingConfigAt returns the newest version at or before the '
        'instant', () async {
      // A retune that takes effect mid-2026.
      final retuneMs = DateTime(2026, 7, 1).millisecondsSinceEpoch;
      await db
          .into(db.pacingConfigs)
          .insert(
            PacingConfigsCompanion.insert(
              effectiveMs: retuneMs,
              b1S: 10,
              b2S: 20,
            ),
          );

      // Just before the retune: still the default (effective from the epoch).
      final before = await db.pacingConfigAt(DateTime(2026, 6, 30));
      expect(before!.b1S, 15);
      expect(before.b2S, 30);

      // Exactly at the retune instant and after: the new version.
      final atRetune = await db.pacingConfigAt(DateTime(2026, 7, 1));
      expect(atRetune!.b1S, 10);
      expect(atRetune.b2S, 20);

      final after = await db.pacingConfigAt(DateTime(2026, 8, 1));
      expect(after!.b1S, 10);
      expect(after.b2S, 20);
    });

    test('pacingConfigAt returns null before the earliest config', () async {
      // Nothing is effective before the epoch-anchored default.
      final beforeEpoch = await db.pacingConfigAt(
        DateTime.fromMillisecondsSinceEpoch(-1),
      );

      expect(beforeEpoch, isNull);
    });
  });
}

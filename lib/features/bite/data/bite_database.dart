import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'bite_database.g.dart';

/// Append-only stream of bite timestamps — the atomic fact the pacing feature
/// is built on. Only the raw millisecond timestamp is stored; counts, deltas,
/// and pacing zones are all derived at read time, so keeping the raw log keeps
/// future options open with zero data loss.
@DataClassName('Bite')
@TableIndex(name: 'idx_bites_at_ms', columns: {#atMs})
class Bites extends Table {
  /// Insertion order is chronological (append-only), so the autoincrement id
  /// doubles as a stable chronological key.
  IntColumn get id => integer().autoIncrement()();

  /// Epoch milliseconds (a UTC instant), millisecond precision.
  ///
  /// Deliberately a plain [integer], not drift's `dateTime()`: the default
  /// datetime mode stores unix *seconds* and would silently truncate the
  /// millisecond precision the inter-bite deltas depend on. Integer epoch
  /// millis keep deltas an exact subtraction and stay DST-safe (monotonic
  /// across midnight and clock changes).
  IntColumn get atMs => integer().named('at_ms')();
}

/// Versioned pacing thresholds — a slowly-changing dimension.
///
/// A bite's pacing zone depends on the thresholds in effect *when it
/// happened*, so retuning the thresholds later appends a new version rather
/// than mutating an existing one. Every historical bite stays gradable against
/// the version effective at its timestamp, so longitudinal comparisons don't
/// get silently contaminated by a later retune.
///
/// Three fixed zones means exactly two boundaries, so two columns suffice and
/// no separate boundaries table is needed.
@DataClassName('PacingConfig')
class PacingConfigs extends Table {
  /// The SQL table is `pacing_config`; the drift accessor stays `pacingConfigs`
  /// (derived from the Dart class name).
  @override
  String get tableName => 'pacing_config';

  IntColumn get id => integer().autoIncrement()();

  /// Epoch millis (a UTC instant): the moment this config version took effect.
  IntColumn get effectiveMs => integer().named('effective_ms')();

  /// End of the "too soon" zone, in seconds. `[0, b1)` is too soon.
  IntColumn get b1S => integer().named('b1_s')();

  /// Start of the "in the clear" zone, in seconds — the point at which biting
  /// is recommended and the haptic fires. `[b1, b2)` is "ok — hold on",
  /// `[b2, ∞)` is "in the clear". Derived boundary, stored so past bites stay
  /// reconstructable.
  IntColumn get b2S => integer().named('b2_s')();
}

@DriftDatabase(tables: [Bites, PacingConfigs])
class BiteDatabase extends _$BiteDatabase {
  /// Production constructor: opens the on-disk `bites` database.
  BiteDatabase() : super(driftDatabase(name: 'bites'));

  /// Test constructor: injects a custom (e.g. in-memory) executor so the
  /// schema can be exercised without touching the device filesystem.
  BiteDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 shipped with only `bites`; v2 adds `pacing_config`.
      if (from < 2) {
        await m.createTable(pacingConfigs);
      }
    },
    beforeOpen: (details) async {
      await _seedDefaultPacingConfig();
    },
  );

  /// The pacing config in effect at [instant]: the newest version whose
  /// effective instant is at or before it.
  ///
  /// Returns null only when no config exists at all — which the default seed
  /// prevents in practice, since it is effective from the epoch onward.
  Future<PacingConfig?> pacingConfigAt(DateTime instant) {
    final atMs = instant.millisecondsSinceEpoch;
    return (select(pacingConfigs)
          ..where((c) => c.effectiveMs.isSmallerOrEqualValue(atMs))
          ..orderBy([(c) => OrderingTerm.desc(c.effectiveMs)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Seeds [defaultPacingConfig] on first run. Idempotent: a no-op once any
  /// config row exists, so it never clobbers a user's retuned thresholds.
  Future<void> _seedDefaultPacingConfig() async {
    final existing = await (select(
      pacingConfigs,
    )..limit(1)).getSingleOrNull();
    if (existing != null) return;
    await into(pacingConfigs).insert(
      PacingConfigsCompanion.insert(
        effectiveMs: defaultPacingConfig.effectiveMs,
        b1S: defaultPacingConfig.b1S,
        b2S: defaultPacingConfig.b2S,
      ),
    );
  }
}

/// The v1 starting thresholds: seeded on first run, and written back whenever
/// the config history is cleared outright.
///
/// Effective from the epoch so that every bite — past or present — resolves to
/// it. The `id` is store-assigned on insert, so the 0 here is a placeholder.
const PacingConfig defaultPacingConfig =
    PacingConfig(id: 0, effectiveMs: 0, b1S: 15, b2S: 30);

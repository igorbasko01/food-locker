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

@DriftDatabase(tables: [Bites])
class BiteDatabase extends _$BiteDatabase {
  /// Production constructor: opens the on-disk `bites` database.
  BiteDatabase() : super(driftDatabase(name: 'bites'));

  /// Test constructor: injects a custom (e.g. in-memory) executor so the
  /// schema can be exercised without touching the device filesystem.
  BiteDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

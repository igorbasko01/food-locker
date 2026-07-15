import 'package:drift/drift.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';

/// Drift/SQLite-backed [BiteRepository].
///
/// Every range in this store is a half-open `[from, to)` window over `at_ms`
/// (epoch millis), which is what the day-granular counts expect: a local day is
/// `[startOfDay, startOfNextDay)`, so consecutive days never double-count the
/// boundary instant.
class DriftBiteRepository implements BiteRepository {
  DriftBiteRepository(this._db);

  final BiteDatabase _db;

  @override
  Future<void> logBite(DateTime at) async {
    await _db
        .into(_db.bites)
        .insert(BitesCompanion.insert(atMs: at.millisecondsSinceEpoch));
  }

  @override
  Future<Bite?> lastBite() {
    // Insertion order is chronological (append-only), so the largest id is the
    // most recent bite — no need to sort on at_ms.
    return (_db.select(_db.bites)
          ..orderBy([(b) => OrderingTerm.desc(b.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    return (_db.select(_db.bites)
          ..where(
            (b) =>
                b.atMs.isBiggerOrEqualValue(fromMs) &
                b.atMs.isSmallerThanValue(toMs),
          )
          ..orderBy([(b) => OrderingTerm.asc(b.atMs)]))
        .get();
  }

  @override
  Future<int> biteCount(DateTime from, DateTime to) async {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    final count = _db.bites.id.count();
    final query = _db.selectOnly(_db.bites)
      ..addColumns([count])
      ..where(
        _db.bites.atMs.isBiggerOrEqualValue(fromMs) &
            _db.bites.atMs.isSmallerThanValue(toMs),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(
    DateTime from,
    DateTime to,
  ) async {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    // 'localtime' resolves each row's day in the device zone, so the grouping
    // stays DST-safe (a day is its own calendar day, never fixed 24h math).
    final dayExpr = CustomExpression<String>(
      "date(at_ms / 1000, 'unixepoch', 'localtime')",
    );
    final count = _db.bites.id.count();
    final query = _db.selectOnly(_db.bites)
      ..addColumns([dayExpr, count])
      ..where(
        _db.bites.atMs.isBiggerOrEqualValue(fromMs) &
            _db.bites.atMs.isSmallerThanValue(toMs),
      )
      ..groupBy([dayExpr])
      ..orderBy([OrderingTerm.asc(dayExpr)]);
    final rows = await query.get();
    return rows.map((row) {
      // date() yields 'YYYY-MM-DD'; parsing it back builds local midnight, the
      // same normalisation every other per-day metric uses as its lower bound.
      final parts = row.read(dayExpr)!.split('-');
      final day = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DailyBiteCount(day: day, count: row.read(count) ?? 0);
    }).toList();
  }

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async {
    await _db
        .into(_db.pacingConfigs)
        .insert(
          PacingConfigsCompanion.insert(
            effectiveMs: cfg.effectiveMs,
            b1S: cfg.b1S,
            b2S: cfg.b2S,
          ),
        );
  }

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) {
    return _db.pacingConfigAt(instant);
  }

  @override
  Future<List<PacingConfig>> allPacingConfigs() {
    return (_db.select(_db.pacingConfigs)
          ..orderBy([(c) => OrderingTerm.asc(c.effectiveMs)]))
        .get();
  }

  @override
  Future<void> clearBites() async {
    await _db.delete(_db.bites).go();
  }

  @override
  Future<void> clearPacingConfigs() async {
    await _db.delete(_db.pacingConfigs).go();
  }
}

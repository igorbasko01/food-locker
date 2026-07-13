import 'package:food_locker/features/bite/data/bite_database.dart';

/// The seam in front of the bite dataset (§1b of the pacing plan).
///
/// The rest of the app depends on this interface, never on the engine backing
/// it — today Drift/SQLite, but that choice stays an implementation detail. It
/// is the single place the two-store tax (§1c) gets coordinated, and it keeps
/// the bite store independently testable.
///
/// The [Bite] and [PacingConfig] data classes it trades in are plain,
/// engine-agnostic value types (drift's generated data classes for this
/// greenfield feature carry no query machinery), so exposing them here doesn't
/// leak the engine.
abstract interface class BiteRepository {
  /// Records a single bite at [at]. One tap = one bite; never blocked
  /// (§3a) — the timestamp is persisted immediately.
  Future<void> logBite(DateTime at);

  /// The most recent bite, or null if none has been logged.
  ///
  /// The reference point for the pacing ticker: the live view seeds itself from
  /// this once per session and derives every zone from `now − lastBite` in
  /// memory thereafter (§3b).
  Future<Bite?> lastBite();

  /// Every bite whose timestamp falls in the half-open window `[from, to)`,
  /// in chronological order.
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to);

  /// The number of bites in the half-open window `[from, to)` — the headline
  /// metric (§3c). Callers pass a local day's bounds for "today's count".
  Future<int> biteCount(DateTime from, DateTime to);

  /// Appends [cfg] as a new pacing-config version (a config-change marker).
  ///
  /// Thresholds are a slowly-changing dimension (§2b): retuning appends rather
  /// than mutates, so every past bite stays gradable against the version
  /// effective at its own timestamp. The version takes effect from
  /// [PacingConfig.effectiveMs]; its [PacingConfig.id] is assigned by the store.
  Future<void> setPacingConfig(PacingConfig cfg);

  /// The pacing config in effect at [instant]: the newest version whose
  /// effective instant is at or before it, or null if none precedes it.
  Future<PacingConfig?> pacingConfigAt(DateTime instant);
}

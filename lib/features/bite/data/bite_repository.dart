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

  /// Every pacing-config version, in chronological (effective-instant) order.
  ///
  /// The backup exports the whole history, not just the current version, so a
  /// restore can still reconstruct the zone of any historical bite.
  Future<List<PacingConfig>> allPacingConfigs();

  /// Deletes every logged bite.
  ///
  /// The clear half of the clear-then-restore import path (§1c): a backup is a
  /// full snapshot of the bite log, so restoring replaces it. The pacing-config
  /// history is deliberately left intact — it is cleared separately via
  /// [clearPacingConfigs] only when a backup actually carries replacement
  /// versions, so a bite-only or weight-only restore keeps the thresholds.
  Future<void> clearBites();

  /// Deletes every pacing-config version.
  ///
  /// The clear half of the config restore: a backup that carries pacing config
  /// is a full snapshot of the threshold history, so restoring replaces it.
  /// Kept distinct from [clearBites] so the bite log and the config history are
  /// cleared independently — a bite restore never touches the thresholds.
  Future<void> clearPacingConfigs();
}

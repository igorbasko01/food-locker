/// The three pacing zones a bite can fall into (§3b of the pacing plan).
///
/// A zone is a *derived* view, never stored: it is always computed at read time
/// from `now − lastBite` against the two boundaries of the effective
/// `PacingConfig`. The zones are the ranges those two boundaries cut —
/// `[0, b1)` too soon, `[b1, b2)` ok — hold on, `[b2, ∞)` in the clear.
///
/// The zone expresses *how costly it is to bite right now*, decreasing to zero
/// once you're clear — so the colour never falsely green-lights an early bite.
enum PacingZone {
  /// `[0, b1)` — too soon to take the next bite; keep chewing.
  tooSoon,

  /// `[b1, b2)` — almost there; hold on a moment.
  holdOn,

  /// `[b2, ∞)` — in the clear; it's ok to take the next bite. Reaching this is
  /// the only readiness signal.
  inTheClear;

  /// The zone for [sinceLastBite] against the boundaries [b1] and [b2].
  ///
  /// The boundaries are half-open, matching the storage windows: a gap exactly
  /// at a boundary belongs to the later (less costly) zone, so `b1` reads as
  /// [holdOn] and `b2` reads as [inTheClear]. `b2` is the point at which biting
  /// is recommended and the haptic fires.
  static PacingZone forElapsed(
    Duration sinceLastBite, {
    required Duration b1,
    required Duration b2,
  }) {
    if (sinceLastBite < b1) return PacingZone.tooSoon;
    if (sinceLastBite < b2) return PacingZone.holdOn;
    return PacingZone.inTheClear;
  }
}

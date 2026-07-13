import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// UI-facing state holder for the bite-logging screen (Phases 4–5).
///
/// Owns the running bite count for the current local day and, after every tap,
/// writes through the [BiteRepository] then re-reads the count so the surfaced
/// number stays consistent with the store — mirroring the weight feature's
/// write-through-then-refresh pattern. Bite count is the headline metric (§0):
/// [logBite] never blocks (§3a) and the count re-queries after each tap.
///
/// It also drives the pacing visualization (§3b, Phase 5). The live pacing view
/// is *clock-driven, not data-driven*: the current [pacingZone] is a function of
/// `now − lastBite`, so a local ticker rebuilds it from the last-bite time held
/// in memory. The store is touched only to seed that reference once per session
/// ([BiteRepository.lastBite]) and to read the effective thresholds. Zones are
/// derived, never stored.
class BiteManager extends ChangeNotifier {
  /// [tickInterval] is how often the pacing ticker recomputes the zone while a
  /// countdown is running (~200–500 ms, §3b). [onReachedClear] fires once when
  /// the gap since the last bite reaches `b2` — the haptic tick that lets you
  /// watch your plate instead of the phone (§3b); it defaults to a real device
  /// haptic and is injectable so the lifecycle stays testable.
  BiteManager(
    this._repository, {
    Duration tickInterval = const Duration(milliseconds: 300),
    Future<void> Function()? onReachedClear,
  })  : _tickInterval = tickInterval,
        _onReachedClear = onReachedClear ?? HapticFeedback.mediumImpact;

  final BiteRepository _repository;
  final Duration _tickInterval;
  final Future<void> Function() _onReachedClear;

  // v1 starting thresholds (§3b), used only as a fallback before a config has
  // been read from the store — the default seed makes this unreachable in
  // practice, but it keeps the pacing view sane if no config exists.
  static const Duration _fallbackB1 = Duration(seconds: 15);
  static const Duration _fallbackB2 = Duration(seconds: 30);

  int _todayCount = 0;

  /// Bites logged so far during the current local day — the headline metric
  /// (§3c). Zero until [initialize] (or a [logBite]) has run.
  int get todayCount => _todayCount;

  // The pacing reference point, held in memory. The live view derives every
  // zone from `now − _lastBiteAt`; the store is not re-read per tick (§3b).
  DateTime? _lastBiteAt;

  // The thresholds in effect for the live view, read once from the store.
  PacingConfig? _pacingConfig;

  PacingZone _pacingZone = PacingZone.inTheClear;

  Timer? _ticker;

  /// The current pacing zone, derived from `now − lastBite` against the
  /// effective thresholds (§3b). Sits at [PacingZone.inTheClear] on open with no
  /// recent bite; a tap restarts the countdown from [PacingZone.tooSoon].
  PacingZone get pacingZone => _pacingZone;

  /// Time elapsed since the last bite, or null if none has been logged this
  /// session. Recomputed against the wall clock on each read so a build during
  /// an active countdown shows a fresh value.
  Duration? get sinceLastBite {
    final ref = _lastBiteAt;
    if (ref == null) return null;
    return clock.now().difference(ref);
  }

  /// Whether a countdown ticker is currently running — i.e. we are mid-pace and
  /// have not yet reached the clear zone. False in the static clear state.
  bool get isPacing => _ticker != null;

  Duration get _b1 => Duration(seconds: _pacingConfig?.b1S ?? _fallbackB1.inSeconds);
  Duration get _b2 => Duration(seconds: _pacingConfig?.b2S ?? _fallbackB2.inSeconds);

  /// Loads today's count and the effective pacing config, and seeds the pacing
  /// reference from the last stored bite so the screen opens with the right
  /// number and state even after an app restart. If that last bite is still
  /// within the countdown window the ticker resumes; otherwise it opens on the
  /// static clear state (§3b).
  Future<void> initialize() async {
    final now = clock.now();
    _pacingConfig = await _repository.pacingConfigAt(now);
    await _refreshTodayCount();

    final last = await _repository.lastBite();
    if (last != null) {
      _lastBiteAt = DateTime.fromMillisecondsSinceEpoch(last.atMs);
      _startCountdown();
    }
  }

  /// Records one bite at the current instant — one tap = one bite, persisted
  /// immediately and never blocked (§3a) — then refreshes today's count and
  /// restarts the pacing countdown from the fresh reference.
  Future<void> logBite() async {
    final now = clock.now();
    await _repository.logBite(now);
    _lastBiteAt = now;
    await _refreshTodayCount();
    // Lazily seed the thresholds if [initialize] was skipped (e.g. the very
    // first bite of a fresh install before a config read landed).
    _pacingConfig ??= await _repository.pacingConfigAt(now);
    _startCountdown();
  }

  Future<void> _refreshTodayCount() async {
    final now = clock.now();
    // Local-day bounds as a half-open window `[startOfDay, startOfNextDay)`.
    // Building the next day via the DateTime constructor (day + 1) normalizes
    // month/year rollovers and lands on local midnight — DST-correct, unlike
    // adding a fixed 24-hour Duration.
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = DateTime(now.year, now.month, now.day + 1);
    _todayCount = await _repository.biteCount(startOfDay, startOfNextDay);
    notifyListeners();
  }

  /// (Re)starts the pacing countdown from the current [_lastBiteAt]. Sets the
  /// zone to whatever the reference implies now and, only while the countdown
  /// still matters (not yet clear), spins up the ticker. If the reference is
  /// already past `b2` — a stale bite on open — it lands on the static clear
  /// state with no ticker running (§3b).
  void _startCountdown() {
    _stopTicker();
    _pacingZone = _currentZone();
    notifyListeners();
    if (_pacingZone != PacingZone.inTheClear) {
      _ticker = Timer.periodic(_tickInterval, _tick);
    }
  }

  void _tick(Timer timer) {
    final zone = _currentZone();
    if (zone == _pacingZone) return;
    _pacingZone = zone;
    if (zone == PacingZone.inTheClear) {
      // Reaching `b2`: haptic, freeze on the static clear state, cancel the
      // ticker so no periodic work runs until the next tap (§3b). Logging is
      // untouched — only the display/compute stops here.
      _stopTicker();
      _onReachedClear();
    }
    notifyListeners();
  }

  PacingZone _currentZone() {
    final ref = _lastBiteAt;
    if (ref == null) return PacingZone.inTheClear;
    return PacingZone.forElapsed(clock.now().difference(ref), b1: _b1, b2: _b2);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

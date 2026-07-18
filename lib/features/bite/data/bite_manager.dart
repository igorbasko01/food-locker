import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/meal_clustering.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// UI-facing state holder for the bite-logging screen.
///
/// Owns the running bite count for the current local day; after every tap it
/// writes through the [BiteRepository] and re-reads the count, so the surfaced
/// number stays consistent with the store. Bite count is the headline metric,
/// and [logBite] never blocks.
///
/// It also drives the pacing visualization. A local ticker rebuilds the current
/// [pacingZone] over time from the last-bite time held in memory, so it advances
/// between bites; the store is read only to seed that reference once per session
/// ([BiteRepository.lastBite]) and for the effective thresholds.
class BiteManager extends ChangeNotifier {
  /// [tickInterval] is how often the pacing ticker recomputes the zone while a
  /// countdown is running (~200–500 ms). [onReachedClear] fires once when
  /// the gap since the last bite reaches `b2` — the haptic tick that lets you
  /// watch your plate instead of the phone; it defaults to a real device
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

  // v1 starting thresholds, used only as a fallback before a config has
  // been read from the store — the default seed makes this unreachable in
  // practice, but it keeps the pacing view sane if no config exists.
  static const Duration _fallbackB1 = Duration(seconds: 15);
  static const Duration _fallbackB2 = Duration(seconds: 30);

  int _todayCount = 0;

  /// Bites logged so far during the current local day — the headline metric.
  /// Zero until [initialize] (or a [logBite]) has run.
  int get todayCount => _todayCount;

  int _currentMealBites = 0;

  /// Bites in the current meal, or 0 when no meal is in progress. Recomputed
  /// from the store alongside [todayCount]: the size of the trailing run of
  /// today's bites no more than [mealGapThreshold] apart — but only when the
  /// most recent bite is within that threshold of now. A last bite older than
  /// the threshold means the sitting has ended, so this reads 0.
  ///
  /// A projection of the log, not a running counter, so there is no
  /// increment/reset arithmetic to keep in sync: a just-logged bite always
  /// starts a fresh cluster after a `> mealGapThreshold` gap, while opening the
  /// app long after the last bite shows nothing. No [minMealBites] gate applies
  /// — it counts from the first bite of the sitting.
  int get currentMealBites => _currentMealBites;

  DateTime? _lastBiteAt;

  PacingConfig? _pacingConfig;

  PacingZone _pacingZone = PacingZone.inTheClear;

  Timer? _ticker;

  /// The current pacing zone, derived from the time since the last bite against
  /// the effective thresholds. Sits at [PacingZone.inTheClear] on open with no
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

  /// Whether a countdown is currently running — mid-pace, before the clear zone.
  bool get isPacing => _ticker != null;

  Duration get _b1 => Duration(seconds: _pacingConfig?.b1S ?? _fallbackB1.inSeconds);
  Duration get _b2 => Duration(seconds: _pacingConfig?.b2S ?? _fallbackB2.inSeconds);

  /// The effective `b2` boundary — the gap since the last bite at which the next
  /// bite is recommended (the [PacingZone.inTheClear] point).
  Duration get b2 => _b2;

  /// Loads today's count and the effective pacing config, and seeds the pacing
  /// reference from the last stored bite so the screen opens with the right
  /// number and state even after an app restart. If that last bite is still
  /// within the countdown window the ticker resumes; otherwise it opens on the
  /// static clear state.
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

  /// Re-reads the store so the surfaced numbers reflect time that passed while
  /// the screen was not the active tab or the app was backgrounded: the day
  /// count rolls to the new local day, [currentMealBites] drops to 0 once the
  /// sitting has ended, and the pacing reference is re-seeded from the last
  /// stored bite. Cheap enough to run every time the Bite tab becomes visible.
  Future<void> refresh() async {
    final now = clock.now();
    _pacingConfig ??= await _repository.pacingConfigAt(now);
    await _refreshTodayCount();

    final last = await _repository.lastBite();
    _lastBiteAt =
        last == null ? null : DateTime.fromMillisecondsSinceEpoch(last.atMs);
    _startCountdown();
  }

  /// Records one bite at the current instant — one tap = one bite, persisted
  /// immediately and never blocked — then refreshes today's count and
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
    // Half-open local-day window; day + 1 via the DateTime constructor keeps
    // month/year rollover and DST correct where a fixed 24-hour offset would not.
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = DateTime(now.year, now.month, now.day + 1);
    final bites = await _repository.bitesInRange(startOfDay, startOfNextDay);
    _todayCount = bites.length;
    _currentMealBites = _currentMealSize(bites, now);
    notifyListeners();
  }

  /// The trailing meal cluster's size given today's chronologically-ordered
  /// [bites] and the current instant [now]. 0 when the day is empty or the most
  /// recent bite is more than [mealGapThreshold] ago — the sitting has ended.
  int _currentMealSize(List<Bite> bites, DateTime now) {
    if (bites.isEmpty) return 0;
    final lastAt = DateTime.fromMillisecondsSinceEpoch(bites.last.atMs);
    if (now.difference(lastAt) > mealGapThreshold) return 0;
    return clusterBites(bites).last.length;
  }

  /// (Re)starts the pacing countdown from the current [_lastBiteAt]. Sets the
  /// zone to whatever the reference implies now and, only while the countdown
  /// still matters (not yet clear), spins up the ticker. If the reference is
  /// already past `b2` — a stale bite on open — it lands on the static clear
  /// state with no ticker running.
  void _startCountdown() {
    _stopTicker();
    _pacingZone = _currentZone();
    notifyListeners();
    if (_pacingZone != PacingZone.inTheClear) {
      _ticker = Timer.periodic(_tickInterval, _tick);
    }
  }

  void _tick(Timer timer) {
    _pacingZone = _currentZone();
    if (_pacingZone == PacingZone.inTheClear) {
      // Reaching `b2`: haptic, freeze on the clear state, cancel the ticker so
      // no periodic work runs until the next tap. Logging is untouched — only
      // the display stops here.
      _stopTicker();
      _onReachedClear();
    }
    // Publish on every tick so the countdown keeps updating within a zone.
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

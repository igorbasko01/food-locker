import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// The pacing ticker lifecycle. Driven with [fakeAsync] so the clock
/// (via `package:clock`) and the periodic ticker advance together and
/// deterministically — no real waiting, no drift database under fake time.
void main() {
  // The default seeded thresholds: b1 = 15 s, b2 = 30 s.
  const config = PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30);

  test('logBite starts the countdown in the too-soon zone', () {
    fakeAsync((async) {
      final repo = _FakeBiteRepository(config: config);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.logBite();
      async.flushMicrotasks();

      expect(manager.pacingZone, PacingZone.tooSoon);
      expect(manager.isPacing, isTrue);

      manager.dispose();
    });
  });

  test('the zone advances through amber to green as time passes', () {
    fakeAsync((async) {
      final repo = _FakeBiteRepository(config: config);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.logBite();
      async.flushMicrotasks();
      expect(manager.pacingZone, PacingZone.tooSoon);

      // Elapse just past each boundary so a tick is guaranteed to have fired
      // after the crossing (the ticker is granular, not continuous).
      async.elapse(const Duration(seconds: 16));
      expect(manager.pacingZone, PacingZone.holdOn);

      async.elapse(const Duration(seconds: 15));
      expect(manager.pacingZone, PacingZone.inTheClear);

      manager.dispose();
    });
  });

  test('the ticker notifies every tick so the readout keeps updating', () {
    fakeAsync((async) {
      final repo = _FakeBiteRepository(config: config);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.logBite();
      async.flushMicrotasks();
      expect(manager.pacingZone, PacingZone.tooSoon);

      // Within a single zone (still too-soon) the zone never changes, yet the
      // ticker must keep publishing so the countdown readout can update —
      // driven by this same clock ticker.
      var ticks = 0;
      manager.addListener(() => ticks++);
      async.elapse(const Duration(seconds: 3));

      expect(manager.pacingZone, PacingZone.tooSoon, reason: 'still same zone');
      expect(ticks, greaterThan(1),
          reason: 'publishes each tick within a zone, not only on change');
      expect(manager.sinceLastBite!.inSeconds, greaterThanOrEqualTo(3));

      manager.dispose();
    });
  });

  test('reaching b2 fires the haptic exactly once and stops the ticker', () {
    fakeAsync((async) {
      var haptics = 0;
      final repo = _FakeBiteRepository(config: config);
      final manager =
          BiteManager(repo, onReachedClear: () async => haptics++);

      manager.logBite();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 31));
      expect(manager.pacingZone, PacingZone.inTheClear);
      expect(manager.isPacing, isFalse, reason: 'ticker frozen at clear');
      expect(haptics, 1);

      // No periodic work runs after clear, so no further haptics fire.
      async.elapse(const Duration(seconds: 120));
      expect(haptics, 1);

      manager.dispose();
    });
  });

  test('a fresh tap resets the reference and restarts the countdown', () {
    fakeAsync((async) {
      var haptics = 0;
      final repo = _FakeBiteRepository(config: config);
      final manager =
          BiteManager(repo, onReachedClear: () async => haptics++);

      manager.logBite();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 31));
      expect(manager.pacingZone, PacingZone.inTheClear);
      expect(haptics, 1);

      // Tapping again from the clear state re-arms the countdown.
      manager.logBite();
      async.flushMicrotasks();
      expect(manager.pacingZone, PacingZone.tooSoon);
      expect(manager.isPacing, isTrue);

      async.elapse(const Duration(seconds: 31));
      expect(manager.pacingZone, PacingZone.inTheClear);
      expect(haptics, 2);

      manager.dispose();
    });
  });

  test('initialize resumes the countdown when the last bite is still recent',
      () {
    fakeAsync((async) {
      final now = clock.now();
      final repo = _FakeBiteRepository(
        config: config,
        bites: [now.subtract(const Duration(seconds: 5))],
      );
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();

      // 5 s in → still too soon, and the ticker is running.
      expect(manager.pacingZone, PacingZone.tooSoon);
      expect(manager.isPacing, isTrue);

      // Elapse past b2 (5 s already gone, so >25 s more) to reach the clear
      // state — a little extra so a tick lands after the crossing.
      async.elapse(const Duration(seconds: 26));
      expect(manager.pacingZone, PacingZone.inTheClear);

      manager.dispose();
    });
  });

  test('initialize opens on the static clear state for a stale last bite', () {
    fakeAsync((async) {
      final now = clock.now();
      final repo = _FakeBiteRepository(
        config: config,
        bites: [now.subtract(const Duration(minutes: 10))],
      );
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();

      expect(manager.pacingZone, PacingZone.inTheClear);
      expect(manager.isPacing, isFalse, reason: 'no ticker for a stale bite');

      manager.dispose();
    });
  });

  test('initialize with no bites shows the static clear state', () {
    fakeAsync((async) {
      final repo = _FakeBiteRepository(config: config);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();

      expect(manager.pacingZone, PacingZone.inTheClear);
      expect(manager.isPacing, isFalse);

      manager.dispose();
    });
  });
}

/// An in-memory [BiteRepository] with synchronous-ish futures so the pacing
/// ticker can be exercised under [fakeAsync] without a real drift database.
class _FakeBiteRepository implements BiteRepository {
  _FakeBiteRepository({this.config, List<DateTime>? bites})
      : _bites = [...?bites];

  final PacingConfig? config;
  final List<DateTime> _bites;

  @override
  Future<void> logBite(DateTime at) async => _bites.add(at);

  @override
  Future<Bite?> lastBite() async => _bites.isEmpty
      ? null
      : Bite(id: _bites.length, atMs: _bites.last.millisecondsSinceEpoch);

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) async {
    var id = 0;
    return [
      for (final at in _bites)
        if (!at.isBefore(from) && at.isBefore(to))
          Bite(id: ++id, atMs: at.millisecondsSinceEpoch),
    ];
  }

  @override
  Future<int> biteCount(DateTime from, DateTime to) async => _bites
      .where((at) => !at.isBefore(from) && at.isBefore(to))
      .length;

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(
    DateTime from,
    DateTime to,
  ) async {
    final byDay = <DateTime, int>{};
    for (final at in _bites) {
      if (at.isBefore(from) || !at.isBefore(to)) continue;
      final day = DateTime(at.year, at.month, at.day);
      byDay[day] = (byDay[day] ?? 0) + 1;
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days) DailyBiteCount(day: day, count: byDay[day]!),
    ];
  }

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async {}

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) async => config;

  @override
  Future<List<PacingConfig>> allPacingConfigs() async => [?config];

  @override
  Future<void> clearBites() async => _bites.clear();

  @override
  Future<void> clearPacingConfigs() async {}
}

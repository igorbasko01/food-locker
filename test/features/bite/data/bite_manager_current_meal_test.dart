import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';

/// [BiteManager.currentMealBites] — the trailing meal cluster of today's bites,
/// recomputed from the store alongside the day count. Driven with [fakeAsync]
/// so `clock.now()` and the seeded bite offsets stay deterministic without a
/// real drift database.
void main() {
  const config = PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30);

  test('is zero on a fresh manager before any refresh', () {
    final repo = _FakeBiteRepository(config: config);
    final manager = BiteManager(repo, onReachedClear: () async {});
    expect(manager.currentMealBites, 0);
    manager.dispose();
  });

  test('counts the trailing cluster when the last bite is recent', () {
    fakeAsync((async) {
      final now = clock.now();
      // An earlier, separate cluster (a 16-min gap breaks it off) then a fresh
      // run of three within the 5-min threshold — only the trailing run counts.
      final repo = _FakeBiteRepository(config: config, bites: [
        now.subtract(const Duration(minutes: 20)),
        now.subtract(const Duration(minutes: 4)),
        now.subtract(const Duration(minutes: 2)),
        now.subtract(const Duration(minutes: 1)),
      ]);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();

      expect(manager.currentMealBites, 3);

      manager.dispose();
    });
  });

  test('is zero when the last bite is older than the meal-gap threshold', () {
    fakeAsync((async) {
      final now = clock.now();
      // A two-bite cluster, but the sitting ended: the last bite is 8 min ago.
      final repo = _FakeBiteRepository(config: config, bites: [
        now.subtract(const Duration(minutes: 10)),
        now.subtract(const Duration(minutes: 8)),
      ]);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();

      expect(manager.currentMealBites, 0);

      manager.dispose();
    });
  });

  test('a bite after a long gap starts a fresh cluster of one', () {
    fakeAsync((async) {
      final now = clock.now();
      // A stale bite from 10 min ago: on open the sitting has ended (0).
      final repo = _FakeBiteRepository(config: config, bites: [
        now.subtract(const Duration(minutes: 10)),
      ]);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.initialize();
      async.flushMicrotasks();
      expect(manager.currentMealBites, 0);

      // A new bite lands more than the threshold after the stale one — a fresh
      // trailing cluster of exactly one, recomputed by the logBite refresh.
      manager.logBite();
      async.flushMicrotasks();
      expect(manager.currentMealBites, 1);

      manager.dispose();
    });
  });

  test('recomputes and grows as consecutive bites are logged', () {
    fakeAsync((async) {
      final repo = _FakeBiteRepository(config: config);
      final manager = BiteManager(repo, onReachedClear: () async {});

      manager.logBite();
      async.flushMicrotasks();
      expect(manager.currentMealBites, 1);

      async.elapse(const Duration(seconds: 30));
      manager.logBite();
      async.flushMicrotasks();
      expect(manager.currentMealBites, 2);

      manager.dispose();
    });
  });
}

/// An in-memory [BiteRepository] returning bites chronologically, for exercising
/// the current-meal recompute under [fakeAsync] without a drift database.
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
    final inRange = _bites
        .where((at) => !at.isBefore(from) && at.isBefore(to))
        .toList()
      ..sort();
    var id = 0;
    return [
      for (final at in inRange) Bite(id: ++id, atMs: at.millisecondsSinceEpoch),
    ];
  }

  @override
  Future<int> biteCount(DateTime from, DateTime to) async =>
      _bites.where((at) => !at.isBefore(from) && at.isBefore(to)).length;

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(
    DateTime from,
    DateTime to,
  ) async =>
      [];

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

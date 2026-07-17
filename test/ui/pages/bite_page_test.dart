import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/ui/pages/bite_page.dart';
import 'package:provider/provider.dart';

/// The "This meal: N" line on [BitePage]: present while a sitting is in
/// progress, absent once it has ended.
void main() {
  const config = PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30);

  Future<BiteManager> pumpPage(
    WidgetTester tester,
    _FakeBiteRepository repo,
  ) async {
    final manager = BiteManager(repo, onReachedClear: () async {});
    await manager.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<BiteManager>.value(
          value: manager,
          child: const BitePage(),
        ),
      ),
    );
    await tester.pump();
    return manager;
  }

  testWidgets('shows the current-meal line while a meal is in progress',
      (tester) async {
    final now = clock.now();
    final repo = _FakeBiteRepository(config: config, bites: [
      now.subtract(const Duration(minutes: 3)),
      now.subtract(const Duration(minutes: 2)),
      now.subtract(const Duration(seconds: 10)),
    ]);

    final manager = await pumpPage(tester, repo);

    expect(find.text('This meal: 3'), findsOneWidget);

    manager.dispose();
  });

  testWidgets('hides the current-meal line when no meal is in progress',
      (tester) async {
    final now = clock.now();
    // A stale bite from 10 min ago: the sitting has ended.
    final repo = _FakeBiteRepository(config: config, bites: [
      now.subtract(const Duration(minutes: 10)),
    ]);

    final manager = await pumpPage(tester, repo);

    expect(find.textContaining('This meal:'), findsNothing);

    manager.dispose();
  });
}

/// A minimal in-memory [BiteRepository] returning bites chronologically.
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

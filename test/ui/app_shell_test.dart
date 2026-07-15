import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/ui/app_shell.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester, BiteRepository biteRepository) async {
    final weightRepository = InMemoryWeightRepository();
    final weightManager = WeightManager(weightRepository);
    await weightManager.initialize();
    final biteManager = BiteManager(biteRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<WeightRepository>.value(value: weightRepository),
          Provider<BiteRepository>.value(value: biteRepository),
          Provider<SerializationService>(create: (_) => SerializationService()),
          ChangeNotifierProvider<WeightManager>.value(value: weightManager),
          ChangeNotifierProvider<BiteManager>.value(value: biteManager),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder analyticsButton() => find.widgetWithIcon(IconButton, Icons.bar_chart_rounded);

  testWidgets('analytics button shows only on the Bite tab', (tester) async {
    await pumpShell(tester, _FakeBiteRepository());

    // Home tab (initial): no analytics action.
    expect(analyticsButton(), findsNothing);

    // Weight tab: still no action.
    await tester.tap(find.text('Weight'));
    await tester.pumpAndSettle();
    expect(analyticsButton(), findsNothing);

    // Bite tab: the action appears.
    await tester.tap(find.text('Bite'));
    await tester.pumpAndSettle();
    expect(analyticsButton(), findsOneWidget);

    // Settings tab: gone again.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(analyticsButton(), findsNothing);
  });

  testWidgets('analytics button opens and pops the analytics page', (tester) async {
    await pumpShell(tester, _FakeBiteRepository());

    await tester.tap(find.text('Bite'));
    await tester.pumpAndSettle();

    await tester.tap(analyticsButton());
    await tester.pumpAndSettle();

    // The self-contained page is on screen with its own app-bar title.
    expect(find.text('Bite Analytics'), findsOneWidget);
    // Empty log → global empty state.
    expect(find.text('No bites logged yet'), findsOneWidget);

    // Back arrow pops the route.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Bite Analytics'), findsNothing);
    expect(analyticsButton(), findsOneWidget);
  });
}

/// A minimal in-memory [BiteRepository] for the shell widget test: only
/// [lastBite] drives the analytics page's empty state here.
class _FakeBiteRepository implements BiteRepository {
  _FakeBiteRepository({List<DateTime>? bites}) : _bites = [...?bites];

  final List<DateTime> _bites;

  @override
  Future<void> logBite(DateTime at) async => _bites.add(at);

  @override
  Future<Bite?> lastBite() async => _bites.isEmpty
      ? null
      : Bite(id: _bites.length, atMs: _bites.last.millisecondsSinceEpoch);

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) async => [
        for (final at in _bites)
          if (!at.isBefore(from) && at.isBefore(to))
            Bite(id: _bites.indexOf(at) + 1, atMs: at.millisecondsSinceEpoch),
      ];

  @override
  Future<int> biteCount(DateTime from, DateTime to) async =>
      _bites.where((at) => !at.isBefore(from) && at.isBefore(to)).length;

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to) async => [];

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async {}

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) async => null;

  @override
  Future<List<PacingConfig>> allPacingConfigs() async => [];

  @override
  Future<void> clearBites() async => _bites.clear();

  @override
  Future<void> clearPacingConfigs() async {}
}

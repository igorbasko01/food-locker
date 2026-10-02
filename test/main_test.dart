import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/main.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {required bool isTestBuild}) async {
    final weightRepository = InMemoryWeightRepository();
    final weightManager = WeightManager(weightRepository);
    await weightManager.initialize();
    final biteRepository = _FakeBiteRepository();
    final settingsRepository = InMemorySettingsRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<WeightRepository>.value(value: weightRepository),
          Provider<BiteRepository>.value(value: biteRepository),
          Provider<SettingsRepository>.value(value: settingsRepository),
          Provider<SerializationService>(create: (_) => SerializationService()),
          ChangeNotifierProvider<WeightManager>.value(value: weightManager),
          ChangeNotifierProvider<BiteManager>.value(
            value: BiteManager(biteRepository),
          ),
          ChangeNotifierProvider<SettingsManager>.value(
            value: SettingsManager(settingsRepository),
          ),
        ],
        child: MainApp(isTestBuild: isTestBuild),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The debug-mode "DEBUG" ribbon is also a Banner, so match on the message.
  Finder testBanner() =>
      find.byWidgetPredicate((w) => w is Banner && w.message == 'TEST');

  testWidgets('a test build shows the TEST banner on every tab', (tester) async {
    await pumpApp(tester, isTestBuild: true);

    expect(testBanner(), findsOneWidget);
    for (final tab in ['Weight', 'Bite', 'Settings', 'Home']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(testBanner(), findsOneWidget, reason: 'on the $tab tab');
    }
  });

  testWidgets('a production build shows no TEST banner', (tester) async {
    await pumpApp(tester, isTestBuild: false);

    expect(testBanner(), findsNothing);
  });

  test('the flag defaults to off without the TEST_BUILD define', () {
    expect(kIsTestBuild, isFalse);
    expect(const MainApp().isTestBuild, isFalse);
  });
}

class _FakeBiteRepository implements BiteRepository {
  @override
  Future<void> logBite(DateTime at) async {}

  @override
  Future<Bite?> lastBite() async => null;

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) async => [];

  @override
  Future<int> biteCount(DateTime from, DateTime to) async => 0;

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to) async => [];

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async {}

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) async => null;

  @override
  Future<List<PacingConfig>> allPacingConfigs() async => [];

  @override
  Future<void> clearBites() async {}

  @override
  Future<void> clearPacingConfigs() async {}
}

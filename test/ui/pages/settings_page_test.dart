import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/ui/pages/settings_page.dart';
import 'package:food_locker/ui/widgets/height_dialog.dart';
import 'package:provider/provider.dart';

/// Backup feedback on [SettingsPage]: work in flight says so, only work
/// that actually moved data reports success, and neither a restore nor a clear
/// leaves a manager holding what it read beforehand.
void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    SerializationService service, {
    WeightManager? weightManager,
    BiteManager? biteManager,
    WeightRepository? weightRepo,
    BiteRepository? biteRepo,
    SettingsRepository? settingsRepo,
    SettingsManager? settingsManager,
  }) {
    final weights = weightRepo ?? InMemoryWeightRepository();
    final bites = biteRepo ?? _FakeBiteRepository();
    final settings = settingsRepo ?? InMemorySettingsRepository();
    return tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<SerializationService>.value(value: service),
            Provider<WeightRepository>.value(value: weights),
            Provider<BiteRepository>.value(value: bites),
            Provider<SettingsRepository>.value(value: settings),
            ChangeNotifierProvider<WeightManager>.value(
              value: weightManager ?? WeightManager(weights),
            ),
            ChangeNotifierProvider<BiteManager>.value(
              value: biteManager ?? _biteManager(bites),
            ),
            ChangeNotifierProvider<SettingsManager>.value(
              value: settingsManager ?? SettingsManager(settings),
            ),
          ],
          child: const SettingsPage(),
        ),
      ),
    );
  }

  /// Long enough for a snackbar to finish animating in or out.
  Future<void> pumpToast(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
  }

  /// Taps Import and answers the confirmation dialog it raises.
  Future<void> tapImport(WidgetTester tester, {required bool confirm}) async {
    await tester.tap(find.text('Import Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(confirm ? 'Replace' : 'Cancel'));
    await tester.pump();
  }

  /// Taps Clear All Data and answers the confirmation dialog it raises. The
  /// action sits at the bottom of a scrolling page, so it is brought into view
  /// first.
  Future<void> tapClear(WidgetTester tester, {required bool confirm}) async {
    await tester.ensureVisible(find.text('Clear All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(confirm ? 'Clear' : 'Cancel'));
    await tester.pump();
  }

  group('profile', () {
    testWidgets('an unanswered height says so rather than showing a default',
        (tester) async {
      await pumpPage(tester, SerializationService());

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('a stored height shows in the active system', (tester) async {
      await pumpPage(
        tester,
        SerializationService(),
        settingsRepo: InMemorySettingsRepository(heightCm: 177.8),
      );

      expect(find.text('177.8 cm'), findsOneWidget);

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      expect(find.text("5' 10\""), findsOneWidget);
    });

    testWidgets('the height dialog stores what it returns', (tester) async {
      final settingsRepo = InMemorySettingsRepository();
      await pumpPage(
        tester,
        SerializationService(),
        settingsRepo: settingsRepo,
      );

      await tester.tap(find.text('Height'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(HeightDialog.centimetresFieldKey),
        '178',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(settingsRepo.heightCm, 178);
      expect(find.text('178 cm'), findsOneWidget);
    });

    testWidgets('the chosen measurement system is stored', (tester) async {
      final settingsRepo = InMemorySettingsRepository();
      await pumpPage(
        tester,
        SerializationService(),
        settingsRepo: settingsRepo,
      );

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      expect(settingsRepo.measurementSystem, MeasurementSystem.imperial);
    });

    testWidgets('a clear leaves no height on the page', (tester) async {
      final settingsRepo = InMemorySettingsRepository(heightCm: 177.8);
      await pumpPage(
        tester,
        SerializationService(),
        settingsRepo: settingsRepo,
      );

      expect(find.text('177.8 cm'), findsOneWidget);

      await tapClear(tester, confirm: true);
      await pumpToast(tester);

      expect(settingsRepo.heightCm, isNull);
      expect(find.text('Not set'), findsOneWidget);
    });
  });

  group('import', () {
    testWidgets('asks before restoring, naming the file it would replace',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tester.tap(find.text('Import Data'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsOneWidget);
      expect(
        find.textContaining(_FakeSerializationService.fileName),
        findsOneWidget,
      );
      // The restore waits behind the dialog.
      expect(find.text('Importing data...'), findsNothing);
    });

    testWidgets('reports nothing when the confirmation is cancelled',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: false);
      await pumpToast(tester);

      expect(find.text('Replace all data?'), findsNothing);
      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsNothing);
    });

    testWidgets('shows a progress toast while restoring, then the success toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: true);

      expect(find.text('Importing data...'), findsOneWidget);
      expect(find.text('Data imported successfully'), findsNothing);

      service.finish();
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsOneWidget);
    });

    testWidgets('reports nothing when the file picker is dismissed',
        (tester) async {
      final service = _FakeSerializationService(cancelled: true);
      await pumpPage(tester, service);

      await tester.tap(find.text('Import Data'));
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsNothing);
    });

    testWidgets('leaves no manager holding pre-import data', (tester) async {
      final weightRepo = InMemoryWeightRepository();
      final biteRepo = _FakeBiteRepository(
        config: const PacingConfig(id: 1, effectiveMs: 0, b1S: 12, b2S: 25),
      );
      final weightManager = WeightManager(weightRepo);
      final biteManager = _biteManager(biteRepo);
      await weightManager.initialize();
      await biteManager.initialize();

      final restored = Weight(date: DateTime.now(), value: 71.5);
      final service = _FakeSerializationService(
        // Stands in for the restore: replaces what is stored without going
        // through either manager.
        onRestore: () async {
          await weightRepo.saveWeight(restored);
          biteRepo.config =
              const PacingConfig(id: 2, effectiveMs: 0, b1S: 40, b2S: 90);
        },
      );
      await pumpPage(
        tester,
        service,
        weightManager: weightManager,
        biteManager: biteManager,
      );

      expect(weightManager.history, isEmpty);
      expect(biteManager.b2, const Duration(seconds: 25));

      await tapImport(tester, confirm: true);
      service.finish();
      await pumpToast(tester);

      expect(weightManager.history.single.value, restored.value);
      expect(biteManager.b2, const Duration(seconds: 90));
    });

    testWidgets('replaces the progress toast with the failure toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: true);

      expect(find.text('Importing data...'), findsOneWidget);

      service.fail('boom');
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.textContaining('Import failed'), findsOneWidget);
    });
  });

  group('clear', () {
    /// Far enough back that a seeded bite is past any pacing threshold, so it
    /// never leaves a ticker running through the test.
    DateTime startOfToday() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }

    testWidgets('asks before deleting anything', (tester) async {
      final weightRepo = InMemoryWeightRepository();
      await weightRepo.saveWeight(Weight(date: DateTime.now(), value: 71.5));
      await pumpPage(tester, SerializationService(), weightRepo: weightRepo);

      await tester.ensureVisible(find.text('Clear All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All Data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all data?'), findsOneWidget);
      expect(weightRepo.getAllWeights(), hasLength(1));
    });

    testWidgets('cancelling leaves the stores untouched', (tester) async {
      final weightRepo = InMemoryWeightRepository();
      await weightRepo.saveWeight(Weight(date: DateTime.now(), value: 71.5));
      await pumpPage(tester, SerializationService(), weightRepo: weightRepo);

      await tapClear(tester, confirm: false);
      await pumpToast(tester);

      expect(find.text('Clear all data?'), findsNothing);
      expect(weightRepo.getAllWeights(), hasLength(1));
      expect(find.text('All data cleared'), findsNothing);
    });

    testWidgets('confirming empties both stores and the managers with them',
        (tester) async {
      final weightRepo = InMemoryWeightRepository();
      await weightRepo.saveWeight(Weight(date: DateTime.now(), value: 71.5));
      final biteRepo = _FakeBiteRepository(
        config: const PacingConfig(id: 1, effectiveMs: 0, b1S: 12, b2S: 25),
      );
      await biteRepo.logBite(startOfToday());
      final weightManager = WeightManager(weightRepo);
      final biteManager = _biteManager(biteRepo);
      await weightManager.initialize();
      await biteManager.initialize();

      await pumpPage(
        tester,
        SerializationService(),
        weightManager: weightManager,
        biteManager: biteManager,
        weightRepo: weightRepo,
        biteRepo: biteRepo,
      );

      expect(weightManager.history, hasLength(1));
      expect(biteManager.todayCount, 1);
      expect(biteManager.b2, const Duration(seconds: 25));

      await tapClear(tester, confirm: true);
      await pumpToast(tester);

      expect(weightRepo.getAllWeights(), isEmpty);
      expect(weightManager.history, isEmpty);
      expect(biteManager.todayCount, 0);
      // Back to a fresh install's thresholds rather than the cleared ones.
      expect(biteManager.b2, const Duration(seconds: 30));
      expect(find.text('All data cleared'), findsOneWidget);
    });

    testWidgets('shows a progress toast while clearing, then the success toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapClear(tester, confirm: true);

      expect(find.text('Clearing data...'), findsOneWidget);
      expect(find.text('All data cleared'), findsNothing);

      service.finish();
      await pumpToast(tester);

      expect(find.text('Clearing data...'), findsNothing);
      expect(find.text('All data cleared'), findsOneWidget);
    });

    testWidgets('replaces the progress toast with the failure toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapClear(tester, confirm: true);

      expect(find.text('Clearing data...'), findsOneWidget);

      service.fail('boom');
      await pumpToast(tester);

      expect(find.text('Clearing data...'), findsNothing);
      expect(find.textContaining('Clear failed'), findsOneWidget);
    });

    testWidgets('re-reads the managers when the clear fails part way',
        (tester) async {
      final weightRepo = InMemoryWeightRepository();
      await weightRepo.saveWeight(Weight(date: DateTime.now(), value: 71.5));
      final weightManager = WeightManager(weightRepo);
      await weightManager.initialize();
      final service = _FakeSerializationService(onClear: weightRepo.clear);
      await pumpPage(
        tester,
        service,
        weightManager: weightManager,
        weightRepo: weightRepo,
      );

      expect(weightManager.history, hasLength(1));

      await tapClear(tester, confirm: true);
      service.fail('boom');
      await pumpToast(tester);

      expect(find.textContaining('Clear failed'), findsOneWidget);
      // The weights are gone whatever the toast says, so the tab must not go
      // on listing them.
      expect(weightManager.history, isEmpty);
    });
  });

  group('export', () {
    testWidgets('shows a progress toast while exporting, then the success toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tester.tap(find.text('Export Data'));
      await tester.pump();

      expect(find.text('Exporting data...'), findsOneWidget);
      expect(find.text('Data exported successfully'), findsNothing);

      service.finish();
      await pumpToast(tester);

      expect(find.text('Exporting data...'), findsNothing);
      expect(find.text('Data exported successfully'), findsOneWidget);
    });

    testWidgets('reports an empty export rather than success', (tester) async {
      final service = _FakeSerializationService(empty: true);
      await pumpPage(tester, service);

      await tester.tap(find.text('Export Data'));
      service.finish();
      await pumpToast(tester);

      expect(find.text('Data exported successfully'), findsNothing);
      expect(find.text('No data to export'), findsOneWidget);
    });
  });
}

/// Replaces the file picker, the restore, and the share sheet, holding the work
/// open until [finish] or [fail] ends it.
class _FakeSerializationService extends SerializationService {
  _FakeSerializationService({
    this.cancelled = false,
    this.empty = false,
    this.onRestore,
    this.onClear,
  });

  /// Import only: what the restore writes to the stores once it is let through.
  final Future<void> Function()? onRestore;

  /// Clear only: what the clear deletes before the work is allowed to end, so a
  /// failure can land on a store that was already emptied part way.
  final Future<void> Function()? onClear;

  /// Import only: the user dismissed the file picker.
  final bool cancelled;

  /// Export only: both stores were empty.
  final bool empty;

  static const fileName = 'food_locker_20260101120000.zip';

  final _work = Completer<void>();

  void finish() => _work.complete();

  void fail(String message) => _work.completeError(message);

  @override
  Future<bool> importData(
    BuildContext context, {
    ConfirmRestore? onConfirm,
    VoidCallback? onRestoreStart,
  }) async {
    if (cancelled) return false;
    if (onConfirm != null && !await onConfirm(fileName)) return false;
    onRestoreStart?.call();
    await _work.future;
    await onRestore?.call();
    return true;
  }

  @override
  Future<void> clearAllData(
    WeightRepository weightRepo,
    BiteRepository biteRepo, {
    required SettingsRepository settingsRepo,
  }) async {
    await onClear?.call();
    await _work.future;
  }

  @override
  Future<bool> exportData(BuildContext context, {VoidCallback? onShareReady}) async {
    await _work.future;
    if (empty) return false;
    onShareReady?.call();
    return true;
  }
}

/// A [BiteManager] over [repo] with the device haptic stubbed out.
BiteManager _biteManager(BiteRepository repo) =>
    BiteManager(repo, onReachedClear: () async {});

/// An in-memory [BiteRepository] whose [config] a test can swap, the way a
/// restore replaces the stored threshold history.
class _FakeBiteRepository implements BiteRepository {
  _FakeBiteRepository({this.config});

  PacingConfig? config;

  final List<DateTime> _bites = [];

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
  Future<int> biteCount(DateTime from, DateTime to) async =>
      _bites.where((at) => !at.isBefore(from) && at.isBefore(to)).length;

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to) async => [];

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async => config = cfg;

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) async => config;

  @override
  Future<List<PacingConfig>> allPacingConfigs() async => [?config];

  @override
  Future<void> clearBites() async => _bites.clear();

  @override
  Future<void> clearPacingConfigs() async => config = null;
}

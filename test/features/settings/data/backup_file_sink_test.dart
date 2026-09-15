import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/backup_file_sink.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:provider/provider.dart';

/// Stands in for the platform's file handling, so an export can be driven
/// without a share sheet and a picked path read without a file on disk.
class _RecordingBackupFileSink implements BackupFileSink {
  _RecordingBackupFileSink({this.staged = const {}});

  final Map<String, List<int>> staged;
  final List<String> savedNames = [];
  final List<List<int>> savedBytes = [];
  final List<String> readPaths = [];

  @override
  Future<void> save(
    String fileName,
    List<int> bytes, {
    VoidCallback? onReady,
  }) async {
    savedNames.add(fileName);
    savedBytes.add(bytes);
    onReady?.call();
  }

  @override
  Future<List<int>> readBytes(String path) async {
    readPaths.add(path);
    final bytes = staged[path];
    if (bytes == null) throw StateError('no file staged at $path');
    return bytes;
  }
}

/// A [BiteRepository] with just enough behaviour for an export and a restore.
class _FakeBiteRepository implements BiteRepository {
  final List<DateTime> bites = [];
  final List<PacingConfig> configs = [];

  @override
  Future<void> logBite(DateTime at) async => bites.add(at);

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) async {
    var id = 0;
    return [
      for (final at in bites)
        if (!at.isBefore(from) && at.isBefore(to))
          Bite(id: ++id, atMs: at.millisecondsSinceEpoch),
    ];
  }

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async => configs.add(cfg);

  @override
  Future<List<PacingConfig>> allPacingConfigs() async => configs;

  @override
  Future<void> clearBites() async => bites.clear();

  @override
  Future<void> clearPacingConfigs() async => configs.clear();

  @override
  Future<Bite?> lastBite() => throw UnimplementedError();

  @override
  Future<int> biteCount(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) =>
      throw UnimplementedError();
}

/// The two shapes the picker returns: a browser reads the file into memory and
/// leaves no path, a native picker points at one on disk and reads nothing.
PlatformFile _browserPick(String name, List<int> bytes) => PlatformFile(
  name: name,
  size: bytes.length,
  bytes: Uint8List.fromList(bytes),
);

PlatformFile _nativePick(String name, String path, int size) =>
    PlatformFile(name: name, size: size, path: path);

/// Backup export and import across the platform seam: whichever half of a
/// picked file a platform supplies reaches the same codecs, and an archive
/// written on one platform restores on the other.
void main() {
  // Runs [body] against a context holding the three repositories an export
  // reads through. The context leaves the tree before [body] sees it, so the
  // call sits where a button tap would put it rather than inside a build.
  Future<T> withRepositories<T>(
    WidgetTester tester, {
    required WeightRepository weightRepo,
    required BiteRepository biteRepo,
    required SettingsRepository settingsRepo,
    required Future<T> Function(BuildContext context) body,
  }) {
    late BuildContext captured;
    return tester
        .pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<WeightRepository>.value(value: weightRepo),
                Provider<BiteRepository>.value(value: biteRepo),
                Provider<SettingsRepository>.value(value: settingsRepo),
              ],
              child: Builder(
                builder: (context) {
                  captured = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        )
        .then((_) => body(captured));
  }

  Future<InMemoryWeightRepository> weightRepoWith(double value) async {
    final repo = InMemoryWeightRepository();
    await repo.saveWeight(Weight(date: DateTime(2023, 10, 27), value: value));
    return repo;
  }

  group('BackupFileSink export', () {
    testWidgets('hands the sink a timestamped zip of the stored data', (
      tester,
    ) async {
      final sink = _RecordingBackupFileSink();
      final service = SerializationService(fileSink: sink);

      final exported = await withRepositories(
        tester,
        weightRepo: await weightRepoWith(75.5),
        biteRepo: _FakeBiteRepository(),
        settingsRepo: InMemorySettingsRepository(),
        body: service.exportData,
      );

      expect(exported, isTrue);
      expect(sink.savedNames.single, matches(r'^food_locker_\d{14}\.zip$'));
      final weights = const WeightBackupCodec().decode(sink.savedBytes.single);
      expect(weights.single.value, 75.5);
    });

    testWidgets('fires onShareReady once the bytes are handed over', (
      tester,
    ) async {
      final sink = _RecordingBackupFileSink();
      final service = SerializationService(fileSink: sink);

      var savedWhenReady = -1;
      await withRepositories(
        tester,
        weightRepo: await weightRepoWith(75.5),
        biteRepo: _FakeBiteRepository(),
        settingsRepo: InMemorySettingsRepository(),
        body: (context) => service.exportData(
          context,
          onShareReady: () => savedWhenReady = sink.savedNames.length,
        ),
      );

      expect(savedWhenReady, 1);
    });

    testWidgets('empty stores produce no file at all', (tester) async {
      final sink = _RecordingBackupFileSink();
      final service = SerializationService(fileSink: sink);

      final exported = await withRepositories(
        tester,
        weightRepo: InMemoryWeightRepository(),
        biteRepo: _FakeBiteRepository(),
        settingsRepo: InMemorySettingsRepository(),
        body: service.exportData,
      );

      expect(exported, isFalse);
      expect(sink.savedNames, isEmpty);
    });
  });

  group('BackupFileSink import', () {
    test('a browser pick is read from its bytes, never from a path', () async {
      final sink = _RecordingBackupFileSink();
      final service = SerializationService(fileSink: sink);

      final bytes = await service.pickedBytes(
        _browserPick('food_locker_20231027120000.zip', [1, 2, 3]),
      );

      expect(bytes, [1, 2, 3]);
      expect(sink.readPaths, isEmpty);
    });

    test('a native pick is read through the sink at its path', () async {
      final sink = _RecordingBackupFileSink(
        staged: {
          '/tmp/backup.zip': [4, 5, 6],
        },
      );
      final service = SerializationService(fileSink: sink);

      final bytes = await service.pickedBytes(
        _nativePick('backup.zip', '/tmp/backup.zip', 3),
      );

      expect(bytes, [4, 5, 6]);
      expect(sink.readPaths.single, '/tmp/backup.zip');
    });

    test('a pick with neither bytes nor path reads as nothing chosen', () async {
      final service = SerializationService(
        fileSink: _RecordingBackupFileSink(),
      );

      expect(
        await service.pickedBytes(PlatformFile(name: 'backup.zip', size: 0)),
        isNull,
      );
    });
  });

  group('BackupFileSink migration', () {
    test('an archive written on native restores from a browser pick', () async {
      // The migration path between the two builds: they share no storage, so
      // the only thing the ends agree on is the archive itself.
      final service = SerializationService(
        fileSink: _RecordingBackupFileSink(),
      );
      final zip = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        [const Bite(id: 1, atMs: 1000)],
        [const PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30)],
        heightCm: 180,
      );

      final picked = _browserPick('food_locker_20231027120000.zip', zip);
      final bytes = await service.pickedBytes(picked);

      final weightRepo = InMemoryWeightRepository();
      final biteRepo = _FakeBiteRepository();
      final settingsRepo = InMemorySettingsRepository();
      final restored = await service.confirmAndRestore(
        weightRepo,
        biteRepo,
        bytes!,
        settingsRepo: settingsRepo,
        fileName: picked.name,
      );

      expect(restored, isTrue);
      expect(weightRepo.getAllWeights().single.value, 75.5);
      expect(biteRepo.bites.single.millisecondsSinceEpoch, 1000);
      expect(biteRepo.configs.single.b2S, 30);
      expect(settingsRepo.heightCm, 180);
    });

    test('declining the confirmation leaves every store untouched', () async {
      final service = SerializationService(
        fileSink: _RecordingBackupFileSink(),
      );
      final zip = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        const [],
        const [],
      );
      final bytes = await service.pickedBytes(_browserPick('backup.zip', zip));

      final weightRepo = InMemoryWeightRepository();
      await weightRepo.saveWeight(
        Weight(date: DateTime(2024, 1, 1), value: 80),
      );
      final settingsRepo = InMemorySettingsRepository(heightCm: 170);

      final restored = await service.confirmAndRestore(
        weightRepo,
        _FakeBiteRepository(),
        bytes!,
        settingsRepo: settingsRepo,
        fileName: 'backup.zip',
        onConfirm: (_) async => false,
      );

      expect(restored, isFalse);
      expect(weightRepo.getAllWeights().single.value, 80);
      expect(settingsRepo.heightCm, 170);
    });
  });
}

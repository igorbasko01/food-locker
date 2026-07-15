import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/bite_backup_codec.dart';
import 'package:food_locker/features/settings/data/pacing_config_backup_codec.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';

/// A repository that records the order of the mutations it receives, so tests
/// can assert on the clear-then-restore sequence rather than only the end state.
class _RecordingWeightRepository extends InMemoryWeightRepository {
  final List<String> operations = [];

  @override
  Future<void> clear() async {
    operations.add('clear');
    await super.clear();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    operations.add('save');
    await super.saveWeight(weight);
  }
}

/// Records the bite mutations a restore performs, so the clear-then-restore
/// sequence and dedup behaviour are assertable without a real Drift store. Only
/// the restore path's methods do anything; the rest aren't exercised here.
class _RecordingBiteRepository implements BiteRepository {
  final List<String> operations = [];
  final List<int> loggedMs = [];
  final List<String> configOperations = [];
  final List<PacingConfig> savedConfigs = [];

  @override
  Future<void> clearBites() async {
    operations.add('clear');
    loggedMs.clear();
  }

  @override
  Future<void> logBite(DateTime at) async {
    operations.add('log');
    loggedMs.add(at.millisecondsSinceEpoch);
  }

  @override
  Future<void> clearPacingConfigs() async {
    configOperations.add('clear');
    savedConfigs.clear();
  }

  @override
  Future<void> setPacingConfig(PacingConfig cfg) async {
    configOperations.add('set');
    savedConfigs.add(cfg);
  }

  @override
  Future<Bite?> lastBite() => throw UnimplementedError();

  @override
  Future<List<Bite>> bitesInRange(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<int> biteCount(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<List<DailyBiteCount>> dailyBiteCounts(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<PacingConfig?> pacingConfigAt(DateTime instant) =>
      throw UnimplementedError();

  @override
  Future<List<PacingConfig>> allPacingConfigs() => throw UnimplementedError();
}

void main() {
  group('SerializationService Zip File Name', () {
    test('generateZipFileName creates timestamped filename', () {
      final timestamp = DateTime(2026, 3, 7, 21, 59, 30);
      final fileName = SerializationService.generateZipFileName(timestamp);
      expect(fileName, 'food_locker_20260307215930.zip');
    });

    test('generateZipFileName pads single digit values', () {
      final timestamp = DateTime(2026, 1, 5, 3, 2, 1);
      final fileName = SerializationService.generateZipFileName(timestamp);
      expect(fileName, 'food_locker_20260105030201.zip');
    });
  });

  group('SerializationService encodeBackup', () {
    final service = SerializationService();

    List<int> contentOf(Archive archive, String name) =>
        archive.files.firstWhere((f) => f.name == name).content as List<int>;

    test('packs all three datasets into one zip, one file each', () {
      final zip = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        [const Bite(id: 1, atMs: 1000)],
        [const PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30)],
      );

      final archive = ZipDecoder().decodeBytes(zip);
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, containsAll([
        WeightBackupCodec.weightFileName,
        BiteBackupCodec.biteFileName,
        PacingConfigBackupCodec.pacingConfigFileName,
      ]));
    });

    test('the weight entry stays decodable by WeightBackupCodec', () {
      // Backward compatibility: adding the bite CSV must not disturb the
      // weight restore path, which reads weight.csv out of the same zip.
      final zip = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        [const Bite(id: 1, atMs: 1000)],
        const [],
      );

      final weights = const WeightBackupCodec().decode(zip);
      expect(weights.single.value, 75.5);
    });

    test('the bite entry holds the exported at_ms values', () {
      final zip = service.encodeBackup(
        const [],
        [const Bite(id: 1, atMs: 1000), const Bite(id: 2, atMs: 31000)],
        const [],
      );

      final archive = ZipDecoder().decodeBytes(zip);
      final csv = String.fromCharCodes(
        contentOf(archive, BiteBackupCodec.biteFileName),
      );
      expect(csv, contains('1000'));
      expect(csv, contains('31000'));
    });

    test('the pacing-config entry holds the exported version values', () {
      final zip = service.encodeBackup(
        const [],
        const [],
        [
          const PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30),
          const PacingConfig(id: 2, effectiveMs: 5000, b1S: 10, b2S: 20),
        ],
      );

      final archive = ZipDecoder().decodeBytes(zip);
      final csv = String.fromCharCodes(
        contentOf(archive, PacingConfigBackupCodec.pacingConfigFileName),
      );
      expect(csv, contains('effective_ms'));
      expect(csv, contains('5000'));
      expect(csv, contains('10'));
      expect(csv, contains('20'));
    });
  });

  group('SerializationService restoreFromBackup', () {
    const codec = WeightBackupCodec();
    final service = SerializationService();

    test('replaces existing weights with the backup contents', () async {
      final repo = InMemoryWeightRepository();
      await repo.saveWeight(Weight(date: DateTime(2020, 1, 1), value: 99.9));

      final backup = codec.encode([
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
        Weight(date: DateTime(2023, 10, 28), value: 75.0),
      ]);

      await service.restoreFromBackup(repo, _RecordingBiteRepository(), backup);

      final restored = repo.getAllWeights();
      expect(restored.map((w) => w.value), containsAll([75.5, 75.0]));
      // The pre-existing weight is gone: the restore is a replace, not a merge.
      expect(restored.any((w) => w.value == 99.9), isFalse);
      expect(restored, hasLength(2));
    });

    test('clears before restoring any weight', () async {
      final repo = _RecordingWeightRepository();
      await repo.saveWeight(Weight(date: DateTime(2020, 1, 1), value: 99.9));
      repo.operations.clear(); // ignore the setup save

      final backup = codec.encode([
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
        Weight(date: DateTime(2023, 10, 28), value: 75.0),
      ]);

      await service.restoreFromBackup(repo, _RecordingBiteRepository(), backup);

      // clear must come first, then one save per restored weight.
      expect(repo.operations, ['clear', 'save', 'save']);
    });

    test('an empty backup clears all existing weights', () async {
      final repo = InMemoryWeightRepository();
      await repo.saveWeight(Weight(date: DateTime(2020, 1, 1), value: 99.9));

      await service.restoreFromBackup(
        repo,
        _RecordingBiteRepository(),
        codec.encode([]),
      );

      expect(repo.getAllWeights(), isEmpty);
    });

    test('restores bites from a two-store backup, clearing first', () async {
      final biteRepo = _RecordingBiteRepository();
      final backup = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        [const Bite(id: 1, atMs: 1000), const Bite(id: 2, atMs: 31000)],
        const [],
      );

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      // clear must come first, then one log per restored bite.
      expect(biteRepo.operations, ['clear', 'log', 'log']);
      expect(biteRepo.loggedMs, [1000, 31000]);
    });

    test('dedupes repeated bite instants on import', () async {
      final biteRepo = _RecordingBiteRepository();
      // Two rows share an at_ms — a re-import artifact; only one bite survives.
      final backup = service.encodeBackup(
        const [],
        [const Bite(id: 1, atMs: 1000), const Bite(id: 2, atMs: 1000)],
        const [],
      );

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      expect(biteRepo.loggedMs, [1000]);
    });

    test('a present-but-empty bite entry clears existing bites', () async {
      final biteRepo = _RecordingBiteRepository();
      final backup = service.encodeBackup(
        [Weight(date: DateTime(2023, 10, 27), value: 75.5)],
        const [],
        const [],
      );

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      // The bite log is a real (empty) snapshot: cleared, nothing logged.
      expect(biteRepo.operations, ['clear']);
    });

    test('leaves bites untouched for a weight-only (pre-bite) backup', () async {
      final biteRepo = _RecordingBiteRepository();
      // A legacy zip with no bites.csv must not wipe the existing bite log.
      final backup = codec.encode([
        Weight(date: DateTime(2023, 10, 27), value: 75.5),
      ]);

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      expect(biteRepo.operations, isEmpty);
      // The config history rides on the bite backup's absence too: no entry.
      expect(biteRepo.configOperations, isEmpty);
    });

    test('restores pacing config from a backup, clearing first', () async {
      final biteRepo = _RecordingBiteRepository();
      final backup = service.encodeBackup(
        const [],
        const [],
        [
          const PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30),
          const PacingConfig(id: 2, effectiveMs: 5000, b1S: 10, b2S: 20),
        ],
      );

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      // clear must come first, then one set per restored version.
      expect(biteRepo.configOperations, ['clear', 'set', 'set']);
      expect(
        biteRepo.savedConfigs.map((c) => c.effectiveMs),
        [0, 5000],
      );
      expect(biteRepo.savedConfigs.map((c) => c.b2S), [30, 20]);
    });

    test('dedupes repeated config versions by effective instant', () async {
      final biteRepo = _RecordingBiteRepository();
      // Two rows share an effective_ms — only the first survives.
      final backup = service.encodeBackup(
        const [],
        const [],
        [
          const PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30),
          const PacingConfig(id: 2, effectiveMs: 0, b1S: 10, b2S: 20),
        ],
      );

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      expect(biteRepo.savedConfigs, hasLength(1));
      expect(biteRepo.savedConfigs.single.b2S, 30);
    });

    test('leaves pacing config untouched for a pre-config backup', () async {
      final biteRepo = _RecordingBiteRepository();
      // A weight+bite backup with no pacing_config.csv must not wipe the
      // seeded thresholds.
      final archive = Archive()
        ..addFile(
          const WeightBackupCodec().toArchiveFile([
            Weight(date: DateTime(2023, 10, 27), value: 75.5),
          ]),
        )
        ..addFile(const BiteBackupCodec().toArchiveFile([]));
      final backup = ZipEncoder().encode(archive);

      await service.restoreFromBackup(
        InMemoryWeightRepository(),
        biteRepo,
        backup,
      );

      expect(biteRepo.configOperations, isEmpty);
    });
  });
}

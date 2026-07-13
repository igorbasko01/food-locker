import 'package:flutter_test/flutter_test.dart';
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

      await service.restoreFromBackup(repo, backup);

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

      await service.restoreFromBackup(repo, backup);

      // clear must come first, then one save per restored weight.
      expect(repo.operations, ['clear', 'save', 'save']);
    });

    test('an empty backup clears all existing weights', () async {
      final repo = InMemoryWeightRepository();
      await repo.saveWeight(Weight(date: DateTime(2020, 1, 1), value: 99.9));

      await service.restoreFromBackup(repo, codec.encode([]));

      expect(repo.getAllWeights(), isEmpty);
    });
  });
}

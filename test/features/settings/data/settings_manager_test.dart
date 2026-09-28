import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/settings/data/storage_persistence.dart';
import 'package:food_locker/features/settings/data/storage_persistence_io.dart';

/// Answers every request with [granted] and counts how often it was asked.
class _FakeStoragePersistence implements StoragePersistence {
  _FakeStoragePersistence({required this.granted});

  final bool granted;
  int requests = 0;

  StoragePersistenceState get _state => granted
      ? StoragePersistenceState.persisted
      : StoragePersistenceState.notPersisted;

  @override
  Future<StoragePersistenceState> current() async => _state;

  @override
  Future<StoragePersistenceState> request() async {
    requests++;
    return _state;
  }
}

void main() {
  test('an unanswered height reads as null, with no default standing in for it',
      () {
    final manager = SettingsManager(InMemorySettingsRepository());

    expect(manager.heightCm, isNull);
    expect(manager.measurementSystem, MeasurementSystem.metric);
  });

  test('a stored height is written through and announced', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.setHeightCm(178.5);

    expect(repository.heightCm, 178.5);
    expect(manager.heightCm, 178.5);
    expect(notifications, 1);
  });

  test('null clears the height back to unanswered', () async {
    final repository = InMemorySettingsRepository(heightCm: 178.5);
    final manager = SettingsManager(repository);

    await manager.setHeightCm(null);

    expect(repository.heightCm, isNull);
    expect(manager.heightCm, isNull);
  });

  test('the measurement system is written through and announced', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.setMeasurementSystem(MeasurementSystem.imperial);

    expect(repository.measurementSystem, MeasurementSystem.imperial);
    expect(manager.measurementSystem, MeasurementSystem.imperial);
    expect(notifications, 1);
  });

  test('refresh announces a height written behind the manager', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    // Stands in for a restore, which writes through the repository.
    await repository.setHeightCm(180);
    await manager.refresh();

    expect(manager.heightCm, 180);
    expect(notifications, 1);
  });

  group('storage persistence', () {
    test('the first run asks the browser and records the answer', () async {
      final repository = InMemorySettingsRepository();
      final persistence = _FakeStoragePersistence(granted: false);
      final manager = SettingsManager(
        repository,
        storagePersistence: persistence,
      );
      var notifications = 0;
      manager.addListener(() => notifications++);

      await manager.initializeStoragePersistence();

      expect(persistence.requests, 1);
      expect(repository.storagePersistenceGranted, isFalse);
      expect(manager.storagePersistence, StoragePersistenceState.notPersisted);
      expect(notifications, 1);
    });

    test('a later run reads the grant back without asking again', () async {
      final persistence = _FakeStoragePersistence(granted: false);
      final manager = SettingsManager(
        InMemorySettingsRepository(storagePersistenceGranted: false),
        storagePersistence: persistence,
      );

      await manager.initializeStoragePersistence();

      expect(persistence.requests, 0);
      expect(manager.storagePersistence, StoragePersistenceState.notPersisted);
    });

    test('a grant given since the last run is picked up', () async {
      final manager = SettingsManager(
        InMemorySettingsRepository(storagePersistenceGranted: false),
        storagePersistence: _FakeStoragePersistence(granted: true),
      );

      await manager.initializeStoragePersistence();

      expect(manager.storagePersistence, StoragePersistenceState.persisted);
    });

    test('asking again records the new answer', () async {
      final repository = InMemorySettingsRepository(
        storagePersistenceGranted: false,
      );
      final persistence = _FakeStoragePersistence(granted: true);
      final manager = SettingsManager(
        repository,
        storagePersistence: persistence,
      );

      await manager.requestStoragePersistence();

      expect(persistence.requests, 1);
      expect(repository.storagePersistenceGranted, isTrue);
      expect(manager.storagePersistence, StoragePersistenceState.persisted);
    });

    test('a native build records nothing and stays not applicable', () async {
      final repository = InMemorySettingsRepository();
      final manager = SettingsManager(
        repository,
        storagePersistence: const NativeStoragePersistence(),
      );

      await manager.initializeStoragePersistence();

      expect(repository.storagePersistenceGranted, isNull);
      expect(manager.storagePersistence, StoragePersistenceState.notApplicable);
    });

    test('the VM build gets the native seam', () async {
      expect(
        await createStoragePersistence().request(),
        StoragePersistenceState.notApplicable,
      );
    });
  });
}

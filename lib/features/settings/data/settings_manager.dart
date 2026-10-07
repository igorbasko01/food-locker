import 'package:flutter/foundation.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/settings/data/storage_persistence.dart';

/// The UI-facing state holder for the profile preferences. Every mutation
/// writes through the repository and then notifies; reads come straight back
/// off the repository, so the two never drift.
class SettingsManager extends ChangeNotifier {
  final SettingsRepository _repository;
  final StoragePersistence _storagePersistence;
  StoragePersistenceState _storagePersistenceState =
      StoragePersistenceState.notApplicable;

  SettingsManager(
    this._repository, {
    StoragePersistence? storagePersistence,
  }) : _storagePersistence = storagePersistence ?? createStoragePersistence();

  double? get heightCm => _repository.heightCm;

  MeasurementSystem get measurementSystem => _repository.measurementSystem;

  StoragePersistenceState get storagePersistence => _storagePersistenceState;

  Future<void> setHeightCm(double? centimetres) async {
    await _repository.setHeightCm(centimetres);
    notifyListeners();
  }

  Future<void> setMeasurementSystem(MeasurementSystem system) async {
    await _repository.setMeasurementSystem(system);
    notifyListeners();
  }

  /// Asks the browser for persistence on the first run only; later runs just
  /// read the grant back, so a denial is not re-asked on every load.
  Future<void> initializeStoragePersistence() async {
    if (_repository.storagePersistenceGranted == null) {
      await requestStoragePersistence();
      return;
    }
    await _record(await _storagePersistence.current());
  }

  Future<void> requestStoragePersistence() async {
    await _record(await _storagePersistence.request());
  }

  Future<void> _record(StoragePersistenceState state) async {
    if (state != StoragePersistenceState.notApplicable) {
      await _repository.setStoragePersistenceGranted(
        state == StoragePersistenceState.persisted,
      );
    }
    _storagePersistenceState = state;
    notifyListeners();
  }

  /// For callers that wrote through the repository without going through this
  /// manager — a backup restore or a clear.
  Future<void> refresh() async {
    notifyListeners();
  }
}

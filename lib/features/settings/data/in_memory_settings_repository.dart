import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  double? _heightCm;
  MeasurementSystem _measurementSystem;
  bool? _storagePersistenceGranted;

  InMemorySettingsRepository({
    double? heightCm,
    MeasurementSystem measurementSystem = MeasurementSystem.metric,
    bool? storagePersistenceGranted,
  })  : _heightCm = heightCm,
        _measurementSystem = measurementSystem,
        _storagePersistenceGranted = storagePersistenceGranted;

  @override
  double? get heightCm => _heightCm;

  @override
  Future<void> setHeightCm(double? centimetres) async {
    _heightCm = centimetres;
  }

  @override
  MeasurementSystem get measurementSystem => _measurementSystem;

  @override
  Future<void> setMeasurementSystem(MeasurementSystem system) async {
    _measurementSystem = system;
  }

  @override
  bool? get storagePersistenceGranted => _storagePersistenceGranted;

  @override
  Future<void> setStoragePersistenceGranted(bool granted) async {
    _storagePersistenceGranted = granted;
  }
}

import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  double? _heightCm;
  MeasurementSystem _measurementSystem;

  InMemorySettingsRepository({
    double? heightCm,
    MeasurementSystem measurementSystem = MeasurementSystem.metric,
  })  : _heightCm = heightCm,
        _measurementSystem = measurementSystem;

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
}

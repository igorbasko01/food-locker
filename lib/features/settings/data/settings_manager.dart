import 'package:flutter/foundation.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';

/// The UI-facing state holder for the profile preferences. Every mutation
/// writes through the repository and then notifies; reads come straight back
/// off the repository, so the two never drift.
class SettingsManager extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsManager(this._repository);

  double? get heightCm => _repository.heightCm;

  MeasurementSystem get measurementSystem => _repository.measurementSystem;

  Future<void> setHeightCm(double? centimetres) async {
    await _repository.setHeightCm(centimetres);
    notifyListeners();
  }

  Future<void> setMeasurementSystem(MeasurementSystem system) async {
    await _repository.setMeasurementSystem(system);
    notifyListeners();
  }

  /// For callers that wrote through the repository without going through this
  /// manager — a backup restore or a clear.
  Future<void> refresh() async {
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';

/// The UI-facing state holder for the preferences. Every mutation writes
/// through the repository and then notifies; reads come straight back off the
/// repository, so the two never drift.
class SettingsManager extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsManager(this._repository);

  WeightUnit get weightUnit => _repository.weightUnit;

  Future<void> setWeightUnit(WeightUnit unit) async {
    if (unit == _repository.weightUnit) return;
    await _repository.setWeightUnit(unit);
    notifyListeners();
  }
}

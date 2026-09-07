import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class InMemorySettingsRepository implements SettingsRepository {
  WeightUnit _weightUnit;

  InMemorySettingsRepository({WeightUnit weightUnit = WeightUnit.kilograms})
    : _weightUnit = weightUnit;

  @override
  WeightUnit get weightUnit => _weightUnit;

  @override
  Future<void> setWeightUnit(WeightUnit unit) async {
    _weightUnit = unit;
  }
}

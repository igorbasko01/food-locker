import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The production [SettingsRepository], on `shared_preferences`.
///
/// [open] loads the stored values once so every later read is synchronous; the
/// asynchronous store is only ever written to after that.
class PreferencesSettingsRepository implements SettingsRepository {
  static const String weightUnitKey = 'weight_unit';

  final SharedPreferences _preferences;
  WeightUnit _weightUnit;

  PreferencesSettingsRepository._(this._preferences, this._weightUnit);

  static Future<PreferencesSettingsRepository> open() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesSettingsRepository._(
      preferences,
      _readWeightUnit(preferences),
    );
  }

  /// Kilograms for a preference never set, and for one that names a unit this
  /// build no longer has — a stored string is not a guarantee.
  static WeightUnit _readWeightUnit(SharedPreferences preferences) {
    final stored = preferences.getString(weightUnitKey);
    if (stored == null) return WeightUnit.kilograms;
    try {
      return WeightUnit.values.byName(stored);
    } on ArgumentError {
      return WeightUnit.kilograms;
    }
  }

  @override
  WeightUnit get weightUnit => _weightUnit;

  /// The store is written first: a write that fails leaves the preference
  /// unchanged rather than holding a value that is gone by the next launch.
  @override
  Future<void> setWeightUnit(WeightUnit unit) async {
    await _preferences.setString(weightUnitKey, unit.name);
    _weightUnit = unit;
  }
}

import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The production [SettingsRepository], on `shared_preferences`. The instance
/// is loaded once at startup, which is what lets the getters stay synchronous.
class PreferencesSettingsRepository implements SettingsRepository {
  static const String heightKey = 'height_cm';
  static const String measurementSystemKey = 'measurement_system';

  final SharedPreferences _preferences;

  PreferencesSettingsRepository(this._preferences);

  @override
  double? get heightCm => _preferences.getDouble(heightKey);

  @override
  Future<void> setHeightCm(double? centimetres) async {
    if (centimetres == null) {
      await _preferences.remove(heightKey);
      return;
    }
    await _preferences.setDouble(heightKey, centimetres);
  }

  /// Anything unrecognised — nothing stored yet, or a name from a build that
  /// knew more systems — reads as metric rather than throwing.
  @override
  MeasurementSystem get measurementSystem {
    final stored = _preferences.getString(measurementSystemKey);
    return MeasurementSystem.values.firstWhere(
      (system) => system.name == stored,
      orElse: () => MeasurementSystem.metric,
    );
  }

  @override
  Future<void> setMeasurementSystem(MeasurementSystem system) async {
    await _preferences.setString(measurementSystemKey, system.name);
  }
}

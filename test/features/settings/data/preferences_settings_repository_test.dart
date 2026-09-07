import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/preferences_settings_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = PreferencesSettingsRepository.weightUnitKey;

  test('an unset preference reads as kilograms', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = await PreferencesSettingsRepository.open();

    expect(repository.weightUnit, WeightUnit.kilograms);
  });

  test('a stored preference survives a reopen', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = await PreferencesSettingsRepository.open();
    await repository.setWeightUnit(WeightUnit.pounds);

    final reopened = await PreferencesSettingsRepository.open();
    expect(reopened.weightUnit, WeightUnit.pounds);
  });

  test('a unit this build does not have reads as kilograms', () async {
    SharedPreferences.setMockInitialValues({key: 'stones'});

    final repository = await PreferencesSettingsRepository.open();

    expect(repository.weightUnit, WeightUnit.kilograms);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/preferences_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real persistence path for the profile preferences, on mocked
/// `shared_preferences` — the store the app ships with, unlike the in-memory
/// one the other tests lean on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesSettingsRepository> repositoryWith(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    return PreferencesSettingsRepository(await SharedPreferences.getInstance());
  }

  test('a fresh install has no height and shows metric', () async {
    final repository = await repositoryWith({});

    expect(repository.heightCm, isNull);
    expect(repository.measurementSystem, MeasurementSystem.metric);
  });

  test('a stored height is read back', () async {
    final repository = await repositoryWith({});

    await repository.setHeightCm(178.5);

    expect(repository.heightCm, 178.5);
  });

  test('null removes the key rather than storing a zero', () async {
    final repository = await repositoryWith({
      PreferencesSettingsRepository.heightKey: 178.5,
    });

    await repository.setHeightCm(null);

    expect(repository.heightCm, isNull);
  });

  test('the measurement system round-trips', () async {
    final repository = await repositoryWith({});

    await repository.setMeasurementSystem(MeasurementSystem.imperial);

    expect(repository.measurementSystem, MeasurementSystem.imperial);
  });

  test('an unrecognised stored system falls back to metric', () async {
    final repository = await repositoryWith({
      PreferencesSettingsRepository.measurementSystemKey: 'nautical',
    });

    expect(repository.measurementSystem, MeasurementSystem.metric);
  });
}

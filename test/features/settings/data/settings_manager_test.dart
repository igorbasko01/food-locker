import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';

void main() {
  test('an unanswered height reads as null, with no default standing in for it',
      () {
    final manager = SettingsManager(InMemorySettingsRepository());

    expect(manager.heightCm, isNull);
    expect(manager.measurementSystem, MeasurementSystem.metric);
  });

  test('a stored height is written through and announced', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.setHeightCm(178.5);

    expect(repository.heightCm, 178.5);
    expect(manager.heightCm, 178.5);
    expect(notifications, 1);
  });

  test('null clears the height back to unanswered', () async {
    final repository = InMemorySettingsRepository(heightCm: 178.5);
    final manager = SettingsManager(repository);

    await manager.setHeightCm(null);

    expect(repository.heightCm, isNull);
    expect(manager.heightCm, isNull);
  });

  test('the measurement system is written through and announced', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.setMeasurementSystem(MeasurementSystem.imperial);

    expect(repository.measurementSystem, MeasurementSystem.imperial);
    expect(manager.measurementSystem, MeasurementSystem.imperial);
    expect(notifications, 1);
  });

  test('refresh announces a height written behind the manager', () async {
    final repository = InMemorySettingsRepository();
    final manager = SettingsManager(repository);
    var notifications = 0;
    manager.addListener(() => notifications++);

    // Stands in for a restore, which writes through the repository.
    await repository.setHeightCm(180);
    await manager.refresh();

    expect(manager.heightCm, 180);
    expect(notifications, 1);
  });
}

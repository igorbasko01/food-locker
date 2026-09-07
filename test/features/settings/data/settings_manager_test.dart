import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  group('SettingsManager', () {
    test('starts on the repository value', () {
      final manager = SettingsManager(
        InMemorySettingsRepository(weightUnit: WeightUnit.pounds),
      );

      expect(manager.weightUnit, WeightUnit.pounds);
    });

    test('defaults to kilograms', () {
      expect(
        SettingsManager(InMemorySettingsRepository()).weightUnit,
        WeightUnit.kilograms,
      );
    });

    test('writes through and notifies on a change', () async {
      final repository = InMemorySettingsRepository();
      final manager = SettingsManager(repository);
      var notifications = 0;
      manager.addListener(() => notifications++);

      await manager.setWeightUnit(WeightUnit.pounds);

      expect(repository.weightUnit, WeightUnit.pounds);
      expect(manager.weightUnit, WeightUnit.pounds);
      expect(notifications, 1);
    });

    test('selecting the current unit notifies nobody', () async {
      final manager = SettingsManager(InMemorySettingsRepository());
      var notifications = 0;
      manager.addListener(() => notifications++);

      await manager.setWeightUnit(WeightUnit.kilograms);

      expect(notifications, 0);
    });
  });
}

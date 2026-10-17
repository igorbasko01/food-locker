import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/hive_weight_entry.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  test('an entry is stored as its metric figure with the kilograms unit', () {
    final entry = WeightEntry(
      date: DateTime(2026, 10, 14),
      weight: Weight(160, MeasurementSystem.imperial),
    );

    final stored = HiveWeightEntry.fromEntry(entry);

    expect(stored.date, DateTime(2026, 10, 14));
    expect(stored.kilograms, closeTo(72.5748, 1e-4));
    expect(stored.unit, WeightUnit.kilograms);
  });

  test('a stored row reads back as the same entry', () {
    final stored = HiveWeightEntry(
      date: DateTime(2026, 10, 14),
      kilograms: 89.4,
      unit: WeightUnit.pounds,
    );

    final entry = stored.toEntry();

    expect(entry.date, DateTime(2026, 10, 14));
    expect(entry.weight, Weight(89.4, MeasurementSystem.metric));
  });
}

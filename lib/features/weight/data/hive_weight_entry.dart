import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:hive_ce/hive.dart';

part 'hive_weight_entry.g.dart';

/// Legacy provenance on a stored weigh-in: always written as kilograms and
/// never read.
@HiveType(typeId: 3)
enum WeightUnit {
  @HiveField(0)
  kilograms,
  @HiveField(1)
  pounds,
}

/// A [WeightEntry] as the Hive box stores it. Only [PersistentWeightRepository]
/// and the box setup use this; everything else reads [WeightEntry].
@HiveType(typeId: 4)
class HiveWeightEntry {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double kilograms;

  @HiveField(2)
  final WeightUnit unit;

  HiveWeightEntry({
    required this.date,
    required this.kilograms,
    this.unit = WeightUnit.kilograms,
  });

  HiveWeightEntry.fromEntry(WeightEntry entry)
    : this(
        date: entry.date,
        kilograms: entry.weight.value(MeasurementSystem.metric),
      );

  WeightEntry toEntry() => WeightEntry(
    date: date,
    weight: Weight(kilograms, MeasurementSystem.metric),
  );
}

import 'package:food_locker/core/weight_units.dart';
import 'package:hive_ce/hive.dart';

part 'weight.g.dart';

@HiveType(typeId: 3)
enum WeightUnit {
  @HiveField(0)
  kilograms,
  @HiveField(1)
  pounds,
}

@HiveType(typeId: 4)
class Weight {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final double value;
  
  @HiveField(2)
  final WeightUnit unit;

  Weight({
    required this.date,
    required this.value,
    this.unit = WeightUnit.kilograms,
  });
}

extension WeightUnitDisplay on WeightUnit {
  String get symbol => this == WeightUnit.pounds ? 'lbs' : 'kg';

  /// A stored weight as this unit reads it. Everything is stored and computed
  /// in kilograms, so this is the only step between the store and the screen.
  double fromKilograms(double kilograms) =>
      this == WeightUnit.pounds ? kilogramsToPounds(kilograms) : kilograms;

  /// A figure typed in this unit, back in kilograms for storage.
  double toKilograms(double value) =>
      this == WeightUnit.pounds ? poundsToKilograms(value) : value;

  /// [kilograms] as it appears on screen: `72.6 kg`, `160.0 lbs`.
  String format(double kilograms) =>
      '${fromKilograms(kilograms).toStringAsFixed(1)} $symbol';
}


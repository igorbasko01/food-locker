import 'package:hive/hive.dart';

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
}


// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_weight_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveWeightEntryAdapter extends TypeAdapter<HiveWeightEntry> {
  @override
  final typeId = 4;

  @override
  HiveWeightEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWeightEntry(
      date: fields[0] as DateTime,
      kilograms: (fields[1] as num).toDouble(),
      unit: fields[2] == null ? WeightUnit.kilograms : fields[2] as WeightUnit,
    );
  }

  @override
  void write(BinaryWriter writer, HiveWeightEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.kilograms)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveWeightEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeightUnitAdapter extends TypeAdapter<WeightUnit> {
  @override
  final typeId = 3;

  @override
  WeightUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeightUnit.kilograms;
      case 1:
        return WeightUnit.pounds;
      default:
        return WeightUnit.kilograms;
    }
  }

  @override
  void write(BinaryWriter writer, WeightUnit obj) {
    switch (obj) {
      case WeightUnit.kilograms:
        writer.writeByte(0);
      case WeightUnit.pounds:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

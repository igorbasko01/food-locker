// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeightAdapter extends TypeAdapter<Weight> {
  @override
  final int typeId = 4;

  @override
  Weight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Weight(
      date: fields[0] as DateTime,
      value: fields[1] as double,
      unit: fields[2] as WeightUnit,
    );
  }

  @override
  void write(BinaryWriter writer, Weight obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeightUnitAdapter extends TypeAdapter<WeightUnit> {
  @override
  final int typeId = 3;

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
        break;
      case WeightUnit.pounds:
        writer.writeByte(1);
        break;
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

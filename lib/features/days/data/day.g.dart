// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodDayAdapter extends TypeAdapter<FoodDay> {
  @override
  final int typeId = 1;

  @override
  FoodDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodDay(
      date: fields[0] as DateTime,
      meals: (fields[1] as List).cast<Food>(),
      snacks: (fields[2] as List).cast<Food>(),
    ).._overate = fields[3] as bool?;
  }

  @override
  void write(BinaryWriter writer, FoodDay obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.meals)
      ..writeByte(2)
      ..write(obj.snacks)
      ..writeByte(3)
      ..write(obj._overate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

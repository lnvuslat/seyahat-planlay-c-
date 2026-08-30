// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_badge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CityBadgeAdapter extends TypeAdapter<CityBadge> {
  @override
  final int typeId = 4;

  @override
  CityBadge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CityBadge(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      isUnlocked: fields[4] as bool,
      unlockedAt: fields[5] as DateTime?,
      memories: (fields[6] as HiveList?)?.castHiveList(),
    );
  }

  @override
  void write(BinaryWriter writer, CityBadge obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.isUnlocked)
      ..writeByte(5)
      ..write(obj.unlockedAt)
      ..writeByte(6)
      ..write(obj.memories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityBadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

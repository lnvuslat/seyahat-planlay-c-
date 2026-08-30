// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoryItemAdapter extends TypeAdapter<MemoryItem> {
  @override
  final int typeId = 5;

  @override
  MemoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryItem(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
      note: fields[3] as String,
      categoryIcon: fields[4] as String,
      imagePath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MemoryItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.categoryIcon)
      ..writeByte(5)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

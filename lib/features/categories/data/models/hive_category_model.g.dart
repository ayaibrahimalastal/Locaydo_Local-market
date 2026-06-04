// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveCategoryModelAdapter extends TypeAdapter<HiveCategoryModel> {
  @override
  final int typeId = 1;

  @override
  HiveCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      nameEn: fields[2] as String,
      iconPath: fields[3] as String,
      order: fields[4] as int,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameEn)
      ..writeByte(3)
      ..write(obj.iconPath)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

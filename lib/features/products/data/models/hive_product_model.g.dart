// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveProductModelAdapter extends TypeAdapter<HiveProductModel> {
  @override
  final int typeId = 0;

  @override
  HiveProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveProductModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      currency: fields[4] as String,
      location: fields[5] as String,
      imageUrl: fields[6] as String,
      additionalImages: (fields[7] as List).cast<String>(),
      category: fields[8] as String,
      condition: fields[9] as String,
      paymentMethods: (fields[10] as List).cast<String>(),
      sellerId: fields[11] as String,
      sellerName: fields[12] as String,
      createdAt: fields[13] as DateTime,
      status: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveProductModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.additionalImages)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.condition)
      ..writeByte(10)
      ..write(obj.paymentMethods)
      ..writeByte(11)
      ..write(obj.sellerId)
      ..writeByte(12)
      ..write(obj.sellerName)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

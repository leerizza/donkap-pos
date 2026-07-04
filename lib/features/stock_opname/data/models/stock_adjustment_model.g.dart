// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_adjustment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdjustmentModelAdapter extends TypeAdapter<StockAdjustmentModel> {
  @override
  final int typeId = 4;

  @override
  StockAdjustmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockAdjustmentModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      previousStock: fields[3] as int,
      newStock: fields[4] as int,
      reasonRaw: fields[5] as String,
      note: fields[6] as String,
      createdAtMs: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StockAdjustmentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.previousStock)
      ..writeByte(4)
      ..write(obj.newStock)
      ..writeByte(5)
      ..write(obj.reasonRaw)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdjustmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

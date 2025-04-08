// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_fence_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeoFenceLocationAdapter extends TypeAdapter<GeoFenceLocation> {
  @override
  final int typeId = 2;

  @override
  GeoFenceLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeoFenceLocation(
      name: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, GeoFenceLocation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoFenceLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

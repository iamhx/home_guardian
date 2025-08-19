// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CameraAdapter extends TypeAdapter<Camera> {
  @override
  final int typeId = 0;

  @override
  Camera read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Camera(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      description: fields[3] as String?,
      status: fields[4] as CameraStatus,
      lastChecked: fields[5] as DateTime,
      dateAdded: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Camera obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.lastChecked)
      ..writeByte(6)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CameraStatusAdapter extends TypeAdapter<CameraStatus> {
  @override
  final int typeId = 1;

  @override
  CameraStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CameraStatus.online;
      case 1:
        return CameraStatus.offline;
      case 2:
        return CameraStatus.checking;
      default:
        return CameraStatus.online;
    }
  }

  @override
  void write(BinaryWriter writer, CameraStatus obj) {
    switch (obj) {
      case CameraStatus.online:
        writer.writeByte(0);
        break;
      case CameraStatus.offline:
        writer.writeByte(1);
        break;
      case CameraStatus.checking:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

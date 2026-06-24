// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_detail_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaDetailCacheAdapter extends TypeAdapter<MediaDetailCache> {
  @override
  final typeId = 1;

  @override
  MediaDetailCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaDetailCache(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[7] as String,
      fields[8] as DateTime,
      title: fields[3] as String?,
      year: fields[4] as String?,
      typeName: fields[5] as String?,
      session: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaDetailCache obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.server)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.typeName)
      ..writeByte(6)
      ..write(obj.session)
      ..writeByte(7)
      ..write(obj.payload)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaDetailCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

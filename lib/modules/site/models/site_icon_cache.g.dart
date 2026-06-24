// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_icon_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteIconCacheAdapter extends TypeAdapter<SiteIconCache> {
  @override
  final typeId = 5;

  @override
  SiteIconCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteIconCache(fields[0] as String, fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, SiteIconCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.iconBase64);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteIconCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

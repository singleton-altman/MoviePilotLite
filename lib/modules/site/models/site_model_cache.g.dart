// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_model_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteModelCacheAdapter extends TypeAdapter<SiteModelCache> {
  @override
  final typeId = 6;

  @override
  SiteModelCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteModelCache(
      (fields[0] as num).toInt(),
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      (fields[4] as num).toInt(),
      fields[5] as String,
      fields[6] as String,
      fields[7] as String,
      fields[8] as String,
      fields[9] as String,
      (fields[10] as num).toInt(),
      fields[11] as String,
      (fields[12] as num).toInt(),
      (fields[13] as num).toInt(),
      fields[14] as String,
      (fields[15] as num).toInt(),
      (fields[16] as num).toInt(),
      (fields[17] as num).toInt(),
      (fields[18] as num).toInt(),
      fields[19] as bool,
      fields[20] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SiteModelCache obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.domain)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.pri)
      ..writeByte(5)
      ..write(obj.rss)
      ..writeByte(6)
      ..write(obj.cookie)
      ..writeByte(7)
      ..write(obj.ua)
      ..writeByte(8)
      ..write(obj.apikey)
      ..writeByte(9)
      ..write(obj.token)
      ..writeByte(10)
      ..write(obj.proxy)
      ..writeByte(11)
      ..write(obj.filter)
      ..writeByte(12)
      ..write(obj.render)
      ..writeByte(13)
      ..write(obj.public)
      ..writeByte(14)
      ..write(obj.note)
      ..writeByte(15)
      ..write(obj.timeout)
      ..writeByte(16)
      ..write(obj.limitInterval)
      ..writeByte(17)
      ..write(obj.limitCount)
      ..writeByte(18)
      ..write(obj.limitSeconds)
      ..writeByte(19)
      ..write(obj.isActive)
      ..writeByte(20)
      ..write(obj.downloader);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModelCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

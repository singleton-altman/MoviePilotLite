// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_userdata_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteUserDataCacheAdapter extends TypeAdapter<SiteUserDataCache> {
  @override
  final typeId = 7;

  @override
  SiteUserDataCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteUserDataCache(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      (fields[5] as num).toDouble(),
      (fields[6] as num).toInt(),
      (fields[7] as num).toInt(),
      (fields[8] as num).toDouble(),
      (fields[9] as num).toInt(),
      (fields[10] as num).toInt(),
      (fields[11] as num).toInt(),
      (fields[12] as num).toInt(),
      (fields[13] as num).toInt(),
      fields[14] as String,
      fields[15] as String,
      fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SiteUserDataCache obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.domain)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.userid)
      ..writeByte(3)
      ..write(obj.userLevel)
      ..writeByte(4)
      ..write(obj.joinAt)
      ..writeByte(5)
      ..write(obj.bonus)
      ..writeByte(6)
      ..write(obj.upload)
      ..writeByte(7)
      ..write(obj.download)
      ..writeByte(8)
      ..write(obj.ratio)
      ..writeByte(9)
      ..write(obj.seeding)
      ..writeByte(10)
      ..write(obj.leeching)
      ..writeByte(11)
      ..write(obj.seedingSize)
      ..writeByte(12)
      ..write(obj.leechingSize)
      ..writeByte(13)
      ..write(obj.messageUnread)
      ..writeByte(14)
      ..write(obj.errMsg)
      ..writeByte(15)
      ..write(obj.updatedDay)
      ..writeByte(16)
      ..write(obj.updatedTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteUserDataCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

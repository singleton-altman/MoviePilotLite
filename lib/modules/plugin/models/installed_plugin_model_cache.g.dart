// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_plugin_model_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstalledPluginModelCacheAdapter
    extends TypeAdapter<InstalledPluginModelCache> {
  @override
  final typeId = 3;

  @override
  InstalledPluginModelCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstalledPluginModelCache(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      fields[5] as String,
      fields[6] as String,
      fields[7] as String,
      fields[8] as String,
      (fields[9] as num).toInt(),
      (fields[10] as num).toInt(),
      fields[11] as bool,
      fields[12] as bool,
      fields[13] as bool,
      fields[14] as bool,
      fields[15] as bool,
      fields[16] as String,
      (fields[17] as num).toInt(),
      (fields[18] as num).toInt(),
      fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstalledPluginModelCache obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pluginName)
      ..writeByte(2)
      ..write(obj.pluginDesc)
      ..writeByte(3)
      ..write(obj.pluginIcon)
      ..writeByte(4)
      ..write(obj.pluginVersion)
      ..writeByte(5)
      ..write(obj.pluginLabel)
      ..writeByte(6)
      ..write(obj.pluginAuthor)
      ..writeByte(7)
      ..write(obj.authorUrl)
      ..writeByte(8)
      ..write(obj.pluginConfigPrefix)
      ..writeByte(9)
      ..write(obj.pluginOrder)
      ..writeByte(10)
      ..write(obj.authLevel)
      ..writeByte(11)
      ..write(obj.installed)
      ..writeByte(12)
      ..write(obj.state)
      ..writeByte(13)
      ..write(obj.hasPage)
      ..writeByte(14)
      ..write(obj.hasUpdate)
      ..writeByte(15)
      ..write(obj.isLocal)
      ..writeByte(16)
      ..write(obj.repoUrl)
      ..writeByte(17)
      ..write(obj.installCount)
      ..writeByte(18)
      ..write(obj.addTime)
      ..writeByte(19)
      ..write(obj.pluginPublicKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstalledPluginModelCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

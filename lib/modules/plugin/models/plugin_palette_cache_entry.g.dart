// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_palette_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PluginPaletteCacheEntryAdapter
    extends TypeAdapter<PluginPaletteCacheEntry> {
  @override
  final typeId = 4;

  @override
  PluginPaletteCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PluginPaletteCacheEntry(
      fields[0] as String,
      (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PluginPaletteCacheEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginPaletteCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

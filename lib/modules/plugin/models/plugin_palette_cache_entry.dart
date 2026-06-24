import 'package:hive_ce/hive.dart';

part 'plugin_palette_cache_entry.g.dart';

@HiveType(typeId: 4)
class PluginPaletteCacheEntry {
  @HiveField(0)
  String url;

  @HiveField(1)
  int colorValue;

  PluginPaletteCacheEntry(this.url, this.colorValue);
}

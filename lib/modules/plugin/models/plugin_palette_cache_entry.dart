import 'package:realm/realm.dart';

part 'plugin_palette_cache_entry.realm.dart';

@RealmModel()
class _PluginPaletteCacheEntry {
  @PrimaryKey()
  late String url;
  late int colorValue;
}

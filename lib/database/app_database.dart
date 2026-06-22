import 'package:drift/drift.dart';

import 'daos/login_profile_dao.dart';
import 'daos/media_detail_cache_dao.dart';
import 'daos/plugin_cache_dao.dart';
import 'daos/plugin_palette_dao.dart';
import 'daos/search_history_dao.dart';
import 'daos/site_cache_dao.dart';
import 'tables/installed_plugin_caches.dart';
import 'tables/login_profiles.dart';
import 'tables/media_detail_caches.dart';
import 'tables/plugin_model_caches.dart';
import 'tables/plugin_palette_entries.dart';
import 'tables/search_history_entries.dart';
import 'tables/site_icon_caches.dart';
import 'tables/site_model_caches.dart';
import 'tables/site_userdata_caches.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LoginProfiles,
    MediaDetailCaches,
    PluginModelCaches,
    InstalledPluginModelCaches,
    PluginPaletteEntries,
    SiteIconCaches,
    SiteModelCaches,
    SiteUserDataCaches,
    SearchHistoryEntries,
  ],
  daos: [
    LoginProfileDao,
    MediaDetailCacheDao,
    PluginCacheDao,
    PluginPaletteDao,
    SiteCacheDao,
    SearchHistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

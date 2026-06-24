import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../modules/login/models/login_profile.dart';
import '../modules/media_detail/models/media_detail_cache.dart';
import '../modules/plugin/models/installed_plugin_model_cache.dart';
import '../modules/plugin/models/plugin_model_cache.dart';
import '../modules/plugin/models/plugin_palette_cache_entry.dart';
import '../modules/search/models/search_history.dart';
import '../modules/site/models/site_icon_cache.dart';
import '../modules/site/models/site_model_cache.dart';
import '../modules/site/models/site_userdata_cache.dart';

class HiveService extends GetxService {
  late final Box<LoginProfile> loginProfileBox;
  late final Box<MediaDetailCache> mediaDetailCacheBox;
  late final Box<PluginModelCache> pluginModelCacheBox;
  late final Box<InstalledPluginModelCache> installedPluginModelCacheBox;
  late final Box<PluginPaletteCacheEntry> pluginPaletteCacheBox;
  late final Box<SiteIconCache> siteIconCacheBox;
  late final Box<SiteModelCache> siteModelCacheBox;
  late final Box<SiteUserDataCache> siteUserDataCacheBox;
  late final Box<SearchHistoryEntry> searchHistoryBox;

  Future<HiveService> init() async {
    await Hive.initFlutter();

    // Register adapters (only if not already registered)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LoginProfileAdapter());
      Hive.registerAdapter(MediaDetailCacheAdapter());
      Hive.registerAdapter(PluginModelCacheAdapter());
      Hive.registerAdapter(InstalledPluginModelCacheAdapter());
      Hive.registerAdapter(PluginPaletteCacheEntryAdapter());
      Hive.registerAdapter(SiteIconCacheAdapter());
      Hive.registerAdapter(SiteModelCacheAdapter());
      Hive.registerAdapter(SiteUserDataCacheAdapter());
      Hive.registerAdapter(SearchHistoryEntryAdapter());
    }

    // Open boxes
    loginProfileBox = await Hive.openBox<LoginProfile>('loginProfiles');
    mediaDetailCacheBox =
        await Hive.openBox<MediaDetailCache>('mediaDetailCache');
    pluginModelCacheBox =
        await Hive.openBox<PluginModelCache>('pluginModelCache');
    installedPluginModelCacheBox =
        await Hive.openBox<InstalledPluginModelCache>(
            'installedPluginModelCache');
    pluginPaletteCacheBox =
        await Hive.openBox<PluginPaletteCacheEntry>('pluginPaletteCache');
    siteIconCacheBox = await Hive.openBox<SiteIconCache>('siteIconCache');
    siteModelCacheBox = await Hive.openBox<SiteModelCache>('siteModelCache');
    siteUserDataCacheBox =
        await Hive.openBox<SiteUserDataCache>('siteUserDataCache');
    searchHistoryBox =
        await Hive.openBox<SearchHistoryEntry>('searchHistory');

    return this;
  }
}

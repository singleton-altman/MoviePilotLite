import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_palette_cache_entry.dart';
import 'package:moviepilot_mobile/modules/site/models/site_icon_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_model_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_userdata_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';

import '../modules/login/models/login_profile.dart';
import '../modules/media_detail/models/media_detail_cache.dart';
import '../modules/search/models/search_history.dart';

class RealmService extends GetxService {
  @override
  void onInit() {
    super.onInit();
    initDatabase();
  }

  final realm = Rxn<Realm>();
  Future<void> initDatabase() async {
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/moviepilot.realm';
    final config = Configuration.local(
      [
        LoginProfile.schema,
        MediaDetailCache.schema,
        PluginModelCache.schema,
        InstalledPluginModelCache.schema,
        SiteIconCache.schema,
        SiteModelCache.schema,
        SiteUserDataCache.schema,
        SearchHistoryEntry.schema,
        PluginPaletteCacheEntry.schema,
      ],
      schemaVersion: 6,
      migrationCallback: (migration, oldSchemaVersion) {
        if (oldSchemaVersion < 2) {}
        if (oldSchemaVersion < 3) {}
        if (oldSchemaVersion < 4) {
          // 新增站点相关缓存表
        }
        if (oldSchemaVersion < 5) {}
        if (oldSchemaVersion < 6) {}
      },
      path: path,
    );
    try {
      realm.value = Realm(config);
    } catch (e) {
      print('初始化 Realm 失败: $e');
      realm.value = null;
    }
  }
}

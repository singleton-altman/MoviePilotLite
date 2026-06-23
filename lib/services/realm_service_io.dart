import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_palette_cache_entry.dart';
import 'package:moviepilot_mobile/modules/site/models/site_icon_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_model_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_userdata_cache.dart';
import 'package:realm/realm.dart';

import '../modules/login/models/login_profile.dart';
import '../modules/media_detail/models/media_detail_cache.dart';
import '../modules/search/models/search_history.dart';

class RealmService extends GetxService {
  RealmService() {
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
        if (oldSchemaVersion < 4) {}
        if (oldSchemaVersion < 5) {}
        if (oldSchemaVersion < 6) {}
      },
    );
    _realm = Realm(config);
  }

  late final Realm _realm;

  Realm get realm => _realm;
}

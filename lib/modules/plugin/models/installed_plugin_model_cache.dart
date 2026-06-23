// {
//         "id": "AutoSignIn",
//         "plugin_name": "站点自动签到",
//         "plugin_desc": "自动模拟登录、签到站点。",
//         "plugin_icon": "signin.png",
//         "plugin_version": "2.8.1",
//         "plugin_label": null,
//         "plugin_author": "thsrite",
//         "author_url": "https://github.com/thsrite",
//         "plugin_config_prefix": null,
//         "plugin_order": 0,
//         "auth_level": 2,
//         "installed": true,
//         "state": true,
//         "has_page": true,
//         "has_update": false,
//         "is_local": true,
//         "repo_url": null,
//         "install_count": 0,
//         "history": {},
//         "add_time": 0,
//         "plugin_public_key": null
//     }

import 'package:realm/realm.dart';

part 'installed_plugin_model_cache.realm.dart';

const _installedPluginCacheScopeSeparator = '::plugin-scope::';

String buildInstalledPluginCacheId(String scopeKey, String pluginId) {
  final normalizedScope = scopeKey.trim();
  if (normalizedScope.isEmpty) return pluginId;
  return '$normalizedScope$_installedPluginCacheScopeSeparator$pluginId';
}

String extractInstalledPluginId(String cacheId) {
  final index = cacheId.indexOf(_installedPluginCacheScopeSeparator);
  if (index < 0) return cacheId;
  return cacheId.substring(index + _installedPluginCacheScopeSeparator.length);
}

bool matchesInstalledPluginScope(String cacheId, String scopeKey) {
  final normalizedScope = scopeKey.trim();
  if (normalizedScope.isEmpty) return false;
  return cacheId.startsWith(
    '$normalizedScope$_installedPluginCacheScopeSeparator',
  );
}

@RealmModel()
class _InstalledPluginModelCache {
  @PrimaryKey()
  late String id;
  late String pluginName;
  late String pluginDesc;
  late String pluginIcon;
  late String pluginVersion;
  late String pluginLabel;
  late String pluginAuthor;
  late String authorUrl;
  late String pluginConfigPrefix;
  late int pluginOrder;
  late int authLevel;
  late bool installed;
  late bool state;
  late bool hasPage;
  late bool hasUpdate;
  late bool isLocal;
  late String repoUrl;
  late int installCount;
  late int addTime;
  late String pluginPublicKey;
}

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

/// Installed plugin cache.
class InstalledPluginModelCache {
  final String id;
  final String pluginName;
  final String pluginDesc;
  final String pluginIcon;
  final String pluginVersion;
  final String pluginLabel;
  final String pluginAuthor;
  final String authorUrl;
  final String pluginConfigPrefix;
  final int pluginOrder;
  final int authLevel;
  final bool installed;
  final bool state;
  final bool hasPage;
  final bool hasUpdate;
  final bool isLocal;
  final String repoUrl;
  final int installCount;
  final int addTime;
  final String pluginPublicKey;

  const InstalledPluginModelCache({
    required this.id,
    required this.pluginName,
    required this.pluginDesc,
    required this.pluginIcon,
    required this.pluginVersion,
    required this.pluginLabel,
    required this.pluginAuthor,
    required this.authorUrl,
    required this.pluginConfigPrefix,
    required this.pluginOrder,
    required this.authLevel,
    required this.installed,
    required this.state,
    required this.hasPage,
    required this.hasUpdate,
    required this.isLocal,
    required this.repoUrl,
    required this.installCount,
    required this.addTime,
    required this.pluginPublicKey,
  });
}

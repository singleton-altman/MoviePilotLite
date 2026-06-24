import 'package:hive_ce/hive.dart';

part 'installed_plugin_model_cache.g.dart';

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

@HiveType(typeId: 3)
class InstalledPluginModelCache {
  @HiveField(0)
  String id;
  @HiveField(1)
  String pluginName;
  @HiveField(2)
  String pluginDesc;
  @HiveField(3)
  String pluginIcon;
  @HiveField(4)
  String pluginVersion;
  @HiveField(5)
  String pluginLabel;
  @HiveField(6)
  String pluginAuthor;
  @HiveField(7)
  String authorUrl;
  @HiveField(8)
  String pluginConfigPrefix;
  @HiveField(9)
  int pluginOrder;
  @HiveField(10)
  int authLevel;
  @HiveField(11)
  bool installed;
  @HiveField(12)
  bool state;
  @HiveField(13)
  bool hasPage;
  @HiveField(14)
  bool hasUpdate;
  @HiveField(15)
  bool isLocal;
  @HiveField(16)
  String repoUrl;
  @HiveField(17)
  int installCount;
  @HiveField(18)
  int addTime;
  @HiveField(19)
  String pluginPublicKey;

  InstalledPluginModelCache(
    this.id,
    this.pluginName,
    this.pluginDesc,
    this.pluginIcon,
    this.pluginVersion,
    this.pluginLabel,
    this.pluginAuthor,
    this.authorUrl,
    this.pluginConfigPrefix,
    this.pluginOrder,
    this.authLevel,
    this.installed,
    this.state,
    this.hasPage,
    this.hasUpdate,
    this.isLocal,
    this.repoUrl,
    this.installCount,
    this.addTime,
    this.pluginPublicKey,
  );
}

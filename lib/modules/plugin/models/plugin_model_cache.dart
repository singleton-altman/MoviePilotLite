import 'package:realm/realm.dart';

part 'plugin_model_cache.realm.dart';

const _pluginMarketCacheScopeSeparator = '::plugin-market-scope::';

String buildPluginMarketCacheId(String scopeKey, String pluginId) {
  final normalizedScope = scopeKey.trim();
  if (normalizedScope.isEmpty) return pluginId;
  return '$normalizedScope$_pluginMarketCacheScopeSeparator$pluginId';
}

String extractPluginMarketPluginId(String cacheId) {
  final index = cacheId.indexOf(_pluginMarketCacheScopeSeparator);
  if (index < 0) return cacheId;
  return cacheId.substring(index + _pluginMarketCacheScopeSeparator.length);
}

bool matchesPluginMarketScope(String cacheId, String scopeKey) {
  final normalizedScope = scopeKey.trim();
  if (normalizedScope.isEmpty) return false;
  return cacheId.startsWith(
    '$normalizedScope$_pluginMarketCacheScopeSeparator',
  );
}

@RealmModel()
class _PluginModelCache {
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

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

/// Plugin market listing cache.
class PluginModelCache {
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

  const PluginModelCache({
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

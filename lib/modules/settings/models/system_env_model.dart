import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_env_model.freezed.dart';
part 'system_env_model.g.dart';

/// 解析前净化 env 载荷:v2 的配置值都是字符串,v3 会下发原生类型(bool/int/对象)。
/// 模型对字符串字段是硬转型(`as String?`),遇到 bool 会抛
/// "type 'bool' is not a subtype of type 'String?'"——2026-10-10 v3 真机实测,
/// 基础设置页整页报这个错。这里把**标量**统一字符串化(数组保持原样),
/// 而模型里数值/布尔字段的 fromJson 都能吃字符串
/// (_intFromJson/_boolFromJson/_doubleFromJson),因此对 v2 / v3 都安全;
/// 放在模型层可以让所有调用点(基础/高级设置、站点、动态表单等)一次修好。
Map<String, dynamic> sanitizeEnvJson(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! Map) return json;
  final sanitized = <String, dynamic>{};
  data.forEach((key, value) {
    final name = key.toString();
    if (value == null || value is String || value is List) {
      sanitized[name] = value;
    } else if (value is Map) {
      sanitized[name] = jsonEncode(value);
    } else {
      sanitized[name] = value.toString();
    }
  });
  return <String, dynamic>{...json, 'data': sanitized};
}

int? _intFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? _boolFromJson(dynamic v) {
  return switch (v) {
    null => null,
    bool b => b,
    String s => s.toLowerCase() == 'true' || s == '1',
    int i => i != 0,
    _ => null,
  };
}

String? _stringFromJson(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

double? _doubleFromJson(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<String> _stringListFromJson(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e == null ? null : e.toString())
        .whereType<String>()
        .toList();
  }
  return const [];
}

List<int> _intListFromJson(dynamic v) {
  if (v is List) {
    return v.map((e) => _intFromJson(e)).whereType<int>().toList();
  }
  return const [];
}

@Freezed(toJson: false)
class SystemEnvResponse with _$SystemEnvResponse {
  const factory SystemEnvResponse({
    required bool success,
    String? message,
    SystemEnvData? data,
  }) = _SystemEnvResponse;

  factory SystemEnvResponse.fromJson(Map<String, dynamic> json) =>
      _$SystemEnvResponseFromJson(sanitizeEnvJson(json));
}

/// 系统环境变量数据，对应 GET /api/v1/system/env 的 data 字段
@Freezed(toJson: false)
class SystemEnvData with _$SystemEnvData {
  const SystemEnvData._();

  const factory SystemEnvData({
    @JsonKey(name: 'CONFIG_DIR') String? configDir,
    @JsonKey(name: 'DEBUG', fromJson: _boolFromJson) bool? debug,
    @JsonKey(name: 'LOG_LEVEL') String? logLevel,
    @JsonKey(name: 'LOG_MAX_FILE_SIZE', fromJson: _intFromJson)
    int? logMaxFileSize,
    @JsonKey(name: 'LOG_BACKUP_COUNT', fromJson: _intFromJson)
    int? logBackupCount,
    @JsonKey(name: 'LOG_CONSOLE_FORMAT') String? logConsoleFormat,
    @JsonKey(name: 'LOG_FILE_FORMAT') String? logFileFormat,
    @JsonKey(name: 'ASYNC_FILE_QUEUE_SIZE', fromJson: _intFromJson)
    int? asyncFileQueueSize,
    @JsonKey(name: 'ASYNC_FILE_WORKERS', fromJson: _intFromJson)
    int? asyncFileWorkers,
    @JsonKey(name: 'BATCH_WRITE_SIZE', fromJson: _intFromJson)
    int? batchWriteSize,
    @JsonKey(name: 'WRITE_TIMEOUT', fromJson: _doubleFromJson)
    double? writeTimeout,
    @JsonKey(name: 'PROJECT_NAME') String? projectName,
    @JsonKey(name: 'APP_DOMAIN') String? appDomain,
    @JsonKey(name: 'API_V1_STR') String? apiV1Str,
    @JsonKey(name: 'FRONTEND_PATH') String? frontendPath,
    @JsonKey(name: 'TZ') String? tz,
    @JsonKey(name: 'HOST') String? host,
    @JsonKey(name: 'PORT', fromJson: _intFromJson) int? port,
    @JsonKey(name: 'NGINX_PORT', fromJson: _intFromJson) int? nginxPort,
    @JsonKey(name: 'DEV', fromJson: _boolFromJson) bool? dev,
    @JsonKey(name: 'ADVANCED_MODE', fromJson: _boolFromJson) bool? advancedMode,
    @JsonKey(name: 'ALLOWED_HOSTS', fromJson: _stringListFromJson)
    List<String>? allowedHosts,
    @JsonKey(name: 'ACCESS_TOKEN_EXPIRE_MINUTES', fromJson: _intFromJson)
    int? accessTokenExpireMinutes,
    @JsonKey(
      name: 'RESOURCE_ACCESS_TOKEN_EXPIRE_SECONDS',
      fromJson: _intFromJson,
    )
    int? resourceAccessTokenExpireSeconds,
    @JsonKey(name: 'SUPERUSER') String? superuser,
    @JsonKey(name: 'SUPERUSER_PASSWORD') String? superuserPassword,
    @JsonKey(name: 'AUXILIARY_AUTH_ENABLE', fromJson: _boolFromJson)
    bool? auxiliaryAuthEnable,
    @JsonKey(name: 'API_TOKEN') String? apiToken,
    @JsonKey(name: 'AUTH_SITE') String? authSite,
    @JsonKey(name: 'DB_TYPE') String? dbType,
    @JsonKey(name: 'DB_ECHO', fromJson: _boolFromJson) bool? dbEcho,
    @JsonKey(name: 'DB_TIMEOUT', fromJson: _intFromJson) int? dbTimeout,
    @JsonKey(name: 'DB_WAL_ENABLE', fromJson: _boolFromJson) bool? dbWalEnable,
    @JsonKey(name: 'DB_POOL_TYPE') String? dbPoolType,
    @JsonKey(name: 'DB_POOL_PRE_PING', fromJson: _boolFromJson)
    bool? dbPoolPrePing,
    @JsonKey(name: 'DB_POOL_RECYCLE', fromJson: _intFromJson)
    int? dbPoolRecycle,
    @JsonKey(name: 'DB_POOL_TIMEOUT', fromJson: _intFromJson)
    int? dbPoolTimeout,
    @JsonKey(name: 'DB_SQLITE_POOL_SIZE', fromJson: _intFromJson)
    int? dbSqlitePoolSize,
    @JsonKey(name: 'DB_SQLITE_MAX_OVERFLOW', fromJson: _intFromJson)
    int? dbSqliteMaxOverflow,
    @JsonKey(name: 'DB_POSTGRESQL_HOST') String? dbPostgresqlHost,
    @JsonKey(name: 'DB_POSTGRESQL_PORT', fromJson: _intFromJson)
    int? dbPostgresqlPort,
    @JsonKey(name: 'DB_POSTGRESQL_DATABASE') String? dbPostgresqlDatabase,
    @JsonKey(name: 'DB_POSTGRESQL_USERNAME') String? dbPostgresqlUsername,
    @JsonKey(name: 'DB_POSTGRESQL_PASSWORD') String? dbPostgresqlPassword,
    @JsonKey(name: 'DB_POSTGRESQL_POOL_SIZE', fromJson: _intFromJson)
    int? dbPostgresqlPoolSize,
    @JsonKey(name: 'DB_POSTGRESQL_MAX_OVERFLOW', fromJson: _intFromJson)
    int? dbPostgresqlMaxOverflow,
    @JsonKey(name: 'CACHE_BACKEND_TYPE') String? cacheBackendType,
    @JsonKey(name: 'CACHE_BACKEND_URL') String? cacheBackendUrl,
    @JsonKey(name: 'CACHE_REDIS_MAXMEMORY', fromJson: _intFromJson)
    int? cacheRedisMaxmemory,
    @JsonKey(name: 'GLOBAL_IMAGE_CACHE', fromJson: _boolFromJson)
    bool? globalImageCache,
    @JsonKey(name: 'GLOBAL_IMAGE_CACHE_DAYS', fromJson: _intFromJson)
    int? globalImageCacheDays,
    @JsonKey(name: 'TEMP_FILE_DAYS', fromJson: _intFromJson) int? tempFileDays,
    @JsonKey(name: 'META_CACHE_EXPIRE', fromJson: _intFromJson)
    int? metaCacheExpire,
    @JsonKey(name: 'PROXY_HOST') String? proxyHost,
    @JsonKey(name: 'DOH_ENABLE', fromJson: _boolFromJson) bool? dohEnable,
    @JsonKey(name: 'DOH_DOMAINS') String? dohDomains,
    @JsonKey(name: 'DOH_RESOLVERS') String? dohResolvers,
    @JsonKey(name: 'SEARCH_SOURCE') String? searchSource,
    @JsonKey(name: 'RECOGNIZE_SOURCE') String? recognizeSource,
    @JsonKey(name: 'SCRAP_SOURCE') String? scrapSource,
    @JsonKey(name: 'ANIME_GENREIDS', fromJson: _intListFromJson)
    List<int>? animeGenreIds,
    @JsonKey(name: 'TMDB_IMAGE_DOMAIN') String? tmdbImageDomain,
    @JsonKey(name: 'TMDB_API_DOMAIN') String? tmdbApiDomain,
    @JsonKey(name: 'TMDB_LOCALE') String? tmdbLocale,
    @JsonKey(name: 'TMDB_SCRAP_ORIGINAL_IMAGE', fromJson: _boolFromJson)
    bool? tmdbScrapOriginalImage,
    @JsonKey(name: 'TMDB_API_KEY') String? tmdbApiKey,
    @JsonKey(name: 'TVDB_V4_API_KEY') String? tvdbV4ApiKey,
    @JsonKey(name: 'TVDB_V4_API_PIN') String? tvdbV4ApiPin,
    @JsonKey(name: 'FANART_ENABLE', fromJson: _boolFromJson) bool? fanartEnable,
    @JsonKey(name: 'FANART_LANG') String? fanartLang,
    @JsonKey(name: 'FANART_API_KEY') String? fanartApiKey,
    @JsonKey(name: 'U115_APP_ID') String? u115AppId,
    @JsonKey(name: 'U115_AUTH_SERVER') String? u115AuthServer,
    @JsonKey(name: 'ALIPAN_APP_ID') String? alipanAppId,
    @JsonKey(name: 'MOVIEPILOT_AUTO_UPDATE', fromJson: _stringFromJson)
    String? moviepilotAutoUpdate,
    @JsonKey(name: 'AUTO_UPDATE_RESOURCE', fromJson: _boolFromJson)
    bool? autoUpdateResource,
    @JsonKey(name: 'RMT_MEDIAEXT', fromJson: _stringListFromJson)
    List<String>? rmtMediaext,
    @JsonKey(name: 'RMT_SUBEXT', fromJson: _stringListFromJson)
    List<String>? rmtSubext,
    @JsonKey(name: 'RMT_AUDIOEXT', fromJson: _stringListFromJson)
    List<String>? rmtAudioext,
    @JsonKey(name: 'MEDIASERVER_SYNC_INTERVAL', fromJson: _intFromJson)
    int? mediaserverSyncInterval,
    @JsonKey(name: 'SUBSCRIBE_MODE') String? subscribeMode,
    @JsonKey(name: 'SUBSCRIBE_RSS_INTERVAL', fromJson: _intFromJson)
    int? subscribeRssInterval,
    @JsonKey(name: 'SUBSCRIBE_STATISTIC_SHARE', fromJson: _boolFromJson)
    bool? subscribeStatisticShare,
    @JsonKey(name: 'SUBSCRIBE_SEARCH', fromJson: _boolFromJson)
    bool? subscribeSearch,
    @JsonKey(name: 'SUBSCRIBE_SEARCH_INTERVAL', fromJson: _intFromJson)
    int? subscribeSearchInterval,
    @JsonKey(name: 'LOCAL_EXISTS_SEARCH', fromJson: _boolFromJson)
    bool? localExistsSearch,
    @JsonKey(name: 'SITEDATA_REFRESH_INTERVAL', fromJson: _intFromJson)
    int? sitedataRefreshInterval,
    @JsonKey(name: 'SITE_MESSAGE', fromJson: _boolFromJson) bool? siteMessage,
    @JsonKey(name: 'NO_CACHE_SITE_KEY') String? noCacheSiteKey,
    @JsonKey(name: 'OCR_HOST') String? ocrHost,
    @JsonKey(name: 'BROWSER_EMULATION') String? browserEmulation,
    @JsonKey(name: 'FLARESOLVERR_URL') String? flaresolverrUrl,
    @JsonKey(name: 'SEARCH_MULTIPLE_NAME', fromJson: _boolFromJson)
    bool? searchMultipleName,
    @JsonKey(name: 'MAX_SEARCH_NAME_LIMIT', fromJson: _intFromJson)
    int? maxSearchNameLimit,
    @JsonKey(name: 'TORRENT_TAG') String? torrentTag,
    @JsonKey(name: 'DOWNLOAD_SUBTITLE', fromJson: _boolFromJson)
    bool? downloadSubtitle,
    @JsonKey(name: 'AUTO_DOWNLOAD_USER') String? autoDownloadUser,
    @JsonKey(name: 'DOWNLOAD_TMPEXT', fromJson: _stringListFromJson)
    List<String>? downloadTmpext,
    @JsonKey(name: 'COOKIECLOUD_ENABLE_LOCAL', fromJson: _boolFromJson)
    bool? cookiecloudEnableLocal,
    @JsonKey(name: 'COOKIECLOUD_HOST') String? cookiecloudHost,
    @JsonKey(name: 'COOKIECLOUD_KEY') String? cookiecloudKey,
    @JsonKey(name: 'COOKIECLOUD_PASSWORD') String? cookiecloudPassword,
    @JsonKey(name: 'COOKIECLOUD_INTERVAL', fromJson: _intFromJson)
    int? cookiecloudInterval,
    @JsonKey(name: 'COOKIECLOUD_BLACKLIST') String? cookiecloudBlacklist,
    @JsonKey(name: 'TRANSFER_THREADS', fromJson: _intFromJson)
    int? transferThreads,
    @JsonKey(name: 'MOVIE_RENAME_FORMAT') String? movieRenameFormat,
    @JsonKey(name: 'TV_RENAME_FORMAT') String? tvRenameFormat,
    @JsonKey(name: 'RENAME_FORMAT_S0_NAMES', fromJson: _stringListFromJson)
    List<String>? renameFormatS0Names,
    @JsonKey(name: 'DEFAULT_SUB') String? defaultSub,
    @JsonKey(name: 'SCRAP_FOLLOW_TMDB', fromJson: _boolFromJson)
    bool? scrapFollowTmdb,
    @JsonKey(name: 'MP_SERVER_HOST') String? mpServerHost,
    @JsonKey(name: 'WALLPAPER') String? wallpaper,
    @JsonKey(name: 'CUSTOMIZE_WALLPAPER_API_URL')
    String? customizeWallpaperApiUrl,
    @JsonKey(name: 'PLUGIN_MARKET') String? pluginMarket,
    @JsonKey(name: 'PLUGIN_STATISTIC_SHARE', fromJson: _boolFromJson)
    bool? pluginStatisticShare,
    @JsonKey(name: 'PLUGIN_AUTO_RELOAD', fromJson: _boolFromJson)
    bool? pluginAutoReload,
    @JsonKey(name: 'GITHUB_TOKEN') String? githubToken,
    @JsonKey(name: 'GITHUB_PROXY') String? githubProxy,
    @JsonKey(name: 'PIP_PROXY') String? pipProxy,
    @JsonKey(name: 'REPO_GITHUB_TOKEN') String? repoGithubToken,
    @JsonKey(name: 'BIG_MEMORY_MODE', fromJson: _boolFromJson)
    bool? bigMemoryMode,
    @JsonKey(
      name: 'ENCODING_DETECTION_PERFORMANCE_MODE',
      fromJson: _boolFromJson,
    )
    bool? encodingDetectionPerformanceMode,
    @JsonKey(
      name: 'ENCODING_DETECTION_MIN_CONFIDENCE',
      fromJson: _doubleFromJson,
    )
    double? encodingDetectionMinConfidence,
    @JsonKey(name: 'MEMORY_GC_INTERVAL', fromJson: _intFromJson)
    int? memoryGcInterval,
    @JsonKey(name: 'SECURITY_IMAGE_DOMAINS', fromJson: _stringListFromJson)
    List<String>? securityImageDomains,
    @JsonKey(name: 'SECURITY_IMAGE_SUFFIXES', fromJson: _stringListFromJson)
    List<String>? securityImageSuffixes,
    @JsonKey(name: 'PASSKEY_REQUIRE_UV', fromJson: _boolFromJson)
    bool? passkeyRequireUv,
    @JsonKey(
      name: 'PASSKEY_ALLOW_REGISTER_WITHOUT_OTP',
      fromJson: _boolFromJson,
    )
    bool? passkeyAllowRegisterWithoutOtp,
    @JsonKey(name: 'WORKFLOW_STATISTIC_SHARE', fromJson: _boolFromJson)
    bool? workflowStatisticShare,
    @JsonKey(
      name: 'RCLONE_SNAPSHOT_CHECK_FOLDER_MODTIME',
      fromJson: _boolFromJson,
    )
    bool? rcloneSnapshotCheckFolderModtime,
    @JsonKey(
      name: 'OPENLIST_SNAPSHOT_CHECK_FOLDER_MODTIME',
      fromJson: _boolFromJson,
    )
    bool? openlistSnapshotCheckFolderModtime,
    @JsonKey(name: 'DOCKER_CLIENT_API') String? dockerClientApi,
    @JsonKey(name: 'PLAYWRIGHT_BROWSER_TYPE') String? playwrightBrowserType,
    @JsonKey(name: 'AI_AGENT_ENABLE', fromJson: _boolFromJson)
    bool? aiAgentEnable,
    @JsonKey(name: 'AI_AGENT_GLOBAL', fromJson: _boolFromJson)
    bool? aiAgentGlobal,
    @JsonKey(name: 'LLM_PROVIDER') String? llmProvider,
    @JsonKey(name: 'LLM_MODEL') String? llmModel,
    @JsonKey(name: 'LLM_API_KEY') String? llmApiKey,
    @JsonKey(name: 'LLM_BASE_URL') String? llmBaseUrl,
    @JsonKey(name: 'LLM_MAX_CONTEXT_TOKENS', fromJson: _intFromJson)
    int? llmMaxContextTokens,
    @JsonKey(name: 'LLM_TEMPERATURE', fromJson: _doubleFromJson)
    double? llmTemperature,
    @JsonKey(name: 'LLM_MAX_ITERATIONS', fromJson: _intFromJson)
    int? llmMaxIterations,
    @JsonKey(name: 'LLM_TOOL_TIMEOUT', fromJson: _intFromJson)
    int? llmToolTimeout,
    @JsonKey(name: 'LLM_VERBOSE', fromJson: _boolFromJson) bool? llmVerbose,
    @JsonKey(name: 'LLM_MAX_MEMORY_MESSAGES', fromJson: _intFromJson)
    int? llmMaxMemoryMessages,
    @JsonKey(name: 'LLM_MEMORY_RETENTION_DAYS', fromJson: _intFromJson)
    int? llmMemoryRetentionDays,
    @JsonKey(name: 'LLM_REDIS_MEMORY_RETENTION_DAYS', fromJson: _intFromJson)
    int? llmRedisMemoryRetentionDays,
    @JsonKey(name: 'AI_RECOMMEND_ENABLED', fromJson: _boolFromJson)
    bool? aiRecommendEnabled,
    @JsonKey(name: 'AI_RECOMMEND_USER_PREFERENCE')
    String? aiRecommendUserPreference,
    @JsonKey(name: 'TAVILY_API_KEY') List? tavilyApiKey,
    @JsonKey(name: 'AI_RECOMMEND_MAX_ITEMS', fromJson: _intFromJson)
    int? aiRecommendMaxItems,
    @JsonKey(name: 'VERSION') String? version,
    @JsonKey(name: 'AUTH_VERSION') String? authVersion,
    @JsonKey(name: 'INDEXER_VERSION') String? indexerVersion,
    @JsonKey(name: 'FRONTEND_VERSION') String? frontendVersion,
  }) = _SystemEnvData;

  factory SystemEnvData.fromJson(Map<String, dynamic> json) =>
      _$SystemEnvDataFromJson(json);

  /// 按 envKey 获取值，供 SettingsFieldConfig.envKey 查找
  dynamic valueFor(String key) {
    switch (key) {
      case 'CONFIG_DIR':
        return configDir;
      case 'DEBUG':
        return debug;
      case 'LOG_LEVEL':
        return logLevel;
      case 'LOG_MAX_FILE_SIZE':
        return logMaxFileSize;
      case 'LOG_BACKUP_COUNT':
        return logBackupCount;
      case 'LOG_CONSOLE_FORMAT':
        return logConsoleFormat;
      case 'LOG_FILE_FORMAT':
        return logFileFormat;
      case 'ASYNC_FILE_QUEUE_SIZE':
        return asyncFileQueueSize;
      case 'ASYNC_FILE_WORKERS':
        return asyncFileWorkers;
      case 'BATCH_WRITE_SIZE':
        return batchWriteSize;
      case 'WRITE_TIMEOUT':
        return writeTimeout;
      case 'PROJECT_NAME':
        return projectName;
      case 'APP_DOMAIN':
        return appDomain;
      case 'API_V1_STR':
        return apiV1Str;
      case 'FRONTEND_PATH':
        return frontendPath;
      case 'TZ':
        return tz;
      case 'HOST':
        return host;
      case 'PORT':
        return port;
      case 'NGINX_PORT':
        return nginxPort;
      case 'DEV':
        return dev;
      case 'ADVANCED_MODE':
        return advancedMode;
      case 'ALLOWED_HOSTS':
        return allowedHosts;
      case 'ACCESS_TOKEN_EXPIRE_MINUTES':
        return accessTokenExpireMinutes;
      case 'RESOURCE_ACCESS_TOKEN_EXPIRE_SECONDS':
        return resourceAccessTokenExpireSeconds;
      case 'SUPERUSER':
        return superuser;
      case 'SUPERUSER_PASSWORD':
        return superuserPassword;
      case 'AUXILIARY_AUTH_ENABLE':
        return auxiliaryAuthEnable;
      case 'API_TOKEN':
        return apiToken;
      case 'AUTH_SITE':
        return authSite;
      case 'DB_TYPE':
        return dbType;
      case 'DB_ECHO':
        return dbEcho;
      case 'DB_TIMEOUT':
        return dbTimeout;
      case 'DB_WAL_ENABLE':
        return dbWalEnable;
      case 'DB_POOL_TYPE':
        return dbPoolType;
      case 'DB_POOL_PRE_PING':
        return dbPoolPrePing;
      case 'DB_POOL_RECYCLE':
        return dbPoolRecycle;
      case 'DB_POOL_TIMEOUT':
        return dbPoolTimeout;
      case 'DB_SQLITE_POOL_SIZE':
        return dbSqlitePoolSize;
      case 'DB_SQLITE_MAX_OVERFLOW':
        return dbSqliteMaxOverflow;
      case 'DB_POSTGRESQL_HOST':
        return dbPostgresqlHost;
      case 'DB_POSTGRESQL_PORT':
        return dbPostgresqlPort;
      case 'DB_POSTGRESQL_DATABASE':
        return dbPostgresqlDatabase;
      case 'DB_POSTGRESQL_USERNAME':
        return dbPostgresqlUsername;
      case 'DB_POSTGRESQL_PASSWORD':
        return dbPostgresqlPassword;
      case 'DB_POSTGRESQL_POOL_SIZE':
        return dbPostgresqlPoolSize;
      case 'DB_POSTGRESQL_MAX_OVERFLOW':
        return dbPostgresqlMaxOverflow;
      case 'CACHE_BACKEND_TYPE':
        return cacheBackendType;
      case 'CACHE_BACKEND_URL':
        return cacheBackendUrl;
      case 'CACHE_REDIS_MAXMEMORY':
        return cacheRedisMaxmemory;
      case 'GLOBAL_IMAGE_CACHE':
        return globalImageCache;
      case 'GLOBAL_IMAGE_CACHE_DAYS':
        return globalImageCacheDays;
      case 'TEMP_FILE_DAYS':
        return tempFileDays;
      case 'META_CACHE_EXPIRE':
        return metaCacheExpire;
      case 'PROXY_HOST':
        return proxyHost;
      case 'DOH_ENABLE':
        return dohEnable;
      case 'DOH_DOMAINS':
        return dohDomains;
      case 'DOH_RESOLVERS':
        return dohResolvers;
      case 'SEARCH_SOURCE':
        return searchSource;
      case 'RECOGNIZE_SOURCE':
        return recognizeSource;
      case 'SCRAP_SOURCE':
        return scrapSource;
      case 'ANIME_GENREIDS':
        return animeGenreIds;
      case 'TMDB_IMAGE_DOMAIN':
        return tmdbImageDomain;
      case 'TMDB_API_DOMAIN':
        return tmdbApiDomain;
      case 'TMDB_LOCALE':
        return tmdbLocale;
      case 'TMDB_SCRAP_ORIGINAL_IMAGE':
        return tmdbScrapOriginalImage;
      case 'TMDB_API_KEY':
        return tmdbApiKey;
      case 'TVDB_V4_API_KEY':
        return tvdbV4ApiKey;
      case 'TVDB_V4_API_PIN':
        return tvdbV4ApiPin;
      case 'FANART_ENABLE':
        return fanartEnable;
      case 'FANART_LANG':
        return fanartLang;
      case 'FANART_API_KEY':
        return fanartApiKey;
      case 'U115_APP_ID':
        return u115AppId;
      case 'U115_AUTH_SERVER':
        return u115AuthServer;
      case 'ALIPAN_APP_ID':
        return alipanAppId;
      case 'MOVIEPILOT_AUTO_UPDATE':
        return moviepilotAutoUpdate;
      case 'AUTO_UPDATE_RESOURCE':
        return autoUpdateResource;
      case 'RMT_MEDIAEXT':
        return rmtMediaext;
      case 'RMT_SUBEXT':
        return rmtSubext;
      case 'RMT_AUDIOEXT':
        return rmtAudioext;
      case 'MEDIASERVER_SYNC_INTERVAL':
        return mediaserverSyncInterval;
      case 'SUBSCRIBE_MODE':
        return subscribeMode;
      case 'SUBSCRIBE_RSS_INTERVAL':
        return subscribeRssInterval;
      case 'SUBSCRIBE_STATISTIC_SHARE':
        return subscribeStatisticShare;
      case 'SUBSCRIBE_SEARCH':
        return subscribeSearch;
      case 'SUBSCRIBE_SEARCH_INTERVAL':
        return subscribeSearchInterval;
      case 'LOCAL_EXISTS_SEARCH':
        return localExistsSearch;
      case 'SITEDATA_REFRESH_INTERVAL':
        return sitedataRefreshInterval;
      case 'SITE_MESSAGE':
        return siteMessage;
      case 'NO_CACHE_SITE_KEY':
        return noCacheSiteKey;
      case 'OCR_HOST':
        return ocrHost;
      case 'BROWSER_EMULATION':
        return browserEmulation;
      case 'FLARESOLVERR_URL':
        return flaresolverrUrl;
      case 'SEARCH_MULTIPLE_NAME':
        return searchMultipleName;
      case 'MAX_SEARCH_NAME_LIMIT':
        return maxSearchNameLimit;
      case 'TORRENT_TAG':
        return torrentTag;
      case 'DOWNLOAD_SUBTITLE':
        return downloadSubtitle;
      case 'AUTO_DOWNLOAD_USER':
        return autoDownloadUser;
      case 'DOWNLOAD_TMPEXT':
        return downloadTmpext;
      case 'COOKIECLOUD_ENABLE_LOCAL':
        return cookiecloudEnableLocal;
      case 'COOKIECLOUD_HOST':
        return cookiecloudHost;
      case 'COOKIECLOUD_KEY':
        return cookiecloudKey;
      case 'COOKIECLOUD_PASSWORD':
        return cookiecloudPassword;
      case 'COOKIECLOUD_INTERVAL':
        return cookiecloudInterval;
      case 'COOKIECLOUD_BLACKLIST':
        return cookiecloudBlacklist;
      case 'TRANSFER_THREADS':
        return transferThreads;
      case 'MOVIE_RENAME_FORMAT':
        return movieRenameFormat;
      case 'TV_RENAME_FORMAT':
        return tvRenameFormat;
      case 'RENAME_FORMAT_S0_NAMES':
        return renameFormatS0Names;
      case 'DEFAULT_SUB':
        return defaultSub;
      case 'SCRAP_FOLLOW_TMDB':
        return scrapFollowTmdb;
      case 'MP_SERVER_HOST':
        return mpServerHost;
      case 'WALLPAPER':
        return wallpaper;
      case 'CUSTOMIZE_WALLPAPER_API_URL':
        return customizeWallpaperApiUrl;
      case 'PLUGIN_MARKET':
        return pluginMarket;
      case 'PLUGIN_STATISTIC_SHARE':
        return pluginStatisticShare;
      case 'PLUGIN_AUTO_RELOAD':
        return pluginAutoReload;
      case 'GITHUB_TOKEN':
        return githubToken;
      case 'GITHUB_PROXY':
        return githubProxy;
      case 'PIP_PROXY':
        return pipProxy;
      case 'REPO_GITHUB_TOKEN':
        return repoGithubToken;
      case 'BIG_MEMORY_MODE':
        return bigMemoryMode;
      case 'ENCODING_DETECTION_PERFORMANCE_MODE':
        return encodingDetectionPerformanceMode;
      case 'ENCODING_DETECTION_MIN_CONFIDENCE':
        return encodingDetectionMinConfidence;
      case 'MEMORY_GC_INTERVAL':
        return memoryGcInterval;
      case 'SECURITY_IMAGE_DOMAINS':
        return securityImageDomains;
      case 'SECURITY_IMAGE_SUFFIXES':
        return securityImageSuffixes;
      case 'PASSKEY_REQUIRE_UV':
        return passkeyRequireUv;
      case 'PASSKEY_ALLOW_REGISTER_WITHOUT_OTP':
        return passkeyAllowRegisterWithoutOtp;
      case 'WORKFLOW_STATISTIC_SHARE':
        return workflowStatisticShare;
      case 'RCLONE_SNAPSHOT_CHECK_FOLDER_MODTIME':
        return rcloneSnapshotCheckFolderModtime;
      case 'OPENLIST_SNAPSHOT_CHECK_FOLDER_MODTIME':
        return openlistSnapshotCheckFolderModtime;
      case 'DOCKER_CLIENT_API':
        return dockerClientApi;
      case 'PLAYWRIGHT_BROWSER_TYPE':
        return playwrightBrowserType;
      case 'AI_AGENT_ENABLE':
        return aiAgentEnable;
      case 'AI_AGENT_GLOBAL':
        return aiAgentGlobal;
      case 'LLM_PROVIDER':
        return llmProvider;
      case 'LLM_MODEL':
        return llmModel;
      case 'LLM_API_KEY':
        return llmApiKey;
      case 'LLM_BASE_URL':
        return llmBaseUrl;
      case 'LLM_MAX_CONTEXT_TOKENS':
        return llmMaxContextTokens;
      case 'LLM_TEMPERATURE':
        return llmTemperature;
      case 'LLM_MAX_ITERATIONS':
        return llmMaxIterations;
      case 'LLM_TOOL_TIMEOUT':
        return llmToolTimeout;
      case 'LLM_VERBOSE':
        return llmVerbose;
      case 'LLM_MAX_MEMORY_MESSAGES':
        return llmMaxMemoryMessages;
      case 'LLM_MEMORY_RETENTION_DAYS':
        return llmMemoryRetentionDays;
      case 'LLM_REDIS_MEMORY_RETENTION_DAYS':
        return llmRedisMemoryRetentionDays;
      case 'AI_RECOMMEND_ENABLED':
        return aiRecommendEnabled;
      case 'AI_RECOMMEND_USER_PREFERENCE':
        return aiRecommendUserPreference;
      case 'TAVILY_API_KEY':
        return tavilyApiKey;
      case 'AI_RECOMMEND_MAX_ITEMS':
        return aiRecommendMaxItems;
      case 'VERSION':
        return version;
      case 'AUTH_VERSION':
        return authVersion;
      case 'INDEXER_VERSION':
        return indexerVersion;
      case 'FRONTEND_VERSION':
        return frontendVersion;
      default:
        return null;
    }
  }
}

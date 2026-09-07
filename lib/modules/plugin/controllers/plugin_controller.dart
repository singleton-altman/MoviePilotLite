import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_backup_models.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_backup_service.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/utils/plugin_repo_url_resolver.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PluginController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _appService = Get.find<AppService>();
  final _hive = Get.find<HiveService>();
  final _backupService = PluginBackupService();
  final items = <PluginItem>[].obs;
  final keyword = ''.obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final isBackingUp = false.obs;
  final isRestoring = false.obs;
  final restoreProgress = Rxn<PluginBatchInstallProgress>();
  final autoBackupEnabled = false.obs;

  bool _visibleCacheDirty = true;
  List<PluginItem> _cachedVisible = [];
  bool _autoBackupRunning = false;
  Future<void>? _autoBackupPrefFuture;

  bool get _canAccessPlugins => _appService.canManage;

  void _clearLocalCache() {
    if (kIsWeb) return;
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) return;
    final stale = _hive.installedPluginModelCacheBox.values
        .where((item) => matchesInstalledPluginScope(item.id, scopeKey))
        .map((e) => e.id)
        .toList();
    _hive.installedPluginModelCacheBox.deleteAll(stale);
  }

  @override
  void onInit() {
    super.onInit();
    ever(keyword, (_) => _visibleCacheDirty = true);
    ever(items, (_) => _visibleCacheDirty = true);
    _loadAutoBackupPref();
  }

  void updateKeyword(String value) {
    keyword.value = value.trim();
    _visibleCacheDirty = true;
  }

  List<PluginItem> get visibleItems {
    keyword.value;
    items.length;
    if (!_visibleCacheDirty) return _cachedVisible;
    final key = keyword.value.trim().toLowerCase();
    if (key.isEmpty) {
      _cachedVisible = items.toList();
    } else {
      _cachedVisible = items.where((item) => _matchKeyword(item, key)).toList();
    }
    _visibleCacheDirty = false;
    return _cachedVisible;
  }

  bool _matchKeyword(PluginItem item, String keywordLower) {
    final buffer = StringBuffer()
      ..write(item.pluginName)
      ..write(' ')
      ..write(item.pluginDesc ?? '')
      ..write(' ')
      ..write(item.pluginLabel ?? '')
      ..write(' ')
      ..write(item.pluginAuthor ?? '');
    return buffer.toString().toLowerCase().contains(keywordLower);
  }

  @override
  void onReady() {
    super.onReady();
    // 列表加载留给页面；每日自动备份由 Index 启动链路触发，避免依赖进入插件页。
    load();
  }

  Future<void> _loadAutoBackupPref() {
    return _autoBackupPrefFuture ??= () async {
      final prefs = await SharedPreferences.getInstance();
      autoBackupEnabled.value =
          prefs.getBool(kPluginAutoBackupEnabledKey) ?? false;
    }();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _loadAutoBackupPref();
    autoBackupEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPluginAutoBackupEnabledKey, enabled);
    if (enabled) {
      await runDailyAutoBackupIfNeeded();
    }
  }

  String _todayKey([DateTime? now]) {
    final t = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  /// App 启动进入主页后调用；不依赖打开插件/备份中心页面。
  Future<void> runDailyAutoBackupIfNeeded() async {
    if (_autoBackupRunning) return;
    if (kIsWeb) return;
    await _loadAutoBackupPref();
    if (!autoBackupEnabled.value) return;
    if (!_canAccessPlugins) return;

    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastKey = kPluginAutoBackupLastDateKey(scopeKey);
    if (prefs.getString(lastKey) == today) return;

    final existing = await _backupService.listBackups(scopeKey);
    if (_backupService.hasAutoBackupOnDate(existing, DateTime.now())) {
      await prefs.setString(lastKey, today);
      return;
    }

    _autoBackupRunning = true;
    try {
      if (items.isEmpty) {
        await loadFromCache();
      }
      if (items.isEmpty) {
        await load();
      }
      if (items.isEmpty) {
        _log.info('插件每日自动备份跳过：当前无已安装插件');
        return;
      }

      final enriched = await enrichPluginsRepoUrl(items.toList());
      final saved = await _backupService.saveBackup(
        scopeKey: scopeKey,
        plugins: enriched,
        auto: true,
      );
      await prefs.setString(lastKey, today);
      _log.info('插件每日自动备份完成: ${saved.fileName}');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '插件每日自动备份失败');
    } finally {
      _autoBackupRunning = false;
    }
  }

  Future<Map<String, int>> loadInstallCount() async {
    if (!_canAccessPlugins) {
      return {};
    }
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/plugin/statistic');
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        _log.info('插件安装统计请求失败: HTTP $status');
        return {};
      }
      final parsed = parsePluginInstallCountMap(response.data);
      _log.info('插件安装统计已加载: ${parsed.length} 条');
      return parsed;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件安装统计失败');
      return {};
    }
  }

  Future<void> loadFromCache() async {
    if (!_canAccessPlugins) {
      _clearLocalCache();
      items.clear();
      _visibleCacheDirty = true;
      return;
    }
    if (kIsWeb) return;
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) {
      items.clear();
      _visibleCacheDirty = true;
      return;
    }
    final cache = _hive.installedPluginModelCacheBox.values.toList();
    if (cache.isEmpty) return;
    final locals = cache
        .where((e) => matchesInstalledPluginScope(e.id, scopeKey))
        .map(
          (e) => PluginItem(
            id: extractInstalledPluginId(e.id),
            pluginName: e.pluginName,
            pluginDesc: e.pluginDesc,
            pluginIcon: e.pluginIcon,
            pluginVersion: e.pluginVersion,
            pluginLabel: e.pluginLabel,
            pluginAuthor: e.pluginAuthor,
            authorUrl: e.authorUrl,
            pluginConfigPrefix: e.pluginConfigPrefix,
            pluginOrder: e.pluginOrder,
            authLevel: e.authLevel,
            installed: e.installed,
            state: e.state,
            hasPage: e.hasPage,
            hasUpdate: e.hasUpdate,
            isLocal: e.isLocal,
            repoUrl: e.repoUrl,
            installCount: e.installCount,
            addTime: e.addTime,
            pluginPublicKey: e.pluginPublicKey,
          ),
        )
        .toList();
    items.assignAll(locals);
  }

  void _saveToCache() {
    if (kIsWeb) return;
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) return;
    late final List<InstalledPluginModelCache> list = [];
    for (final item in items) {
      final cache = InstalledPluginModelCache(
        buildInstalledPluginCacheId(scopeKey, item.id),
        item.pluginName,
        item.pluginDesc ?? '',
        item.pluginIcon ?? '',
        item.pluginVersion ?? '',
        item.pluginLabel ?? '',
        item.pluginAuthor ?? '',
        item.authorUrl ?? '',
        item.pluginConfigPrefix ?? '',
        item.pluginOrder,
        item.authLevel,
        item.installed,
        item.state,
        item.hasPage,
        item.hasUpdate,
        item.isLocal,
        item.repoUrl ?? '',
        item.installCount,
        item.addTime,
        item.pluginPublicKey ?? '',
      );
      list.add(cache);
    }
    final stale = _hive.installedPluginModelCacheBox.values
        .where((item) => matchesInstalledPluginScope(item.id, scopeKey))
        .map((e) => e.id)
        .toList();
    _hive.installedPluginModelCacheBox.deleteAll(stale);
    for (final c in list) {
      _hive.installedPluginModelCacheBox.put(c.id, c);
    }
  }

  Future<void> load({bool force = false}) async {
    if (!_canAccessPlugins) {
      errorText.value = '当前帐号无管理权限';
      _clearLocalCache();
      items.clear();
      _visibleCacheDirty = true;
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorText.value = null;
    if (!force) {
      await loadFromCache();
    }
    try {
      final installCount = await loadInstallCount();
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/',
        queryParameters: {'state': 'installed'},
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        items.clear();
        return;
      }
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      final parsed = <PluginItem>[];
      for (final item in list) {
        if (item is! Map) continue;
        try {
          final map = Map<String, dynamic>.from(item);
          parsed.add(
            PluginItem.fromJson(map).copyWith(
              installCount: lookupPluginInstallCount(installCount, map['id']),
            ),
          );
        } catch (e, st) {
          _log.handle(e, stackTrace: st, message: '解析插件失败');
        }
      }
      items.assignAll(parsed);
      _visibleCacheDirty = true;
      _preloadPalettes(limit: 12);
      _saveToCache();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件列表失败');
      errorText.value = '请求失败，请稍后重试';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _preloadPalettes({int limit = 12}) {
    try {
      final cache = Get.isRegistered<PluginPaletteCache>()
          ? Get.find<PluginPaletteCache>()
          : Get.put(PluginPaletteCache(), permanent: true);
      final all = visibleItems;
      final slice = all.length <= limit ? all : all.take(limit);
      final urls = slice
          .map(
            (e) => e.pluginIcon != null && e.pluginIcon!.isNotEmpty
                ? ImageUtil.convertPluginIconUrl(e.pluginIcon!)
                : '',
          )
          .where((s) => s.isNotEmpty);
      cache.preload(urls);
    } catch (_) {}
  }

  Future<PluginInstallResult> installPlugin(PluginItem item) async {
    if (!_canAccessPlugins) {
      return const PluginInstallResult(success: false, message: '当前帐号无管理权限');
    }
    final candidates = await _repoCandidatesFor(item);
    if (candidates.isEmpty) {
      return const PluginInstallResult(
        success: false,
        message: '缺少仓库地址，无法安装',
      );
    }

    String? lastMessage;
    for (final repoUrl in candidates) {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/install/${item.id}',
        queryParameters: {
          'repo_url': repoUrl,
          'force': false,
        },
      );
      final data = response.data;
      final map = data is Map ? Map<String, dynamic>.from(data) : null;
      final success =
          response.statusCode == 200 && map != null && map['success'] == true;
      final message = map?['message']?.toString().trim();
      if (success) {
        return PluginInstallResult(
          success: true,
          message: message == null || message.isEmpty ? null : message,
        );
      }
      lastMessage = message == null || message.isEmpty ? null : message;
    }
    return PluginInstallResult(
      success: false,
      message: lastMessage ?? '安装失败（已尝试 ${candidates.length} 个仓库）',
    );
  }

  Future<List<PluginItem>> enrichPluginsRepoUrl(List<PluginItem> plugins) async {
    final marketRepos = await _loadPluginMarketRepos();
    return plugins
        .map(
          (item) => item.copyWith(
            repoUrl: PluginRepoUrlResolver.primaryFor(
              item,
              cachedRepoUrl: _marketCachedRepoUrl(item.id),
              marketRepos: marketRepos,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<PluginBackupFile> backupInstalledPlugins() async {
    if (!_canAccessPlugins) {
      throw StateError('当前帐号无管理权限');
    }
    if (kIsWeb) {
      throw UnsupportedError('当前平台不支持插件备份');
    }
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) {
      throw StateError('无法确定当前服务器作用域');
    }
    if (items.isEmpty) {
      throw StateError('当前没有已安装插件可备份');
    }
    isBackingUp.value = true;
    try {
      final enriched = await enrichPluginsRepoUrl(items.toList());
      final saved = await _backupService.saveBackup(
        scopeKey: scopeKey,
        plugins: enriched,
      );
      _log.info('插件备份完成: ${saved.fileName} (${saved.plugins.length})');
      return saved;
    } finally {
      isBackingUp.value = false;
    }
  }

  Future<List<PluginBackupListItem>> listPluginBackups() async {
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty || kIsWeb) return const [];
    return _backupService.listBackups(scopeKey);
  }

  Future<PluginBackupFile> readPluginBackup(String path) async {
    final backup = await _backupService.readBackupFile(path);
    final plugins = await enrichPluginsRepoUrl(backup.plugins);
    return PluginBackupFile(
      version: backup.version,
      createdAt: backup.createdAt,
      scopeKey: backup.scopeKey,
      plugins: plugins,
      fileName: backup.fileName,
      filePath: backup.filePath,
      imported: backup.imported,
      auto: backup.auto,
    );
  }

  Future<PluginBackupFile> readPluginBackupBytes(
    List<int> bytes, {
    String fileName = '',
  }) async {
    final backup = await _backupService.readBackupBytes(
      bytes,
      fileName: fileName,
    );
    final plugins = await enrichPluginsRepoUrl(backup.plugins);
    return PluginBackupFile(
      version: backup.version,
      createdAt: backup.createdAt,
      scopeKey: backup.scopeKey,
      plugins: plugins,
      fileName: backup.fileName,
      filePath: backup.filePath,
      imported: backup.imported,
      auto: backup.auto,
    );
  }

  Future<PluginBackupFile> importPluginBackup({
    String? path,
    List<int>? bytes,
    String fileName = '',
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('当前平台不支持导入备份');
    }
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) {
      throw StateError('无法确定当前服务器作用域');
    }
    final PluginBackupFile parsed;
    if (bytes != null) {
      parsed = await readPluginBackupBytes(bytes, fileName: fileName);
    } else if (path != null && path.isNotEmpty) {
      parsed = await readPluginBackup(path);
    } else {
      throw StateError('无法读取所选文件');
    }
    final saved = await _backupService.importBackup(
      scopeKey: scopeKey,
      source: parsed,
    );
    _log.info('插件备份已导入本地: ${saved.fileName} (${saved.plugins.length})');
    return saved;
  }

  Future<void> deletePluginBackup(String path) {
    return _backupService.deleteBackup(path);
  }

  Future<ShareResultStatus> exportPluginBackup(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('当前平台不支持导出备份');
    }
    final payload = await _backupService.readBackupExportPayload(path);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            mimeType: 'application/json',
            name: payload.fileName,
          ),
        ],
        subject: '插件备份 ${payload.fileName}',
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      throw StateError('当前设备不支持分享导出');
    }
    return result.status;
  }

  Future<PluginBatchInstallProgress> restorePlugins(
    List<PluginItem> selected,
  ) async {
    if (!_canAccessPlugins) {
      throw StateError('当前帐号无管理权限');
    }
    if (selected.isEmpty) {
      throw StateError('请至少选择一个插件');
    }
    isRestoring.value = true;
    var successCount = 0;
    var failedCount = 0;
    try {
      final enriched = await enrichPluginsRepoUrl(selected);
      for (var i = 0; i < enriched.length; i++) {
        final item = enriched[i];
        restoreProgress.value = PluginBatchInstallProgress(
          total: enriched.length,
          currentIndex: i,
          currentId: item.id,
          currentName: item.pluginName,
          successCount: successCount,
          failedCount: failedCount,
        );
        try {
          final result = await installPlugin(item);
          if (result.success) {
            successCount += 1;
          } else {
            failedCount += 1;
            _log.info(
              '恢复安装失败 ${item.id}: ${result.message ?? '未知错误'}',
            );
          }
        } catch (e, st) {
          failedCount += 1;
          _log.handle(e, stackTrace: st, message: '恢复安装异常 ${item.id}');
        }
        restoreProgress.value = PluginBatchInstallProgress(
          total: enriched.length,
          currentIndex: i,
          currentId: item.id,
          currentName: item.pluginName,
          successCount: successCount,
          failedCount: failedCount,
        );
      }
      final done = PluginBatchInstallProgress(
        total: enriched.length,
        currentIndex: enriched.length,
        currentName: '',
        successCount: successCount,
        failedCount: failedCount,
        done: true,
      );
      restoreProgress.value = done;
      await load(force: true);
      return done;
    } finally {
      isRestoring.value = false;
    }
  }

  Future<List<String>> _repoCandidatesFor(PluginItem item) async {
    final marketRepos = await _loadPluginMarketRepos();
    return PluginRepoUrlResolver.candidatesFor(
      item,
      cachedRepoUrl: _marketCachedRepoUrl(item.id),
      marketRepos: marketRepos,
    );
  }

  String? _marketCachedRepoUrl(String pluginId) {
    if (kIsWeb) return null;
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) return null;
    final cacheId = buildPluginMarketCacheId(scopeKey, pluginId);
    final cached = _hive.pluginModelCacheBox.get(cacheId);
    final repo = cached?.repoUrl.trim() ?? '';
    return repo.isEmpty ? null : repo;
  }

  Future<List<String>> _loadPluginMarketRepos() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/system/setting/PLUGIN_MARKET',
      );
      if ((response.statusCode ?? 0) >= 400) return const [];
      final body = response.data;
      if (body is! Map) return const [];
      final data = body['data'];
      final value = data is Map ? data['value'] : body['value'];
      if (value is String) {
        return PluginRepoUrlResolver.parseMarketRepos(value);
      }
      if (value is List) {
        return value
            .map((e) => PluginRepoUrlResolver.normalize(e?.toString()))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取 PLUGIN_MARKET 失败');
    }
    return const [];
  }

  Future<bool> resetPlugin(String id) async {
    if (!_canAccessPlugins) return false;
    final response = await _apiClient.get<dynamic>('/api/v1/plugin/reset/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> uninstallPlugin(String id) async {
    if (!_canAccessPlugins) return false;
    final response = await _apiClient.delete<dynamic>('/api/v1/plugin/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }
}

class PluginInstallResult {
  const PluginInstallResult({required this.success, this.message});

  final bool success;
  final String? message;
}

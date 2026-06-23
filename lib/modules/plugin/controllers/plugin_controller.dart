import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class PluginController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _appService = Get.find<AppService>();
  final _realm = Get.find<RealmService>();
  final items = <PluginItem>[].obs;
  final keyword = ''.obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  bool _visibleCacheDirty = true;
  List<PluginItem> _cachedVisible = [];

  bool get _canAccessPlugins => _appService.canManage;

  void _clearLocalCache() {
    if (kIsWeb) return;
    final scopeKey = _appService.pluginCacheScopeKey;
    if (scopeKey.isEmpty) return;
    final stale = _realm.realm
        .all<InstalledPluginModelCache>()
        .where((item) => matchesInstalledPluginScope(item.id, scopeKey))
        .toList();
    _realm.realm.write(() {
      _realm.realm.deleteMany(stale);
    });
  }

  @override
  void onInit() {
    super.onInit();
    ever(keyword, (_) => _visibleCacheDirty = true);
    ever(items, (_) => _visibleCacheDirty = true);
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
    load();
  }

  Future<Map<String, dynamic>> loadInstallCount() async {
    if (!_canAccessPlugins) {
      return {};
    }
    final response = await _apiClient.get<dynamic>('/api/v1/plugin/statistic');
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      return {};
    }
    return response.data ?? {};
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
    final cache = _realm.realm.all<InstalledPluginModelCache>();
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
    final stale = _realm.realm
        .all<InstalledPluginModelCache>()
        .where((item) => matchesInstalledPluginScope(item.id, scopeKey))
        .toList();
    _realm.realm.write(() {
      _realm.realm.deleteMany(stale);
      _realm.realm.addAll(list, update: true);
    });
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
    final installCount = await loadInstallCount();
    try {
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
        if (item is Map<String, dynamic>) {
          try {
            final pluginItem = PluginItem.fromJson(
              item,
            ).copyWith(installCount: installCount[item['id']] ?? 0);
            parsed.add(pluginItem);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析插件失败');
          }
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
    final queryParameters = {
      'repo_url': _normalizeInstallRepoUrl(item.repoUrl),
      'force': false,
    };
    final response = await _apiClient.get<dynamic>(
      '/api/v1/plugin/install/${item.id}',
      queryParameters: queryParameters,
    );
    final data = response.data;
    final success =
        response.statusCode == 200 &&
        data is Map<String, dynamic> &&
        data['success'] == true;
    final message = data is Map ? data['message']?.toString().trim() : null;
    return PluginInstallResult(
      success: success,
      message: message == null || message.isEmpty ? null : message,
    );
  }

  String _normalizeInstallRepoUrl(String? repoUrl) {
    final raw = repoUrl?.trim() ?? '';
    if (raw.isEmpty) return '';

    if (raw.startsWith('git@github.com:')) {
      final path = raw
          .substring('git@github.com:'.length)
          .replaceFirst(RegExp(r'\.git$'), '');
      return 'https://github.com/$path';
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return raw.replaceFirst(RegExp(r'\.git$'), '');
    }

    final normalizedPath = uri.path.replaceFirst(RegExp(r'\.git$'), '');
    return uri.replace(path: normalizedPath).toString();
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

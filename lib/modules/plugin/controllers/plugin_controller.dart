import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class PluginController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _realm = Get.find<RealmService>().realm.value;
  final items = <PluginItem>[].obs;
  final keyword = ''.obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  void updateKeyword(String value) => keyword.value = value.trim();

  List<PluginItem> get visibleItems {
    final key = keyword.value.trim().toLowerCase();
    if (key.isEmpty) return items.toList();
    return items.where((item) => _matchKeyword(item, key)).toList();
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
    final response = await _apiClient.get<dynamic>('/api/v1/plugin/statistic');
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      return {};
    }
    return response.data ?? {};
  }

  Future<void> loadFromCache() async {
    final realm = _realm;
    if (realm == null) return;
    final cache = realm.all<InstalledPluginModelCache>();
    if (cache.isEmpty) return;
    final locals = cache
        .map(
          (e) => PluginItem(
            id: e.id,
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
    late final List<InstalledPluginModelCache> list = [];
    for (final item in items) {
      final cache = InstalledPluginModelCache(
        item.id,
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
    final realm = _realm;
    if (realm == null) return;
    realm.write(() {
      realm.deleteAll<InstalledPluginModelCache>();
      realm.addAll(list, update: true);
    });
  }

  Future<void> load({bool force = false}) async {
    isLoading.value = true;
    errorText.value = null;
    if (!force) {
      loadFromCache();
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
      _preloadPalettes();
      _saveToCache();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件列表失败');
      errorText.value = '请求失败，请稍后重试';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _preloadPalettes() {
    try {
      final cache = Get.isRegistered<PluginPaletteCache>()
          ? Get.find<PluginPaletteCache>()
          : Get.put(PluginPaletteCache(), permanent: true);
      final urls = visibleItems
          .map(
            (e) => e.pluginIcon != null && e.pluginIcon!.isNotEmpty
                ? ImageUtil.convertPluginIconUrl(e.pluginIcon!)
                : '',
          )
          .where((s) => s.isNotEmpty);
      cache.preload(urls);
    } catch (_) {}
  }

  Future<bool> installPlugin(PluginItem item) async {
    final queryParameters = {'repo_url': item.repoUrl ?? '', 'force': false};
    final response = await _apiClient.get<dynamic>(
      '/api/v1/plugin/install/${item.id}',
      queryParameters: queryParameters,
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> resetPlugin(String id) async {
    final response = await _apiClient.get<dynamic>('/api/v1/plugin/reset/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> uninstallPlugin(String id) async {
    final response = await _apiClient.delete<dynamic>('/api/v1/plugin/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }
}

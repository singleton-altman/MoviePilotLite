import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/plugin/defines/plugin_list_filter_defines.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class PluginListController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _realm = Get.find<RealmService>();
  final _appService = Get.find<AppService>();
  final _authRepository = Get.find<AuthRepository>();
  static const int _pageSize = 40;

  final scrollController = ScrollController();
  final items = <PluginItem>[].obs;
  final keyword = ''.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorText = RxnString();

  int _displayedLimit = _pageSize;

  final sortKey = PluginListSortKey.defaultSort.obs;
  final sortAscending = false.obs;

  final selectedAuthors = <String>[].obs;
  final selectedLabels = <String>[].obs;
  final selectedRepos = <String>[].obs;

  @override
  void onReady() {
    super.onReady();
    load();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (isLoadingMore.value) return;
    if (!hasMore) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      loadMore();
    }
  }

  bool get hasMore {
    final all = _computeFilteredAndSorted();
    return _displayedLimit < all.length;
  }

  Future<Map<String, dynamic>> loadInstallCount() async {
    final response = await _apiClient.get<dynamic>('/api/v1/plugin/statistic');
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      return {};
    }
    return response.data ?? {};
  }

  Future<void> _refreshUserCookie() async {
    final server = _appService.baseUrl ?? _apiClient.baseUrl;
    final token =
        _appService.loginResponse?.accessToken ??
        _appService.latestLoginProfileAccessToken ??
        _apiClient.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    try {
      await _authRepository.getUserGlobalConfig(
        server: server,
        accessToken: token,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新详情 Cookie 失败');
    }
  }

  Future<void> load({bool force = false}) async {
    isLoading.value = true;
    errorText.value = null;
    await _refreshUserCookie();
    if (!force) {
      loadFromCache();
    }

    final installCount = await loadInstallCount();
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/',
        queryParameters: {'state': 'market', 'force': 'false'},
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
            parsed.add(
              PluginItem.fromJson(
                item,
              ).copyWith(installCount: installCount[item['id']] ?? 0),
            );
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析插件失败');
          }
        }
      }
      items.assignAll(parsed);
      _displayedLimit = _pageSize;
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

  Future<void> loadFromCache() async {
    final cache = _realm.realm.all<PluginModelCache>();
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
    late final List<PluginModelCache> list = [];
    for (final item in items) {
      final cache = PluginModelCache(
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
    _realm.realm.write(() {
      _realm.realm.deleteAll<PluginModelCache>();
      _realm.realm.addAll(list, update: true);
    });
  }

  void loadMore() {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    final all = _computeFilteredAndSorted();
    _displayedLimit = (_displayedLimit + _pageSize).clamp(0, all.length);
    isLoadingMore.value = false;
    _preloadPalettes();
  }

  void _preloadPalettes() {
    try {
      final cache = Get.find<PluginPaletteCache>();
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

  void updateKeyword(String value) {
    keyword.value = value.trim();
    _displayedLimit = _pageSize;
  }

  void updateSortKey(PluginListSortKey key) {
    sortKey.value = key;
    _displayedLimit = _pageSize;
  }

  void toggleSortDirection() => sortAscending.value = !sortAscending.value;

  void toggleFilter(PluginListFilterType type, String value) {
    final target = _filterList(type);
    final next = target.toList();
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    _assignFilter(type, next);
  }

  void clearFilters() {
    selectedAuthors.clear();
    selectedLabels.clear();
    selectedRepos.clear();
    _displayedLimit = _pageSize;
  }

  bool get hasActiveFilters =>
      selectedAuthors.isNotEmpty ||
      selectedLabels.isNotEmpty ||
      selectedRepos.isNotEmpty;

  List<String> get availableAuthors =>
      _uniqueOptions(items.map((e) => e.pluginAuthor));
  List<String> get availableLabels =>
      _uniqueOptions(items.map((e) => e.pluginLabel));
  List<String> get availableRepos =>
      _uniqueOptions(items.map((e) => _repoLabel(e.repoUrl)));

  List<PluginItem> get visibleItems {
    final all = _computeFilteredAndSorted();
    final end = _displayedLimit.clamp(0, all.length);
    return all.sublist(0, end);
  }

  List<PluginItem> _computeFilteredAndSorted() {
    final key = keyword.value.trim().toLowerCase();
    final authors = selectedAuthors.toSet();
    final labels = selectedLabels.toSet();
    final repos = selectedRepos.toSet();

    var results = items.toList();
    if (key.isNotEmpty) {
      results = results.where((item) => _matchKeyword(item, key)).toList();
    }
    results = results.where((item) {
      if (authors.isNotEmpty &&
          (item.pluginAuthor == null ||
              !authors.contains(item.pluginAuthor!))) {
        return false;
      }
      if (labels.isNotEmpty &&
          (item.pluginLabel == null || !labels.contains(item.pluginLabel!))) {
        return false;
      }
      if (repos.isNotEmpty) {
        final repo = _repoLabel(item.repoUrl);
        if (repo.isEmpty || !repos.contains(repo)) return false;
      }
      return true;
    }).toList();

    return _sortResults(results);
  }

  List<String> _uniqueOptions(Iterable<String?> values) {
    final set = <String>{};
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      set.add(trimmed);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  String _repoLabel(String? repoUrl) {
    if (repoUrl == null || repoUrl.trim().isEmpty) return '';
    try {
      final uri = Uri.tryParse(repoUrl);
      if (uri != null && uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return repoUrl;
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

  List<PluginItem> _sortResults(List<PluginItem> list) {
    final key = sortKey.value;
    if (key == PluginListSortKey.defaultSort) return list;
    list.sort((a, b) {
      int result;
      switch (key) {
        case PluginListSortKey.installCount:
          result = a.installCount.compareTo(b.installCount);
          break;
        case PluginListSortKey.pluginName:
          result = (a.pluginName).compareTo(b.pluginName);
          break;
        case PluginListSortKey.addTime:
          result = a.addTime.compareTo(b.addTime);
          break;
        case PluginListSortKey.defaultSort:
          result = 0;
          break;
      }
      return sortAscending.value ? result : -result;
    });
    return list;
  }

  List<String> _filterList(PluginListFilterType type) {
    switch (type) {
      case PluginListFilterType.author:
        return selectedAuthors.toList();
      case PluginListFilterType.label:
        return selectedLabels.toList();
      case PluginListFilterType.repo:
        return selectedRepos.toList();
    }
  }

  void _assignFilter(PluginListFilterType type, List<String> value) {
    switch (type) {
      case PluginListFilterType.author:
        selectedAuthors.assignAll(value);
        break;
      case PluginListFilterType.label:
        selectedLabels.assignAll(value);
        break;
      case PluginListFilterType.repo:
        selectedRepos.assignAll(value);
        break;
    }
  }
}

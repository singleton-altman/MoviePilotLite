import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/services/search_keyword_hints_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_source.dart';
import 'package:moviepilot_mobile/services/user_config_service.dart';

const List<String> _movieSubCategories = <String>[
  '正在热映',
  'TMDB 热门电影',
  '豆瓣热门电影',
  '豆瓣最新电影',
];

const List<String> _tvSubCategories = <String>[
  'TMDB热门电视剧',
  '豆瓣热门电视剧',
  '豆瓣最新电视剧',
];

const List<String> _animeSubCategories = <String>['Bangumi每日放送', '豆瓣热门动漫'];

const List<String> _chartSubCategories = <String>[
  '流行趋势',
  '豆瓣电影TOP250',
  '豆瓣国产剧集榜',
  '豆瓣全球剧集榜',
];

const List<String> _allSubCategories = <String>[
  ..._movieSubCategories,
  ..._tvSubCategories,
  ..._animeSubCategories,
  ..._chartSubCategories,
];

const Map<String, String> _subCategoryKeyMap = <String, String>{
  '正在热映': 'douban_showing',
  'TMDB 热门电影': 'tmdb_movies',
  '豆瓣热门电影': 'douban_movie_hot',
  '豆瓣最新电影': 'douban_movies',
  'TMDB热门电视剧': 'tmdb_tvs?with_original_language=zh|en|ja|ko',
  '豆瓣热门电视剧': 'douban_tv_hot',
  '豆瓣最新电视剧': 'douban_tvs',
  'Bangumi每日放送': 'bangumi_calendar',
  '豆瓣热门动漫': 'douban_tv_animation',
  '流行趋势': 'tmdb_trending',
  '豆瓣电影TOP250': 'douban_movie_top250',
  '豆瓣国产剧集榜': 'douban_tv_weekly_chinese',
  '豆瓣全球剧集榜': 'douban_tv_weekly_global',
};

enum RecommendCategory {
  all('全部', _allSubCategories),
  movie('电影', _movieSubCategories),
  tv('电视剧', _tvSubCategories),
  anime('动漫', _animeSubCategories),
  chart('榜单', _chartSubCategories);

  const RecommendCategory(this.label, this.subCategories);

  final String label;
  final List<String> subCategories;
}

class RecommendController extends GetxController {
  static const String _localConfigFileName = 'recommend_config.json';
  static const int _localConfigVersion = 1;
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  static const Duration _forceRefreshInterval = Duration(seconds: 10);
  static const Duration _throttleGap = Duration(milliseconds: 350);

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();
  final _appService = Get.find<AppService>();

  final selectedCategory = RecommendCategory.all.obs;
  final selectedSubCategory = RxnString();
  final _visibleCategories = RecommendCategory.values.toList().obs;
  final _hiddenSubCategoryKeys = <String>[].obs;
  final dynamicSources = <RecommendSource>[].obs;
  final sourceLoadError = RxnString();
  final preferenceSyncError = RxnString();
  static const _serverPreferenceKey = 'MoviePilotMobile.RecommendSources';
  final _userConfig = UserConfigService();
  Future<void> _preferenceQueue = Future.value();
  int _preferenceRevision = 0;

  List<String> subCategoriesFor(RecommendCategory category) => [
    ...category.subCategories,
    ...dynamicSources
        .where((source) => _categoryForSource(source) == category)
        .map((source) => source.name),
  ];

  RecommendCategory _categoryForSource(RecommendSource source) {
    return switch (source.type.toLowerCase()) {
      '电影' || 'movie' => RecommendCategory.movie,
      '电视剧' || 'tv' => RecommendCategory.tv,
      '动漫' || 'anime' => RecommendCategory.anime,
      _ => RecommendCategory.chart,
    };
  }

  Future<void> reloadSources() async {
    sourceLoadError.value = null;
    final profile = _profileKey();
    try {
      final sources = await RecommendSourceService().load();
      if (isClosed || profile != _profileKey()) return;
      final names = _allSubCategories.toSet();
      final paths = _subCategoryKeyMap.values
          .map(RecommendSource.resolveApiPath)
          .toSet();
      // Preserve built-in names/keys used by the existing local preferences.
      dynamicSources.assignAll(
        sources.where(
          (source) =>
              !names.contains(source.name) &&
              paths.add(source.apiPath) &&
              names.add(source.name),
        ),
      );
      _syncSubCategory();
      prefetchAllVisibleCategories();
    } catch (e, st) {
      sourceLoadError.value = '扩展推荐源加载失败，仍可使用默认来源';
      _log.handle(e, stackTrace: st, message: '加载扩展推荐源失败');
    }
  }

  Map<String, dynamic> _preferenceSnapshot() => {
    'visibleCategories': _visibleCategories
        .map((category) => category.name)
        .toList(),
    'hiddenSubCategoryKeys': _hiddenSubCategoryKeys.toList(),
  };

  Future<void> _loadServerPreferences() async {
    final profile = _profileKey();
    final revision = _preferenceRevision;
    try {
      final value = await _userConfig.read(_serverPreferenceKey);
      if (isClosed ||
          profile != _profileKey() ||
          revision != _preferenceRevision) {
        return;
      }
      if (value is! Map) return; // No preference yet: retain local defaults.
      final visible = _parseVisibleCategories(value['visibleCategories']);
      if (visible.isNotEmpty) {
        if (!visible.contains(RecommendCategory.all)) {
          visible.insert(0, RecommendCategory.all);
        }
        _visibleCategories.assignAll(visible);
      }
      _hiddenSubCategoryKeys.assignAll(
        _parseStringList(value['hiddenSubCategoryKeys']),
      );
      await _saveLocalConfig();
    } catch (e, st) {
      preferenceSyncError.value = '云端偏好读取失败，使用本地设置';
      _log.handle(e, stackTrace: st, message: '读取推荐用户偏好失败');
    }
  }

  void _persistPreferences() {
    _preferenceRevision++;
    unawaited(_saveLocalConfig());
    final snapshot = _preferenceSnapshot();
    final profile = _profileKey();
    _preferenceQueue = _preferenceQueue.then((_) async {
      if (_profileKey() != profile || isClosed) return;
      try {
        await _userConfig.write(_serverPreferenceKey, snapshot);
        preferenceSyncError.value = null;
      } catch (e, st) {
        preferenceSyncError.value = '云端偏好保存失败，设置已保存在本机';
        _log.handle(e, stackTrace: st, message: '保存推荐用户偏好失败');
      }
    });
  }

  final itemsByKey = <String, List<RecommendApiItem>>{}.obs;
  final isLoadingByKey = <String, bool>{}.obs;
  final errorByKey = <String, String?>{}.obs;

  final subscribeService = Get.put(SubscribeService());

  final categoryPageController = PageController(viewportFraction: 0.95);

  PageController? _bannerPageController;
  PageController get bannerPageController =>
      _bannerPageController ??= PageController(viewportFraction: 1);

  final bannerPageIndex = 0.obs;

  Future<void> _requestQueue = Future.value();
  final _pendingKeys = <String>{};
  final Map<String, DateTime> _lastFetchAt = {};

  /// 进行中的 Cookie 刷新。冷启动时多个分区会并发触发刷新，
  /// 共享同一个 Future，所有调用方都等到刷新真正完成再发请求。
  Future<void>? _cookieRefresh;

  List<RecommendCategory> get visibleCategories => _visibleCategories;

  List<String> get currentSubCategories {
    final category = selectedCategory.value;
    if (category == RecommendCategory.all) {
      return _visibleAllSubCategories();
    }
    return _visibleSubCategoriesFor(category);
  }

  List<String> get allVisibleSubCategories => _visibleAllSubCategories();

  @override
  void onInit() {
    super.onInit();
    _initLocalConfig();
  }

  @override
  void onClose() {
    categoryPageController.dispose();
    _bannerPageController?.dispose();
    super.onClose();
  }

  Future<void> _initLocalConfig() async {
    await _loadLocalConfig();
    _syncSubCategory();
    if (!_appService.canDiscovery || isClosed) {
      return;
    }
    await Future.wait([_loadServerPreferences(), reloadSources()]);
    if (isClosed) return;
    _ensureSelectedCategoryVisible();
    prefetchAllVisibleCategories();
    ever(selectedCategory, (_) {
      if (!_appService.canDiscovery) return;
      prefetchAllVisibleCategories(forceRefresh: true);
      _prefetchSubscribeStatusesForCurrentCategory();
    });
  }

  /// 确保用户 Cookie 已就绪。并发调用方共享同一次刷新并一起等待它完成——
  /// 豆瓣等来源不带 Cookie 时服务端会返回空列表，所以首个请求就必须带上。
  Future<void> ensureUserCookieRefreshed() {
    final pending = _cookieRefresh;
    if (pending != null) return pending;
    final future = _refreshUserCookie().whenComplete(() {
      _cookieRefresh = null;
    });
    _cookieRefresh = future;
    return future;
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
      _log.handle(e, stackTrace: st, message: '刷新推荐 Cookie 失败');
    }
    return;
  }

  void selectCategory(RecommendCategory category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    _syncSubCategory();
  }

  void selectSubCategory(String? subCategory) {
    if (subCategory == null || subCategory.isEmpty) return;
    if (!currentSubCategories.contains(subCategory)) {
      return;
    }
    selectedSubCategory.value = subCategory;
  }

  String? keyForSubCategory(String subCategory) {
    return _subCategoryKeyMap[subCategory] ??
        dynamicSources
            .firstWhereOrNull((source) => source.name == subCategory)
            ?.apiPath;
  }

  List<RecommendApiItem> itemsForSubCategory(String subCategory) {
    final key = keyForSubCategory(subCategory);
    if (key == null) return const [];
    return itemsByKey[key] ?? const [];
  }

  bool isLoadingForSubCategory(String subCategory) {
    final key = keyForSubCategory(subCategory);
    if (key == null) return false;
    return isLoadingByKey[key] ?? false;
  }

  /// 该分组是否还没有任何结果（既没有缓存条目，也没有已记录的失败）。
  /// 首屏用它判断该画骨架而不是空白。
  bool isAwaitingFirstResult(String subCategory) {
    if (!_appService.canDiscovery) return false;
    final key = keyForSubCategory(subCategory);
    if (key == null) return false;
    if (errorByKey[key] != null) return false;
    // 请求成功但确实返回空列表时也算「已有结果」，否则骨架会一直挂着不消失
    return !itemsByKey.containsKey(key);
  }

  String? errorForSubCategory(String subCategory) {
    final key = keyForSubCategory(subCategory);
    if (key == null) return null;
    return errorByKey[key];
  }

  void ensureSubCategoryLoaded(
    String subCategory, {
    bool forceRefresh = false,
  }) {
    final key = keyForSubCategory(subCategory);
    if (key == null) return;

    final hasCache = itemsByKey.containsKey(key);
    if (hasCache) {
      final shouldRefresh = forceRefresh
          ? _shouldForceRefresh(key)
          : _shouldRefresh(key);
      if (!shouldRefresh) return;
    }
    _enqueueFetch(key, subCategory);
  }

  void prefetchCurrentCategory({bool forceRefresh = false}) {
    if (!_appService.canDiscovery) return;
    // 预热 Cookie；入队后的请求自身会等待这次刷新完成
    unawaited(ensureUserCookieRefreshed());
    for (final subCategory in currentSubCategories) {
      ensureSubCategoryLoaded(subCategory, forceRefresh: forceRefresh);
    }
  }

  void prefetchAllVisibleCategories({bool forceRefresh = false}) {
    if (!_appService.canDiscovery) return;
    // 预热 Cookie；入队后的请求自身会等待这次刷新完成
    unawaited(ensureUserCookieRefreshed());
    for (final subCategory in allVisibleSubCategories) {
      ensureSubCategoryLoaded(subCategory, forceRefresh: forceRefresh);
    }
  }

  bool isCategoryVisible(RecommendCategory category) {
    return _visibleCategories.contains(category);
  }

  void setCategoryVisibility(RecommendCategory category, bool visible) {
    final next = _visibleCategories.toList();
    if (visible) {
      if (!next.contains(category)) {
        next.add(category);
      }
    } else {
      if (next.length <= 1) return;
      next.remove(category);
    }

    next.sort(
      (a, b) => RecommendCategory.values
          .indexOf(a)
          .compareTo(RecommendCategory.values.indexOf(b)),
    );
    _visibleCategories.assignAll(next);
    _ensureSelectedCategoryVisible();
    prefetchAllVisibleCategories();
    _persistPreferences();
  }

  bool isSubCategoryVisible(RecommendCategory category, String subCategory) {
    return !_hiddenSubCategoryKeys.contains(_subKey(category, subCategory));
  }

  void setSubCategoryVisibility(
    RecommendCategory category,
    String subCategory,
    bool visible,
  ) {
    final key = _subKey(category, subCategory);
    if (visible) {
      _hiddenSubCategoryKeys.remove(key);
    } else {
      if (!_hiddenSubCategoryKeys.contains(key)) {
        _hiddenSubCategoryKeys.add(key);
      }
    }
    _hiddenSubCategoryKeys.refresh();
    _syncSubCategory();
    prefetchAllVisibleCategories();
    _persistPreferences();
  }

  Future<void> _loadLocalConfig() async {
    if (kIsWeb) return;
    try {
      final file = await _resolveLocalConfigFile();
      if (file == null || !await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final profiles = decoded['profiles'];
      if (profiles is! Map) return;
      final key = _profileKey();
      final profile = profiles[key];
      if (profile is! Map) return;
      final visibleRaw = profile['visibleCategories'];
      final hiddenRaw = profile['hiddenSubCategoryKeys'];
      final visible = _parseVisibleCategories(visibleRaw);
      if (visible.isNotEmpty) {
        if (!visible.contains(RecommendCategory.all)) {
          visible.insert(0, RecommendCategory.all);
        }
        _visibleCategories.assignAll(visible);
      }
      final hidden = _parseStringList(hiddenRaw);
      if (hidden.isNotEmpty) {
        _hiddenSubCategoryKeys.assignAll(hidden);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取推荐分组配置失败');
    }
  }

  Future<void> _saveLocalConfig() async {
    if (kIsWeb) return;
    try {
      final file = await _resolveLocalConfigFile();
      if (file == null) return;
      final data = await _readLocalConfigRaw(file);
      final profiles = <String, dynamic>{};
      final existingProfiles = data['profiles'];
      if (existingProfiles is Map) {
        profiles.addAll(existingProfiles.cast<String, dynamic>());
      }
      profiles[_profileKey()] = {
        'visibleCategories': _visibleCategories
            .map((category) => category.name)
            .toList(),
        'hiddenSubCategoryKeys': _hiddenSubCategoryKeys.toList(),
      };
      data['version'] = _localConfigVersion;
      data['profiles'] = profiles;
      await file.writeAsString(jsonEncode(data));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存推荐分组配置失败');
    }
  }

  Future<File?> _resolveLocalConfigFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_localConfigFileName');
  }

  Future<Map<String, dynamic>> _readLocalConfigRaw(File file) async {
    if (!await file.exists()) return <String, dynamic>{};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  String _profileKey() {
    final baseUrl =
        _appService.baseUrl ?? _apiClient.baseUrl ?? 'default-server';
    final userId =
        _appService.loginResponse?.userId ?? _appService.userInfo?.id ?? 0;
    return '$baseUrl::$userId';
  }

  List<RecommendCategory> _parseVisibleCategories(dynamic raw) {
    if (raw is! List) return const [];
    final items = <RecommendCategory>[];
    for (final entry in raw) {
      final name = entry?.toString();
      if (name == null || name.isEmpty) continue;
      RecommendCategory? match;
      for (final category in RecommendCategory.values) {
        if (category.name == name) {
          match = category;
          break;
        }
      }
      if (match != null && !items.contains(match)) {
        items.add(match);
      }
    }
    return items;
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => item?.toString())
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  void _ensureSelectedCategoryVisible() {
    final category = selectedCategory.value;
    if (_visibleCategories.contains(category)) {
      _syncSubCategory();
      return;
    }
    selectedCategory.value = _visibleCategories.first;
    _syncSubCategory();
  }

  void _syncSubCategory() {
    final items = currentSubCategories;
    final current = selectedSubCategory.value;
    if (current != null && items.contains(current)) return;
    selectedSubCategory.value = items.isNotEmpty ? items.first : null;
  }

  List<String> _visibleSubCategoriesFor(RecommendCategory category) {
    return subCategoriesFor(
      category,
    ).where((sub) => isSubCategoryVisible(category, sub)).toList();
  }

  List<String> _visibleAllSubCategories() {
    final result = <String>[];
    for (final category in RecommendCategory.values) {
      if (category == RecommendCategory.all) continue;
      if (!isCategoryVisible(category)) continue;
      for (final sub in subCategoriesFor(category)) {
        if (isSubCategoryVisible(category, sub)) {
          result.add(sub);
        }
      }
    }
    return result;
  }

  String _subKey(RecommendCategory category, String subCategory) {
    return '${category.name}::$subCategory';
  }

  bool _shouldRefresh(String key) {
    final last = _lastFetchAt[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minRefreshInterval;
  }

  bool _shouldForceRefresh(String key) {
    final last = _lastFetchAt[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _forceRefreshInterval;
  }

  void _enqueueFetch(String key, String subCategory) {
    if (_pendingKeys.contains(key)) return;
    _pendingKeys.add(key);
    _requestQueue = _requestQueue
        .then((_) async {
          try {
            await _fetchSubCategory(key, subCategory);
          } finally {
            _pendingKeys.remove(key);
            await Future.delayed(_throttleGap);
          }
        })
        .catchError((error, stack) {
          _log.handle(error, stackTrace: stack, message: '推荐请求队列异常');
        });
  }

  Future<void> _fetchSubCategory(String key, String subCategory) async {
    isLoadingByKey[key] = true;
    errorByKey[key] = null;
    isLoadingByKey.refresh();
    errorByKey.refresh();

    try {
      // 先等 Cookie 就绪再请求：冷启动时 AppService 里还没有 Cookie，
      // 抢先发出去会拿到「成功但空列表」，表现为首屏没数据、刷新才有。
      await ensureUserCookieRefreshed();
      final url = RecommendSource.resolveApiPath(key);
      final response = await _apiClient.get<dynamic>(url);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        errorByKey[key] = '请求失败 (HTTP $statusCode)';
        return;
      }

      final payload = _decodePayload(response.data);
      final list = _extractList(payload);
      final category = _categoryForSubCategory(subCategory);
      final fallbackMediaType = category?.label ?? '电影';
      final items = _parseItems(list, fallbackMediaType: fallbackMediaType);

      itemsByKey[key] = items;
      itemsByKey.refresh();
      _lastFetchAt[key] = DateTime.now();
      unawaited(Get.find<SearchKeywordHintsService>().ingestFromItems(items));
      // 订阅状态只为当前展示的分类预取；其余分类等切换过去再补，
      // 避免启动时为所有榜单的每一条都打一个请求。
      if (currentSubCategories.contains(subCategory)) {
        _prefetchSubscribeStatuses(items);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '推荐数据请求异常');
      errorByKey[key] = '请求异常';
    } finally {
      isLoadingByKey[key] = false;
      isLoadingByKey.refresh();
    }
  }

  dynamic _decodePayload(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = _toStringKeyMap(payload);
      final candidates = <String>[
        'data',
        'results',
        'items',
        'list',
        'subjects',
        'subject',
        'rows',
      ];
      for (final key in candidates) {
        final value = map[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }

      for (final entry in map.values) {
        if (entry is List) return entry;
        if (entry is Map) {
          final nested = _extractList(entry);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _toStringKeyMap(Map<dynamic, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key is String) {
        result[key] = value;
      }
    });
    return result;
  }

  List<RecommendApiItem> _parseItems(
    List<dynamic> rawList, {
    required String fallbackMediaType,
  }) {
    final items = <RecommendApiItem>[];
    for (var i = 0; i < rawList.length; i++) {
      final raw = rawList[i];
      if (raw is! Map) continue;
      final map = _toStringKeyMap(raw);
      try {
        final apiItem = RecommendApiItem.fromJson(normalizeMediaJson(map));
        items.add(apiItem);
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '解析推荐条目失败');
      }
    }
    return items;
  }

  RecommendCategory? _categoryForSubCategory(String subCategory) {
    for (final category in RecommendCategory.values) {
      if (category == RecommendCategory.all) continue;
      if (category.subCategories.contains(subCategory)) return category;
    }
    return null;
  }

  void _prefetchSubscribeStatuses(Iterable<RecommendApiItem> items) {
    for (final item in items) {
      subscribeService.prefetchSubscribeStatus(
        item.mediaKey,
        season: item.season,
        title: item.title,
      );
    }
  }

  /// 为当前分类下已加载的榜单补齐订阅状态；已有新鲜结果的 key 会被服务层跳过
  void _prefetchSubscribeStatusesForCurrentCategory() {
    for (final subCategory in currentSubCategories) {
      _prefetchSubscribeStatuses(itemsForSubCategory(subCategory));
    }
  }
}

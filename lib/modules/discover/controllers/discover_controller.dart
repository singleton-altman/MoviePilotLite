import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/discover/defines/discover_filter_defines.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_dynamic_source.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_filters.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/services/search_keyword_hints_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DiscoverSource {
  tmdb('TheMovieDB'),
  douban('豆瓣'),
  bangumi('Bangumi');

  const DiscoverSource(this.label);

  final String label;
}

class DiscoverSourceEntry {
  const DiscoverSourceEntry._({
    required this.id,
    required this.label,
    this.localSource,
    this.dynamicSource,
  });

  factory DiscoverSourceEntry.local(DiscoverSource source) {
    return DiscoverSourceEntry._(
      id: source.name,
      label: source.label,
      localSource: source,
    );
  }

  factory DiscoverSourceEntry.dynamic(DiscoverDynamicSource source) {
    return DiscoverSourceEntry._(
      id: 'dynamic:${source.id}',
      label: source.name,
      dynamicSource: source,
    );
  }

  final String id;
  final String label;
  final DiscoverSource? localSource;
  final DiscoverDynamicSource? dynamicSource;

  bool get isDynamic => dynamicSource != null;

  @override
  bool operator ==(Object other) {
    return other is DiscoverSourceEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DiscoverController extends GetxController {
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  static const Duration _forceRefreshInterval = Duration(seconds: 10);
  static const Duration _throttleGap = Duration(milliseconds: 350);
  static const String _lastSelectedSourceKey = 'discover.lastSelectedSourceId';

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();
  final _appService = Get.find<AppService>();

  final sourceEntries = <DiscoverSourceEntry>[].obs;
  final selectedSource = DiscoverSourceEntry.local(DiscoverSource.tmdb).obs;
  final filters = const DiscoverFilters().obs;
  final dynamicFilters = const DiscoverDynamicFilters().obs;
  final _filtersBySource = <String, DiscoverFilters>{};
  final _dynamicFiltersBySource = <String, DiscoverDynamicFilters>{};
  final _dynamicSourcesById = <String, DiscoverDynamicSource>{};

  final itemsByKey = <String, List<RecommendApiItem>>{}.obs;
  final isLoadingByKey = <String, bool>{}.obs;
  final errorByKey = <String, String?>{}.obs;
  final isLoadingDynamicSources = false.obs;
  final dynamicSourcesError = RxnString();

  Future<void> _requestQueue = Future.value();
  final _pendingKeys = <String>{};
  final Map<String, DateTime> _lastFetchAt = {};
  bool _suspendAutoLoad = false;
  bool _cookieRefreshTriggered = false;

  @override
  void onInit() {
    super.onInit();
    _bootstrapFilters();
    unawaited(_restoreLastSelectedSourceAndLoad());
    ever(selectedSource, (_) {
      if (_suspendAutoLoad) return;
      if (!_appService.canDiscovery) return;
      loadCurrent(forceRefresh: true);
    });
    ever(filters, (_) {
      if (_suspendAutoLoad) return;
      if (!_appService.canDiscovery) return;
      if (selectedSource.value.isDynamic) return;
      loadCurrent(forceRefresh: true);
    });
    ever(dynamicFilters, (_) {
      if (_suspendAutoLoad) return;
      if (!_appService.canDiscovery) return;
      if (!selectedSource.value.isDynamic) return;
      loadCurrent(forceRefresh: true);
    });
  }

  void selectSource(DiscoverSourceEntry source) {
    if (selectedSource.value == source) return;
    _suspendAutoLoad = true;
    _activateSource(source);
    _suspendAutoLoad = false;
    unawaited(_persistSelectedSource(source));
    loadCurrent(forceRefresh: true);
  }

  void _activateSource(DiscoverSourceEntry source) {
    selectedSource.value = source;
    if (source.isDynamic) {
      final next =
          _dynamicFiltersBySource[source.id] ??
          source.dynamicSource?.defaultFilters() ??
          const DiscoverDynamicFilters();
      _dynamicFiltersBySource[source.id] = next;
      dynamicFilters.value = next;
    } else {
      final local = source.localSource ?? DiscoverSource.tmdb;
      final next = _filtersBySource[source.id] ?? _defaultFiltersFor(local);
      _filtersBySource[source.id] = next;
      filters.value = next;
    }
  }

  Future<void> _restoreLastSelectedSourceAndLoad() async {
    var storedSourceId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      storedSourceId = prefs.getString(_lastSelectedSourceKey) ?? '';
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取探索来源偏好失败');
    }

    final localSource = _findSourceById(storedSourceId);
    if (localSource != null) {
      _suspendAutoLoad = true;
      _activateSource(localSource);
      _suspendAutoLoad = false;
    }

    await loadDynamicSources(forceRefresh: true);

    final restoredSource = _findSourceById(storedSourceId);
    if (restoredSource != null) {
      _suspendAutoLoad = true;
      _activateSource(restoredSource);
      _suspendAutoLoad = false;
    }

    if (_appService.canDiscovery) {
      loadCurrent();
    }
  }

  DiscoverSourceEntry? _findSourceById(String id) {
    if (id.isEmpty) return null;
    for (final source in sourceEntries) {
      if (source.id == id) return source;
    }
    return null;
  }

  Future<void> _persistSelectedSource(DiscoverSourceEntry source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSelectedSourceKey, source.id);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存探索来源偏好失败');
    }
  }

  void updateFilters(DiscoverFilters next) {
    filters.value = next;
    _filtersBySource[selectedSource.value.id] = next;
  }

  void updateDynamicFilters(DiscoverDynamicFilters next) {
    dynamicFilters.value = next;
    _dynamicFiltersBySource[selectedSource.value.id] = next;
  }

  void ensureUserCookieRefreshed() {
    if (_cookieRefreshTriggered) return;
    _cookieRefreshTriggered = true;
    _refreshUserCookie();
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
      _log.handle(e, stackTrace: st, message: '刷新探索 Cookie 失败');
    }
  }

  Map<String, DiscoverFilters> snapshotFiltersBySource() {
    final snapshot = <String, DiscoverFilters>{};
    for (final source in sourceEntries) {
      final local = source.localSource;
      if (local == null) continue;
      snapshot[source.id] =
          _filtersBySource[source.id] ?? _defaultFiltersFor(local);
    }
    return snapshot;
  }

  Map<String, DiscoverDynamicFilters> snapshotDynamicFiltersBySource() {
    final snapshot = <String, DiscoverDynamicFilters>{};
    for (final source in sourceEntries) {
      final dynamicSource = source.dynamicSource;
      if (dynamicSource == null) continue;
      snapshot[source.id] =
          _dynamicFiltersBySource[source.id] ?? dynamicSource.defaultFilters();
    }
    return snapshot;
  }

  void applySelection(
    DiscoverSourceEntry source,
    Map<String, DiscoverFilters> filtersBySource,
    Map<String, DiscoverDynamicFilters> dynamicFiltersBySource,
  ) {
    _suspendAutoLoad = true;
    _filtersBySource
      ..clear()
      ..addAll(filtersBySource);
    _dynamicFiltersBySource
      ..clear()
      ..addAll(dynamicFiltersBySource);
    selectedSource.value = source;
    if (source.isDynamic) {
      dynamicFilters.value =
          dynamicFiltersBySource[source.id] ??
          source.dynamicSource?.defaultFilters() ??
          const DiscoverDynamicFilters();
    } else {
      final local = source.localSource ?? DiscoverSource.tmdb;
      filters.value = filtersBySource[source.id] ?? _defaultFiltersFor(local);
    }
    _suspendAutoLoad = false;
    unawaited(_persistSelectedSource(source));
    loadCurrent(forceRefresh: true);
  }

  List<RecommendApiItem> currentItems() {
    final key = _cacheKeyForCurrent();
    return itemsByKey[key] ?? const [];
  }

  bool isLoading() {
    final key = _cacheKeyForCurrent();
    return isLoadingByKey[key] ?? false;
  }

  String? errorText() {
    final key = _cacheKeyForCurrent();
    return errorByKey[key];
  }

  void loadCurrent({bool forceRefresh = false}) {
    if (!_appService.canDiscovery) {
      return;
    }
    final source = selectedSource.value;
    final key = _cacheKeyForCurrent();

    final hasCache = itemsByKey.containsKey(key);
    if (hasCache) {
      final shouldRefresh = forceRefresh
          ? _shouldForceRefresh(key)
          : _shouldRefresh(key);
      if (!shouldRefresh) return;
    }

    _enqueueFetch(source, key);
  }

  void _enqueueFetch(DiscoverSourceEntry source, String key) {
    if (_pendingKeys.contains(key)) return;
    _pendingKeys.add(key);
    _requestQueue = _requestQueue
        .then((_) async {
          try {
            await _fetch(source, key);
          } finally {
            _pendingKeys.remove(key);
            await Future.delayed(_throttleGap);
          }
        })
        .catchError((error, stack) {
          _log.handle(error, stackTrace: stack, message: '探索请求队列异常');
        });
  }

  Future<void> _fetch(DiscoverSourceEntry source, String key) async {
    isLoadingByKey[key] = true;
    errorByKey[key] = null;
    isLoadingByKey.refresh();
    errorByKey.refresh();

    try {
      final request = source.isDynamic
          ? _dynamicRequestFor(source.dynamicSource!, dynamicFilters.value)
          : _localRequestFor(
              source.localSource ?? DiscoverSource.tmdb,
              filters.value,
            );
      final path = request.path;
      final query = request.query;
      _log.info('探索请求: $path, $query');
      final response = await _apiClient.get<dynamic>(
        path,
        queryParameters: query,
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        errorByKey[key] = '请求失败 (HTTP $statusCode)';
        return;
      }

      final payload = _decodePayload(response.data);
      final list = _extractList(payload);
      final items = _parseItems(
        list,
        fallbackMediaType: _fallbackMediaTypeFor(source),
      );
      ensureUserCookieRefreshed();
      itemsByKey[key] = items;
      itemsByKey.refresh();
      _lastFetchAt[key] = DateTime.now();
      unawaited(Get.find<SearchKeywordHintsService>().ingestFromItems(items));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '探索数据请求异常');
      errorByKey[key] = '请求异常';
    } finally {
      isLoadingByKey[key] = false;
      isLoadingByKey.refresh();
    }
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

  String _cacheKeyForCurrent() {
    final source = selectedSource.value;
    if (source.isDynamic) {
      final dynamicSource = source.dynamicSource;
      final apiPath = dynamicSource?.apiPath ?? '';
      return '${source.id}|$apiPath|${dynamicFilters.value.signature()}';
    }
    final local = source.localSource ?? DiscoverSource.tmdb;
    final filter = filters.value;
    final endpoint = _endpointFor(local, filter);
    return '${source.id}|$endpoint|${_signatureFor(local, filter)}';
  }

  void _bootstrapFilters() {
    final entries = DiscoverSource.values
        .map((source) => DiscoverSourceEntry.local(source))
        .toList();
    sourceEntries.assignAll(entries);
    for (final entry in entries) {
      final local = entry.localSource!;
      _filtersBySource[entry.id] = _defaultFiltersFor(local);
    }
    filters.value = _filtersBySource[selectedSource.value.id]!;
  }

  Future<void> loadDynamicSources({bool forceRefresh = false}) async {
    if (!_appService.canDiscovery) return;
    if (isLoadingDynamicSources.value && !forceRefresh) return;
    isLoadingDynamicSources.value = true;
    dynamicSourcesError.value = null;
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/discover/source');
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        dynamicSourcesError.value = '动态来源请求失败 (HTTP $statusCode)';
        return;
      }
      final payload = _decodePayload(response.data);
      final list = payload is List ? payload : _extractList(payload);
      final dynamicSources = <DiscoverDynamicSource>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        try {
          final source = DiscoverDynamicSource.fromJson(_toStringKeyMap(raw));
          if (source.id.isEmpty || source.apiPath.isEmpty) continue;
          dynamicSources.add(source);
        } catch (e, st) {
          _log.handle(e, stackTrace: st, message: '解析动态探索来源失败');
        }
      }

      _dynamicSourcesById
        ..clear()
        ..addEntries(
          dynamicSources.map((source) => MapEntry(source.id, source)),
        );
      for (final source in dynamicSources) {
        final entry = DiscoverSourceEntry.dynamic(source);
        _dynamicFiltersBySource.putIfAbsent(entry.id, source.defaultFilters);
      }
      final localEntries = DiscoverSource.values
          .map((source) => DiscoverSourceEntry.local(source))
          .toList();
      final dynamicEntries = dynamicSources
          .map((source) => DiscoverSourceEntry.dynamic(source))
          .toList();
      final nextEntries = [...localEntries, ...dynamicEntries];
      sourceEntries.assignAll(nextEntries);
      final refreshedSelection = _findSourceById(selectedSource.value.id);
      if (refreshedSelection != null) {
        _suspendAutoLoad = true;
        _activateSource(refreshedSelection);
        _suspendAutoLoad = false;
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取动态探索来源失败');
      dynamicSourcesError.value = '动态来源请求异常';
    } finally {
      isLoadingDynamicSources.value = false;
    }
  }

  DiscoverDynamicSource? dynamicSourceFor(DiscoverSourceEntry source) {
    return source.dynamicSource;
  }

  DiscoverDynamicFilters dynamicFiltersFor(DiscoverSourceEntry source) {
    return _dynamicFiltersBySource[source.id] ??
        source.dynamicSource?.defaultFilters() ??
        const DiscoverDynamicFilters();
  }

  void selectDynamicFilter(String model, String value) {
    final source = selectedSource.value.dynamicSource;
    if (source == null) return;
    updateDynamicFilters(
      source.selectValue(dynamicFilters.value, model, value),
    );
  }

  String currentSummaryText() {
    final source = selectedSource.value;
    if (source.isDynamic) {
      final dynamicSource = source.dynamicSource;
      if (dynamicSource == null) return source.label;
      return dynamicSource.summaryParts(dynamicFilters.value).join(' · ');
    }
    final local = source.localSource ?? DiscoverSource.tmdb;
    return _localSummaryText(local, filters.value);
  }

  String _fallbackMediaTypeFor(DiscoverSourceEntry source) {
    if (source.isDynamic) {
      return source.dynamicSource?.fallbackMediaType(dynamicFilters.value) ??
          source.label;
    }
    final filter = filters.value;
    return filter.mediaType.isNotEmpty ? filter.mediaType : source.label;
  }

  _DiscoverRequest _localRequestFor(
    DiscoverSource source,
    DiscoverFilters filter,
  ) {
    final endpoint = _endpointFor(source, filter);
    return _DiscoverRequest(
      path: '/api/v1/discover/$endpoint',
      query: _buildQueryParams(source, filter),
    );
  }

  _DiscoverRequest _dynamicRequestFor(
    DiscoverDynamicSource source,
    DiscoverDynamicFilters filter,
  ) {
    final uri = Uri.tryParse(source.apiPath);
    var path = uri?.path ?? source.apiPath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (!path.startsWith('api/v1/')) {
      path = 'api/v1/$path';
    }
    final query = <String, String>{
      if (uri != null) ...uri.queryParameters,
      'page': '1',
      ...source.visibleQueryValues(filter),
    };
    return _DiscoverRequest(path: '/$path', query: query);
  }

  DiscoverFilters _defaultFiltersFor(DiscoverSource source) {
    switch (source) {
      case DiscoverSource.tmdb:
        return const DiscoverFilters(
          mediaType: '电影',
          sortBy: 'popularity.desc',
          voteAverage: 0,
        );
      case DiscoverSource.douban:
        return const DiscoverFilters(mediaType: '电影', sortBy: 'U');
      case DiscoverSource.bangumi:
        return const DiscoverFilters(
          mediaType: '',
          bangumiCategory: '',
          sortBy: 'rank',
        );
    }
  }

  String _endpointFor(DiscoverSource source, DiscoverFilters filter) {
    switch (source) {
      case DiscoverSource.tmdb:
        return _isTvType(filter.mediaType) ? 'tmdb_tvs' : 'tmdb_movies';
      case DiscoverSource.douban:
        return _isTvType(filter.mediaType) ? 'douban_tvs' : 'douban_movies';
      case DiscoverSource.bangumi:
        return 'bangumi';
    }
  }

  bool _isTvType(String mediaType) {
    final normalized = mediaType.trim();
    if (normalized.isEmpty) return false;
    return normalized == '电视剧';
  }

  Map<String, String> _buildQueryParams(
    DiscoverSource source,
    DiscoverFilters filter,
  ) {
    if (source == DiscoverSource.douban) {
      return _buildDoubanQuery(filter);
    }
    final options = _queryOptionsFor(source, filter);
    return filter.toQueryParameters(
      useOriginCountry: options.useOriginCountry,
      useProductionCountries: options.useProductionCountries,
    );
  }

  String _signatureFor(DiscoverSource source, DiscoverFilters filter) {
    final params = _buildQueryParams(source, filter);
    final keys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write('$key=${params[key]};');
    }
    return buffer.toString();
  }

  _QueryOptions _queryOptionsFor(
    DiscoverSource source,
    DiscoverFilters filter,
  ) {
    if (source == DiscoverSource.tmdb) {
      final isTv = _isTvType(filter.mediaType);
      return _QueryOptions(
        useOriginCountry: isTv,
        useProductionCountries: !isTv,
      );
    }
    return const _QueryOptions();
  }

  Map<String, String> _buildDoubanQuery(DiscoverFilters filter) {
    final tags = <String>[];
    tags.addAll(
      _labelsForValues(
        filter.selectedGenres,
        DiscoverFilterDefines.doubanGenreOptions,
      ),
    );
    tags.addAll(
      _labelsForValues(
        filter.selectedRegions,
        DiscoverFilterDefines.regionOptions,
      ),
    );
    final decadeLabel = _labelForValue(
      filter.selectedDecade,
      DiscoverFilterDefines.decadeOptions,
    );
    if (decadeLabel.isNotEmpty) {
      tags.add(decadeLabel);
    }
    final sort = _mapDoubanSort(filter.sortBy);
    final params = <String, String>{
      'page': filter.page.toString(),
      'sort': sort,
    };
    if (tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }
    return params;
  }

  String _localSummaryText(DiscoverSource source, DiscoverFilters filter) {
    switch (source) {
      case DiscoverSource.tmdb:
        return _joinSummary([
          source.label,
          filter.mediaType.isEmpty ? '类型:全部' : filter.mediaType,
          _labelForSort(_tmdbSortLabels(filter.mediaType), filter.sortBy),
          _formatListWithOptions(
            filter.selectedGenres,
            _tmdbGenreOptions(filter.mediaType),
            '风格:全部',
          ),
          _formatListWithOptions(
            filter.selectedLanguages,
            DiscoverFilterDefines.tmdbLanguageOptions,
            '语言:全部',
          ),
          filter.voteAverage <= 0 ? '评分不限' : '${filter.voteAverage}分+',
        ]);
      case DiscoverSource.douban:
        return _joinSummary([
          source.label,
          filter.mediaType.isEmpty ? '类型:全部' : filter.mediaType,
          _labelForSort(DiscoverFilterDefines.doubanSortLabels, filter.sortBy),
          _formatListWithOptions(
            filter.selectedGenres,
            DiscoverFilterDefines.doubanGenreOptions,
            '风格:全部',
          ),
          _formatListWithOptions(
            filter.selectedRegions,
            DiscoverFilterDefines.regionOptions,
            '地区:全部',
          ),
          _labelForValue(
                filter.selectedDecade,
                DiscoverFilterDefines.decadeOptions,
              ).isEmpty
              ? '年代:全部'
              : _labelForValue(
                  filter.selectedDecade,
                  DiscoverFilterDefines.decadeOptions,
                ),
        ]);
      case DiscoverSource.bangumi:
        return _joinSummary([
          source.label,
          filter.bangumiCategory.isEmpty ? '类别:全部' : filter.bangumiCategory,
          _labelForSort(DiscoverFilterDefines.bangumiSortLabels, filter.sortBy),
          filter.bangumiYear.isEmpty ? '年份:全部' : filter.bangumiYear,
        ]);
    }
  }

  String _joinSummary(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(' · ');
  }

  String _labelForSort(Map<String, String> labels, String value) {
    return labels[value] ?? value;
  }

  Map<String, String> _tmdbSortLabels(String mediaType) {
    return _isTvType(mediaType)
        ? DiscoverFilterDefines.tmdbTvSortLabels
        : DiscoverFilterDefines.tmdbMovieSortLabels;
  }

  List<DiscoverFilterOption> _tmdbGenreOptions(String mediaType) {
    return _isTvType(mediaType)
        ? DiscoverFilterDefines.tmdbTvGenreOptions
        : DiscoverFilterDefines.tmdbMovieGenreOptions;
  }

  String _formatListWithOptions(
    List<String> values,
    List<DiscoverFilterOption> options,
    String emptyLabel,
  ) {
    if (values.isEmpty) return emptyLabel;
    final labels = _labelsForValues(values, options);
    if (labels.length <= 2) return labels.join('、');
    return '${labels.take(2).join('、')}等${labels.length}项';
  }

  String _mapDoubanSort(String value) {
    switch (value) {
      case 'U':
      case 'R':
      case 'T':
      case 'S':
        return value;
      case 'comprehensive':
        return 'U';
      case 'release_date.desc':
        return 'R';
      case 'popularity.desc':
        return 'T';
      case 'vote_average.desc':
        return 'S';
      default:
        return value.isEmpty ? 'U' : value;
    }
  }

  List<String> _labelsForValues(
    List<String> values,
    List<DiscoverFilterOption> options,
  ) {
    if (values.isEmpty) return const [];
    final map = {for (final option in options) option.value: option.label};
    return values.map((value) => map[value] ?? value).toList();
  }

  String _labelForValue(String value, List<DiscoverFilterOption> options) {
    if (value.isEmpty) return '';
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
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
        final apiItem = RecommendApiItem.fromJson(map);
        final patched = (apiItem.type == null || apiItem.type!.isEmpty)
            ? apiItem.copyWith(type: fallbackMediaType)
            : apiItem;
        items.add(patched);
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '解析探索条目失败');
      }
    }
    return items;
  }
}

class _QueryOptions {
  const _QueryOptions({
    this.useOriginCountry = false,
    this.useProductionCountries = false,
  });

  final bool useOriginCountry;
  final bool useProductionCountries;
}

class _DiscoverRequest {
  const _DiscoverRequest({required this.path, required this.query});

  final String path;
  final Map<String, String> query;
}

import 'dart:async';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaSearchListController extends GetxController {
  static const _viewModePrefKey = 'media_search_list_view_mode';

  final _subscribeService = Get.put(SubscribeService());
  MediaSearchListController({String? initialKeyword, String? initialType}) {
    final seed = initialKeyword?.trim();
    if (seed != null && seed.isNotEmpty) {
      keyword.value = seed;
    }
    if (initialType != null && initialType.isNotEmpty) {
      type = initialType.trim().toLowerCase();
    }
  }
  String type = 'media';
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();

  final RxString keyword = ''.obs;
  final RxList<RecommendApiItem> items = <RecommendApiItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasCompletedInitialSearch = false.obs;
  final RxnString error = RxnString();
  final RxBool hasMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxnInt totalItems = RxnInt();
  final RxnInt totalPages = RxnInt();
  final RxnInt pageSize = RxnInt();
  final Rxn<SearchResultViewMode> preferredViewMode =
      Rxn<SearchResultViewMode>();

  static const _basePath = '/api/v1/media/search';
  static const _mediaserverExistsPath = '/api/v1/mediaserver/exists';

  final RxMap<String, bool> mediaserverInLibrary = <String, bool>{}.obs;
  bool _navigatedToPerson = false;

  @override
  void onReady() {
    super.onReady();
    if (keyword.value.isNotEmpty) {
      if (type.toLowerCase() == 'person' && !_navigatedToPerson) {
        _navigatedToPerson = true;
        Get.offNamed(
          '/person-search-list',
          arguments: {'keyword': keyword.value},
        );
        return;
      }
      search(keyword: keyword.value);
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreViewModePref());
  }

  SearchResultViewMode resolvedViewMode({required bool isNarrowScreen}) {
    return preferredViewMode.value ??
        (isNarrowScreen
            ? SearchResultViewMode.list
            : SearchResultViewMode.grid);
  }

  void toggleViewMode({required bool isNarrowScreen}) {
    final current = resolvedViewMode(isNarrowScreen: isNarrowScreen);
    preferredViewMode.value = current == SearchResultViewMode.list
        ? SearchResultViewMode.grid
        : SearchResultViewMode.list;
    unawaited(_persistViewModePref());
  }

  Future<void> search({String? keyword}) async {
    final term = (keyword ?? this.keyword.value).trim();
    if (term.isEmpty) {
      error.value = '请输入搜索关键字';
      items.clear();
      hasMore.value = false;
      hasCompletedInitialSearch.value = true;
      return;
    }
    if (type.toLowerCase() == 'person') {
      if (!_navigatedToPerson) {
        _navigatedToPerson = true;
        Get.offNamed('/person-search-list', arguments: {'keyword': term});
      }
      return;
    }
    this.keyword.value = term;
    await _fetch(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await _fetch(page: currentPage.value + 1, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    final term = keyword.value.trim();
    if (term.isEmpty) return;
    await _refreshImageCookie();
    isLoading.value = true;
    error.value = null;

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        error.value = '请先登录后再尝试搜索';
        isLoading.value = false;
        hasCompletedInitialSearch.value = true;
        return;
      }
      final params = {'title': term, 'type': type, 'page': page};

      final response = await _apiClient.get<dynamic>(
        _basePath,
        token: token,
        timeout: 120,
        queryParameters: params,
      );
      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        error.value = '登录已过期，请重新登录';
        isLoading.value = false;
        hasCompletedInitialSearch.value = true;
        return;
      }
      if (status >= 400) {
        error.value = '请求失败 (HTTP $status)';
        isLoading.value = false;
        hasCompletedInitialSearch.value = true;
        return;
      }
      final raw = response.data;
      final parsed = _extractList(raw)
          .whereType<Map<String, dynamic>>()
          .map(RecommendApiItem.fromJson)
          .toList();
      if (append) {
        items.addAll(parsed);
      } else {
        mediaserverInLibrary.clear();
        mediaserverInLibrary.refresh();
        items.assignAll(parsed);
      }
      currentPage.value = page;
      _updatePagination(raw, page, parsed.length, append);
      if (parsed.isEmpty && !append) {
        error.value = '没有找到匹配的媒体';
      }
      for (final item in parsed) {
        _subscribeService.fetchAndSaveSubscribeStatus(
          item.mediaKey,
          season: item.season,
          title: item.title,
        );
      }
      if (_appService.enableFetchMediaserverLibraryStatus.value) {
        for (final item in parsed) {
          unawaited(_fetchMediaserverExists(item, token));
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '媒体搜索失败');
      error.value = '搜索失败，请稍后重试';
    } finally {
      hasCompletedInitialSearch.value = true;
      isLoading.value = false;
    }
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in const ['data', 'results', 'items', 'list']) {
        final value = raw[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  void _updatePagination(dynamic raw, int page, int received, bool append) {
    bool? serverHasMore;
    int? serverTotal;
    int? serverPages;
    int? serverPageSize;
    if (raw is Map<String, dynamic>) {
      serverHasMore = _asBool(
        raw['has_more'] ?? raw['hasMore'] ?? raw['has_next'] ?? raw['hasNext'],
      );
      serverTotal = _asInt(raw['total'] ?? raw['total_count'] ?? raw['count']);
      serverPages = _asInt(
        raw['pages'] ?? raw['total_pages'] ?? raw['totalPages'],
      );
      serverPageSize = _asInt(
        raw['page_size'] ?? raw['pageSize'] ?? raw['per_page'],
      );
    }

    if (!append || page == 1) {
      totalItems.value = serverTotal;
      totalPages.value = serverPages;
      pageSize.value = serverPageSize;
    } else {
      totalItems.value ??= serverTotal;
      totalPages.value ??= serverPages;
      pageSize.value ??= serverPageSize;
    }

    bool next;
    if (serverHasMore != null) {
      next = serverHasMore;
    } else if (totalPages.value != null) {
      next = page < totalPages.value!;
    } else if (totalItems.value != null &&
        pageSize.value != null &&
        pageSize.value! > 0) {
      final maxPages = (totalItems.value! / pageSize.value!).ceil();
      next = page < maxPages;
    } else {
      final expectedSize = pageSize.value ?? received;
      if (expectedSize <= 0) {
        next = received > 0;
      } else {
        next = received >= expectedSize;
      }
    }
    hasMore.value = next;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String mediaserverExistsKey(RecommendApiItem item) {
    final t = _existsTitle(item);
    return '$t|${item.year ?? ''}|${item.type ?? ''}';
  }

  String _existsTitle(RecommendApiItem item) {
    final a = item.title?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = item.en_title?.trim();
    if (b != null && b.isNotEmpty) return b;
    final c = item.original_title?.trim();
    if (c != null && c.isNotEmpty) return c;
    final d = item.original_name?.trim();
    if (d != null && d.isNotEmpty) return d;
    return '';
  }

  Future<void> queryMediaserverExists(RecommendApiItem item) async {
    if (!_appService.enableFetchMediaserverLibraryStatus.value) return;
    final token =
        _appService.loginResponse?.accessToken ??
        _appService.latestLoginProfileAccessToken ??
        _apiClient.token;
    if (token == null || token.isEmpty) return;
    await _fetchMediaserverExists(item, token);
  }

  Future<void> _fetchMediaserverExists(
    RecommendApiItem item,
    String token,
  ) async {
    final title = _existsTitle(item);
    if (title.isEmpty) return;
    final key = mediaserverExistsKey(item);
    try {
      final query = <String, dynamic>{'title': title};
      final y = item.year?.trim();
      if (y != null && y.isNotEmpty) query['year'] = y;
      final m = item.type?.trim();
      if (m != null && m.isNotEmpty) query['mtype'] = m;
      final response = await _apiClient.get<dynamic>(
        _mediaserverExistsPath,
        token: token,
        queryParameters: query,
      );
      if (response.statusCode != 200) {
        mediaserverInLibrary[key] = false;
        mediaserverInLibrary.refresh();
        return;
      }
      mediaserverInLibrary[key] = _parseMediaserverExists(response.data);
      mediaserverInLibrary.refresh();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '媒体入库状态查询失败');
      mediaserverInLibrary[key] = false;
      mediaserverInLibrary.refresh();
    }
  }

  bool _parseMediaserverExists(dynamic raw) {
    if (raw is! Map) return false;
    final m = Map<String, dynamic>.from(raw);
    if (m['success'] != true) return false;
    final data = m['data'];
    if (data is! Map) return false;
    final inner = data['item'];
    if (inner is! Map) return false;
    final id = inner['id'];
    if (id == null) return false;
    return id.toString().trim().isNotEmpty;
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  Future<void> _refreshImageCookie() async {
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
      _log.handle(e, stackTrace: st, message: '刷新媒体搜索图片 Cookie 失败');
    }
  }

  Future<void> _persistViewModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = preferredViewMode.value;
    if (mode == null) {
      await prefs.remove(_viewModePrefKey);
      return;
    }
    await prefs.setString(_viewModePrefKey, mode.name);
  }

  Future<void> _restoreViewModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewModePrefKey);
    if (raw == null || raw.isEmpty) return;
    final matched = SearchResultViewMode.values.where((e) => e.name == raw);
    if (matched.isNotEmpty) {
      preferredViewMode.value = matched.first;
    }
  }
}

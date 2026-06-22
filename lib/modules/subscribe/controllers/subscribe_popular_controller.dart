import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_popular_filter_defines.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class SubscribePopularController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _authRepository = Get.find<AuthRepository>();
  final _log = Get.find<AppLog>();

  static const int _pageSize = 30;
  static const String _defaultSortType = 'count';

  late final SubscribeType subscribeType;
  bool _cookieRefreshTriggered = false;

  final scrollController = ScrollController();
  int _page = 1;
  final hasMore = true.obs;

  final items = <RecommendApiItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final keyword = ''.obs;

  /// 排序：time 最新、count 热门、vote 评分
  final sortType = 'count'.obs;
  final selectedGenres = <String>[].obs;
  final voteMin = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscribeType) {
      subscribeType = args;
    } else if (args is Map && args['type'] is SubscribeType) {
      subscribeType = args['type'] as SubscribeType;
    } else {
      final route = Get.currentRoute;
      subscribeType = route.contains('movie')
          ? SubscribeType.movie
          : SubscribeType.tv;
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  bool get isTv => subscribeType == SubscribeType.tv;

  void ensureUserCookieRefreshed() {
    if (_cookieRefreshTriggered) return;
    _cookieRefreshTriggered = true;
    _refreshUserCookie();
  }

  Future<void> _refreshUserCookie() async {
    final server = _appService.baseUrl ?? _apiClient.baseUrl;
    final token = _getToken();
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    try {
      await _authRepository.getUserGlobalConfig(
        server: server,
        accessToken: token,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新热门订阅 Cookie 失败');
    }
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    _page = 1;
    hasMore.value = true;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/popular',
        queryParameters: {
          'stype': subscribeType.stype,
          'page': _page,
          'count': _pageSize,
          'sort_type': sortType.value,
          'genre_id': selectedGenres,
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        items.clear();
        return;
      }
      final list = _extractList(response.data);
      final parsed = <RecommendApiItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = RecommendApiItem.fromJson(raw);
            parsed.add(item);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析热门订阅失败');
            continue;
          }
        }
      }
      items.assignAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取热门订阅失败');
      errorText.value = '请求失败，请稍后重试';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value || items.isEmpty) return;
    isLoading.value = true;
    _page += 1;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/popular',
        queryParameters: {
          'stype': subscribeType.stype,
          'page': _page,
          'count': _pageSize,
          'sort_type': sortType.value,
          'genre_id': selectedGenres,
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        _page -= 1;
        hasMore.value = false;
        return;
      }
      final list = _extractList(response.data);
      final parsed = <RecommendApiItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = RecommendApiItem.fromJson(raw);
            parsed.add(item);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析热门订阅失败');
            continue;
          }
        }
      }
      items.addAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多热门订阅失败');
      _page -= 1;
    } finally {
      isLoading.value = false;
    }
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }

  void updateKeyword(String value) => keyword.value = value.trim();

  void setSortType(String value) {
    sortType.value = value;
    load();
  }

  void setGenres(List<String> value) {
    selectedGenres.assignAll(value);
  }

  void setVoteMin(int value) {
    voteMin.value = value;
  }

  void applyFilter(List<String> genres, int ratingMin) {
    selectedGenres.assignAll(genres);
    voteMin.value = ratingMin;
    load();
  }

  String get genreLabel {
    if (selectedGenres.isEmpty) return '风格';
    final opts = isTv
        ? SubscribePopularFilterDefines.tvGenreOptions
        : SubscribePopularFilterDefines.movieGenreOptions;
    final map = {for (final o in opts) o['value']!: o['label']!};
    final labels = selectedGenres.map((v) => map[v] ?? v).toList();
    return labels.length <= 2
        ? labels.join('、')
        : '${labels.take(2).join('、')}等';
  }

  String get ratingLabel {
    if (voteMin.value <= 0) return '评分';
    return '${voteMin.value}分+';
  }

  bool get hasActiveFilters => selectedGenres.isNotEmpty || voteMin.value > 0;

  List<RecommendApiItem> get visibleItems {
    var list = items.toList();
    final key = keyword.value.trim().toLowerCase();
    if (key.isNotEmpty) {
      list = list.where((e) {
        final blob = [
          e.title,
          e.original_title,
          e.en_title,
          e.overview,
        ].whereType<String>().join(' ').toLowerCase();
        return blob.contains(key);
      }).toList();
    }
    final min = voteMin.value;
    if (min > 0) {
      list = list.where((e) {
        final v = e.vote_average;
        if (v == null) return false;
        return v >= min;
      }).toList();
    }
    return list;
  }

  static Future<List<RecommendApiItem>> fetchPreviewItems({
    required ApiClient apiClient,
    required AppLog log,
    required SubscribeType subscribeType,
    int count = 5,
  }) async {
    try {
      final response = await apiClient.get<dynamic>(
        '/api/v1/subscribe/popular',
        queryParameters: {
          'stype': subscribeType.stype,
          'page': 1,
          'count': count,
          'sort_type': _defaultSortType,
          'genre_id': const <String>[],
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) return const [];
      return _parseItems(_extractStaticList(response.data), log);
    } catch (e, st) {
      log.handle(e, stackTrace: st, message: '获取热门订阅预览失败');
      return const [];
    }
  }

  static Iterable<dynamic> _extractStaticList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }

  static List<RecommendApiItem> _parseItems(
    Iterable<dynamic> list,
    AppLog log,
  ) {
    final parsed = <RecommendApiItem>[];
    for (final raw in list) {
      if (raw is Map<String, dynamic>) {
        try {
          parsed.add(RecommendApiItem.fromJson(raw));
        } catch (e, st) {
          log.handle(e, stackTrace: st, message: '解析热门订阅失败');
        }
      }
    }
    return parsed;
  }
}

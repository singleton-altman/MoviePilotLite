import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_popular_filter_defines.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class SubscribeShareController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _authRepository = Get.find<AuthRepository>();
  final _log = Get.find<AppLog>();

  static const int _pageSize = 30;

  bool _cookieRefreshTriggered = false;

  final scrollController = ScrollController();
  int _page = 1;
  final hasMore = true.obs;

  final items = <SubscribeShareItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final keyword = ''.obs;

  /// 排序：time 最新、count 热门、vote 评分
  final sortType = 'time'.obs;
  final selectedGenres = <String>[].obs;
  final voteMin = 0.obs;
  final searchController = TextEditingController();
  @override
  void onReady() {
    super.onReady();
    searchController.text = keyword.value;
    load();
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

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
      _log.handle(e, stackTrace: st, message: '刷新订阅分享 Cookie 失败');
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
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        items.clear();
        return;
      }
      final params = <String, dynamic>{
        'page': _page,
        'count': _pageSize,
        'name': keyword.value.trim().isEmpty ? '' : keyword.value.trim(),
        'sort_type': sortType.value,
      };
      if (selectedGenres.isNotEmpty) {
        params['genre_id'] = selectedGenres;
      }
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/shares',
        queryParameters: params,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        items.clear();
        return;
      }
      final list = _extractList(response.data);
      final parsed = <SubscribeShareItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            parsed.add(SubscribeShareItem.fromJson(raw));
          } catch (_) {}
        }
      }
      items.assignAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅分享失败');
      errorText.value = '请求失败，请稍后重试';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value || items.isEmpty) return;
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    isLoading.value = true;
    _page += 1;
    try {
      final params = <String, dynamic>{
        'page': _page,
        'count': _pageSize,
        'name': keyword.value.trim().isEmpty ? '' : keyword.value.trim(),
        'sort_type': sortType.value,
      };
      if (selectedGenres.isNotEmpty) {
        params['genre_id'] = selectedGenres;
      }
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/shares',
        queryParameters: params,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        _page -= 1;
        hasMore.value = false;
        return;
      }
      final list = _extractList(response.data);
      final parsed = <SubscribeShareItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            parsed.add(SubscribeShareItem.fromJson(raw));
          } catch (_) {}
        }
      }
      items.addAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多订阅分享失败');
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

  void updateKeyword(String value) {
    keyword.value = value.trim();
    searchController.text = value.trim();
    load();
  }

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
    final opts = SubscribePopularFilterDefines.tvGenreOptions;
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

  bool get hasActiveFilters =>
      selectedGenres.isNotEmpty || voteMin.value > 0;

  List<SubscribeShareItem> get visibleItems {
    var list = items.toList();
    final key = keyword.value.trim().toLowerCase();
    if (key.isNotEmpty) {
      list = list
          .where(
            (e) =>
                '${e.name ?? ''} ${e.shareTitle ?? ''} ${e.shareComment ?? ''} ${e.description ?? ''}'
                    .toLowerCase()
                    .contains(key),
          )
          .toList();
    }
    final min = voteMin.value;
    if (min > 0) {
      list = list.where((e) => (e.vote ?? 0) >= min.toDouble()).toList();
    }
    return list;
  }
}

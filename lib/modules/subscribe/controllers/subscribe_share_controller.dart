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

  /// 服务端关注名单按 share_uid 保存，不使用可重名的显示用户名。
  final followedUsers = <String>{}.obs;
  final followsLoaded = false.obs;
  final followError = RxnString();
  final followBusy = false.obs;
  Future<void>? _followLoad;
  int _loadGeneration = 0;
  String get _scope => '${_apiClient.baseUrl}\n${_getToken()}';
  bool _current(String scope) => !isClosed && scope == _scope;

  /// 「只看关注」过滤开关
  final followOnly = false.obs;

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
    loadFollowed();
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

  Future<void> load() => _loadPage(reset: true);

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    final scope = _scope;
    final page = reset ? 1 : _page + 1;
    isLoading.value = true;
    errorText.value = null;
    if (reset) {
      items.clear();
      hasMore.value = true;
    }
    try {
      if (_getToken()?.isNotEmpty != true) throw StateError('请先登录');
      // Both contracts accept one integer genre_id, not an array.
      if (selectedGenres.length > 1) throw StateError('订阅分享每次仅支持筛选一种风格');
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/shares',
        queryParameters: {
          'page': page,
          'count': _pageSize,
          'name': keyword.value.trim(),
          'sort_type': sortType.value,
          if (selectedGenres.isNotEmpty) 'genre_id': int.parse(selectedGenres.single),
          if (voteMin.value > 0) 'min_rating': voteMin.value,
        },
        skipV3EnvelopeUnwrap: true,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) throw StateError('请求失败 (HTTP $status)');
      final list = _extractList(response.data);
      final parsed = list.map((raw) {
        if (raw is! Map<String, dynamic>) throw const FormatException('分享格式错误');
        return SubscribeShareItem.fromJson(raw);
      }).toList();
      if (!_current(scope) || generation != _loadGeneration) return;
      if (reset) {
        items.assignAll(parsed);
      } else {
        items.addAll(parsed);
      }
      _page = page;
      // Pagination follows the raw server page, never the locally filtered list.
      hasMore.value = list.length >= _pageSize;
    } catch (e, st) {
      if (!_current(scope) || generation != _loadGeneration) return;
      _log.handle(e, stackTrace: st, message: '获取订阅分享失败');
      errorText.value = e is StateError ? e.message.toString() : '请求失败，请稍后重试';
      if (reset) hasMore.value = false;
      // A failed next page remains retryable and does not advance _page.
    } finally {
      if (!isClosed && generation == _loadGeneration) isLoading.value = false;
    }
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['success'] == true && raw['data'] is List) {
      return raw['data'] as List;
    }
    throw const FormatException('服务端未返回有效列表');
  }

  String? _followKeyOf(SubscribeShareItem item) {
    final uid = item.shareUid?.trim();
    if (uid != null && uid.isNotEmpty) return uid;
    return null;
  }

  bool isFollowed(SubscribeShareItem item) {
    final key = _followKeyOf(item);
    return key != null && followedUsers.contains(key);
  }

  bool canToggleFollow(SubscribeShareItem item) =>
      _getToken()?.isNotEmpty == true &&
      followsLoaded.value && !followBusy.value && _followKeyOf(item) != null;

  /// Both versions return List<String>; token authentication is sufficient.
  Future<void> loadFollowed() {
    if (followBusy.value) return Future.value();
    return _followLoad ??= _loadFollowed().whenComplete(() => _followLoad = null);
  }

  Future<void> _loadFollowed() async {
    final scope = _scope;
    try {
      if (_getToken()?.isNotEmpty != true) throw StateError('请先登录');
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/follow',
        skipV3EnvelopeUnwrap: true,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) throw StateError('HTTP $status');
      final list = _extractList(response.data);
      if (list.any((e) => e is! String)) throw const FormatException('关注名单格式错误');
      if (!_current(scope)) return;
      followedUsers.assignAll(list.cast<String>().where((e) => e.isNotEmpty));
      followsLoaded.value = true;
      followError.value = null;
    } catch (e, st) {
      if (!_current(scope)) return;
      followsLoaded.value = false;
      followError.value = '关注名单加载失败，请重试';
      _log.handle(e, stackTrace: st, message: '获取关注列表失败');
    }
  }

  /// Serializes mutations because the backend writes one shared UID list.
  /// The result is exposed to the view; failed acknowledgments never alter state.
  Future<({bool ok, String message})> toggleFollow(SubscribeShareItem item) async {
    if (followBusy.value || isClosed) return (ok: false, message: '关注操作正在提交');
    final key = _followKeyOf(item);
    if (key == null) return (ok: false, message: '该分享缺少用户 UID，无法关注');
    final scope = _scope;
    await loadFollowed();
    if (!_current(scope) || !followsLoaded.value) {
      return (ok: false, message: '无法确认关注状态，请重试');
    }
    // Another tap may have reached this point while the same read was pending.
    if (followBusy.value) return (ok: false, message: '关注操作正在提交');
    followBusy.value = true;
    final following = followedUsers.contains(key);
    try {
      final response = following
          ? await _apiClient.delete<dynamic>(
              '/api/v1/subscribe/follow', queryParameters: {'share_uid': key})
          : await _apiClient.post<dynamic>(
              '/api/v1/subscribe/follow', queryParameters: {'share_uid': key});
      if (!_current(scope)) return (ok: false, message: '帐号或服务端已切换');
      final status = response.statusCode ?? 0;
      final data = response.data;
      if (status < 200 || status >= 300 || data is! Map || data['success'] != true) {
        followsLoaded.value = false;
        followError.value = '操作未确认成功，请刷新关注名单';
        return (ok: false, message: data is Map
            ? data['message']?.toString() ?? '关注操作未确认成功'
            : '关注操作未确认成功');
      }
      if (following) {
        followedUsers.remove(key);
      } else {
        followedUsers.add(key);
      }
      followError.value = null;
      return (ok: true, message: following ? '已取消关注' : '已关注');
    } catch (e, st) {
      if (_current(scope)) {
        followsLoaded.value = false;
        followError.value = '操作结果未知，请刷新关注名单后再试';
      }
      _log.handle(e, stackTrace: st, message: '关注分享人失败');
      return (ok: false, message: '关注操作失败，请刷新名单后重试');
    } finally {
      if (!isClosed) followBusy.value = false;
    }
  }

  void toggleFollowOnly() {
    followOnly.value = !followOnly.value;
    if (followOnly.value) loadFollowed();
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
    if (followOnly.value) {
      list = list.where(isFollowed).toList();
    }
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

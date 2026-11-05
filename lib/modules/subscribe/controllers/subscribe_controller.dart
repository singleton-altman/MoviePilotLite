import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_popular_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_submit_resp.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 订阅类型：电视剧 / 电影 / 音乐
enum SubscribeType { tv, movie, music }

enum SubscribeCollectionTab { following, washing }

enum SubscribeSortKey { addedAt }

extension SubscribeSortKeyX on SubscribeSortKey {
  String get displayName {
    switch (this) {
      case SubscribeSortKey.addedAt:
        return '添加时间';
    }
  }
}

/// 订阅状态
enum SubscribeState {
  washing, // 洗板中（best_version == true）
  notStarted, // 未开始
  running, // 订阅中
  pending, // 待定
  paused, // 暂停
  completed, // 订阅完成
}

extension SubscribeStateX on SubscribeState {
  String get displayName {
    switch (this) {
      case SubscribeState.washing:
        return '洗板中';
      case SubscribeState.notStarted:
        return '未开始';
      case SubscribeState.running:
        return '订阅中';
      case SubscribeState.pending:
        return '待定';
      case SubscribeState.paused:
        return '暂停';
      case SubscribeState.completed:
        return '订阅完成';
    }
  }
}

extension SubscribeTypeX on SubscribeType {
  String get stype =>
      switch (this) {
        SubscribeType.tv => '电视剧',
        SubscribeType.movie => '电影',
        SubscribeType.music => '音乐',
      };
  String get displayName =>
      switch (this) {
        SubscribeType.tv => '电视剧订阅',
        SubscribeType.movie => '电影订阅',
        SubscribeType.music => '音乐订阅',
      };
}

class SubscribeController extends GetxController {
  static const int _recommendationThreshold = 10;
  static const int _recommendationPreviewCount = 5;
  static const String _sortKeyPrefPrefix = 'subscribe.sort.key';
  static const String _sortAscendingPrefPrefix = 'subscribe.sort.ascending';

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.put(AuthRepository());
  final _versionService = Get.find<ServerApiVersionService>();
  final subscribeService = Get.put(SubscribeService());
  var subscribeType = SubscribeType.tv;

  final userItems = <SubscribeItem>[].obs;
  final userLoading = false.obs;

  /// 原始订阅记录（按订阅 id 索引），供音乐订阅等场景读取模型未覆盖的字段
  final rawSubscribeById = <String, Map<String, dynamic>>{}.obs;

  final errorText = RxnString();
  final recommendationItems = <RecommendApiItem>[].obs;
  final recommendationLoading = false.obs;

  final keyword = ''.obs;
  final selectedStates = <SubscribeState>{}.obs;
  final selectedCollectionTab = SubscribeCollectionTab.following.obs;
  final sortKey = SubscribeSortKey.addedAt.obs;
  final sortAscending = false.obs;
  int _recommendationRequestId = 0;

  /// v3 执行可观测入口（活动记录/运行日志）可见性；v2 服务端隐藏，不发出 v3 请求
  final executionEntriesVisible = false.obs;

  @override
  void onReady() {
    super.onReady();
    _restoreSortPreferences();
    _resolveExecutionEntriesVisible();
    loadAll();
  }

  Future<void> _resolveExecutionEntriesVisible() async {
    try {
      executionEntriesVisible.value = await _versionService.isV3();
    } catch (_) {
      executionEntriesVisible.value = false;
    }
  }

  bool get isTv => subscribeType == SubscribeType.tv;

  Future<void> loadAll() async {
    await loadUserSubscribes();
  }

  Future<void> _notifyMultifunctionSubscribeChanged() async {
    if (Get.isRegistered<IosSharedSessionService>()) {
      Get.find<IosSharedSessionService>().reloadWidgets();
    }
    if (!Get.isRegistered<MultifunctionController>()) return;
    final controller = Get.find<MultifunctionController>();
    await controller.refreshSubscribeSection();
  }

  /// 是否有默认规则入口（TV 和 Movie 分别有独立入口）
  void openDefaultRules() {
    Get.snackbar('默认规则', '${subscribeType.displayName}的默认规则入口，待接入');
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  bool _ensureCanSubscribe() {
    if (_appService.canSubscribe) return true;
    ToastUtil.info('当前帐号无订阅权限');
    return false;
  }

  String? _normalizeUsername(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }

  String? _latestProfileUsername() {
    if (!Get.isRegistered<HiveService>()) return null;
    try {
      final profiles = Get.find<HiveService>().loginProfileBox.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (profiles.isEmpty) return null;
      return _normalizeUsername(profiles.first.username);
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _currentUsernames() async {
    final usernames = <String>{};

    final profileUsername = _latestProfileUsername();
    if (profileUsername != null) {
      usernames.add(profileUsername);
    }

    final loginUsername = _normalizeUsername(
      _appService.loginResponse?.userName,
    );
    if (loginUsername != null) {
      usernames.add(loginUsername);
    }

    final userInfoName = _normalizeUsername(_appService.userInfo?.name);
    if (userInfoName != null) {
      usernames.add(userInfoName);
    }

    return usernames;
  }

  Future<void> loadUserSubscribes() async {
    userLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        userItems.clear();
        rawSubscribeById.clear();
        _clearRecommendations();
        return;
      }
      if (subscribeType == SubscribeType.music) {
        final supported = await _versionService.isV3();
        if (!supported) {
          errorText.value = '音乐功能需要 MoviePilot v3 服务端';
          userItems.clear();
          rawSubscribeById.clear();
          _clearRecommendations();
          return;
        }
      }
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/',
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        userItems.clear();
        rawSubscribeById.clear();
        _clearRecommendations();
        return;
      }
      _refreshUserCookie();
      final list = _extractList(response.data);
      rawSubscribeById.assignAll({
        for (final entry in list.whereType<Map<String, dynamic>>())
          if (entry['id'] != null) '${entry['id']}': entry,
      });
      final currentUsernames = await _currentUsernames();
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) =>
                SubscribeItem.fromJson(normalizeSubscribeJson(item)),
          )
          .where(
            (e) => _matchesType(e) && _matchesCurrentUser(e, currentUsernames),
          )
          .toList();
      userItems.assignAll(parsed);
      if (subscribeType == SubscribeType.music) {
        // 音乐暂无热门推荐数据源
        _clearRecommendations();
      } else if (parsed.length < _recommendationThreshold) {
        _loadRecommendationPreview();
      } else {
        _clearRecommendations();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅列表失败');
      errorText.value = '请求失败，请稍后重试';
      userItems.clear();
      rawSubscribeById.clear();
      _clearRecommendations();
    } finally {
      userLoading.value = false;
    }
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

  bool _matchesType(SubscribeItem item) {
    final t = item.type?.trim().toLowerCase() ?? '';
    switch (subscribeType) {
      case SubscribeType.tv:
        return t.contains('电视剧') || t.contains('tv') || t == 'tv';
      case SubscribeType.movie:
        return t.contains('电影') || t.contains('movie') || t == 'movie';
      case SubscribeType.music:
        return t.contains('音乐') || t == 'music';
    }
  }

  bool _matchesCurrentUser(SubscribeItem item, Set<String> currentUsernames) {
    if (_appService.isSuperuser) return true;
    if (currentUsernames.isEmpty) return true;
    final itemUsername = _normalizeUsername(item.username);
    if (itemUsername == null) return false;
    return currentUsernames.contains(itemUsername);
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

  void toggleStateFilter(SubscribeState state) {
    final next = selectedStates.toSet();
    if (next.contains(state)) {
      next.remove(state);
    } else {
      next.add(state);
    }
    selectedStates.assignAll(next);
  }

  void clearStateFilters() => selectedStates.clear();

  void setCollectionTab(SubscribeCollectionTab tab) {
    selectedCollectionTab.value = tab;
  }

  String get sortValue => sortKey.value.name;

  void setSortValue(String value) {
    final next = SubscribeSortKey.values.firstWhereOrNull(
      (key) => key.name == value,
    );
    if (next == null || next == sortKey.value) return;
    sortKey.value = next;
    _saveSortPreferences();
  }

  void setSortDirection(bool ascending) {
    if (sortAscending.value == ascending) return;
    sortAscending.value = ascending;
    _saveSortPreferences();
  }

  List<SubscribeItem> get filteredUserItems {
    var list = userItems.toList();
    final key = keyword.value.trim().toLowerCase();
    if (key.isNotEmpty) {
      list = list
          .where((e) => _matchKeyword(e.name, e.description, key))
          .toList();
    }
    final states = selectedStates.toSet();
    if (states.isNotEmpty) {
      list = list
          .where((e) => states.contains(_resolveSubscribeState(e)))
          .toList();
    }
    return _sortItems(list);
  }

  List<SubscribeItem> get visibleUserItems => filteredUserItems;

  List<SubscribeItem> get followingItems =>
      filteredUserItems.where((item) => !isWashingItem(item)).toList();

  List<SubscribeItem> get washingItems =>
      filteredUserItems.where(isWashingItem).toList();

  int get followingItemCount =>
      userItems.where((item) => !isWashingItem(item)).length;

  int get washingItemCount => userItems.where(isWashingItem).length;

  SubscribeCollectionTab get effectiveCollectionTab {
    if (!canShowCollectionTabs) {
      return followingItemCount > 0
          ? SubscribeCollectionTab.following
          : SubscribeCollectionTab.washing;
    }
    return selectedCollectionTab.value;
  }

  List<SubscribeItem> get currentTabItems =>
      effectiveCollectionTab == SubscribeCollectionTab.following
      ? followingItems
      : washingItems;

  bool get isFollowingTab =>
      effectiveCollectionTab == SubscribeCollectionTab.following;

  bool get canShowCollectionTabs =>
      followingItemCount > 0 && washingItemCount > 0;

  bool get shouldShowRecommendationSection =>
      userItems.length < _recommendationThreshold &&
      keyword.value.trim().isEmpty &&
      selectedStates.isEmpty &&
      recommendationItems.isNotEmpty;

  bool get shouldShowRecommendationLoading =>
      userItems.length < _recommendationThreshold &&
      keyword.value.trim().isEmpty &&
      selectedStates.isEmpty &&
      recommendationLoading.value;

  List<SubscribeItem> _sortItems(List<SubscribeItem> source) {
    final sorted = source.toList();
    sorted.sort(_compareSubscribeItems);
    return sorted;
  }

  int _compareSubscribeItems(SubscribeItem a, SubscribeItem b) {
    final factor = sortAscending.value ? 1 : -1;
    switch (sortKey.value) {
      case SubscribeSortKey.addedAt:
        final compared = _compareAddedSequence(a, b);
        if (compared != 0) return compared * factor;
        return _compareNullableStrings(a.name, b.name);
    }
  }

  int _compareAddedSequence(SubscribeItem a, SubscribeItem b) {
    final aValue = _addedSequenceValue(a);
    final bValue = _addedSequenceValue(b);
    return aValue.compareTo(bValue);
  }

  int _addedSequenceValue(SubscribeItem item) {
    final parsedDate = _parseDate(item.date);
    if (parsedDate != null) {
      return parsedDate.millisecondsSinceEpoch;
    }
    return item.id ?? 0;
  }

  DateTime? _parseDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  int _compareNullableStrings(String? a, String? b) {
    final av = a?.trim().toLowerCase() ?? '';
    final bv = b?.trim().toLowerCase() ?? '';
    return av.compareTo(bv);
  }

  /// 解析订阅项的状态：洗板中由 best_version 决定，其余由 state 字段映射
  SubscribeState _resolveSubscribeState(SubscribeItem item) {
    if (isWashingItem(item)) {
      return SubscribeState.washing;
    }
    final s = item.state?.trim().toUpperCase() ?? '';
    switch (s) {
      case 'R':
        return SubscribeState.running;
      case 'N':
        return SubscribeState.notStarted;
      case 'S':
        return SubscribeState.completed;
      case 'P':
        return SubscribeState.paused;
      case 'U':
      case 'D':
        return SubscribeState.pending;
      default:
        return SubscribeState.pending;
    }
  }

  bool _matchKeyword(String? name, String? desc, String key) {
    final haystack = '${name ?? ''} ${desc ?? ''}'.toLowerCase();
    return haystack.contains(key);
  }

  Future<void> _loadRecommendationPreview() async {
    final requestId = ++_recommendationRequestId;
    recommendationLoading.value = true;
    recommendationItems.clear();
    try {
      final previewItems = await SubscribePopularController.fetchPreviewItems(
        apiClient: _apiClient,
        log: _log,
        subscribeType: subscribeType,
        count: _recommendationPreviewCount,
      );
      if (requestId != _recommendationRequestId) return;
      final dedupKeys = userItems
          .expand(_subscribeDedupKeys)
          .where((key) => key.isNotEmpty)
          .toSet();
      final deduped = previewItems.where((item) {
        final keys = _recommendationDedupKeys(item);
        return keys.isNotEmpty && !keys.any(dedupKeys.contains);
      }).toList();
      recommendationItems.assignAll(deduped);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载订阅推荐失败');
      if (requestId != _recommendationRequestId) return;
      recommendationItems.clear();
    } finally {
      if (requestId == _recommendationRequestId) {
        recommendationLoading.value = false;
      }
    }
  }

  void _clearRecommendations() {
    _recommendationRequestId += 1;
    recommendationLoading.value = false;
    recommendationItems.clear();
  }

  Iterable<String> _subscribeDedupKeys(SubscribeItem item) sync* {
    final tmdbId = item.tmdbid?.toString();
    final doubanId = item.doubanid?.toString();
    final bangumiId = item.bangumiid?.toString();
    if (tmdbId != null && tmdbId.isNotEmpty) yield 'tmdb:$tmdbId';
    if (doubanId != null && doubanId.isNotEmpty) yield 'douban:$doubanId';
    if (bangumiId != null && bangumiId.isNotEmpty) yield 'bangumi:$bangumiId';
    final fallback = _buildFallbackKey(
      name: item.name,
      year: item.year,
      season: item.season,
    );
    if (fallback != null) yield fallback;
  }

  Iterable<String> _recommendationDedupKeys(RecommendApiItem item) sync* {
    final tmdbId = item.tmdb_id;
    final doubanId = item.douban_id;
    final bangumiId = item.bangumi_id;
    if (tmdbId != null && tmdbId.isNotEmpty) yield 'tmdb:$tmdbId';
    if (doubanId != null && doubanId.isNotEmpty) yield 'douban:$doubanId';
    if (bangumiId != null && bangumiId.isNotEmpty) yield 'bangumi:$bangumiId';
    final fallback = _buildFallbackKey(
      name: item.title ?? item.original_title ?? item.original_name,
      year: item.year,
      season: item.season,
    );
    if (fallback != null) yield fallback;
  }

  String? _buildFallbackKey({
    required String? name,
    required String? year,
    required int? season,
  }) {
    final normalizedName = name?.trim().toLowerCase() ?? '';
    final normalizedYear = year?.trim() ?? '';
    if (normalizedName.isEmpty) return null;
    return 'title:$normalizedName:$normalizedYear:${season ?? 0}';
  }

  bool isWashingItem(SubscribeItem item) {
    final bestVersion = item.bestVersion;
    return bestVersion != null && bestVersion != 0;
  }

  List<SubscribeState> get availableStates => SubscribeState.values;

  bool get hasActiveFilters => selectedStates.isNotEmpty;

  String get _sortKeyPrefKey => '$_sortKeyPrefPrefix.${subscribeType.name}';

  String get _sortAscendingPrefKey =>
      '$_sortAscendingPrefPrefix.${subscribeType.name}';

  Future<void> _restoreSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString(_sortKeyPrefKey);
      final restoredKey = SubscribeSortKey.values.firstWhereOrNull(
        (key) => key.name == storedKey,
      );
      if (restoredKey != null) {
        sortKey.value = restoredKey;
      }
      sortAscending.value = prefs.getBool(_sortAscendingPrefKey) ?? false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取订阅排序偏好失败');
    }
  }

  Future<void> _saveSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortKeyPrefKey, sortKey.value.name);
      await prefs.setBool(_sortAscendingPrefKey, sortAscending.value);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '写入订阅排序偏好失败');
    }
  }

  /// 用于卡片等展示：显示订阅项的状态名称
  String resolveStateDisplayName(SubscribeItem item) {
    return _resolveSubscribeState(item).displayName;
  }

  /// 格式化更新时间为相对时间，如 "7 天前"
  static String formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return dateStr;
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 0) return '${diff.inDays} 天前';
      if (diff.inHours > 0) return '${diff.inHours} 小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes} 分钟前';
      return '刚刚';
    } catch (_) {
      return dateStr;
    }
  }

  /// 更新订阅；fullPayload 需包含完整字段（与 PUT 接口一致），id 为 int
  Future<bool> updateSubscribeData(
    int id, {
    required Map<String, dynamic> fullPayload,
  }) async {
    if (!_ensureCanSubscribe()) return false;
    fullPayload['id'] = id;
    if (fullPayload['doubanid'] is int) {
      fullPayload['doubanid'] = fullPayload['doubanid'].toString();
    }
    final requestPayload = await subscribeService.prepareSubscribePayload(
      fullPayload,
    );
    final response = await _apiClient.put(
      '/api/v1/subscribe/',
      requestPayload,
    );
    if (response.statusCode == null || response.statusCode! >= 400) {
      return false;
    }
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      await _notifyMultifunctionSubscribeChanged();
      return true;
    }
    return false;
  }

  Future<bool> pauseSubscribe(String id) async {
    if (!_ensureCanSubscribe()) return false;
    final payload = {'state': 'S'};
    final response = await _apiClient.put(
      '/api/v1/subscribe/status/$id',
      payload,
      queryParameters: payload,
    );
    final ok = response.statusCode == 200 && response.data['success'] == true;
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }

  Future<bool> resumeSubscribe(String id) async {
    if (!_ensureCanSubscribe()) return false;
    final payload = {'state': 'R'};
    final response = await _apiClient.put(
      '/api/v1/subscribe/status/$id',
      payload,
      queryParameters: payload,
    );
    final ok = response.statusCode == 200 && response.data['success'] == true;
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }

  Future<bool> resetSubscribeState(String id) async {
    if (!_ensureCanSubscribe()) return false;
    final response = await _apiClient.get('/api/v1/subscribe/reset/$id');
    final ok = response.statusCode == 200 && response.data['success'] == true;
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }

  Future<bool> searchSubscribe(String id) async {
    if (!_ensureCanSubscribe()) return false;
    final response = await _apiClient.get('/api/v1/subscribe/search/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> shareSubscribe({
    required String id,
    String? title,
    String? description,
    String? shareComment,
    String? shareUser,
  }) async {
    if (!_ensureCanSubscribe()) return false;
    final data = {
      'share_comment': shareComment,
      'share_title': title,
      'share_user': shareUser,
      'subscribe_id': id,
    };
    final response = await _apiClient.post(
      '/api/v1/subscribe/share',
      data: data,
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<SubscribeSubmitResp> forkSubscribe({SubscribeShareItem? item}) async {
    if (!_ensureCanSubscribe()) {
      return SubscribeSubmitResp(success: false, message: '当前帐号无订阅权限');
    }
    Map<String, dynamic> data = {};
    if (item != null) {
      data = item.toJson();
    }
    final response = await _apiClient.post(
      '/api/v1/subscribe/fork',
      data: data,
    );
    if (response.statusCode == 200) {
      return SubscribeSubmitResp.fromJson(response.data);
    }
    return SubscribeSubmitResp(success: false, message: '请求失败');
  }

  Future<bool> deleteSubscribe(String id) async {
    final ok = await subscribeService.deleteSubscribes(id);
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }

  Future<SubscribeSubmitResp> submitSubscribe(
    String mediaType, {
    required Map<String, dynamic> payload,
  }) async {
    final resp = await subscribeService.submitSubscribe(
      mediaType,
      payload: payload,
    );
    if (resp.success == true) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return resp;
  }

  Future<SubscribeSubmitResp> submitMovieSubscribe({
    String? bangumiid,
    int? bestVersion = 0,
    String? doubanid,
    String? episodeGroup = '',
    String? mediaid = '',
    String? name,
    int? season = 0,
    String? tmdbid,
    String? year = '',
  }) async {
    final resp = await subscribeService.submitMovieSubscribe(
      bangumiid: bangumiid,
      bestVersion: bestVersion,
      doubanid: doubanid,
      episodeGroup: episodeGroup,
      mediaid: mediaid,
      name: name,
      season: season,
      tmdbid: tmdbid,
      year: year,
    );
    if (resp.success == true) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return resp;
  }

  Future<SubscribeSubmitResp> submitTvSubscribe({
    String? doubanid,
    String? episode_group = '',
    String? mediaid = '',
    String? name,
    int? season = 0,
    String? tmdbid,
    String? year = '',
  }) async {
    final resp = await subscribeService.submitTvSubscribe(
      doubanid: doubanid,
      episode_group: episode_group,
      mediaid: mediaid,
      name: name,
      season: season,
      tmdbid: tmdbid,
      year: year,
      bestVersionFull: null,
    );
    if (resp.success == true) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return resp;
  }

  Future<bool> deleteMediaSubscribe(
    String mediaKey, {
    String season = '0',
  }) async {
    final ok = await subscribeService.deleteMediaSubscribe(
      mediaKey,
      season: season,
    );
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }

  deleteSubscribes(String id) async {
    final ok = await subscribeService.deleteSubscribes(id);
    if (ok) {
      await _notifyMultifunctionSubscribeChanged();
    }
    return ok;
  }
}

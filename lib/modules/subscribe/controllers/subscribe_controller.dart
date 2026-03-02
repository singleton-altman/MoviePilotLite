import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_submit_resp.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 订阅类型：电视剧 / 电影
enum SubscribeType { tv, movie }

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
  String get stype => this == SubscribeType.tv ? '电视剧' : '电影';
  String get displayName => this == SubscribeType.tv ? '电视剧订阅' : '电影订阅';
}

class SubscribeController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.put(AuthRepository());
  final subscribeService = Get.put(SubscribeService());
  var subscribeType = SubscribeType.tv;

  final userItems = <SubscribeItem>[].obs;
  final userLoading = false.obs;

  final errorText = RxnString();

  final keyword = ''.obs;
  final selectedStates = <SubscribeState>{}.obs;

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  bool get isTv => subscribeType == SubscribeType.tv;

  Future<void> loadAll() async {
    await loadUserSubscribes();
  }

  /// 是否有默认规则入口（TV 和 Movie 分别有独立入口）
  void openDefaultRules() {
    Get.snackbar('默认规则', '${subscribeType.displayName}的默认规则入口，待接入');
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  Future<void> loadUserSubscribes() async {
    userLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        userItems.clear();
        return;
      }
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/',
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        userItems.clear();
        return;
      }
      _refreshUserCookie();
      final list = _extractList(response.data);
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(SubscribeItem.fromJson)
          .where((e) => _matchesType(e))
          .toList();
      userItems.assignAll(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅列表失败');
      errorText.value = '请求失败，请稍后重试';
      userItems.clear();
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
    if (subscribeType == SubscribeType.tv) {
      return t.contains('电视剧') || t.contains('tv') || t == 'tv';
    }
    return t.contains('电影') || t.contains('movie') || t == 'movie';
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

  List<SubscribeItem> get visibleUserItems {
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
    return list;
  }

  /// 解析订阅项的状态：洗板中由 best_version 决定，其余由 state 字段映射
  SubscribeState _resolveSubscribeState(SubscribeItem item) {
    final bestVersion = item.bestVersion;
    if (bestVersion != null && bestVersion != 0) {
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

  List<SubscribeState> get availableStates => SubscribeState.values;

  bool get hasActiveFilters => selectedStates.isNotEmpty;

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
    fullPayload['id'] = id;
    if (fullPayload['doubanid'] is int) {
      fullPayload['doubanid'] = fullPayload['doubanid'].toString();
    }
    final response = await _apiClient.put('/api/v1/subscribe/', fullPayload);
    if (response.statusCode == null || response.statusCode! >= 400) {
      return false;
    }
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return true;
    }
    return false;
  }

  Future<bool> pauseSubscribe(String id) async {
    final payload = {'state': 'S'};
    final response = await _apiClient.put(
      '/api/v1/subscribe/status/$id',
      payload,
      queryParameters: payload,
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> resumeSubscribe(String id) async {
    final payload = {'state': 'R'};
    final response = await _apiClient.put(
      '/api/v1/subscribe/status/$id',
      payload,
      queryParameters: payload,
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> resetSubscribeState(String id) async {
    final response = await _apiClient.get('/api/v1/subscribe/reset/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> searchSubscribe(String id) async {
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
    return subscribeService.deleteSubscribes(id);
  }

  Future<SubscribeSubmitResp> submitSubscribe(
    String mediaType, {
    required Map<String, dynamic> payload,
  }) async {
    return subscribeService.submitSubscribe(mediaType, payload: payload);
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
    final payload = {
      'bangumiid': bangumiid,
      'best_version': bestVersion,
      'doubanid': doubanid,
      'episode_group': episodeGroup,
      'mediaid': mediaid,
      'name': name,
      'season': season,
      'tmdbid': tmdbid,
      'year': year,
    };
    final resp = await subscribeService.submitSubscribe(
      'movie',
      payload: payload,
    );
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
    final payload = {
      'doubanid': doubanid,
      'episode_group': episode_group,
      'mediaid': mediaid,
      'name': name,
      'season': season,
      'tmdbid': tmdbid,
      'year': year,
      'best_version': 0,
      'type': '电视剧',
    };
    return await subscribeService.submitSubscribe('tv', payload: payload);
  }

  Future<bool> deleteMediaSubscribe(
    String mediaKey, {
    String season = '0',
  }) async {
    return subscribeService.deleteMediaSubscribe(mediaKey, season: season);
  }

  deleteSubscribes(String id) async {
    return subscribeService.deleteSubscribes(id);
  }
}

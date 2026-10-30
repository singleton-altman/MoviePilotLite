import 'dart:collection';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_files_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_submit_resp.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubscribeService extends GetxService {
  /// 订阅状态按 key 各自独立响应，卡片只监听自己的那一个，
  /// 避免一条状态写入牵动整个列表重建。
  final Map<String, Rxn<SubscribeItem>> _statusRxByKey = {};
  final Map<String, DateTime> _statusResolvedAt = {};
  final Set<String> _prefetchInflightKeys = {};
  final Queue<Future<void> Function()> _prefetchQueue = Queue();
  int _prefetchActive = 0;

  /// 后台预取的并发上限；列表页一次会产生上百个状态查询，不能同时打出去
  static const int _maxConcurrentPrefetch = 3;

  /// 预取结果的有效期，过期后允许再次预取以感知其他入口的订阅变化
  static const Duration _prefetchTtl = Duration(minutes: 10);

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  ServerApiVersionService get _serverApiVersionService =>
      Get.find<ServerApiVersionService>();

  static String subscribeKeyFor(
    String mediaKey, {
    int? season,
    String? title,
  }) =>
      '$mediaKey${season != null ? ':$season' : ''}${title != null ? ':$title' : ''}';

  Rxn<SubscribeItem> subscribeStatusRx(String key) =>
      _statusRxByKey.putIfAbsent(key, Rxn<SubscribeItem>.new);

  SubscribeItem? subscribeStatusOf(String key) => _statusRxByKey[key]?.value;

  void setSubscribeStatus(String key, SubscribeItem? item) {
    subscribeStatusRx(key).value = item;
    _statusResolvedAt[key] = DateTime.now();
  }

  void clearSubscribeStatus(String key) => setSubscribeStatus(key, null);

  bool _isPrefetchFresh(String key) {
    final resolvedAt = _statusResolvedAt[key];
    if (resolvedAt == null) return false;
    return DateTime.now().difference(resolvedAt) < _prefetchTtl;
  }

  /// 列表场景的后台状态预取：已有新鲜结果或正在排队的 key 直接跳过，
  /// 其余进入限流队列串行消化。
  void prefetchSubscribeStatus(String mediaKey, {int? season, String? title}) {
    final key = subscribeKeyFor(mediaKey, season: season, title: title);
    if (_isPrefetchFresh(key) || _prefetchInflightKeys.contains(key)) return;
    _prefetchInflightKeys.add(key);
    _prefetchQueue.add(() async {
      try {
        if (_isPrefetchFresh(key)) return;
        final item = await getSubscribeMediaStatus(
          mediaKey,
          season: season,
          title: title,
        );
        setSubscribeStatus(key, item);
      } finally {
        _prefetchInflightKeys.remove(key);
      }
    });
    _drainPrefetchQueue();
  }

  void _drainPrefetchQueue() {
    while (_prefetchActive < _maxConcurrentPrefetch &&
        _prefetchQueue.isNotEmpty) {
      final task = _prefetchQueue.removeFirst();
      _prefetchActive++;
      task()
          .catchError((Object e, StackTrace st) {
            _log.handle(e, stackTrace: st, message: '订阅状态预取失败');
          })
          .whenComplete(() {
            _prefetchActive--;
            _drainPrefetchQueue();
          });
    }
  }

  bool _ensureCanSubscribe() {
    if (_appService.canSubscribe) return true;
    ToastUtil.info('当前帐号无订阅权限');
    return false;
  }

  Future<SubscribeItem?> fetchAndSaveSubscribeStatus(
    String mediaKey, {
    int? season,
    String? title,
  }) async {
    final subscribeItem = await getSubscribeMediaStatus(
      mediaKey,
      season: season,
      title: title,
    );
    setSubscribeStatus(
      subscribeKeyFor(mediaKey, season: season, title: title),
      subscribeItem,
    );
    return subscribeItem;
  }

  /// GET /api/v1/subscribe/media/{mediaKey}?season=&title= 获取媒体/季的订阅状态
  /// 参考 media detail：mediaKey 与详情 path 一致，如 tmdb:1434
  /// 返回订阅 item 的 json 结构，未订阅时可能 404 或空
  Future<SubscribeItem?> getSubscribeMediaStatus(
    String mediaKey, {
    int? season,
    String? title,
  }) async {
    try {
      final identity = MediaIdentity.parse(mediaKey);
      final useV3 = identity != null && await _serverApiVersionService.isV3();
      final path = useV3
          ? '/api/v1/subscribe/media/${identity.id}'
          : '/api/v1/subscribe/media/$mediaKey';
      final query = <String, dynamic>{};
      if (useV3) query['media_source'] = identity.source;
      if (season != null) query['season'] = season;
      if (title != null && title.trim().isNotEmpty) {
        query['title'] = title.trim();
      }
      final response = await _apiClient.get<dynamic>(
        path,
        queryParameters: query.isNotEmpty ? query : null,
      );
      if (response.statusCode == 404 || response.statusCode == 204) return null;
      if (response.statusCode != 200) return null;
      final data = response.data;
      SubscribeItem? subscribeItem;
      if (data is Map) {
        subscribeItem = SubscribeItem.fromJson(
          normalizeSubscribeJson(Map<String, dynamic>.from(data)),
        );
      }
      if (subscribeItem != null && subscribeItem.id != null) {
        return subscribeItem;
      }
      return null;
    } catch (e) {
      _log.handle(e, message: '获取订阅状态失败');
      return null;
    }
  }

  Future<(bool isSuccess, int? subscribeId)> toggleMediaSubscribe({
    required String mediaKey,
    required bool isTv,
    required bool isSubscribed,
    String? doubanid,
    String? name,
    int? season,
    String? year,
    String? tmdbid,
    String? subscribeId,
  }) async {
    if (!_ensureCanSubscribe()) return (false, null);
    if (isSubscribed) {
      if (subscribeId != null) {
        final ok = await deleteSubscribes(subscribeId);
        return (ok, null);
      } else {
        final ok = await deleteMediaSubscribe(
          mediaKey,
          season: season?.toString() ?? '0',
        );
        return (ok, null);
      }
    }

    if (isTv) {
      final ok = await submitTvSubscribe(
        doubanid: doubanid,
        identityKey: mediaKey,
        name: name,
        season: season,
        year: year,
        tmdbid: tmdbid,
      );
      return (ok.success == true, ok.data?.id);
    } else {
      final ok = await submitMovieSubscribe(
        doubanid: doubanid,
        identityKey: mediaKey,
        name: name,
        season: season,
        year: year,
        tmdbid: tmdbid,
      );
      return (ok.success == true, ok.data?.id);
    }
  }

  Future<SubscribeSubmitResp> submitSubscribe(
    String mediaType, {
    required Map<String, dynamic> payload,
  }) async {
    if (!_ensureCanSubscribe()) {
      return SubscribeSubmitResp(success: false, message: '当前帐号无订阅权限');
    }
    try {
      final path = '/api/v1/subscribe/';
      final requestPayload = await prepareSubscribePayload(payload);
      final response = await _apiClient.post(path, data: requestPayload);
      if (response.statusCode == 200) {
        final result = SubscribeSubmitResp.fromJson(response.data);
        if (result.success == true) _refreshCalendarWidget();
        return result;
      }
      return SubscribeSubmitResp(success: false, message: '请求失败');
    } catch (e) {
      _log.handle(e, message: '提交订阅失败');
      return SubscribeSubmitResp(success: false, message: '请求失败');
    }
  }

  Future<SubscribeSubmitResp> submitMovieSubscribe({
    String? bangumiid,
    int? bestVersion = 0,
    String? doubanid,
    String? episodeGroup = '',
    String? identityKey,
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
    final isV3 = await _serverApiVersionService.isV3();
    if (isV3) {
      final identity = _deriveMediaIdentity(
        mediaid: identityKey ?? mediaid,
        tmdbid: tmdbid,
        doubanid: doubanid,
        bangumiid: bangumiid,
      );
      _removeLegacyIdentityKeys(payload);
      if (identity != null) {
        payload['media_source'] = identity.source;
        payload['media_id'] = identity.id;
      }
    }
    final resp = await submitSubscribe('movie', payload: payload);
    return resp;
  }

  Future<SubscribeSubmitResp> submitTvSubscribe({
    String? bangumiid,
    String? doubanid,
    String? episode_group = '',
    String? identityKey,
    String? mediaid = '',
    String? name,
    int? season = 0,
    String? tmdbid,
    String? year = '',
    int bestVersion = 0,
    int? bestVersionFull = 1,
  }) async {
    final payload = {
      'doubanid': doubanid,
      'episode_group': episode_group,
      'mediaid': mediaid,
      'name': name,
      'season': season,
      'tmdbid': tmdbid,
      'year': year,
      'best_version': bestVersion,
      if (bestVersionFull != null) 'best_version_full': bestVersionFull,
      'type': '电视剧',
    };
    final isV3 = await _serverApiVersionService.isV3();
    if (isV3) {
      final identity = _deriveMediaIdentity(
        mediaid: identityKey ?? mediaid,
        tmdbid: tmdbid,
        doubanid: doubanid,
        bangumiid: bangumiid,
      );
      _removeLegacyIdentityKeys(payload);
      if (identity != null) {
        payload['media_source'] = identity.source;
        payload['media_id'] = identity.id;
      }
    }
    return await submitSubscribe('tv', payload: payload);
  }

  Future<bool> deleteMediaSubscribe(
    String mediaKey, {
    String season = '0',
  }) async {
    if (!_ensureCanSubscribe()) return false;
    final identity = MediaIdentity.parse(mediaKey);
    final useV3 = identity != null && await _serverApiVersionService.isV3();
    final response = await _apiClient.delete(
      useV3
          ? '/api/v1/subscribe/media/${identity.id}'
          : '/api/v1/subscribe/media/$mediaKey',
      queryParameters: {
        if (useV3) 'media_source': identity.source,
        'season': season,
      },
    );
    final ok =
        response.statusCode == 200 && response.data['success'] == true;
    if (ok) _refreshCalendarWidget();
    return ok;
  }

  Future<bool> deleteSubscribes(String id) async {
    if (!_ensureCanSubscribe()) return false;
    final response = await _apiClient.delete('/api/v1/subscribe/$id');
    final ok =
        response.statusCode == 200 && response.data['success'] == true;
    if (ok) _refreshCalendarWidget();
    return ok;
  }

  void _refreshCalendarWidget() {
    if (!Get.isRegistered<IosSharedSessionService>()) return;
    Get.find<IosSharedSessionService>().reloadWidgets();
  }

  /// GET /api/v1/subscribe/history/{mtype}?page=&count=
  Future<List<Map<String, dynamic>>> fetchSubscribeHistory({
    required String mtype,
    int page = 1,
    int count = 30,
  }) async {
    if (!_ensureCanSubscribe()) {
      throw StateError('当前帐号无订阅权限');
    }
    final encoded = Uri.encodeComponent(mtype);
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/history/$encoded',
      queryParameters: {'page': page, 'count': count},
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw StateError('请求失败 (HTTP $status)');
    }
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// DELETE /api/v1/subscribe/history/{history_id}
  Future<bool> deleteSubscribeHistory(int historyId) async {
    if (!_ensureCanSubscribe()) return false;
    try {
      final response = await _apiClient.delete(
        '/api/v1/subscribe/history/$historyId',
      );
      if (response.statusCode != 200) return false;
      final data = response.data;
      if (data is Map && data['success'] == false) return false;
      return true;
    } catch (e) {
      _log.handle(e, message: '删除订阅历史失败');
      return false;
    }
  }

  /// POST /api/v1/subscribe/ 重新订阅（原样回写历史项）
  Future<SubscribeSubmitResp> resubscribeFromHistory(
    Map<String, dynamic> payload,
  ) {
    return submitSubscribe(payload['type']?.toString() ?? '', payload: payload);
  }

  /// GET /api/v1/subscribe/files/{subscribe_id}
  Future<SubscribeFilesResult> fetchSubscribeFiles(int subscribeId) async {
    if (!_ensureCanSubscribe()) {
      throw StateError('当前帐号无订阅权限');
    }
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/files/$subscribeId',
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw StateError('请求失败 (HTTP $status)');
    }
    final data = response.data;
    if (data is! Map) {
      throw StateError('返回数据格式错误');
    }
    return SubscribeFilesResult.fromJson(Map<String, dynamic>.from(data));
  }

  MediaIdentity? _deriveMediaIdentity({
    String? mediaid,
    String? tmdbid,
    String? doubanid,
    String? bangumiid,
  }) {
    final fromMediaId = MediaIdentity.parse(mediaid);
    if (fromMediaId != null) return fromMediaId;
    return _identityFromSource('themoviedb', tmdbid) ??
        _identityFromSource('douban', doubanid) ??
        _identityFromSource('bangumi', bangumiid);
  }

  MediaIdentity? _identityFromSource(String source, String? id) {
    final normalizedId = id?.trim();
    if (normalizedId == null || normalizedId.isEmpty || normalizedId == '0') {
      return null;
    }
    return MediaIdentity(source: source, id: normalizedId);
  }

  void _removeLegacyIdentityKeys(Map<String, dynamic> payload) {
    payload.remove('tmdbid');
    payload.remove('doubanid');
    payload.remove('bangumiid');
    payload.remove('mediaid');
  }

  Future<Map<String, dynamic>> prepareSubscribePayload(
    Map<String, dynamic> payload,
  ) async {
    if (!await _serverApiVersionService.isV3()) {
      return payload;
    }

    final result = Map<String, dynamic>.from(payload);
    final source = normalizeMediaSource(result['media_source']?.toString());
    final mediaId = result['media_id']?.toString().trim();
    final currentIdentity =
        source != null &&
            mediaId != null &&
            mediaId.isNotEmpty &&
            mediaId != '0'
        ? MediaIdentity(source: source, id: mediaId)
        : null;
    final identity =
        currentIdentity ??
        _deriveMediaIdentity(
          mediaid: result['mediaid']?.toString(),
          tmdbid: result['tmdbid']?.toString(),
          doubanid: result['doubanid']?.toString(),
          bangumiid: result['bangumiid']?.toString(),
        );
    _removeLegacyIdentityKeys(result);
    result.remove('media_source');
    result.remove('media_id');
    if (identity != null) {
      result['media_source'] = identity.source;
      result['media_id'] = identity.id;
    }
    return result;
  }

  // V2 and V3 both retain these GET routes (V3 imports submaintenance).
  bool get canMaintainAll => _appService.isSuperuser;
  bool get canSearchSubscriptions => _appService.canSubscribe;
  final maintenanceBusy = false.obs;

  Future<bool> maintenanceSupported() async =>
      canMaintainAll || canSearchSubscriptions;

  Future<({bool ok, String message})> _runMaintenanceAction(
    String path,
    String doingLabel,
  ) async {
    final allowed = path.endsWith('/search')
        ? canSearchSubscriptions
        : canMaintainAll;
    if (!allowed) return (ok: false, message: '当前帐号无此订阅维护权限');
    if (maintenanceBusy.value) return (ok: false, message: '订阅维护正在提交，请稍候');
    maintenanceBusy.value = true;
    try {
      final response = await _apiClient.get<dynamic>(path);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return (ok: false, message: '$doingLabel失败 (HTTP $status)');
      }
      final data = response.data;
      final message = data is Map ? data['message']?.toString() : null;
      final ok = data is Map && data['success'] == true;
      return (
        ok: ok,
        message: (message?.isNotEmpty ?? false)
            ? message!
            : ok
            ? '已提交执行'
            : '$doingLabel失败：服务端未确认成功',
      );
    } catch (e) {
      _log.handle(e, message: '$doingLabel异常');
      return (ok: false, message: '$doingLabel失败，请稍后重试');
    } finally {
      maintenanceBusy.value = false;
    }
  }

  /// GET /api/v1/subscribe/refresh 刷新订阅（搜索订阅缺货）
  Future<({bool ok, String message})> refreshSubscribes() =>
      _runMaintenanceAction('/api/v1/subscribe/refresh', '刷新订阅');

  /// GET /api/v1/subscribe/check 刷新订阅 TMDB 信息
  Future<({bool ok, String message})> checkSubscribes() =>
      _runMaintenanceAction('/api/v1/subscribe/check', '刷新订阅信息');

  /// GET /api/v1/subscribe/search 搜索所有订阅
  Future<({bool ok, String message})> searchSubscribes() =>
      _runMaintenanceAction('/api/v1/subscribe/search', '搜索订阅');
}

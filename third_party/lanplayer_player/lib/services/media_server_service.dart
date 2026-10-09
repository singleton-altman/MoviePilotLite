import 'dart:convert';
import '../player/iso/iso_native.dart';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../models/media_models.dart';
import '../utils/app_log.dart';
import 'dual_stack_http.dart';

class ChapterMarker {
  final String name;
  final int startTicks, endTicks;
  final String? markerType;

  const ChapterMarker({required this.name, required this.startTicks, required this.endTicks, this.markerType});

  Duration get startDuration => Duration(microseconds: startTicks ~/ 10);
  Duration get endDuration => Duration(microseconds: endTicks ~/ 10);
}

class IntroSkip {
  final int introStartTicks, introEndTicks;
  final int? creditsStartTicks, creditsEndTicks;

  const IntroSkip({required this.introStartTicks, required this.introEndTicks, this.creditsStartTicks, this.creditsEndTicks});

  Duration get introStartDuration => Duration(microseconds: introStartTicks ~/ 10);
  Duration get introEndDuration => Duration(microseconds: introEndTicks ~/ 10);
  Duration? get creditsStartDuration => creditsStartTicks != null ? Duration(microseconds: creditsStartTicks! ~/ 10) : null;
  Duration? get creditsEndDuration => creditsEndTicks != null ? Duration(microseconds: creditsEndTicks! ~/ 10) : null;
  bool get hasIntro => introEndTicks > introStartTicks;
  bool get hasCredits => creditsStartTicks != null;
}

class TrickplayInfo {
  final int intervalMs;     // 每张缩略图对应的时间间隔（毫秒）
  final int tileWidth;      // 拼图网格列数
  final int tileHeight;     // 拼图网格行数
  final int thumbnailCount; // 每张精灵图包含的缩略图总数

  const TrickplayInfo({
    required this.intervalMs,
    required this.tileWidth,
    required this.tileHeight,
    required this.thumbnailCount,
  });

  /// 每张拼图覆盖的总时长（毫秒）
  int get tileDurationMs => intervalMs * thumbnailCount;
}

/// 精灵图中单张缩略图的定位信息
/// 进度条用此数据从精灵图中裁剪出正确的子图
class TrickplayTile {
  final String spriteSheetUrl; // 精灵图 URL
  final int col;              // 列位置（0-indexed）
  final int row;              // 行位置（0-indexed）
  final int gridWidth;        // 网格总列数
  final int gridHeight;       // 网格总行数

  const TrickplayTile({
    required this.spriteSheetUrl,
    required this.col,
    required this.row,
    required this.gridWidth,
    required this.gridHeight,
  });
}

abstract class MediaServerService {
  String baseUrl;
  final Dio dio;

  MediaServerService({required this.baseUrl, Dio? dioClient})
      : dio = dioClient ?? createDualStackDio(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json; charset=utf-8',
          },
        ) {
    // 401 自愈拦截器：收到 401 → 强制重新登录 → 用新 token 重试原请求一次。
    // 覆盖两种情况：① 从未登录（首页缓存新鲜时跳过登录，service 一直无 token）；
    // ② token 会话中过期。登录请求自身标记 _isLoginRequest 避免递归死锁；
    // 并发 401 通过 _reauthFuture 共享同一次重登，避免重复登录。
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, ErrorInterceptorHandler handler) async {
        final opts = e.requestOptions;
        final is401 = e.response?.statusCode == 401;
        final isLogin = opts.extra['_isLoginRequest'] == true;
        final isRetry = opts.extra['_retried401'] == true;
        final isSkipRetry = opts.extra['_skipAuthRetry'] == true;
        if (is401 && !isLogin && !isRetry && !isSkipRetry) {
          AppLog.w('Auth', '请求 401，尝试重新认证: ${opts.path}');
          final ok = await reAuthenticate();
          if (ok) {
            try {
              opts.extra['_retried401'] = true;
              opts.headers.addAll(authHeaders); // 用新 token 覆盖请求头里的旧 token
              final response = await dio.fetch<dynamic>(opts);
              AppLog.i('Auth', '401 重试成功: ${opts.path}');
              return handler.resolve(response);
            } on DioException catch (retryError) {
              AppLog.w('Auth', '401 重试仍失败: ${opts.path}');
              return handler.next(retryError);
            }
          } else {
            AppLog.w('Auth', '重新认证失败（可能未配置凭据）: ${opts.path}');
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool>? _reauthFuture;

  /// 强制重新认证（401 拦截器调用）。并发 401 共享同一次重登，避免重复登录。
  Future<bool> reAuthenticate() {
    _reauthFuture ??= doReAuthenticate().whenComplete(() => _reauthFuture = null);
    return _reauthFuture!;
  }

  /// 作废过期 token 并重新登录。子类重写；默认仅 ensureAuthenticated()。
  Future<bool> doReAuthenticate() => ensureAuthenticated();

  /// 当前认证请求头（401 重试时用于刷新原请求头里的旧 token）。子类按各自认证方式重写。
  Map<String, String> get authHeaders => const {};

  Future<bool> testConnection();

  // ─── 轻量健康检查（不触发登录流程）──────────────────────────
  /// 当前是否已持有有效认证凭据（纯本地判断，无网络请求）
  bool get isCurrentlyAuthenticated => false;

  /// 轻量连通性检查：仅验证当前 token 是否有效，不触发登录。
  /// 默认回退到 testConnection()（子类应覆盖为轻量实现）
  Future<bool> ping() async => testConnection();

  // ─── 登录冷却机制 ──────────────────────────────────────────────
  DateTime? _lastLoginFailure;
  static const Duration _loginFailureBackoff = Duration(minutes: 5);

  /// 是否处于登录冷却期（避免轰炸已宕机的服务器）。
  /// **只有失败才退避**：失败后 5 分钟内不再尝试，成功即清除。
  /// 「登录进行中」不是冷却 —— 并发场景由各子类的单飞互斥兜住
  /// （Emby loginByUsernamePassword / FnOS login 同款）。旧实现把
  /// 进行中也当冷却，健康检查/媒体库/下拉刷新并发的后来者直接拿到
  /// false（移动端真机日志 2026-09-06 实证：每次冷启动都报认证失败）。
  bool get isInLoginCooldown {
    final f = _lastLoginFailure;
    if (f == null) return false;
    return DateTime.now().difference(f) < _loginFailureBackoff;
  }

  /// 登录失败时调用：进入 5 分钟退避。
  void recordLoginFailure() {
    _lastLoginFailure = DateTime.now();
  }

  /// 登录成功时调用：清除失败退避。
  void recordLoginSuccess() {
    _lastLoginFailure = null;
  }

  Future<List<MediaItem>> getLibraries();
  Future<List<MediaItem>> getLibraryItems(String libraryId, {int page = 0, int limit = 50, bool includeBoxSets = false});
  /// 分页拉取库内全部条目（单页默认 50 条，大库需要循环分页取全）
  Future<List<MediaItem>> getAllLibraryItems(String libraryId, {bool includeBoxSets = false});
  Future<MediaItem> getItemDetails(String itemId);
  Future<String> getStreamUrl(String itemId, {String? quality, bool burnInSubtitle = false, int? subtitleIndex});

  /// 释放 ISO 原盘直连的本地代理(不支持转码判定的实现为空操作)。
  void stopIsoProxy() {}

  /// 最近一次 PlaybackInfo 的转码备用流;不支持转码判定的实现返回 null。
  String? get lastTranscodeUrl => null;
  Future<List<MediaItem>> search(String query);

  /// 相似推荐（Emby/Jellyfin `/Items/{id}/Similar`）
  /// 服务端不支持时返回空列表，UI 无数据则不显示分区
  Future<List<MediaItem>> getSimilarItems(String itemId) async => [];
  /// 单独查某个条目的演职人员。
  ///
  /// 只有飞牛需要：它的剧集级 `person/list` 返回空，演员挂在可播放的子条目上，
  /// 所以 UI 在拿到剧集列表之后要用某一集的 guid 再查一次（此时集列表已经在
  /// 手上，不产生额外请求）。其余服务器的 People 随 getItemDetails 一起回来，
  /// 这里返回 null 表示「不用再查」。
  Future<List<Map<String, dynamic>>?> getPeopleFor(String itemId) async => null;
  Future<void> markWatched(String itemId, {double? progress, int? positionMs});
  Future<void> markUnwatched(String itemId);
  Future<void> reportPlaybackStart(String itemId, {String? mediaSourceId});
  Future<void> reportPlaybackProgress(String itemId, int positionMs, {bool isPlaying = true, String? mediaSourceId});
  Future<void> reportPlaybackStopped(String itemId, {int? positionMs, String? mediaSourceId});
  Future<void> markFavorite(String itemId);
  Future<void> unmarkFavorite(String itemId);
  Future<List<ChapterMarker>> getChapters(String itemId);
  Future<IntroSkip?> getIntroSkipInfo(String itemId);
  Future<List<MediaItem>> getSeasons(String seriesId);
  Future<List<MediaItem>> getEpisodes(String seriesId, {String? seasonId, int? page, int limit = 50});
  Future<List<MediaItem>> getResumeItems({int limit = 20});

  /// 获取流播放所需的 HTTP 请求头（由子类实现各自的认证方式）
  Map<String, String> get streamHeaders;

  /// 获取图片加载所需的 HTTP 请求头（默认空，需要认证的服务重写）
  Map<String, String> get imageHeaders => const {};

  /// 确保服务已认证（公开方法，供 UI 层在加载图片/视频前调用）
  /// 默认实现：视为已认证（子类按需重写触发登录流程）
  Future<bool> ensureAuthenticated() async => true;

  /// 获取当前的认证信息（登录成功后可调用）
  /// 返回 { 'apiKey': ..., 'userId': ... }，无认证信息返回空 map
  Map<String, String> getAuthInfo() => const {};
}

// ==================== EmbyService ====================

class EmbyService extends MediaServerService {
  String apiKey;
  String? userId;
  String? _username;
  String? _password;
  bool _userIdLoaded = false;
  String _playSessionId = _generateSessionId();

  /// ISO 原盘直连由原生层管理,无需 Dart 侧释放。
  /// 最近一次 PlaybackInfo 返回的转码地址（remux：视频拷贝+音频转码）。
  /// 服务器判定不能直连时 getStreamUrl 已直接改用转码流；判定能直连但
  /// 播放中途失败（Exo Source error / MPV 解码器起不来）时，播放页拿它
  /// 做自动回退。null = 服务器没给转码地址。
  String? _lastTranscodeUrl;
  String? get lastTranscodeUrl => _lastTranscodeUrl;

  static String _generateSessionId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16)}${now.hashCode.toRadixString(16)}';
  }

  /// 刷新播放会话 ID（每次开始新播放时调用）
  void refreshPlaySession() {
    _playSessionId = _generateSessionId();
  }

  final Map<String, _CachedDetailItem> _detailsCache = {};
  final Map<String, _CachedSeasons> _seasonsCache = {};
  final Map<String, _CachedEpisodes> _episodesCache = {};
  static const int _cacheDurationMs = 5 * 60 * 1000;

  EmbyService({required String baseUrl, this.apiKey = '', this.userId, String? username, String? password, Dio? dioClient})
      : _username = username,
        _password = password,
        super(baseUrl: baseUrl, dioClient: dioClient) {
    if (apiKey.isNotEmpty) {
      dio.options.headers['X-MediaBrowser-Token'] = apiKey;
    }
    AppLog.i('Emby', 'init baseUrl=$baseUrl hasKey=${apiKey.isNotEmpty} hasUser=${(username ?? '').isNotEmpty}');
  }

  void clearCache() {
    _detailsCache.clear();
    _seasonsCache.clear();
    _episodesCache.clear();
  }

  @override
  Map<String, String> get streamHeaders => {'X-MediaBrowser-Token': apiKey};

  @override
  Map<String, String> get imageHeaders => apiKey.isNotEmpty
      ? {'X-MediaBrowser-Token': apiKey}
      : const {};

  @override
  Future<bool> ensureAuthenticated() => _ensureAuth();

  /// 使用用户名密码登录，获取 AccessToken 并填充 apiKey 和 userId。
  /// 适用于 Emby/Jellyfin 服务器，无需手动配置 API 密钥。
  ///
  /// **单飞**：并发调用共享同一次登录（冷启动时健康检查/媒体库/详情页会
  /// 同时发现未认证,各自登录会互相踩 —— 后到的 401 处理器把先到的
  /// 新 token 作废,引发登录风暴）。
  Future<bool> loginByUsernamePassword() {
    _loginFuture ??= _doLoginByUsernamePassword().whenComplete(() => _loginFuture = null);
    return _loginFuture!;
  }

  Future<bool>? _loginFuture;

  Future<bool> _doLoginByUsernamePassword() async {
    if (_username == null || _password == null) return false;
    if (_username!.isEmpty) return false;
    if (isInLoginCooldown) {
      AppLog.w('Emby', '登录冷却中，跳过: $_username');
      return false;
    }

    AppLog.i('Emby', '尝试用户名密码登录: $_username');
    try {
      final deviceId = 'LANPlayer_${DateTime.now().millisecondsSinceEpoch}';
      final authHeader = 'MediaBrowser Client="LANPlayer", Device="LANPlayer", '
          'DeviceId="$deviceId", Version="1.0.0"';
      final response = await dio.post(
        '$baseUrl/Users/AuthenticateByName',
        data: {'Username': _username, 'Pw': _password},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        }, extra: {'_isLoginRequest': true}),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300 && response.data is Map) {
        final data = response.data as Map;
        final accessToken = data['AccessToken']?.toString()
            ?? (data['User'] as Map?)?['AccessToken']?.toString();
        final userIdStr = (data['User'] as Map?)?['Id']?.toString()
            ?? data['User']?['Id']?.toString();

        if (accessToken != null && accessToken.isNotEmpty) {
          apiKey = accessToken;
          userId = userIdStr;
          _userIdLoaded = userId != null && userId!.isNotEmpty;

          // 更新全局认证头
          dio.options.headers['X-MediaBrowser-Token'] = apiKey;
          // Jellyfin 12.0:登录拿到 token 后刷新 Authorization 头(内联 Token);
          // Emby 服务器上多一个头无害
          try {
            if (this is JellyfinService) {
              (this as JellyfinService)._applyAuthorizationHeader();
            }
          } catch (_) {}

          AppLog.i('Emby', '用户名密码登录成功: userId=$userId');
          _tokenAcquiredAt = DateTime.now();
          recordLoginSuccess();
          return true;
        }
      }

      AppLog.w('Emby', '用户名密码登录失败: HTTP $statusCode');
    } catch (e) {
      AppLog.w('Emby', '用户名密码登录异常: $e');
    }
    recordLoginFailure();
    return false;
  }

  /// 确保已通过认证（有 apiKey）
  /// 如果没有 apiKey 但有用户名密码，则自动登录获取 access token
  Future<bool> _ensureAuth() async {
    if (apiKey.isNotEmpty) return true;
    if (_username != null && _password != null && _username!.isNotEmpty) {
      return await loginByUsernamePassword();
    }
    return false;
  }

  @override
  Map<String, String> get authHeaders =>
      apiKey.isNotEmpty ? {'X-MediaBrowser-Token': apiKey} : const {};

  /// 401 自愈：作废当前（可能过期的）token，用用户名密码强制重新登录。
  ///
  /// **新鲜 token 保护**：token 拿到 5 秒内的 401 是「登录完成前就发出的
  /// 旧请求」迟到的报应 —— 作废刚到手的 token 会引发登录风暴（并发旧请求
  /// 每个都作废一次），让该次请求直接失败即可，后续请求用新 token 正常走。
  @override
  Future<bool> doReAuthenticate() async {
    if (_username == null || _username!.isEmpty) {
      return apiKey.isNotEmpty; // 无凭据无法重登
    }
    if (shouldKeepFreshToken(
        acquiredAt: _tokenAcquiredAt, now: DateTime.now())) {
      AppLog.w('Emby',
          '401 来自登录完成前的旧请求,保留新鲜 token 不作废: $_username');
      return false;
    }
    AppLog.i('Emby', '作废旧 token，强制重新登录: $_username');
    apiKey = '';
    userId = null;
    _userIdLoaded = false;
    _tokenAcquiredAt = null;
    dio.options.headers.remove('X-MediaBrowser-Token');
    return await loginByUsernamePassword();
  }

  /// token 是否新鲜到不该被 401 作废（拿到 5 秒内）。
  static bool shouldKeepFreshToken({DateTime? acquiredAt, required DateTime now}) {
    if (acquiredAt == null) return false;
    return now.difference(acquiredAt) < const Duration(seconds: 5);
  }

  Future<String> _ensureUserId() async {
    if (_userIdLoaded && userId != null && userId!.isNotEmpty) return userId!;
    // 先确保认证
    await _ensureAuth();
    try {
      if (userId != null && userId!.isNotEmpty) {
        try {
          final r = await dio.get('/Users/$userId');
          if (r.statusCode == 200) { _userIdLoaded = true; AppLog.i('Emby', 'userId OK: $userId'); return userId!; }
        } catch (e) { AppLog.w('Emby', '/Users/\$userId failed: $e'); }
      }
      final r = await dio.get('/Users');
      final users = (r.data is List) ? (r.data as List) : <dynamic>[];
      if (users.isNotEmpty) {
        userId = users.first['Id']?.toString() ?? '';
        _userIdLoaded = true;
        AppLog.i('Emby', 'userId from /Users: $userId');
        return userId!;
      }
      AppLog.w('Emby', '/Users returned empty list');
    } catch (e) { AppLog.e('Emby', '_ensureUserId failed', e); }
    _userIdLoaded = true;
    return userId ?? '';
  }

  // ─── token 过期追踪 ──────────────────────────────────────────
  DateTime? _tokenAcquiredAt;
  static const Duration _tokenLifetime = Duration(hours: 24);

  /// token 是否可能已过期
  bool get _tokenPossiblyExpired {
    if (_tokenAcquiredAt == null) return true;
    return DateTime.now().difference(_tokenAcquiredAt!) > _tokenLifetime;
  }

  @override
  bool get isCurrentlyAuthenticated => apiKey.isNotEmpty && !_tokenPossiblyExpired && !isInLoginCooldown;

  /// 轻量连通性检查：仅用已有 token 验证服务器可达性，不触发登录流程
  @override
  Future<bool> ping() async {
    if (apiKey.isEmpty) return false;
    try {
      final r = await dio.get(
        '/System/Info',
        options: Options(extra: {'_skipAuthRetry': true}),
      );
      AppLog.i('Emby', 'ping OK, server=${r.data['ServerName']}');
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      await _ensureUserId();
      final r = await dio.get('/System/Info');
      AppLog.i('Emby', 'connection OK, server=${r.data['ServerName']}');
      return r.statusCode == 200;
    } catch (e) { AppLog.e('Emby', 'connection FAILED', e); return false; }
  }

  @override
  Map<String, String> getAuthInfo() {
    if (apiKey.isEmpty) return const {};
    return {
      'apiKey': apiKey,
      if (userId != null && userId!.isNotEmpty) 'userId': userId!,
    };
  }

  @override
  Future<List<MediaItem>> getLibraries() async {
    try {
      await _ensureUserId();
      final r = await dio.get('/Users/$userId/Views');
      final items = (r.data['Items'] as List?) ?? [];
      AppLog.i('Emby', 'getLibraries: ${items.length} views');
      return items.map((i) => MediaItem(id: i['Id'] ?? '', title: i['Name'] ?? '',
        posterUrl: i['ImageTags']?['Primary'] != null ? '$baseUrl/Items/${i['Id']}/Images/Primary?api_key=$apiKey' : '',
        type: i['CollectionType'] == 'tvshows' ? MediaType.series : MediaType.movie,
        collectionType: i['CollectionType']?.toString())).toList();
    } catch (e) { AppLog.e('Emby', 'getLibraries FAILED', e); return []; }
  }

  @override
  Future<List<MediaItem>> getLibraryItems(String libraryId, {int page = 0, int limit = 50, bool includeBoxSets = false}) async {
    try {
      await _ensureUserId();
      final hasUid = userId != null && userId!.isNotEmpty;
      // Jellyfin 的合集(boxsets)库必须显式 IncludeItemTypes=BoxSet 才返回合集条目
      // （实测 Movie,Series 过滤下返回 0；Emby 则两者都返回），故 boxsets 库追加。
      final itemTypes = includeBoxSets ? 'Movie,Series,BoxSet' : 'Movie,Series';
      final params = <String, dynamic>{'StartIndex': page * limit, 'Limit': limit, 'Recursive': true,
        'IncludeItemTypes': itemTypes, 'SortBy': 'DateCreated', 'SortOrder': 'Descending',
        'Fields': 'Genres,MediaSources,Overview,CommunityRating,ProviderIds,UserData'};
      if (libraryId.isNotEmpty) params['ParentId'] = libraryId;
      final path = hasUid ? '/Users/$userId/Items' : '/Items';
      final r = await dio.get(path, queryParameters: params);
      final items = (r.data['Items'] as List?) ?? [];
      AppLog.i('Emby', 'getLibraryItems($libraryId) uid=$userId: ${items.length} items (boxsets=$includeBoxSets)');
      return _parseItems(items);
    } catch (e) {
      // 网络/鉴权错误必须向上抛：上层（首页缓存刷新）才能回退到旧数据，
      // 而不是把错误吞成空列表，覆盖并清空正常的缓存
      AppLog.e('Emby', 'getLibraryItems FAILED: $libraryId', e);
      rethrow;
    }
  }

  /// 分页拉取库内全部条目：Emby/Jellyfin 单页默认 50 条，大库只取第一页会"少".
  /// （实测 Emby 166 部 / Jellyfin 173 部电影的库，之前都只显示 50）。每页 200 条循环直到取完。
  @override
  Future<List<MediaItem>> getAllLibraryItems(String libraryId, {bool includeBoxSets = false}) async {
    final all = <MediaItem>[];
    var page = 0;
    const perPage = 200;
    while (page < 50) {
      final batch = await getLibraryItems(libraryId, page: page, limit: perPage, includeBoxSets: includeBoxSets);
      all.addAll(batch);
      if (batch.length < perPage) break;
      page++;
    }
    AppLog.i('Emby', 'getAllLibraryItems($libraryId): ${all.length} items (${page + 1} 页)');
    return all;
  }

  @override
  Future<List<MediaItem>> getSimilarItems(String itemId) async {
    try {
      await _ensureUserId();
      final r = await dio.get('/Items/$itemId/Similar', queryParameters: {
        'Limit': 12,
        'Fields': 'Genres,MediaSources,Overview,CommunityRating,ProviderIds,UserData',
      });
      final items = (r.data['Items'] as List?) ?? [];
      AppLog.i('Emby', 'getSimilarItems($itemId): ${items.length} items');
      return _parseItems(items);
    } catch (e) {
      AppLog.w('Emby', 'getSimilarItems FAILED (服务端可能不支持): $e');
      return [];
    }
  }

  @override
  /// 按 TMDB ID 查询媒体服务器条目(电影/剧集通吃),供宿主详情页播放映射。
  /// 注意:Emby 对 AnyProviderIdEquals 查询会返回 500(4.9 实测),
  /// 因此用标题搜索 + 本地比对 ProviderIds 的方式。
  Future<MediaItem?> findItemByTmdb({
    required int tmdbId,
    bool? isTv,
    String? title,
  }) async {
    await _ensureUserId();
    // 类型未知时不加 IncludeItemTypes,电影/剧集都查
    final include = isTv == null ? null : (isTv ? 'Series' : 'Movie');
    if (title == null || title.isEmpty) {
      AppLog.i('Emby', 'findItemByTmdb: 无标题可查 (tmdb=$tmdbId)');
      return null;
    }
    final query = <String, dynamic>{
      'Recursive': 'true',
      'SearchTerm': title,
      'Fields': 'ProviderIds,UserData',
      'Limit': '20',
      'UserId': userId,
    };
    if (include != null) query['IncludeItemTypes'] = include;
    final r = await dio.get('/Items', queryParameters: query);
    final items = (r.data is Map ? r.data['Items'] as List? : null) ?? const [];
    AppLog.i('Emby',
        'findItemByTmdb("$title", tmdb=$tmdbId, isTv=$isTv) -> ${items.length} items');
    MediaItem? single;
    var count = 0;
    for (final it in items.whereType<Map>()) {
      final id = it['Id']?.toString() ?? '';
      if (id.isEmpty) continue;
      count++;
      single ??= _parseItem(Map<String, dynamic>.from(it));
      final providers = (it['ProviderIds'] as Map?) ?? const {};
      var tmdb = providers['Tmdb']?.toString() ??
          providers['tmdb']?.toString() ??
          providers['TMDB']?.toString();
      if (tmdb != null && tmdb.contains('.')) tmdb = tmdb.split('.').last;
      if (tmdbId > 0 && tmdb == tmdbId.toString()) {
        AppLog.i('Emby', 'findItemByTmdb matched: $id');
        return _parseItem(Map<String, dynamic>.from(it));
      }
    }
    // 只有一个结果时直接采信(标题足够特异)
    if (count == 1 && single != null) {
      AppLog.i('Emby', 'findItemByTmdb single result accepted: ${single.id}');
      return single;
    }
    AppLog.i('Emby', 'findItemByTmdb: no ProviderIds match (count=$count)');
    return null;
  }

  Future<MediaItem> getItemDetails(String itemId) async {
    final cached = _detailsCache[itemId];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cached.timestamp < _cacheDurationMs) {
      AppLog.d('Emby', 'getItemDetails cache hit: $itemId');
      return cached.item;
    }

    await _ensureUserId();
    final r = await dio.get('/Users/$userId/Items/$itemId', queryParameters: {
      'Fields': 'Overview,Genres,People,MediaSources,MediaStreams,ProviderIds,CommunityRating,UserData',
    });
    final item = _parseItem(r.data);
    _detailsCache[itemId] = _CachedDetailItem(item);
    AppLog.d('Emby', 'getItemDetails cached: $itemId (${_detailsCache.length} items)');
    return item;
  }

  /// 画质选项 → MaxStreamingBitrate（bps）：
  /// auto/original = 直连或自适应（不设 bitrate 上限）；
  /// 1080p/720p/4k 映射为对应的转码码率上限
  static String? _resolveBitrate(String? quality) {
    switch (quality) {
      case null:
      case 'auto':
      case 'original':
        return null;
      case '720p':
        return '4000000';
      case '1080p':
        return '8000000';
      case '4k':
        return '40000000';
      default:
        return quality; // 兼容直接传数字字符串
    }
  }

  @override
  Future<String> getStreamUrl(String itemId, {String? quality, bool burnInSubtitle = false, int? subtitleIndex}) async {
    await _ensureUserId();
    await _ensureAuth();
    final bitrate = _resolveBitrate(quality);

    // 字幕烧录：请求服务器用 FFmpeg 把字幕编码进视频流（SubtitleMethod=Encode）。
    // 此时服务器必须转码，DirectPlay 会被忽略，字幕变成画面像素——
    // 适合截图/投屏要带字幕或客户端渲染不了的复杂字幕。
    final burnQuery = burnInSubtitle
        ? '&SubtitleMethod=Encode'
            '&TranscodingSubtitleMethod=Encode'
            '${subtitleIndex != null ? '&SubtitleStreamIndex=$subtitleIndex' : ''}'
        : '';

    // ── DeviceProfile：如实申报客户端能力 ──
    // 之前不带 Profile 且永远 Static=true 直传，原盘文件（TrueHD 音频/PGS
    // 字幕/.iso）直接怼给播放器：Exo 数据源层报 Source error、MPV 缺
    // truehd/pgssub 解码器有画无声（真机日志 2026-08-29 实证）。
    // 申报后服务器自行判定：能直连给直连，不能就返回 TranscodingUrl
    // （remux：视频原样拷贝仅音频转码，开销很低）。
    const deviceProfile = {
      'MaxStreamingBitrate': 120000000,
      'DirectPlayProfiles': [
        {
          'Container':
              'mp4,mkv,mov,m4v,webm,avi,ts,m2ts,mts,wmv,flv,3gp,ogv,mpg,mpeg',
          'Type': 'Video',
          'VideoCodec': 'h264,hevc,av1,vp9,mpeg4,mpeg2video',
          'AudioCodec':
              'aac,mp3,ac3,eac3,flac,opus,vorbis,alac,mp2,pcm_s16le,pcm_s24le',
        },
      ],
      'TranscodingProfiles': [
        {
          'Container': 'ts',
          'Type': 'Video',
          'VideoCodec': 'h264,hevc',
          'AudioCodec': 'aac,ac3,eac3,mp3',
          'Protocol': 'http',
          'BreakOnNonKeyFrames': true,
        },
        {
          'Container': 'mkv',
          'Type': 'Video',
          'VideoCodec': 'copy',
          'AudioCodec': 'aac,ac3,eac3,mp3',
          'Protocol': 'http',
        },
      ],
      'SubtitleProfiles': [
        {'Format': 'srt', 'Method': 'External'},
        {'Format': 'subrip', 'Method': 'External'},
        {'Format': 'ass', 'Method': 'External'},
        {'Format': 'ssa', 'Method': 'External'},
        {'Format': 'vtt', 'Method': 'External'},
        {'Format': 'pgssub', 'Method': 'Embed'},
        {'Format': 'dvdsub', 'Method': 'Embed'},
        {'Format': 'dvbsub', 'Method': 'Embed'},
      ],
    };

    // Emby 需要先获取 PlaybackInfo 拿到真实 MediaSourceId 和 PlaySessionId
    try {
      final r = await dio.post(
        '/Items/$itemId/PlaybackInfo',
        data: {
          'UserId': userId,
          'AllowVideoStreamCopy': true,
          'AllowAudioStreamCopy': true,
          'EnableDirectPlay': true,
          'EnableDirectStream': true,
          'DeviceProfile': deviceProfile,
        },
      );
      final mediaSources = (r.data['MediaSources'] as List?) ?? [];
      final playSessionId = r.data['PlaySessionId']?.toString();
      if (mediaSources.isNotEmpty) {
        final source = mediaSources[0] as Map;
        final sourceId = source['Id']?.toString() ?? itemId;
        final supportsDirect = source['SupportsDirectPlay'] == true ||
            source['SupportsDirectStream'] == true;

        // ── ISO 原盘:永不直连 ──
        // 服务器会把 BDMV ISO 的 Container 误报为 'ts' 并声称可直连(实测),
        // 但客户端(ffmpeg/mpv/Exo)都没有 UDF 解复用器,直连必然
        // 「Failed to recognize file format」——疯狂动物城 2160p.iso 53GB
        // 真机实证(2026-08-29)。识别命中即走客户端 ISO 直连(libudfread)。
        // ⚠️ 识别不能只看 VideoType/IsoType：Emby 对 .iso 条目这两个字段都是
        // null（Container=blurayiso、Path 以 .iso 结尾，却声称 SupportsDirectPlay
        // =true），漏判就落到「服务器转码流」，而 Emby 转 blurayiso 直接
        // HTTP 500 → 黑屏（2026-09-27 真机实证；同一条目在 Jellyfin 上有值）。
        final videoType = source['VideoType']?.toString() ?? '';
        final isoType = source['IsoType']?.toString() ?? '';
        final container = source['Container']?.toString() ?? '';
        final isoDetected = isIsoMediaSource(source);
        final isoLabel =
            isoType.isNotEmpty ? isoType : (container.isNotEmpty ? container : 'ISO');
        AppLog.i('Emby',
            '媒体源判定: videoType=${videoType.isEmpty ? 'null' : videoType} '
            'isoType=${isoType.isEmpty ? 'null' : isoType} container=$container '
            '→ ${isoDetected ? 'ISO 原盘' : '普通视频'}');
        if (isoDetected) {
          // ── 首选:原生直连(libudfread 解析 + 本地流服务)──
          try {
            final directUrl = isoDirectStreamUrl(
              baseUrl: baseUrl,
              itemId: itemId,
              apiKey: apiKey,
              sourceId: sourceId,
            );
            final localUrl = await IsoNative.openIso(
                directUrl, source['Size'] as int? ?? 0);
            if (localUrl != null) {
              AppLog.i('Emby', 'ISO 原盘($isoLabel):客户端直连 → $localUrl');
              return localUrl;
            }
            AppLog.w('Emby', '原生直连不可用,回退服务器转码');
          } catch (e) {
            AppLog.w('Emby', 'ISO 直连异常,回退服务器转码: $e');
          }

          // ── 回退:服务器转码(字幕烧录)──
          // 从服务器流里挑默认音轨与字幕(优先默认 → 中文 → 第一条):
          // 转码流默认不带字幕(原盘 PGS 必须烧录),音轨只混一路,
          // 所以必须显式指定 SubtitleStreamIndex + SubtitleMethod=Encode。
          final streams = (source['MediaStreams'] as List?) ?? const [];
          bool isKind(Map s, String kind) => s['Type'] == kind;
          bool isZh(Map s) {
            const zh = {'zh', 'zho', 'chi', 'cmn', 'chs', 'zh-hans', 'zh-cn'};
            const zhHant = {'zh-hant', 'zh-tw', 'zh-hk', 'cht'};
            final l = (s['Language'] ?? s['language'] ?? '')
                .toString()
                .toLowerCase();
            return zh.contains(l) || zhHant.contains(l);
          }

          int? pickIndex(String kind, {bool Function(Map)? extra}) {
            Map? hit;
            for (final cond in [
              (Map s) => isKind(s, kind) && s['IsDefault'] == true,
              (Map s) => isKind(s, kind) && isZh(s),
              (Map s) => isKind(s, kind),
            ]) {
              for (final s in streams) {
                final m = Map<String, dynamic>.from(s as Map);
                if (cond(m) && (extra == null || extra(m))) {
                  hit = m;
                  break;
                }
              }
              if (hit != null) break;
            }
            return hit == null ? null : (hit['Index'] as num?)?.toInt();
          }

          final audioIdx = pickIndex('Audio');
          final subIdx = pickIndex('Subtitle');

          final r2 = await dio.post(
            '/Items/$itemId/PlaybackInfo',
            data: {
              'UserId': userId,
              'EnableDirectPlay': false,
              'EnableDirectStream': false,
              'DeviceProfile': deviceProfile,
              // 原盘 PGS 是位图,转码必须烧录(Encode)才有字幕;
              // 文本字幕同样走烧录,保证任何客户端都能看到
              if (subIdx != null) ...{
                'SubtitleStreamIndex': subIdx,
                'SubtitleMethod': 'Encode',
              },
              if (audioIdx != null) 'AudioStreamIndex': audioIdx,
            },
          );
          final sources2 = (r2.data['MediaSources'] as List?) ?? [];
          final raw2 = sources2.isNotEmpty
              ? sources2[0]['TranscodingUrl']?.toString() ?? ''
              : '';
          if (raw2.isNotEmpty) {
            var url2 = raw2.startsWith('http')
                ? raw2
                : '$baseUrl${raw2.startsWith('/') ? '' : '/'}$raw2';
            // TranscodingUrl 若未带烧录参数,补一遍(服务器版本行为差异)
            if (subIdx != null && !url2.contains('SubtitleMethod')) {
              url2 +=
                  '&SubtitleStreamIndex=$subIdx&SubtitleMethod=Encode';
            }
            AppLog.i('Emby',
                'ISO 原盘($isoLabel):转码播放(字幕${subIdx != null ? '烧录@流$subIdx' : '无'},音轨@$audioIdx)');
            return url2;
          }
          AppLog.w('Emby', 'ISO 原盘且服务器未提供转码地址,回退直连(预期失败)');
        }

        // 服务器提供的转码地址（remux/转码），归一成完整 URL 备用
        final raw = source['TranscodingUrl']?.toString();
        if (raw != null && raw.isNotEmpty) {
          _lastTranscodeUrl = raw.startsWith('http')
              ? raw
              : '$baseUrl${raw.startsWith('/') ? '' : '/'}$raw';
        } else {
          _lastTranscodeUrl = null;
        }

        // 服务器判定不能直连（TrueHD 音频/PGS 字幕/iso 容器等）→ 直接给转码
        // 流，不再喂必死的直连地址。
        if (!supportsDirect && _lastTranscodeUrl != null) {
          AppLog.i('Emby', '服务器判定需转码，直接使用转码流: $_lastTranscodeUrl');
          return _lastTranscodeUrl!;
        }

        String url = '$baseUrl/Videos/$itemId/stream?api_key=$apiKey&Static=true'
            '&MediaSourceId=$sourceId'
            '&DeviceId=$_playSessionId'
            '$burnQuery';
        if (playSessionId != null && playSessionId.isNotEmpty) {
          url += '&PlaySessionId=$playSessionId';
        }
        if (bitrate != null) url += '&MaxStreamingBitrate=$bitrate';
        AppLog.i('Emby', 'streamUrl (PlaybackInfo): $url (转码备用: ${_lastTranscodeUrl != null})');
        return url;
      }
    } catch (e) {
      AppLog.w('Emby', 'PlaybackInfo failed, fallback: $e');
    }
    _lastTranscodeUrl = null;

    // Fallback: 直接用 itemId 作为 MediaSourceId
    String url = '$baseUrl/Videos/$itemId/stream?api_key=$apiKey&Static=true&MediaSourceId=$itemId&DeviceId=$_playSessionId$burnQuery';
    if (bitrate != null) url += '&MaxStreamingBitrate=$bitrate';
    AppLog.i('Emby', 'streamUrl (fallback): $url');
    return url;
  }

  @override
  Future<List<MediaItem>> search(String query) async {
    try {
      await _ensureUserId();
      final r = await dio.get('/Items', queryParameters: {
        'SearchTerm': query,
        'IncludeItemTypes': 'Movie,Series',
        'Recursive': true,
        'Limit': 50,
        'Fields': 'Overview,Genres,CommunityRating,ProviderIds,UserData',
      });
      final items = (r.data['Items'] as List?) ?? [];
      final filtered = items.where((i) {
        final type = i['Type']?.toString() ?? '';
        return type == 'Movie' || type == 'Series';
      }).toList();
      AppLog.i('Emby', 'search "$query": ${items.length} total, ${filtered.length} filtered');
      return _parseItems(filtered);
    } catch (e) {
      AppLog.w('Emby', 'search failed: $e');
      return [];
    }
  }

  @override Future<void> markWatched(String itemId, {double? progress, int? positionMs}) async {
    try {
      final params = <String, dynamic>{};
      if (positionMs != null) {
        params['PlaybackPositionTicks'] = (positionMs * 10000); // ms → ticks (100ns)
      } else if (progress != null) {
        params['PlaybackPositionTicks'] = (progress * 10000000).round();
      }
      // Emby UserData 端点要求 Content-Type: application/json，参数放在 body
      // 用 queryParameters 会触发 415 Unsupported Media Type
      await dio.post(
        '/Users/$userId/Items/$itemId/UserData',
        data: params,
        options: Options(contentType: Headers.jsonContentType),
      );
      AppLog.d('Emby', 'markWatched: itemId=$itemId, posTicks=${params['PlaybackPositionTicks']}');
    } catch (e) { AppLog.e('Emby', 'markWatched FAILED: $e'); }
  }

  /// 取消已观看（Emby/Jellyfin：UserData Played=false）
  @override Future<void> markUnwatched(String itemId) async {
    try {
      await dio.post(
        '/Users/$userId/Items/$itemId/UserData',
        data: {'Played': false},
        options: Options(contentType: Headers.jsonContentType),
      );
      AppLog.d('Emby', 'markUnwatched: itemId=$itemId');
    } catch (e) { AppLog.e('Emby', 'markUnwatched FAILED: $e'); }
  }

  /// 播放开始上报 — 注册播放会话，使项目出现在"继续观看"列表
  @override
  Future<void> reportPlaybackStart(String itemId, {String? mediaSourceId}) async {
    try {
      final data = <String, dynamic>{
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId ?? itemId,
        'PlayMethod': 'DirectStream',
        'CanSeek': true,
        'IsPaused': false,
        'IsMuted': false,
        'PlaySessionId': _playSessionId,
      };
      await dio.post(
        '/Sessions/Playing',
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      AppLog.i('Emby', 'reportPlaybackStart OK: itemId=$itemId sessionId=$_playSessionId');
    } catch (e) { AppLog.e('Emby', 'reportPlaybackStart FAILED: $e'); }
  }

  /// 播放进度定期上报 — 更新服务器端播放位置
  @override
  Future<void> reportPlaybackProgress(String itemId, int positionMs, {bool isPlaying = true, String? mediaSourceId}) async {
    try {
      final ticks = positionMs * 10000; // ms → 100ns ticks
      final data = <String, dynamic>{
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId ?? itemId,
        'PositionTicks': ticks,
        'IsPaused': !isPlaying,
        'IsMuted': false,
        'CanSeek': true,
        'PlayMethod': 'DirectStream',
        'PlaySessionId': _playSessionId,
      };
      final r = await dio.post(
        '/Sessions/Playing/Progress',
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      // 提级到 info:进度上报是"继续观看"的核心链路,失败/成功都需可观测
      AppLog.i('Emby',
          'reportPlaybackProgress OK: itemId=$itemId posMs=$positionMs status=${r.statusCode} session=$_playSessionId');
    } catch (e) { AppLog.e('Emby', 'reportPlaybackProgress FAILED: $e, posMs=$positionMs, ticks=${positionMs * 10000}'); }
  }

  /// 播放停止上报 — 提交最终位置，服务器据此更新"继续观看"进度
  @override
  Future<void> reportPlaybackStopped(String itemId, {int? positionMs, String? mediaSourceId}) async {
    try {
      final data = <String, dynamic>{
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId ?? itemId,
        'PlaySessionId': _playSessionId,
      };
      if (positionMs != null) {
        data['PositionTicks'] = positionMs * 10000;
      }
      await dio.post(
        '/Sessions/Playing/Stopped',
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      AppLog.i('Emby', 'reportPlaybackStopped OK: itemId=$itemId posMs=${positionMs ?? 0} session=$_playSessionId');
      AppLog.i('Emby', 'reportPlaybackStopped OK: itemId=$itemId, pos=${positionMs}ms');
    } catch (e) { AppLog.e('Emby', 'reportPlaybackStopped FAILED: $e'); }
  }
  @override Future<void> markFavorite(String itemId) async { try { await dio.post('/Users/$userId/FavoriteItems/$itemId'); } catch (_) {} }
  @override Future<void> unmarkFavorite(String itemId) async { try { await dio.delete('/Users/$userId/FavoriteItems/$itemId'); } catch (_) {} }

  @override
  Future<List<ChapterMarker>> getChapters(String itemId) async {
    try {
      await _ensureUserId();
      // 从 Item 详情中获取 Chapters（/Items/{id}/Chapters 端点不存在）
      final r = await dio.get('/Users/$userId/Items/$itemId', queryParameters: {
        'Fields': 'Chapters',
      });
      final chapters = (r.data['Chapters'] as List?) ?? [];
      final result = <ChapterMarker>[];
      for (int i = 0; i < chapters.length; i++) {
        final c = chapters[i];
        final startTicks = (c['StartPositionTicks'] as num?)?.toInt() ?? 0;
        // 用下一章的起始位置作为本章结束，最后一章默认 1s
        final endTicks = (i + 1 < chapters.length)
            ? ((chapters[i + 1]['StartPositionTicks'] as num?)?.toInt() ?? startTicks + 10000000)
            : startTicks + 10000000;
        result.add(ChapterMarker(
          name: c['Name']?.toString() ?? '',
          startTicks: startTicks,
          endTicks: endTicks,
          markerType: c['MarkerType']?.toString(),
        ));
      }
      AppLog.d('Emby', 'getChapters: ${result.length} chapters for $itemId');
      return result;
    } catch (e) {
      AppLog.w('Emby', 'getChapters failed: $e');
      return [];
    }
  }

  @override
  Future<IntroSkip?> getIntroSkipInfo(String itemId) async {
    // 0) Jellyfin 10.9+ 官方 MediaSegments API: GET /MediaSegments/{itemId}
    //    返回 { Items: [{ Type: 'Intro'|'Outro'|..., StartTicks, EndTicks }], TotalRecordCount }
    try {
      final r = await dio.get('/MediaSegments/$itemId');
      if (r.statusCode == 200 && r.data is Map) {
        final items = (r.data['Items'] as List?) ?? [];
        if (items.isNotEmpty) {
          int? introStart, introEnd, creditsStart, creditsEnd;
          for (final seg in items) {
            if (seg is! Map) continue;
            final type = (seg['Type'] as String?)?.toLowerCase() ?? '';
            final start = (seg['StartTicks'] as num?)?.toInt();
            final end = (seg['EndTicks'] as num?)?.toInt();
            if (start == null || end == null) continue;
            AppLog.d('Emby', 'MediaSegment: type=$type, start=$start, end=$end');
            if (type == 'intro') {
              introStart = start;
              introEnd = end;
            } else if (type == 'outro' || type == 'credits') {
              creditsStart = start;
              creditsEnd = end;
            }
          }
          if (introStart != null && introEnd != null && introEnd > introStart) {
            AppLog.i('Emby', 'IntroSkip via MediaSegments API: intro=$introStart→$introEnd, credits=$creditsStart→$creditsEnd');
            return IntroSkip(
              introStartTicks: introStart,
              introEndTicks: introEnd,
              creditsStartTicks: creditsStart,
              creditsEndTicks: creditsEnd,
            );
          }
          // 只有 credits 也返回
          if (creditsStart != null) {
            AppLog.i('Emby', 'IntroSkip via MediaSegments API (credits only): $creditsStart→$creditsEnd');
            return IntroSkip(
              introStartTicks: 0,
              introEndTicks: 0,
              creditsStartTicks: creditsStart,
              creditsEndTicks: creditsEnd,
            );
          }
        }
      }
    } catch (e) {
      AppLog.d('Emby', 'MediaSegments API 不可用（可能非 Jellyfin 10.9+）: $e');
    }

    // 1) Jellyfin IntroSkipper 插件: GET /Episodes/{episodeId}/IntroTimestamps
    try {
      final r = await dio.get('/Episodes/$itemId/IntroTimestamps');
      if (r.statusCode == 200 && r.data is Map) {
        final result = _parseIntroResponse(r.data as Map<String, dynamic>);
        if (result != null) {
          AppLog.i('Emby', 'IntroSkip via Jellyfin API: intro=${result.hasIntro}, credits=${result.hasCredits}');
          return result;
        }
      }
    } catch (e) {
      AppLog.d('Emby', 'Jellyfin IntroTimestamps 不可用: $e');
    }

    // 2) Emby IntroSkip 插件: 多种端点模式
    // Jellyfin 12.0 移除了 /emby/* 路由前缀 —— 候选路径一律不带前缀
    for (final path in [
      '/Episodes/$itemId/IntroTimestamps',
      '/Items/$itemId/IntroTimestamps',
      '/IntroSkip/Items/$itemId',
    ]) {
      try {
        final r = await dio.get(path);
        if (r.statusCode == 200 && r.data is Map) {
          final result = _parseIntroResponse(r.data as Map<String, dynamic>);
          if (result != null) {
            AppLog.i('Emby', 'IntroSkip via Emby plugin ($path): intro=${result.hasIntro}');
            return result;
          }
        }
      } catch (_) {}
    }

    // 3) 章节数据回退（少数服务器通过 MarkerType 标记 Intro）
    final ch = await getChapters(itemId);
    // 位置合理性校验需要总时长：部分服务器把普通章节命名为"片头/片尾"
    //（位置可能在片头之后很远/片尾之前很远），直接当标记会导致
    // "跳过片头后立刻弹跳过片尾"、autoSkip 误跳整集。
    final durTicks = await _getItemRunTimeTicks(itemId);
    int? introStart, introEnd, creditsStart, creditsEnd;
    for (final c in ch) {
      final mt = c.markerType?.toLowerCase() ?? '';
      final nm = c.name.toLowerCase();
      // Emby/Jellyfin 标准 marker：Intro（整段区间）
      if (mt == 'intro') {
        introStart = c.startTicks;
        introEnd = c.endTicks;
        AppLog.d('Emby', 'chapter marker Intro: ${c.startTicks}→${c.endTicks}');
        continue;
      }
      // Outro/Credits marker
      if (mt == 'outro' || mt == 'credits') {
        creditsStart = c.startTicks;
        creditsEnd = c.endTicks;
        AppLog.d('Emby', 'chapter marker $mt: ${c.startTicks}→${c.endTicks}');
        continue;
      }
      // 兼容 IntroSkipper 的 MarkerType
      if (mt == 'introstart' || nm == 'intro start' || nm.contains('片头开始')) {
        introStart = c.startTicks;
      }
      if (mt == 'introend' || nm == 'intro end' || nm == '片头结束') {
        introEnd = c.startTicks;
      }
      if (mt == 'creditsstart' || nm == 'credits start' || nm == '片尾开始') {
        creditsStart = c.startTicks;
      }
      // 中文名兜底
      if (nm.contains('片头') && introStart == null) introStart = c.startTicks;
      if (nm.contains('片尾') && creditsStart == null) {
        creditsStart = c.startTicks;
        creditsEnd = c.endTicks;
      }
    }
    // 合理性校验：片头必须在前 25%；片尾必须在后 50% 且晚于片头结束。
    // 异常位置直接丢弃对应标记，宁缺毋滥（避免乱跳过）。
    if (durTicks != null && durTicks > 0) {
      if (introStart != null && introEnd != null && introEnd > durTicks * 25 ~/ 100) {
        AppLog.w('Emby', 'IntroSkip chapters: intro 位置异常（${introEnd}ms > 前25%），丢弃 intro');
        introStart = null;
        introEnd = null;
      }
      if (creditsStart != null &&
          (creditsStart < durTicks ~/ 2 || (introEnd != null && creditsStart <= introEnd))) {
        AppLog.w('Emby', 'IntroSkip chapters: credits 位置异常（${creditsStart}ms），丢弃 credits');
        creditsStart = null;
        creditsEnd = null;
      }
    }
    if (introStart != null && introEnd != null && introEnd > introStart) {
      AppLog.i('Emby', 'IntroSkip via chapters: intro=$introStart→$introEnd, credits=$creditsStart→$creditsEnd');
      return IntroSkip(
        introStartTicks: introStart,
        introEndTicks: introEnd,
        creditsStartTicks: creditsStart,
        creditsEndTicks: creditsEnd,
      );
    }
    // 只有 credits 也返回（可能电影只有片尾）
    if (creditsStart != null) {
      AppLog.i('Emby', 'IntroSkip via chapters (credits only): $creditsStart→$creditsEnd');
      return IntroSkip(
        introStartTicks: 0,
        introEndTicks: 0,
        creditsStartTicks: creditsStart,
        creditsEndTicks: creditsEnd,
      );
    }
    AppLog.i('Emby', 'IntroSkip: 未检测到片头片尾信息 (itemId=$itemId, chapters=${ch.length})');
    return null;
  }

  /// 获取条目总时长（ticks），用于片头片尾位置合理性校验
  Future<int?> _getItemRunTimeTicks(String itemId) async {
    try {
      await _ensureUserId();
      final r = await dio.get('/Users/$userId/Items/$itemId', queryParameters: {'Fields': 'Chapters'});
      return (r.data['RunTimeTicks'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// 解析 IntroSkip 插件返回的时间戳数据（兼容多种字段名格式）
  IntroSkip? _parseIntroResponse(Map<String, dynamic> data) {
    int? introStart, introEnd, creditsStart;

    // Jellyfin IntroSkipper: IntroStart / IntroEnd (ticks)
    // Emby 插件变体: IntroStartTicks / IntroEndTicks
    introStart = (data['IntroStart'] as num?)?.toInt()
        ?? (data['IntroStartTicks'] as num?)?.toInt()
        ?? (data['intro_start'] as num?)?.toInt();
    introEnd = (data['IntroEnd'] as num?)?.toInt()
        ?? (data['IntroEndTicks'] as num?)?.toInt()
        ?? (data['intro_end'] as num?)?.toInt();

    // Credits
    creditsStart = (data['CreditsStart'] as num?)?.toInt()
        ?? (data['CreditsStartTicks'] as num?)?.toInt()
        ?? (data['credits_start'] as num?)?.toInt();

    if (introStart != null && introEnd != null && introEnd > introStart) {
      return IntroSkip(
        introStartTicks: introStart,
        introEndTicks: introEnd,
        creditsStartTicks: creditsStart,
      );
    }
    return null;
  }

  @override
  Future<List<MediaItem>> getSeasons(String seriesId) async {
    final cacheKey = seriesId;
    final cached = _seasonsCache[cacheKey];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cached.timestamp < _cacheDurationMs) {
      AppLog.d('Emby', 'getSeasons cache hit: $seriesId');
      return cached.seasons;
    }
    // 不吞错：HTTP 错误/网络错误向上抛出，让 UI 能区分"加载失败"与"无数据"
    await _ensureUserId();
    final r = await dio.get('/Shows/$seriesId/Seasons', queryParameters: {'UserId': userId, 'Fields': 'Overview'});
    _throwIfHttpError(r);
    final seasons = ((r.data['Items'] as List?) ?? []).map((i) => _parseItem({
      'Id': i['Id'] ?? '', 'Name': i['Name'] ?? '', 'Type': 'Season', 'IndexNumber': i['IndexNumber'],
      'ImageTags': {'Primary': i['ImageTags']?['Primary'] ?? ''}, 'Overview': i['Overview'],
    })).toList();
    // 只缓存非空结果，避免 401/网络错误返回的空列表被负缓存
    if (seasons.isNotEmpty) {
      _seasonsCache[cacheKey] = _CachedSeasons(seasons);
      AppLog.d('Emby', 'getSeasons cached: $seriesId (${seasons.length} seasons)');
    }
    return seasons;
  }

  @override
  Future<List<MediaItem>> getEpisodes(String seriesId, {String? seasonId, int? page, int limit = 50}) async {
    final cacheKey = '${seriesId}_${seasonId ?? ''}_$limit';
    final cached = _episodesCache[cacheKey];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cached.timestamp < _cacheDurationMs && page == null) {
      AppLog.d('Emby', 'getEpisodes cache hit: $cacheKey');
      return cached.episodes;
    }
    // 不吞错：HTTP 错误/网络错误向上抛出，让 UI 能区分"加载失败"与"无数据"
    await _ensureUserId();
    final params = <String, dynamic>{'UserId': userId, 'Fields': 'Overview,MediaSources', 'SortBy': 'SortName', 'Limit': limit};
    if (seasonId != null) params['SeasonId'] = seasonId;
    if (page != null) params['StartIndex'] = page * limit;
    final r = await dio.get('/Shows/$seriesId/Episodes', queryParameters: params);
    _throwIfHttpError(r);
    final episodes = _parseItems((r.data['Items'] as List?) ?? []);
    _sortEpisodes(episodes);
    // 只缓存非空结果，避免 401/网络错误返回的空列表被负缓存
    if (page == null && episodes.isNotEmpty) {
      _episodesCache[cacheKey] = _CachedEpisodes(episodes);
      AppLog.d('Emby', 'getEpisodes cached: $cacheKey (${episodes.length} episodes)');
    }
    return episodes;
  }

  /// 按 (季, 集) 稳定排序剧集列表。部分服务器的 SortName 缺失或乱序
  /// （例如把第13集排在最前），不排序会导致："第1集"卡片实际播放第13集、
  /// 自动连播/上一集下一集跳到随机集。
  void _sortEpisodes(List<MediaItem> episodes) {
    episodes.sort((a, b) {
      final sa = a.seasonNumber ?? 0, sb = b.seasonNumber ?? 0;
      if (sa != sb) return sa.compareTo(sb);
      return (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0);
    });
  }

  /// 将 HTTP 错误状态码转为异常抛出。
  /// 必要原因：FnOSService 子类设置了 validateStatus=(_)=>true 接受所有状态码，
  /// 401 等错误不会自动抛 DioException，需手动转换，上层 UI 才能感知"加载失败"。
  void _throwIfHttpError(Response r) {
    final status = r.statusCode ?? 0;
    if (status >= 400) {
      throw DioException(
        requestOptions: r.requestOptions,
        response: r,
        type: DioExceptionType.badResponse,
        message: 'HTTP $status',
      );
    }
  }

  List<MediaItem> _parseItems(List items) => items.map((i) => _parseItem(i)).toList();

  @override
  Future<List<MediaItem>> getResumeItems({int limit = 20}) async {
    try {
      await _ensureUserId();
      final r = await dio.get('/Users/$userId/Items/Resume', queryParameters: {
        'Limit': limit,
        'IncludeItemTypes': 'Movie,Episode',
        'Recursive': true,
        'EnableTotalRecordCount': false,
        'Fields': 'Overview,Genres,MediaSources,CommunityRating,ProviderIds,SeriesId,SeasonId,EpisodeNumber,UserData',
      });
      final items = (r.data['Items'] as List?) ?? [];
      AppLog.i('Emby', 'getResumeItems: ${items.length} items');
      for (final it in items) {
        AppLog.d('Emby', '  resume: ${it['Name']} (${it['Type']}, id=${it['Id']}, hasImage=${it['ImageTags']?['Primary'] != null})');
      }
      return _parseItems(items);
    } catch (e) { AppLog.e('Emby', 'getResumeItems FAILED: $e'); return []; }
  }

  MediaItem _parseItem(dynamic item) {
    final m = item is Map<String, dynamic> ? item : <String, dynamic>{};
    final mediaSources = (m['MediaSources'] as List?) ?? [];
    final firstSource = mediaSources.isNotEmpty ? mediaSources.first : null;
    final providerIds = m['ProviderIds'] as Map?;
    final tmdbIdStr = providerIds?['Tmdb']?.toString() ?? providerIds?['TMDB']?.toString();
    final tmdbId = tmdbIdStr != null ? int.tryParse(tmdbIdStr) : null;
    final userData = m['UserData'];
    final playbackTicks = userData?['PlaybackPositionTicks'];
    final runTimeTicks = m['RunTimeTicks'];
    double? watchProgress;
    if (playbackTicks != null && runTimeTicks != null && runTimeTicks > 0) {
      watchProgress = (playbackTicks / runTimeTicks).toDouble().clamp(0.0, 1.0);
    }
    return MediaItem(
      id: m['Id']?.toString() ?? '', title: m['Name'] ?? '',
      posterUrl: m['ImageTags']?['Primary'] != null ? '$baseUrl/Items/${m['Id']}/Images/Primary?api_key=$apiKey' : '',
      backdropUrl: m['BackdropImageTags']?.isNotEmpty == true ? '$baseUrl/Items/${m['Id']}/Images/Backdrop/0?api_key=$apiKey' : null,
      logoUrl: m['ImageTags']?['Logo'] != null ? '$baseUrl/Items/${m['Id']}/Images/Logo?api_key=$apiKey' : null,
      overview: m['Overview'], rating: (m['CommunityRating'] as num?)?.toDouble(),
      year: m['ProductionYear'], genres: (m['Genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: m['Type'] == 'Series' ? MediaType.series : m['Type'] == 'Episode' ? MediaType.episode : MediaType.movie,
      isBoxSet: m['Type'] == 'BoxSet',
      seasonNumber: m['ParentIndexNumber'] ?? m['SeasonNumber'],
      episodeNumber: m['IndexNumber'] ?? m['EpisodeNumber'],
      seriesTitle: m['SeriesName'],
      seriesId: m['SeriesId']?.toString(),
      duration: m['RunTimeTicks'] != null ? (m['RunTimeTicks'] / 10000000).toInt() : 0,
      imdbId: providerIds?['Imdb']?.toString(),
      tmdbId: tmdbId,
      isWatched: userData?['Played'] ?? false,
      isFavorite: userData?['IsFavorite'] ?? false,
      watchProgress: watchProgress,
      filePath: firstSource?['Path']?.toString(),
      director: _extractPeople(m, 'Director')?.firstOrNull,
      cast: _extractPeople(m, 'Actor'),
      videoTracks: _extractStreams(m, 'Video'),
      audioTracks: _extractStreams(m, 'Audio'),
      subtitleTracks: _extractStreams(m, 'Subtitle'),
      people: _extractPeopleFull(m)?.map((p) {
        if (p['PrimaryImageTag'] != null) {
          p['ImageUrl'] = _buildPersonImageUrl(p['Id'], p['PrimaryImageTag']);
        }
        return p;
      }).toList(),
    );
  }

  /// 构造人物图片 URL（子类可覆盖，如 FnOS 不支持此端点）
  String? _buildPersonImageUrl(String? id, String? imageTag) {
    if (id == null || id.isEmpty || imageTag == null || imageTag.isEmpty) return null;
    // Emby/Jellyfin 使用 /Items/{id}/Images/Primary（/Persons/ 端点返回 404）
    return '$baseUrl/Items/$id/Images/Primary?api_key=$apiKey&Tag=$imageTag';
  }

  List<String>? _extractPeople(Map m, String type) {
    final p = (m['People'] as List?)?.where((e) => e['Type'] == type).map((e) => e['Name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    return p != null && p.isNotEmpty ? p : null;
  }

  List<Map<String, dynamic>>? _extractPeopleFull(Map m) {
    final p = (m['People'] as List?)?.map((e) => {
      'Id': e['Id']?.toString() ?? '',
      'Name': e['Name']?.toString() ?? '',
      'Role': e['Role']?.toString() ?? e['Type']?.toString() ?? '',
      'Type': e['Type']?.toString() ?? '',
      'PrimaryImageTag': e['PrimaryImageTag']?.toString(),
    }).where((e) => (e['Name'] as String).isNotEmpty).toList();
    return p != null && p.isNotEmpty ? p : null;
  }

  List<Map<String, dynamic>>? _extractStreams(Map m, String type) {
    final s = (m['MediaSources'] as List?)?.firstOrNull;
    if (s == null) return null;
    final streams = (s['MediaStreams'] as List?)?.where((e) => e['Type'] == type).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    return streams != null && streams.isNotEmpty ? streams : null;
  }
}

class _CachedDetailItem {
  final MediaItem item;
  final int timestamp;
  _CachedDetailItem(this.item) : timestamp = DateTime.now().millisecondsSinceEpoch;
}

class _CachedSeasons {
  final List<MediaItem> seasons;
  final int timestamp;
  _CachedSeasons(this.seasons) : timestamp = DateTime.now().millisecondsSinceEpoch;
}

class _CachedEpisodes {
  final List<MediaItem> episodes;
  final int timestamp;
  _CachedEpisodes(this.episodes) : timestamp = DateTime.now().millisecondsSinceEpoch;
}

// ==================== JellyfinService ====================

class JellyfinService extends EmbyService {
  static const String _clientVersion = '0.136.0';
  static final int _deviceIdSeed = DateTime.now().millisecondsSinceEpoch;

  JellyfinService({required String baseUrl, String apiKey = '', String? userId, String? username, String? password, Dio? dioClient})
      : super(baseUrl: baseUrl, apiKey: apiKey, userId: userId, username: username, password: password, dioClient: dioClient) {
    // EmbyService 构造函数已设置 X-MediaBrowser-Token
    // 追加 X-Emby-Token（Jellyfin 专用），同时保留 X-MediaBrowser-Token（兼容 Emby 服务器）
    dio.options.headers['X-Emby-Token'] = apiKey;
    // 兜底：默认 query 参数带上 api_key，兼容仅接受 URL 参数认证的服务器
    dio.options.queryParameters['api_key'] = apiKey;
    // Jellyfin 12.0:legacy authorization 默认禁用 —— 客户端必须以标准
    // Authorization 头声明设备信息(格式:MediaBrowser Client=".." Device=".."
    // DeviceId=".." Version=".." Token="..")。Token 也并入此头。
    _applyAuthorizationHeader();
    AppLog.i('Jellyfin', 'init baseUrl=$baseUrl (X-Emby-Token + api_key + Authorization 设备声明)');
  }

  /// 组装 Jellyfin 规范的 Authorization 头(12.0 要求;Token 内联)。
  /// 登录前无 token 也发(设备声明),登录成功后带 Token 重发。
  String _authorizationHeader({String? token}) {
    final t = (token ?? apiKey).trim();
    final deviceId = 'LANPlayer_${_deviceIdSeed}';
    final h = 'MediaBrowser Client="LANPlayer", Device="LANPlayer", '
        'DeviceId="$deviceId", Version="${_clientVersion}"';
    return t.isEmpty ? h : '$h, Token="$t"';
  }

  void _applyAuthorizationHeader() {
    dio.options.headers['Authorization'] = _authorizationHeader();
  }

  @override
  Map<String, String> get streamHeaders => {'X-Emby-Token': apiKey, 'X-MediaBrowser-Token': apiKey};

  @override
  Map<String, String> get imageHeaders => apiKey.isNotEmpty
      ? {'X-Emby-Token': apiKey, 'X-MediaBrowser-Token': apiKey}
      : const {};

  @override
  Map<String, String> get authHeaders => apiKey.isNotEmpty
      ? {'X-Emby-Token': apiKey, 'X-MediaBrowser-Token': apiKey}
      : const {};

  /// 401 自愈：作废双头旧 token 和 api_key，强制重新登录。
  @override
  Future<bool> doReAuthenticate() async {
    if (_username == null || _username!.isEmpty) {
      return apiKey.isNotEmpty; // 无凭据无法重登
    }
    AppLog.i('Jellyfin', '作废旧 token，强制重新登录: $_username');
    apiKey = '';
    userId = null;
    _userIdLoaded = false;
    dio.options.headers.remove('X-MediaBrowser-Token');
    dio.options.headers.remove('X-Emby-Token');
    dio.options.queryParameters['api_key'] = '';
    return await loginByUsernamePassword();
  }

  /// 登录成功后同步更新 Jellyfin 专有的 X-Emby-Token 和 api_key 查询参数
  @override
  Future<bool> loginByUsernamePassword() async {
    final ok = await super.loginByUsernamePassword();
    if (ok) {
      // 同步更新 Jellyfin 专有头
      dio.options.headers['X-Emby-Token'] = apiKey;
      dio.options.queryParameters['api_key'] = apiKey;
    }
    return ok;
  }

  /// Trickplay 缩略图 URL（Jellyfin 10.9+ 专属特性）
  String getTrickplayTileUrl(String itemId, int sheetIndex, {int width = 320}) {
    final uid = userId ?? '';
    return '$baseUrl/Videos/$itemId/Trickplay/$width/$sheetIndex.jpg?api_key=$apiKey'
        '${uid.isNotEmpty ? '&UserId=$uid' : ''}';
  }

  /// 获取 Trickplay 元数据（缩略图间隔等信息）
  Future<TrickplayInfo?> getTrickplayInfo(String itemId) async {
    try {
      final r = await dio.get('/Videos/$itemId/Trickplay');
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map<String, dynamic>;
        final widthMap = data['320'] ?? data.values.firstOrNull;
        if (widthMap is Map) {
          return TrickplayInfo(
            intervalMs: (widthMap['Interval'] as num?)?.toInt() ?? 10000,
            tileWidth: (widthMap['TileWidth'] as num?)?.toInt() ?? 10,
            tileHeight: (widthMap['TileHeight'] as num?)?.toInt() ?? 10,
            thumbnailCount: (widthMap['ThumbnailCount'] as num?)?.toInt() ?? 100,
          );
        }
      }
    } catch (e) {
      // 服务器未生成 Trickplay 缩略图时返回 404，属正常降级，不刷 WARN；
      // 其它错误（网络/鉴权等）才需要告警
      if (e is DioException && e.response?.statusCode == 404) {
        AppLog.d('Jellyfin', 'Trickplay 未生成（服务器无缩略图），拖拽预览已降级');
      } else {
        AppLog.w('Jellyfin', 'getTrickplayInfo failed: $e');
      }
    }
    return null;
  }

  @override
  Future<String> _ensureUserId() async {
    if (_userIdLoaded && userId != null && userId!.isNotEmpty) return userId!;
    // 确保已认证（如果没有 apiKey 但有用户名密码，先自动登录）
    await _ensureAuth();
    try {
      final r = await dio.get('/Users');
      if (r.statusCode == 200 && r.data is List) {
        final users = r.data as List;
        if (users.isNotEmpty) {
          userId = users.first['Id']?.toString() ?? '';
          if (userId!.isNotEmpty) { _userIdLoaded = true; AppLog.i('Jellyfin', 'userId: $userId'); return userId!; }
        }
      }
    } catch (e) { AppLog.w('Jellyfin', '/Users failed: $e'); }
    _userIdLoaded = true;
    return userId ?? '';
  }
}

// ==================== FnOSService ====================
//
// 飞牛影视 (FnOS) 客户端实现
// 参考 FlyNarwhal 官方客户端（GitHub: fnOS/fly-narwhal）
// 使用飞牛专有 API：/v/api/v1/* + Authx 单层签名 + Cookie 会话
//
// 登录流程：
//   1. 检测中继模式（域名含 5ddd.com 或 fnos.net），构造 Cookie: mode=relay
//   2. POST /v/api/v1/login  body: {username, password, app_name: "trimemedia-web"}
//      响应：{code: 0, msg: ..., data: {token: ...}}，code==0 表示成功
//   3. 保存 Cookie: Trim-MC-token=<token>[; mode=relay]
//
// 后续请求：
//   - Authorization: <token>
//   - Cookie: Trim-MC-token=<token>[; mode=relay]
//   - Authx: nonce=<6位随机>&timestamp=<毫秒>&sign=<md5(apiKey_path_nonce_timestamp_dataJsonMd5_apiSecret)>
//   - User-Agent: Chrome UA
//
// 同时保留 Jellyfin 兼容模式：部分老版本飞牛部署支持 Jellyfin API，
// login() 先尝试 Jellyfin 认证，失败则回退到飞牛专有 API

class FnOSService extends EmbyService {
  // 飞牛专有 API 密钥（来自 FlyNarwhal app_constants.dart）
  static const String _fnosApiKey = 'NDzZTVxnRKP8Z0jXg1VAMonaG8akvh';
  static const String _fnosApiSecret = '16CCEB3D-AB42-077D-36A1-F355324E4237';
  static const String _fnosApiBase = '/v/api/v1';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36';

  final String? username;
  final String? password;
  String? _fnosToken;
  String? _cookie;
  bool _isRelayMode = false;
  bool _jellyfinMode = false;

  /// 缓存媒体库 ID → category 映射，供 getLibraryItems 决定 tags.type 过滤
  final Map<String, String> _libraryCategoryCache = {};

  /// play/info 的会话缓存（itemId → 会话）。
  ///
  /// 存在的理由是 `/play/record` 的 `media_guid` 是必填的：只带 item_guid 上报，
  /// 服务端不认这条进度。而 media_guid 只有 play/info 才给，播放期间每 10 秒
  /// 重打一次 play/info 太浪费，所以开播时拿一次、停播时清掉。
  ///
  /// 停播必须清：转码会话有时效，停掉之后 play_link 会 410 Gone（文档 §5）。
  final Map<String, _FnosPlaySession> _playSessions = {};

  /// tag/genres 的 ID → 名称映射（登录后拉一次，进程内缓存）。
  /// 飞牛的 item 只返回数字 ID（`genres:[5]`），不查这张表就没有类型标签。
  Map<int, String>? _genreNames;

  /// `/stream` 要求的 ip 字段是「任意指纹串」，同一台设备保持稳定即可。
  late final String _deviceFingerprint =
      'lanplayer-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  /// 当前是否运行在 Jellyfin 兼容模式
  bool get isJellyfinMode => _jellyfinMode;
  /// 公开 token 的只读访问
  String? get token => _jellyfinMode ? apiKey : _fnosToken;

  @override
  Map<String, String> get streamHeaders {
    if (_jellyfinMode) return {'X-Emby-Token': apiKey};
    final headers = <String, String>{};
    if (_fnosToken != null && _fnosToken!.isNotEmpty) {
      headers['Authorization'] = _fnosToken!;
    }
    if (_cookie != null && _cookie!.isNotEmpty) {
      headers['Cookie'] = _cookie!;
    }
    headers['User-Agent'] = _userAgent;
    return headers;
  }

  @override
  Map<String, String> get imageHeaders {
    if (_jellyfinMode) return const {};
    final headers = <String, String>{};
    if (_fnosToken != null && _fnosToken!.isNotEmpty) {
      headers['Authorization'] = _fnosToken!;
    }
    if (_cookie != null && _cookie!.isNotEmpty) {
      headers['Cookie'] = _cookie!;
    }
    headers['User-Agent'] = _userAgent;
    return headers;
  }

  @override
  Future<bool> ensureAuthenticated() async {
    if (_jellyfinMode) return apiKey.isNotEmpty;
    if (_fnosToken != null && _fnosToken!.isNotEmpty) return true;
    return await login();
  }

  /// 飞牛不走 Emby 的 apiKey 字段（构造时传空），基类实现恒为 false，
  /// HealthCheck 因此每分钟误报未认证并空转 ensureAuth —— 按飞牛真实
  /// 凭证状态覆写。
  @override
  bool get isCurrentlyAuthenticated =>
      _jellyfinMode ? apiKey.isNotEmpty : (_fnosToken != null && _fnosToken!.isNotEmpty);

  /// FnOS 不支持 /Persons/{id}/Images/Primary 端点（返回 500），跳过构造
  @override
  String? _buildPersonImageUrl(String? id, String? imageTag) => null;

  @override
  Map<String, String> get authHeaders {
    if (_jellyfinMode) {
      return apiKey.isNotEmpty ? {'X-Emby-Token': apiKey} : const {};
    }
    final h = <String, String>{};
    if (_fnosToken != null && _fnosToken!.isNotEmpty) h['Authorization'] = _fnosToken!;
    if (_cookie != null && _cookie!.isNotEmpty) h['Cookie'] = _cookie!;
    return h;
  }

  /// 401 自愈：作废所有旧 token，强制重新登录（先 Jellyfin 兼容、后飞牛专有）。
  @override
  Future<bool> doReAuthenticate() async {
    if (username == null || username!.isEmpty) {
      return (_jellyfinMode && apiKey.isNotEmpty) || (_fnosToken?.isNotEmpty == true);
    }
    AppLog.i('FnOS', '作废旧 token，强制重新登录: $username');
    _fnosToken = null;
    _cookie = null;
    _jellyfinMode = false;
    apiKey = '';
    userId = null;
    _userIdLoaded = false;
    dio.options.headers.remove('X-Emby-Token');
    return await login();
  }

  FnOSService({required String baseUrl, this.username, this.password, Dio? dioClient})
      : super(baseUrl: baseUrl, apiKey: '', dioClient: dioClient) {
    // 接受所有状态码，便于读取非 200 响应体进行调试
    dio.options.validateStatus = (_) => true;
    // 清除 EmbyService 构造函数设置的空 token 头
    dio.options.headers.remove('X-MediaBrowser-Token');
    // 检测中继模式
    _isRelayMode = _detectRelayMode(baseUrl);
  }

  /// 中继模式检测：域名包含 5ddd.com 或 fnos.net
  static bool _detectRelayMode(String baseUrl) {
    try {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null) return false;
      final host = uri.host.toLowerCase();
      return host.contains('5ddd.com') || host.contains('fnos.net');
    } catch (_) {
      return false;
    }
  }

  // ==================== 登录 ====================

  @override
  Future<bool> login() {
    // 单飞互斥：并发调用共享同一次登录（冷启动时健康检查/媒体库/下拉
    // 刷新会同时发现未认证）。旧实现没有互斥，后来者撞上「登录冷却中」
    // 直接拿到 false —— 真机日志 2026-09-06 实证，每次冷启动必现。
    _loginFuture ??= _doLogin().whenComplete(() => _loginFuture = null);
    return _loginFuture!;
  }

  Future<bool>? _loginFuture;

  Future<bool> _doLogin() async {
    if (username == null || password == null) return false;
    if (isInLoginCooldown) {
      AppLog.w('FnOS', '登录冷却中，跳过: $username');
      return false;
    }
    // ── 第一步：飞牛专有 API 登录（优先，支持 tags.type 过滤等原生能力）──
    if (await _tryFnOSLogin()) {
      recordLoginSuccess();
      return true;
    }
    // ── 第二步：尝试 Jellyfin 兼容认证（部分飞牛版本仅支持此模式）──
    final ok = await _tryJellyfinLogin();
    if (ok) {
      recordLoginSuccess();
    } else {
      recordLoginFailure();
    }
    return ok;
  }

  /// Jellyfin 兼容登录：POST /Users/AuthenticateByName
  Future<bool> _tryJellyfinLogin() async {
    AppLog.i('FnOS', '尝试 Jellyfin 兼容认证...');
    try {
      final deviceId = 'LANPlayer_${DateTime.now().millisecondsSinceEpoch}';
      final authHeader = 'MediaBrowser Client="FnOSPlayer", Device="LANPlayer", '
          'DeviceId="$deviceId", Version="1.0.0"';
      final response = await dio.post(
        '$baseUrl/Users/AuthenticateByName',
        data: {'Username': username, 'Pw': password},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        }, extra: {'_isLoginRequest': true}),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300 && response.data is Map) {
        final data = response.data as Map;
        final accessToken = data['AccessToken']?.toString()
            ?? (data['User'] as Map?)?['AccessToken']?.toString();
        final userIdStr = (data['User'] as Map?)?['Id']?.toString()
            ?? data['User']?['Id']?.toString();

        if (accessToken != null && accessToken.isNotEmpty) {
          _jellyfinMode = true;
          apiKey = accessToken;
          userId = userIdStr;

          dio.options.headers['X-Emby-Token'] = apiKey;
          dio.options.headers.remove('X-MediaBrowser-Token');

          if (userId == null || userId!.isEmpty) {
            try {
              final usersRes = await dio.get('$baseUrl/Users');
              if (usersRes.statusCode == 200 && usersRes.data is List) {
                final users = usersRes.data as List;
                if (users.isNotEmpty) {
                  userId = users.first['Id']?.toString() ?? '';
                }
              }
            } catch (_) {}
          }

          AppLog.i('FnOS', 'Jellyfin 兼容登录成功: userId=$userId');
          return true;
        }
      }

      AppLog.w('FnOS', 'Jellyfin 认证失败: HTTP $statusCode, body=${response.data}');
    } catch (e) {
      AppLog.w('FnOS', 'Jellyfin 认证异常: $e');
    }
    return false;
  }

  /// 飞牛专有 API 登录：POST /v/api/v1/login
  /// 参考 FlyNarwhal login_view_model.dart
  Future<bool> _tryFnOSLogin() async {
    AppLog.i('FnOS', '尝试飞牛专有 API 登录: ${_isRelayMode ? "relay" : "direct"} mode');
    const loginPath = '/v/api/v1/login';
    final url = '$baseUrl$loginPath';

    try {
      final requestData = {
        'username': username,
        'password': password,
        'app_name': 'trimemedia-web',
      };
      // Authx 签名使用完整路径（与 FlyNarwhal 一致，路径 = 请求的 URL path）
      final authx = _generateAuthx(loginPath, data: requestData);
      final response = await dio.post(
        url,
        data: requestData,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': _userAgent,
          'Authx': authx,
        }, extra: {'_isLoginRequest': true}),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        AppLog.w('FnOS', 'HTTP $statusCode $url, body=${response.data}');
        return false;
      }

      final res = response.data;
      if (res is! Map) {
        AppLog.w('FnOS', '响应不是 JSON Map: ${res.runtimeType}');
        return false;
      }

      // 飞牛响应格式：{code, msg, data}
      final code = res['code'];
      final msg = res['msg']?.toString() ?? '';
      if (code != 0) {
        AppLog.w('FnOS', '登录失败: code=$code msg=$msg');
        return false;
      }

      final dataMap = res['data'];
      if (dataMap is! Map) {
        AppLog.w('FnOS', '响应 data 字段缺失或非 Map');
        return false;
      }
      final token = dataMap['token']?.toString();
      if (token == null || token.isEmpty) {
        AppLog.w('FnOS', 'token 为空');
        return false;
      }

      _fnosToken = token;
      _jellyfinMode = false;
      // 构造 Cookie，中继模式追加 mode=relay
      _cookie = _isRelayMode
          ? 'Trim-MC-token=$token; mode=relay'
          : 'Trim-MC-token=$token';

      AppLog.i('FnOS', '飞牛 API 登录成功: tokenLen=${token.length} relay=$_isRelayMode');
      return true;
    } catch (e) {
      AppLog.w('FnOS', '登录异常 $url: $e');
      return false;
    }
  }

  // ==================== 认证保障 ====================

  @override
  Future<bool> _ensureAuth() async {
    if (_jellyfinMode) return apiKey.isNotEmpty;
    if (_fnosToken != null && _fnosToken!.isNotEmpty) return true;
    return await login();
  }

  // ==================== 连接测试 ====================

  @override
  Future<bool> testConnection() async {
    try {
      if (_jellyfinMode && apiKey.isNotEmpty) {
        // Jellyfin 模式：使用标准 /System/Info
        dio.options.validateStatus = (s) => s != null && s < 500;
        final r = await dio.get('$baseUrl/System/Info');
        return r.statusCode == 200;
      }
      // 飞牛专有模式：尝试登录后调用 /mediadb/list
      if (!await _ensureAuth()) return false;
      final res = await _fnosGet('/mediadb/list');
      return res != null;
    } catch (e) {
      AppLog.w('FnOS', 'testConnection failed: $e');
      return false;
    }
  }

  // ==================== 媒体库操作（双模式路由）====================

  @override
  Future<List<MediaItem>> getLibraries() async {
    if (_jellyfinMode) return super.getLibraries();
    await _ensureAuth();
    try {
      // GET /v/api/v1/mediadb/list
      // FlyNarwhal MediaDbListResponse: {guid, title, posters[], category, view_type}
      final res = await _fnosGet('/mediadb/list');
      if (res == null) return [];
      final list = _extractList(res);
      _libraryCategoryCache.clear();
      return list.map((c) {
        final m = c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{};
        final guid = m['guid']?.toString() ?? '';
        final name = m['title']?.toString() ?? '';
        final poster = _firstImagePath(m['posters'] ?? m['poster']);
        final category = m['category']?.toString().toLowerCase() ?? '';
        final viewType = m['view_type'];
        _libraryCategoryCache[guid] = category;
        final type = category.contains('tv') || category.contains('series') || viewType == 1
            ? MediaType.series
            : MediaType.movie;
        return MediaItem(
          id: guid,
          title: name,
          posterUrl: _resolveImageUrl(poster, width: 500),
          type: type,
        );
      }).toList();
    } catch (e) {
      AppLog.w('FnOS', 'getLibraries failed: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getLibraryItems(String libraryId, {int page = 0, int limit = 50, bool includeBoxSets = false}) async {
    if (_jellyfinMode) return super.getLibraryItems(libraryId, page: page, limit: limit, includeBoxSets: includeBoxSets);
    await _ensureAuth();
    await _ensureGenres();
    try {
      // 根据媒体库 category 决定 tags.type 过滤，避免返回 Season/Episode 子条目
      final category = _libraryCategoryCache[libraryId] ?? '';
      final typeFilter = category.contains('tv') || category.contains('series')
          ? ['TV']
          : category.contains('movie')
              ? ['Movie']
              : ['TV', 'Movie']; // Mix 或未知类型：排除 Season/Episode

      // 分页获取全部条目（每页 200，循环直到取完）
      const pageSize = 200;
      var currentPage = 1;
      final allItems = <MediaItem>[];
      while (true) {
        final requestData = {
          if (libraryId.isNotEmpty) 'ancestor_guid': libraryId,
          'exclude_grouped_video': 1,
          'sort_type': 'DESC',
          'sort_column': 'create_time',
          'page_size': pageSize,
          'page': currentPage,
          'tags': {
            'type': typeFilter,
          },
        };
        final res = await _fnosPost('/item/list', requestData);
        if (res == null) break;
        final list = _extractList(res);
        if (list.isEmpty) break;
        allItems.addAll(_fnosParseItems(list));
        // 如果返回数量不足一页，说明已到最后一页
        if (list.length < pageSize) break;
        currentPage++;
      }
      return allItems;
    } catch (e) {
      AppLog.w('FnOS', 'getLibraryItems failed: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getAllLibraryItems(String libraryId, {bool includeBoxSets = false}) async {
    // FnOS 的 getLibraryItems 内部已按页取全量且忽略 page/limit 参数，
    // 直接返回即可；若用父类循环分页会对同一批数据重复追加。
    return getLibraryItems(libraryId, includeBoxSets: includeBoxSets);
  }

  @override
  Future<MediaItem> getItemDetails(String itemId) async {
    if (_jellyfinMode) return super.getItemDetails(itemId);
    await _ensureAuth();
    await _ensureGenres();
    // GET /v/api/v1/item/{guid}
    final res = await _fnosGet('/item/$itemId');
    if (res == null) return _fnosParseItem(<String, dynamic>{}, itemId);
    final raw = Map<String, dynamic>.from(res);

    // Series/Season 本身没有媒体文件，别去打 play/info（必然拿不到 media_guid）
    final type = raw['type']?.toString() ?? '';
    final isPlayable = type != 'TV' && type != 'Series' && type != 'Season';

    // 演员和轨道都是纯补充：并发取，任何一个失败都不影响详情页正常显示
    final extras = await Future.wait([
      _personList(itemId),
      isPlayable ? _fetchTracks(itemId) : Future<Map<String, dynamic>?>.value(null),
    ]);
    final people = extras[0] as List?;
    final tracks = extras[1] as Map<String, dynamic>?;
    if (people != null && people.isNotEmpty) raw['people'] = people;
    if (tracks != null) raw.addAll(tracks);

    return _fnosParseItem(raw, itemId);
  }

  /// 演员：`POST /person/list/{guid}`，body 传 `{}`。
  /// ⚠︎ 必须是 POST —— GET 返回 501（文档 §4.7）。
  ///
  /// ⚠︎ 剧集要传**季** guid。实测（还魂）剧集 guid 和单集 guid 都返回 0 条，
  /// 只有季 guid 有数据 —— 飞牛自己的 Web 端也是这个行为：剧集根页面没有
  /// 「演职人员」区，点进某一季才有。UI 侧走 [getPeopleFor]。
  Future<List?> _personList(String guid) async {
    try {
      final res = await _fnosPost('/person/list/$guid', const <String, dynamic>{});
      if (res == null) {
        AppLog.w('FnOS', 'person/list/$guid 无响应');
        return null;
      }
      final list = _extractList(res);
      AppLog.i('FnOS', 'person/list/$guid → ${list.length} 条');
      return list.isEmpty ? null : list;
    } catch (e) {
      AppLog.w('FnOS', 'person/list failed: $e');
      return null;
    }
  }

  /// UI 在拿到剧集列表后，用某一集的 guid 补查演员（剧集级查不到）。
  @override
  Future<List<Map<String, dynamic>>?> getPeopleFor(String itemId) async {
    if (_jellyfinMode) return null;
    await _ensureAuth();
    final list = await _personList(itemId);
    if (list == null) return null;
    final people = _fnosExtractPeople({'people': list});
    AppLog.i('FnOS', 'getPeopleFor($itemId) → ${people?.length ?? 0} 人');
    return people;
  }

  /// 轨道 + 画质：play/info 拿 media_guid → `POST /stream`。
  /// 返回的键会并进 item 原始 map，由 _fnosParseItem 填到 MediaItem 上。
  Future<Map<String, dynamic>?> _fetchTracks(String itemId) async {
    try {
      final s = await _ensurePlaySession(itemId);
      if (s == null || s.mediaGuid.isEmpty) return null;
      final res = await _fetchStreamInfo(s.mediaGuid);
      if (res == null) return null;
      final video = res['video_stream'];
      return <String, dynamic>{
        '_video_tracks':
            video is List ? video : (video is Map ? [video] : const []),
        '_audio_tracks': res['audio_streams'] is List ? res['audio_streams'] : const [],
        '_subtitle_tracks':
            res['subtitle_streams'] is List ? res['subtitle_streams'] : const [],
      };
    } catch (e) {
      AppLog.w('FnOS', 'stream failed: $e');
      return null;
    }
  }

  @override
  Future<String> getStreamUrl(String itemId, {String? quality, bool burnInSubtitle = false, int? subtitleIndex}) async {
    if (_jellyfinMode) return super.getStreamUrl(itemId, quality: quality, burnInSubtitle: burnInSubtitle, subtitleIndex: subtitleIndex);
    await _ensureAuth();
    final session = await _ensurePlaySession(itemId);
    if (session == null) {
      throw Exception('飞牛 play/info 无响应，无法获取播放地址');
    }

    // ① 直播频道：live_channels[].path 是外部可播直链，不经过 NAS（文档 §4.13）
    if (session.isLive) {
      final live = session.liveUrl;
      if (live != null && live.isNotEmpty) {
        AppLog.i('FnOS', 'streamUrl (live · ${session.liveName ?? "线路1"}): $live');
        return live;
      }
      throw Exception('飞牛直播频道没有可用线路');
    }

    // ② 原画直连：media/range 完整支持 HTTP Range，免签名但要带 Authorization。
    //    ExoPlayer 能解就一直走这条，不主动转码。
    if (session.mediaGuid.isNotEmpty) {
      final url = '$baseUrl$_fnosApiBase/media/range/${session.mediaGuid}';
      AppLog.i('FnOS', 'streamUrl (media/range): $url');
      return url;
    }

    // ③ 兜底：file_stream.file（部分固件直接给路径）
    final file = session.fileStreamPath;
    if (file != null && file.isNotEmpty) {
      final url = file.startsWith('http') ? file : '$baseUrl$file';
      AppLog.i('FnOS', 'streamUrl (file_stream): $url');
      return url;
    }
    throw Exception('飞牛 play/info 未返回 media_guid，无法播放');
  }

  /// HLS 转码兜底：仅当直连的编码播不了时调用（如某些杜比视界）。
  ///
  /// **每次播放都必须重新调一遍**：转码会话有时效，停播之后 play_link 会 410 Gone
  /// （文档 §5），所以这里刻意不缓存返回值。
  Future<String?> getTranscodeUrl(String itemId) async {
    if (_jellyfinMode) return null;
    await _ensureAuth();
    final s = await _ensurePlaySession(itemId);
    if (s == null || s.mediaGuid.isEmpty) return null;
    final res = await _fnosPost('/play/play', {
      'item_guid': itemId,
      'media_guid': s.mediaGuid,
      'video_guid': s.videoGuid,
      'audio_guid': s.audioGuid,
      'ts': 0,
    });
    final link = res?['play_link']?.toString();
    if (link == null || link.isEmpty) {
      AppLog.w('FnOS', 'play/play 未返回 play_link');
      return null;
    }
    final url = link.startsWith('http') ? link : '$baseUrl$link';
    AppLog.i('FnOS', 'transcodeUrl (HLS): $url');
    return url;
  }

  Future<String> getDirectStreamUrl(String itemId) async => getStreamUrl(itemId);

  @override
  Future<List<MediaItem>> search(String query) async {
    if (_jellyfinMode) return super.search(query);
    await _ensureAuth();
    try {
      // GET /v/api/v1/search/list?q=<query>
      // 使用 queryParameters 让 dio 正确处理 query string，
      // 同时 Authx 签名也会基于排序后的 query 生成
      final res = await _fnosGet('/search/list', query: {'q': query});
      if (res == null) return [];
      final list = _extractList(res);
      return _fnosParseItems(list);
    } catch (e) {
      AppLog.w('FnOS', 'search failed: $e');
      return [];
    }
  }

  @override
  Future<void> markWatched(String itemId, {double? progress, int? positionMs}) async {
    if (_jellyfinMode) return super.markWatched(itemId, progress: progress, positionMs: positionMs);
    await _ensureAuth();
    try {
      if (positionMs != null) {
        await _recordProgress(itemId, positionMs ~/ 1000);
        return;
      }
      // 标记已看：POST /v/api/v1/item/watched  body: {item_guid}
      await _fnosPost('/item/watched', {'item_guid': itemId});
    } catch (e) {
      AppLog.w('FnOS', 'markWatched failed: $e');
    }
  }

  @override
  Future<void> markUnwatched(String itemId) async {
    if (_jellyfinMode) return super.markUnwatched(itemId);
    await _ensureAuth();
    try {
      // item/unwatched 不在逆向文档的端点清单里（文档只列了 item/watched），
      // 所以先按原路径试，失败再退到 DELETE item/watched —— 两条都不通时
      // 至少日志里能看出是哪一步断的，而不是静默失败。
      final res = await _fnosPost('/item/unwatched', {'item_guid': itemId});
      if (res != null) return;
      AppLog.w('FnOS', 'item/unwatched 无响应，改试 DELETE item/watched');
      await _fnosRequest('/item/watched', data: {'item_guid': itemId}, method: 'DELETE');
    } catch (e) {
      AppLog.w('FnOS', 'markUnwatched failed: $e');
    }
  }

  // 进度上报必须覆写：FnOSService 继承 EmbyService，不覆写就会去打
  // /Sessions/Playing{,/Progress,/Stopped} —— 飞牛没有这三条路由，
  // 于是播放期间每 10 秒的心跳和退出时的收尾上报全部 404，
  // /play/record 一次都写不到，官方 App 的「继续观看」里也就永远不出现。
  @override
  Future<void> reportPlaybackStart(String itemId, {String? mediaSourceId}) async {
    if (_jellyfinMode) return super.reportPlaybackStart(itemId, mediaSourceId: mediaSourceId);
    await _ensureAuth();
    // 开播时预热会话，后续每次心跳就不用再打一遍 play/info
    await _ensurePlaySession(itemId);
  }

  @override
  Future<void> reportPlaybackProgress(String itemId, int positionMs,
      {bool isPlaying = true, String? mediaSourceId}) async {
    if (_jellyfinMode) {
      return super.reportPlaybackProgress(itemId, positionMs,
          isPlaying: isPlaying, mediaSourceId: mediaSourceId);
    }
    await _ensureAuth();
    try {
      await _recordProgress(itemId, positionMs ~/ 1000);
    } catch (e) {
      AppLog.w('FnOS', 'reportPlaybackProgress failed: $e');
    }
  }

  @override
  Future<void> reportPlaybackStopped(String itemId,
      {int? positionMs, String? mediaSourceId}) async {
    if (_jellyfinMode) {
      return super.reportPlaybackStopped(itemId,
          positionMs: positionMs, mediaSourceId: mediaSourceId);
    }
    await _ensureAuth();
    try {
      if (positionMs != null && positionMs > 0) {
        await _recordProgress(itemId, positionMs ~/ 1000);
      }
    } catch (e) {
      AppLog.w('FnOS', 'reportPlaybackStopped failed: $e');
    } finally {
      // 会话作废：转码会话停播后 play_link 会 410，下次播放必须重新 play/play
      _playSessions.remove(itemId);
    }
  }

  @override
  Future<void> markFavorite(String itemId) async {
    if (_jellyfinMode) return super.markFavorite(itemId);
    await _ensureAuth();
    try {
      // PUT /v/api/v1/item/favorite  body: {item_guid}
      await _fnosRequest('/item/favorite', data: {'item_guid': itemId}, method: 'PUT');
    } catch (e) {
      AppLog.w('FnOS', 'markFavorite failed: $e');
    }
  }

  @override
  Future<void> unmarkFavorite(String itemId) async {
    if (_jellyfinMode) return super.unmarkFavorite(itemId);
    await _ensureAuth();
    try {
      // DELETE /v/api/v1/item/favorite  body: {item_guid}
      await _fnosRequest('/item/favorite', data: {'item_guid': itemId}, method: 'DELETE');
    } catch (e) {
      AppLog.w('FnOS', 'unmarkFavorite failed: $e');
    }
  }

  @override
  Future<List<ChapterMarker>> getChapters(String itemId) async {
    if (_jellyfinMode) return super.getChapters(itemId);
    return [];
  }

  @override
  Future<IntroSkip?> getIntroSkipInfo(String itemId) async {
    if (_jellyfinMode) return super.getIntroSkipInfo(itemId);
    return null;
  }

  @override
  Future<List<MediaItem>> getSeasons(String seriesId) async {
    if (_jellyfinMode) return super.getSeasons(seriesId);
    // 走父类现成的缓存：原来这个覆写完全绕过了 _seasonsCache，一次剧集详情页
    // 会把 season/list 拉两遍（详情页自己一次、演员兜底一次）。
    final cached = _seasonsCache[seriesId];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cached.timestamp < EmbyService._cacheDurationMs) {
      AppLog.d('FnOS', 'getSeasons cache hit: $seriesId');
      return cached.seasons;
    }
    await _ensureAuth();
    // GET /v/api/v1/season/list/{guid}
    // _fnosGet 返回 null 即请求失败 —— 不再直接抛：先走下面的「季当容器」
    // 兜底，兜底也拿不到集才向上抛错让 UI 感知（不吞错成 []）
    final res = await _fnosGet('/season/list/$seriesId');
    final list = res == null ? <dynamic>[] : _extractList(res);
    final seasons = list.map((s) {
      final m = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
      final guid = m['guid']?.toString() ?? '';
      final seasonNumber = (m['season_number'] as num?)?.toInt() ?? 1;
      return MediaItem(
        id: guid,
        title: m['title']?.toString() ?? '第$seasonNumber季',
        posterUrl: _resolveImageUrl(m['poster'] ?? m['posters'], width: 500),
        type: MediaType.series,
        seasonNumber: seasonNumber,
        overview: m['overview']?.toString(),
        seriesTitle: m['tv_title']?.toString() ?? m['parent_title']?.toString(),
        totalEpisodes: (m['number_of_episodes'] as num?)?.toInt(),
      );
    }).toList();

    // 「季当容器」兜底：继续观看链路把季 guid 当 seriesId 推进详情页，
    // season/list 对季 guid 不返回季列表 —— 此时用 episode/list/{guid}
    // （季 guid 已验证可用，详情页选集一直走的它）拉全集合成单季，
    // 让选季/选集照常工作。飞牛的容器单位就是季：person/list 也只有
    // 季 guid 才有演员（docs/fnos-api-gap.md 实证）。
    if (seasons.isEmpty) {
      try {
        final episodes = await getEpisodes(seriesId);
        if (episodes.isNotEmpty) {
          final sn = episodes.first.seasonNumber ?? 1;
          final synthesized = [
            MediaItem(
              id: seriesId,
              title: '第$sn季',
              posterUrl: episodes.first.posterUrl,
              type: MediaType.series,
              seasonNumber: sn,
              totalEpisodes: episodes.length,
            ),
          ];
          _seasonsCache[seriesId] = _CachedSeasons(synthesized);
          AppLog.i('FnOS', 'getSeasons: $seriesId 非剧集 guid,以 episode/list 合成单季(${episodes.length}集)');
          return synthesized;
        }
      } catch (_) {}
      if (res == null) {
        throw Exception('FnOS getSeasons failed for $seriesId');
      }
    }
    // 只缓存非空结果，避免把失败的空列表负缓存住
    if (seasons.isNotEmpty) _seasonsCache[seriesId] = _CachedSeasons(seasons);
    return seasons;
  }

  @override
  Future<List<MediaItem>> getEpisodes(String seriesId, {String? seasonId, int? page, int limit = 50}) async {
    if (_jellyfinMode) return super.getEpisodes(seriesId, seasonId: seasonId, page: page, limit: limit);
    final targetGuid = seasonId ?? seriesId;
    // 同 getSeasons：接上父类缓存，别让 episode/list 一次详情页拉两遍
    final cached = _episodesCache[targetGuid];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cached.timestamp < EmbyService._cacheDurationMs) {
      AppLog.d('FnOS', 'getEpisodes cache hit: $targetGuid');
      return cached.episodes;
    }
    await _ensureAuth();
    // GET /v/api/v1/episode/list/{guid}；seasonId 优先，否则用 seriesId
    // _fnosGet 返回 null 即请求失败，向上抛错让 UI 感知（不吞错成 []）
    final res = await _fnosGet('/episode/list/$targetGuid');
    if (res == null) {
      throw Exception('FnOS getEpisodes failed for $targetGuid');
    }
    final list = _extractList(res);
    final items = _fnosParseItems(list);
    _sortEpisodes(items);
    if (items.isNotEmpty) _episodesCache[targetGuid] = _CachedEpisodes(items);
    return items;
  }

  @override
  Future<List<MediaItem>> getResumeItems({int limit = 20}) async {
    if (_jellyfinMode) return super.getResumeItems(limit: limit);
    await _ensureAuth();
    await _ensureGenres();
    try {
      // GET /v/api/v1/play/list  返回最近观看列表（每条带 ts = 已看秒数）
      final res = await _fnosGet('/play/list');
      if (res == null) return [];
      final list = _extractList(res);
      final items = _fnosParseItems(list);
      return items.take(limit).toList();
    } catch (e) {
      AppLog.w('FnOS', 'getResumeItems failed: $e');
      return [];
    }
  }

  // ==================== 播放会话 / 进度 ====================

  /// 拿一次 `POST /play/info` 并缓存。
  ///
  /// 返回的 media_guid 是后面两件事的前提：`/play/record` 上报进度、
  /// `POST /stream` 查轨道和画质。
  Future<_FnosPlaySession?> _ensurePlaySession(String itemId) async {
    final cached = _playSessions[itemId];
    if (cached != null) return cached;
    final res = await _fnosPost('/play/info', {'item_guid': itemId});
    if (res == null) return null;
    final session = _FnosPlaySession.fromJson(res);
    // 直播频道没有 media_guid，但 live_channels 有直链，照样要缓存
    if (session.mediaGuid.isEmpty && !session.isLive) return null;
    _playSessions[itemId] = session;
    return session;
  }

  /// 上报播放进度：`POST /play/record`（免签名路径，但仍需 Authorization）。
  ///
  /// 传假 guid 服务端返回 -5，不产生脏数据，所以拿不到会话时也可以照发。
  Future<void> _recordProgress(String itemId, int tsSeconds) async {
    final s = await _ensurePlaySession(itemId);
    await _fnosPost('/play/record', {
      'item_guid': itemId,
      'media_guid': s?.mediaGuid ?? '',
      'video_guid': s?.videoGuid ?? '',
      'audio_guid': s?.audioGuid ?? '',
      'subtitle_guid': s?.subtitleGuid ?? '',
      'resolution': '',
      'bitrate': 0,
      'ts': tsSeconds,
      'duration': s?.durationSec ?? 0,
      'play_link': '',
      'device_id': 'LANPlayer',
      'direct_link_audio_index': 0,
      'lan': 'original',
      'device_name': 'LANPlayer',
    });
  }

  // ==================== 飞牛专有 API 工具方法 ====================

  /// `POST /stream` —— 轨道信息 + 画质清单。
  /// body 里的 ip 是「任意指纹串」，header 要带一个 UA 数组（文档 §4.11）。
  Future<Map<String, dynamic>?> _fetchStreamInfo(String mediaGuid) {
    return _fnosPost('/stream', {
      'media_guid': mediaGuid,
      'ip': _deviceFingerprint,
      'header': {
        'User-Agent': [_userAgent]
      },
      'level': null,
    });
  }

  /// 拉一次 tag/genres 建 ID → 名称映射。
  /// 返回的是数组，_fnosRequest 会包成 {list: [...]}。
  Future<void> _ensureGenres() async {
    if (_genreNames != null) return;
    final res = await _fnosGet('/tag/genres', query: {'lan': 'zh-CN'});
    final map = <int, String>{};
    final list = res == null ? const [] : _extractList(res);
    for (final e in list) {
      if (e is! Map) continue;
      final id = (e['id'] as num?)?.toInt();
      final value = e['value']?.toString() ?? '';
      if (id != null && value.isNotEmpty) map[id] = value;
    }
    // 失败也要落一个空表，否则每次解析都会重试一遍拖慢列表
    _genreNames = map;
    if (map.isEmpty) AppLog.w('FnOS', 'tag/genres 为空，类型标签将不显示');
  }

  /// 数字 genre ID → 中文名。取不到映射的 ID 直接丢掉，不显示裸数字。
  List<String> _mapGenres(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];
    final names = _genreNames;
    final out = <String>[];
    for (final g in raw) {
      if (g is num) {
        final n = names?[g.toInt()];
        if (n != null && n.isNotEmpty) out.add(n);
      } else if (g is String && g.isNotEmpty) {
        out.add(g);                       // 有些固件直接给名字
      } else if (g is Map) {
        final v = g['value']?.toString() ?? g['name']?.toString() ?? '';
        if (v.isNotEmpty) out.add(v);
      }
    }
    return out;
  }

  /// 从响应中提取 list（兼容多种字段名）
  List _extractList(Map<String, dynamic> res) {
    final list = res['list'];
    if (list is List) return list;
    final items = res['items'];
    if (items is List) return items;
    final data = res['data'];
    if (data is List) return data;
    return const [];
  }

  /// 解析图片 URL：相对路径拼接飞牛图片服务基路径
  /// 飞牛图片服务端点为 {baseUrl}/v/api/v1/sys/img{path}，可选 ?w={width} 服务端缩放。
  /// 注意：该端点需要 Authorization 头（见 imageHeaders），裸 URL 会返回 "Auth Failed"。
  String _resolveImageUrl(dynamic url, {int width = 0}) {
    final path = _firstImagePath(url);
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = '$baseUrl$_fnosApiBase/sys/img';
    return width > 0 ? '$base$normalized?w=$width' : '$base$normalized';
  }

  /// 从可能为 String 或 List 的字段中取出单个图片路径。
  /// item/list、season/list、episode/list 返回 poster（单个字符串）；
  /// item/{guid} 详情返回 posters/backdrops（字段名为复数但通常仍是单个字符串，偶尔为数组）。
  String _firstImagePath(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is List) {
      for (final e in v) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
      return '';
    }
    return v.toString().trim();
  }

  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// 生成 Authx 头值（参考 FlyNarwhalAuthHelper.generateAuthx）
  /// 算法：MD5(apiKey_path_nonce_timestamp_dataJsonMd5_apiSecret)
  /// 其中 dataJsonMd5 = MD5(jsonEncode(data)) 或 MD5(sortedQuery) 或 MD5("")
  String _generateAuthx(String path, {Map<String, dynamic>? queryParameters, dynamic data}) {
    // nonce: 6 位随机数字（100000~999999）
    final random = DateTime.now().microsecond;
    final nonce = (100000 + random % 900000).toString();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    String dataJsonMd5;
    if (data != null) {
      dataJsonMd5 = _md5(jsonEncode(data));
    } else if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedKeys = queryParameters.keys.toList()..sort();
      final sortedQuery = sortedKeys
          .where((k) => queryParameters[k] != null)
          .map((k) => '$k=${queryParameters[k]}')
          .join('&');
      dataJsonMd5 = _md5(sortedQuery);
    } else {
      dataJsonMd5 = _md5('');
    }

    final signSource = [_fnosApiKey, path, nonce, timestamp, dataJsonMd5, _fnosApiSecret].join('_');
    return 'nonce=$nonce&timestamp=$timestamp&sign=${_md5(signSource)}';
  }

  /// 飞牛 API 通用请求方法
  /// 自动添加 Authorization、Cookie、Authx、User-Agent 头
  Future<Map<String, dynamic>?> _fnosRequest(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String method = 'GET',
    int retry = 1,
  }) async {
    final fullPath = '$_fnosApiBase$path';
    final url = '$baseUrl$fullPath';
    // DELETE 的签名内容服务端固定按空串校验（文档 §2 实测：带 body 也按空串验签），
    // 所以这里不能把 body 交给 _generateAuthx —— 之前把 body 签进去，
    // 服务端一律返回 5000 invalid sign，取消收藏因此从来没成功过。
    final authx = _generateAuthx(
      fullPath,
      queryParameters: queryParameters,
      data: method == 'DELETE'
          ? null
          : (data is Map<String, dynamic> ? data : null),
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': _userAgent,
      'Authx': authx,
    };
    if (_fnosToken != null && _fnosToken!.isNotEmpty) {
      headers['Authorization'] = _fnosToken!;
    }
    if (_cookie != null && _cookie!.isNotEmpty) {
      headers['Cookie'] = _cookie!;
    }

    try {
      Response response;
      switch (method) {
        case 'POST':
          response = await dio.post(url, data: data, options: Options(headers: headers));
          break;
        case 'PUT':
          response = await dio.put(url, data: data, options: Options(headers: headers));
          break;
        case 'DELETE':
          response = await dio.delete(url, data: data, options: Options(headers: headers));
          break;
        default:
          response = await dio.get(
            url,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
      }

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        if (statusCode == 401 && retry > 0) {
          // 401 自愈：token 失效（HTTP 层）
          return _reauthAndRetry(path,
              data: data, queryParameters: queryParameters, method: method, retry: retry);
        }
        AppLog.w('FnOS', 'HTTP $statusCode $method $fullPath, body=${response.data}');
        return null;
      }

      final res = response.data;
      if (res is! Map) {
        AppLog.w('FnOS', '响应非 JSON Map: ${res.runtimeType}');
        return null;
      }

      // 飞牛响应格式：{code, msg, data}
      final code = res['code'];
      if (code == null) {
        // 不带 code 字段的响应，直接返回整个 Map
        return Map<String, dynamic>.from(res);
      }
      if (code == 0 || code == 200) {
        final dataField = res['data'];
        if (dataField is Map) {
          return Map<String, dynamic>.from(dataField);
        } else if (dataField is List) {
          // data 是数组时包装成 {list: [...]} 便于上层处理
          return {'list': dataField};
        }
        return <String, dynamic>{};
      } else if (code == -2 && retry > 0) {
        // 鉴权失效自愈：飞牛「有效签名+失效/缺失 token」返回 HTTP 200 +
        // code=-2 "Auth Failed"（2026-09-06 实机 curl 实证）。作废 token
        // 强制重登后原样重试一次 —— 旧实现静默返回 null，调用方各自为政，
        // 冷启动后过期会话拉全是空还不重登。
        return _reauthAndRetry(path,
            data: data, queryParameters: queryParameters, method: method, retry: retry);
      } else if (code == 5000 && res['msg'] == 'invalid sign' && retry > 0) {
        AppLog.w('FnOS', '签名错误，重试...');
        await Future.delayed(const Duration(milliseconds: 500));
        return _fnosRequest(path,
            data: data, queryParameters: queryParameters, method: method, retry: retry - 1);
      } else {
        AppLog.w('FnOS', 'API错误 ${res['msg']} (code=$code)');
        return null;
      }
    } catch (e) {
      AppLog.w('FnOS', '请求失败 $method $fullPath: $e');
      return null;
    }
  }

  /// 鉴权失效自愈：作废 token → 重新登录 → 原样重试一次。
  /// retry 是 _fnosRequest 的剩余重试预算，重试时减一防循环。
  Future<Map<String, dynamic>?> _reauthAndRetry(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required String method,
    required int retry,
  }) async {
    AppLog.w('FnOS', 'Auth Failed，作废 token 重新登录后重试: $method $path');
    _fnosToken = null;
    _cookie = null;
    if (await _ensureAuth()) {
      return _fnosRequest(path,
          data: data, queryParameters: queryParameters, method: method, retry: retry - 1);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fnosGet(String p, {Map<String, dynamic>? query}) =>
      _fnosRequest(p, queryParameters: query, method: 'GET');
  Future<Map<String, dynamic>?> _fnosPost(String p, dynamic d) =>
      _fnosRequest(p, data: d, method: 'POST');

  List<MediaItem> _fnosParseItems(List items) => items.map((i) => _fnosParseItem(i)).toList();

  MediaItem _fnosParseItem(dynamic item, [String? fallbackId]) {
    if (item is! Map) {
      return MediaItem(id: fallbackId ?? '', title: '', posterUrl: '', type: MediaType.movie);
    }
    final m = Map<String, dynamic>.from(item);
    final guid = m['guid']?.toString() ?? m['id']?.toString() ?? fallbackId ?? '';
    final title = m['title']?.toString() ?? m['name']?.toString() ?? '';
    final typeStr = m['type']?.toString() ?? '';
    final typeLower = typeStr.toLowerCase();
    final isSeries = typeStr == 'TV' || typeStr == 'Series' || typeStr == 'Season' ||
        typeLower.contains('tv') || typeLower.contains('series');
    final isEpisode = typeStr == 'Episode' || typeLower.contains('episode');

    // FlyNarwhal MediaItem 字段映射
    final yearStr = m['release_date']?.toString() ?? m['first_air_date']?.toString();
    final voteAverage = m['vote_average'];
    final mediaStream = m['media_stream'];
    String? quality;
    if (mediaStream is Map) {
      final r = mediaStream['resolutions'];
      if (r is List && r.isNotEmpty) {
        quality = r.first.toString();
      }
    }
    final watchedVal = m['watched'];
    final isFavoriteInt = m['is_favorite'];
    final isWatched = watchedVal == 1 || watchedVal == true;
    final isFavorite = isFavoriteInt == 1 || isFavoriteInt == true;

    // 续播进度：play/list 的每条记录带 ts（已看秒数），配合 duration 算比例。
    // 不填这个字段，「继续观看」卡片就没有进度条也没有「剩余 N 分钟」。
    final durationSec = (m['duration'] as num?)?.toInt() ?? 0;
    final tsSec = (m['ts'] as num?)?.toDouble();
    double? watchProgress;
    if (tsSec != null && tsSec > 0 && durationSec > 0) {
      watchProgress = (tsSec / durationSec).clamp(0.0, 1.0);
    }

    List<Map<String, dynamic>>? tracks(String key) {
      final v = m[key];
      if (v is! List || v.isEmpty) return null;
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // 背景图：FnOS list API 常不带 backdrop 字段，解析为空时返回 null（与 Jellyfin 一致），
    // 以便 Hero 的 `backdropUrl ?? posterUrl` 能回退到海报，避免首页 Hero 纯暗色背景。
    final backdrop =
        _resolveImageUrl(m['backdrop'] ?? m['backdrops'] ?? m['background'], width: 1600);

    return MediaItem(
      id: guid,
      title: title,
      posterUrl: _resolveImageUrl(m['poster'] ?? m['posters'], width: 1080),
      backdropUrl: backdrop.isEmpty ? null : backdrop,
      // FnOS 暂未见到 Logo 字段,防御性读一下;没有就 null 回退文字标题
      logoUrl: _resolveImageUrl(m['logo'] ?? m['clearLogo']).isEmpty
          ? null
          : _resolveImageUrl(m['logo'] ?? m['clearLogo']),
      overview: m['overview']?.toString(),
      rating: (voteAverage is num)
          ? voteAverage.toDouble()
          : double.tryParse(voteAverage?.toString() ?? ''),
      year: yearStr != null && yearStr.length >= 4 ? int.tryParse(yearStr.substring(0, 4)) : null,
      releaseDate: m['release_date']?.toString() ?? m['first_air_date']?.toString(),
      genres: _mapGenres(m['genres']),
      type: isSeries ? MediaType.series : (isEpisode ? MediaType.episode : MediaType.movie),
      duration: durationSec,
      watchProgress: watchProgress,
      videoTracks: tracks('_video_tracks'),
      audioTracks: tracks('_audio_tracks'),
      subtitleTracks: tracks('_subtitle_tracks'),
      seasonNumber: (m['season_number'] as num?)?.toInt(),
      episodeNumber: (m['episode_number'] as num?)?.toInt(),
      // 继续观看 → 剧集上下文:飞牛单集 payload 没有剧集 guid ——
      // parent_guid 是季 guid、ancestor_guid 是媒体库 guid(FlyNarwhal
      // 模型实证;person/list 也只有季 guid 才有演员,见 fnos-api-gap.md)。
      // 把季 guid 落到 seriesId:TV _playItem 拿它 episode/list 直接出
      // 全集(选集按钮恢复);移动端详情页走「季当容器」—— getSeasons
      // 对季 guid 有空列表兜底(合成单季)。
      seriesId: isEpisode
          ? ((m['tv_guid'] ?? m['series_guid'] ?? m['parent_guid'])?.toString())
          : null,
      seriesTitle: m['tv_title']?.toString() ?? m['ancestor_name']?.toString(),
      totalSeasons: (m['number_of_seasons'] as num?)?.toInt(),
      totalEpisodes: (m['number_of_episodes'] as num?)?.toInt(),
      imdbId: m['imdb_id']?.toString(),
      quality: quality,
      isWatched: isWatched,
      isFavorite: isFavorite,
      filePath: m['file_name']?.toString() ?? m['file_path']?.toString(),
      // FnOS API 可能在 cast/actors/people 字段返回演员数据
      people: _fnosExtractPeople(m),
    );
  }

  /// 测试入口：继续观看剧集上下文的回归钉直接驱动解析器
  /// （_fnosParseItem 依赖实例方法，公开一层最小可见面）。
  @visibleForTesting
  MediaItem fnosParseItemForTest(dynamic item, [String? fallbackId]) =>
      _fnosParseItem(item, fallbackId);

  /// 测试入口：预置一个过期 token，模拟冷启动会话残留（自愈回归钉用）。
  @visibleForTesting
  void setStaleTokenForTest(String token) {
    _fnosToken = token;
    _cookie = _isRelayMode ? 'Trim-MC-token=$token; mode=relay' : 'Trim-MC-token=$token';
  }

  /// 从 FnOS API 响应中提取演员数据（兼容多种字段名）
  ///
  /// 数据来源是 `POST person/list/{guid}`（见 _fetchPeople），item 详情本身不带演员。
  List<Map<String, dynamic>>? _fnosExtractPeople(Map m) {
    // 尝试多种字段名：cast, actors, people, credits
    final rawList = m['cast'] ?? m['actors'] ?? m['people'] ?? m['credits'];
    if (rawList is! List || rawList.isEmpty) return null;
    final result = <Map<String, dynamic>>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      final name = (item['name'] ?? item['Name'] ?? item['person_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final role = (item['character'] ?? item['Role'] ?? item['role'] ?? item['type'] ?? '').toString().trim();
      final type = (item['type'] ?? item['Type'] ?? 'Actor').toString();
      final id = (item['id'] ?? item['Id'] ?? item['person_id'] ?? '').toString();

      // 头像。**不要**去拼 /Persons/{id}/Images/Primary —— 飞牛这个端点返回 500，
      // 这也是 _buildPersonImageUrl 被覆写成 null 的原因。
      // 取第一个**非空**候选（不是第一个非 null）：飞牛经常把字段给成空串，
      // 用 ?? 链会在 poster:"" 上就停下，漏掉后面真有值的 profile_path。
      var path = '';
      for (final k in const ['poster', 'posters', 'profile', 'avatar',
        'profile_path', 'ProfilePath']) {
        path = _firstImagePath(item[k]);
        if (path.isNotEmpty) break;
      }
      String? imageUrl;
      if (path.isNotEmpty) {
        if (path.startsWith('http')) {
          imageUrl = path;
        } else if (_isLocalImagePath(path)) {
          imageUrl = _resolveImageUrl(path, width: 300);
        } else {
          imageUrl = 'https://image.tmdb.org/t/p/w185$path';
        }
      }
      result.add({
        'Id': id,
        'Name': name,
        'Role': role.isNotEmpty ? role : type,
        'Type': type,
        'ImageUrl': imageUrl,
        // 刻意**不**透传 profile_path：_castSection 在 ImageUrl 为空时会拿它
        // 去拼 image.tmdb.org，而飞牛塞在这个字段里的往往是自己的本地路径。
      });
    }
    return result.isNotEmpty ? result : null;
  }

  /// 人物图片路径是飞牛本地的还是 TMDB 的？
  ///
  /// 飞牛把自己缓存的图片路径也塞在 `profile_path`（TMDB 的字段名）里，形如
  /// `/d3/02/RXFg….webp` —— 两级散列目录 + webp。TMDB 的是单段 `/wJ5S….jpg`。
  /// 原来不分辨、一律拼 image.tmdb.org，于是飞牛源每个头像都 404（真机日志里
  /// 一片 `Invalid statusCode: 404, uri = https://image.tmdb.org/t/p/w185/d3/02/…`）。
  static bool _isLocalImagePath(String p) =>
      p.startsWith('/') && p.substring(1).contains('/');
}

/// 一次 `POST /play/info` 的结果。
///
/// 三个 guid 是 `/play/record`（进度上报）和 `/play/play`（转码）的必填项；
/// 直播频道走另一条路：没有 media_guid，但 live_channels[] 里是外部直链。
class _FnosPlaySession {
  const _FnosPlaySession({
    required this.mediaGuid,
    required this.videoGuid,
    required this.audioGuid,
    required this.subtitleGuid,
    required this.durationSec,
    required this.isLive,
    this.liveUrl,
    this.liveName,
    this.fileStreamPath,
  });

  final String mediaGuid;
  final String videoGuid;
  final String audioGuid;
  final String subtitleGuid;
  final int durationSec;
  final bool isLive;
  final String? liveUrl;
  final String? liveName;
  final String? fileStreamPath;

  factory _FnosPlaySession.fromJson(Map<String, dynamic> j) {
    final item = j['item'];
    final isLive = j['type']?.toString() == 'LiveChannel' ||
        (item is Map && item['type']?.toString() == 'LiveChannel');

    // 直播：live_channels[] 每项是一条线路，path 就是外部可播的 m3u8
    String? liveUrl;
    String? liveName;
    final channels = j['live_channels'];
    if (channels is List) {
      for (final c in channels) {
        if (c is! Map) continue;
        final p = c['path']?.toString() ?? '';
        if (p.isEmpty) continue;
        liveUrl = p;
        liveName = c['file_name']?.toString();
        break;
      }
    }

    final fs = j['file_stream'];
    return _FnosPlaySession(
      mediaGuid: j['media_guid']?.toString() ?? '',
      videoGuid: j['video_guid']?.toString() ?? '',
      audioGuid: j['audio_guid']?.toString() ?? '',
      subtitleGuid: j['subtitle_guid']?.toString() ?? '',
      durationSec: (j['duration'] as num?)?.toInt() ??
          (item is Map ? (item['duration'] as num?)?.toInt() ?? 0 : 0),
      isLive: isLive || liveUrl != null,
      liveUrl: liveUrl,
      liveName: liveName,
      fileStreamPath: fs is Map ? fs['file']?.toString() : null,
    );
  }
}




/// 该媒体源是不是 BDMV/ISO 原盘。
///
/// 各服务端字段差异极大，只认 VideoType/IsoType 会漏判（2026-09-27 真机实证）：
/// 同一个 1080p 蓝光 ISO，Jellyfin 给 `VideoType='Iso'` + `IsoType='BluRay'`，
/// 而 Emby 两个字段都是 **null**、`Container='blurayiso'`、`Path` 以 `.iso`
/// 结尾，却声称 `SupportsDirectPlay=true`。漏判 → 走服务器转码流 → Emby 转
/// blurayiso 直接 HTTP 500 → 黑屏。
///
/// 所以按与服务器版本无关的特征判定（路径后缀 / 容器名），字段只作补充。
bool isIsoMediaSource(Map<dynamic, dynamic> source) {
  final videoType = source['VideoType']?.toString().toLowerCase() ?? '';
  final isoType = source['IsoType']?.toString() ?? '';
  if (videoType == 'iso' || isoType.isNotEmpty) return true;
  // blurayiso / dvd-iso / iso 都命中；常见容器（mkv/mp4/ts）不含 'iso'
  final container = source['Container']?.toString().toLowerCase() ?? '';
  if (container.contains('iso')) return true;
  final path = source['Path']?.toString().toLowerCase() ?? '';
  return path.endsWith('.iso');
}


/// ISO 客户端直连用的静态流地址。
///
/// ⚠️ **不要加 `DeviceId`**（这里曾经把 PlaySessionId 当 DeviceId 拼进去）。
/// 真机实测（2026-09-27，同一个 39.6GB 原盘、同一台服务器、同尺寸 2KB 请求）：
///   Emby 静态流  不带 DeviceId = 8.2ms   带 DeviceId = 78~99ms
/// 而开 ISO 要打几十次小请求 → Emby 启播 3.06s vs Jellyfin 0.28s（差 11 倍），
/// 差距几乎全部来自这个参数触发的每请求开销。Jellyfin 忽略该参数，因此去掉它
/// 两边都安全（实测不带 DeviceId 仍返回 206 且字节数正确）。播放进度上报走
/// 独立的 PlaybackStart/Progress 接口，不依赖流地址里的会话参数。
String isoDirectStreamUrl({
  required String baseUrl,
  required String itemId,
  required String apiKey,
  required String sourceId,
}) {
  // 端点选择(真机 + 电脑双向实测,2026-09-27):
  // Emby 对 ISO 条目的 `/Videos/{id}/stream`(无扩展名)**挂起不响应**
  // (实测 15~20 秒零字节,原生侧因此报 "步骤=header errno=11" 后超时),
  // 客户端只能等超时回退服务器转码,而转码流启动又需约 20 秒,合计等待约 40 秒。
  // 同一 ISO 用 `/Items/{id}/Download`(Emby 官方原文件下载端点)0.09s 即返回
  // 206 + 原始字节,`/Videos/{id}/stream.mkv`(0.01s)、`/original`(0.03s) 亦可。
  // 这里用语义最明确的 Download 端点读原始 ISO 字节供客户端 UDF 解析。
  return '$baseUrl/Items/$itemId/Download?api_key=$apiKey';
}

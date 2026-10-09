import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/download/utils/search_result_raw_cache.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/services/sse_client.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SearchType { media, title }

class SearchMediaController extends GetxController {
  static const _sortKeyPrefKey = 'search_result_sort_key';
  static const _sortDirectionPrefKey = 'search_result_sort_direction';

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  ServerApiVersionService get _serverApiVersionService =>
      Get.find<ServerApiVersionService>();

  final searchText = ''.obs;
  String? prefillTitle;
  String? prefillBackdrop;
  var mediaSearchKey = '';
  var mtype = '电影';
  var area = 'title';
  var year = '';
  String? season;
  var sites = <int>[];
  late SearchType searchType;

  /// 本轮流式搜索的 HTTP 状态(失败时用于区分"流式失败"与"本地失败")
  int? _lastStreamStatus;

  final items = <SearchResultItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  final viewMode = SearchResultViewMode.list.obs;
  final sortKey = SearchResultSortKey.defaultSort.obs;
  final sortDirection = SortDirection.desc.obs;
  final keyword = ''.obs;

  final selectedSites = <String>{}.obs;
  final selectedSeasons = <String>{}.obs;
  final selectedPromotions = <String>{}.obs;
  final selectedVideoEncodes = <String>{}.obs;
  final selectedQualities = <String>{}.obs;
  final selectedResolutions = <String>{}.obs;
  final selectedTeams = <String>{}.obs;

  // SSE 进度跟踪相关
  final isProgressActive = false.obs;
  final searchProgress = 0.0.obs;
  final progressMessage = ''.obs;
  final progressStatus = ''.obs; // 'searching', 'completed', 'failed'
  final progressCurrent = 0.obs;
  final progressTotal = 0.obs;
  final progressSource = ''.obs;

  SseClient? _sseClient;
  StreamSubscription<SseEvent>? _sseSubscription;
  StreamSubscription<String>? _searchStreamSubscription;
  bool _streamTerminalHandled = false;

  int _progressSessionId = 0;

  static const _progressPath = '/api/v1/system/progress/search';

  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  void updateSearchText(String text) {
    searchText.value = text;
  }

  void updateKeyword(String value) {
    keyword.value = value.trim();
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == SearchResultViewMode.list
        ? SearchResultViewMode.grid
        : SearchResultViewMode.list;
  }

  void updateSortKey(SearchResultSortKey next) {
    sortKey.value = next;
    unawaited(_persistSortPrefs());
  }

  void toggleSortDirection() {
    sortDirection.value = sortDirection.value == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
    unawaited(_persistSortPrefs());
  }

  void toggleFilter(SearchResultFilterType type, String value) {
    final target = _filterSet(type);
    final next = target.toSet();
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    _assignFilter(type, next);
  }

  void clearFilters() {
    selectedSites.value = <String>{};
    selectedSeasons.value = <String>{};
    selectedPromotions.value = <String>{};
    selectedVideoEncodes.value = <String>{};
    selectedQualities.value = <String>{};
    selectedResolutions.value = <String>{};
    selectedTeams.value = <String>{};
  }

  bool get hasActiveFilters =>
      selectedSites.value.isNotEmpty ||
      selectedSeasons.value.isNotEmpty ||
      selectedPromotions.value.isNotEmpty ||
      selectedVideoEncodes.value.isNotEmpty ||
      selectedQualities.value.isNotEmpty ||
      selectedResolutions.value.isNotEmpty ||
      selectedTeams.value.isNotEmpty;

  List<SearchResultItem> get visibleItems {
    final key = keyword.value.trim().toLowerCase();
    final sites = selectedSites.value.toSet();
    final seasons = selectedSeasons.value.toSet();
    final promotions = selectedPromotions.value.toSet();
    final encodes = selectedVideoEncodes.value.toSet();
    final qualities = selectedQualities.value.toSet();
    final resolutions = selectedResolutions.value.toSet();
    final teams = selectedTeams.value.toSet();

    var results = items.toList();
    if (key.isNotEmpty) {
      results = results.where((item) => _matchKeyword(item, key)).toList();
    }
    results = results.where((item) {
      if (sites.isNotEmpty && !sites.contains(_siteName(item))) {
        return false;
      }
      if (seasons.isNotEmpty) {
        final season = _seasonLabel(item);
        if (season == null || !seasons.contains(season)) return false;
      }
      if (promotions.isNotEmpty) {
        final promotion = _promotionLabel(item);
        if (promotion == null || !promotions.contains(promotion)) {
          return false;
        }
      }
      if (encodes.isNotEmpty) {
        final encode = item.meta_info?.video_encode ?? '';
        if (!encodes.contains(encode)) return false;
      }
      if (qualities.isNotEmpty) {
        final quality = _qualityLabel(item);
        if (quality == null || !qualities.contains(quality)) return false;
      }
      if (resolutions.isNotEmpty) {
        final resolution = item.meta_info?.resource_pix ?? '';
        if (!resolutions.contains(resolution)) return false;
      }
      if (teams.isNotEmpty) {
        final team = item.meta_info?.resource_team ?? '';
        if (!teams.contains(team)) return false;
      }
      return true;
    }).toList();

    return _sortResults(results);
  }

  Future<void> performSearch() async {
    if (mediaSearchKey.isEmpty) {
      errorText.value = '请先选择要搜索的媒体';
      return;
    }

    if (sites.isEmpty) {
      errorText.value = '请至少选择一个站点';
      return;
    }

    await _searchStreamSubscription?.cancel();
    _searchStreamSubscription = null;
    _stopProgressTracking();

    _progressSessionId++;
    final sessionId = _progressSessionId;
    _streamTerminalHandled = false;
    _lastStreamStatus = null;

    items.clear();
    isLoading.value = true;
    errorText.value = null;
    _resetProgressUi();

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录后再进行搜索';
        _finishSearchSession(sessionId);
        return;
      }

      final streamed = await _startStreamSearch(
        token: token,
        sessionId: sessionId,
      );
      if (streamed) return;

      await _performBlockingSearch(token: token, sessionId: sessionId);
    } catch (e, st) {
      if (sessionId != _progressSessionId) return;
      _log.handle(e, stackTrace: st, message: '搜索失败');
      errorText.value = '请求失败，请稍后重试 $e';
      _finishSearchSession(sessionId);
    }
  }

  void _resetProgressUi() {
    isProgressActive.value = true;
    searchProgress.value = 0;
    progressMessage.value = '正在搜索...';
    progressStatus.value = 'searching';
    progressCurrent.value = 0;
    progressTotal.value = 0;
    progressSource.value = '';
  }

  void _finishSearchSession(int sessionId, {String? error}) {
    if (sessionId != _progressSessionId) return;
    if (error != null) errorText.value = error;
    isLoading.value = false;
    if (error == null) {
      progressStatus.value = 'completed';
      searchProgress.value = 1;
    } else {
      progressStatus.value = 'failed';
    }
    Future.delayed(const Duration(seconds: 1), () {
      _stopProgressTracking(sessionId: sessionId);
    });
  }

  Future<bool> _startStreamSearch({
    required String token,
    required int sessionId,
  }) async {
    // 形态不确定:先按首选形态发起,被 422/404 拒时换另一种形态再试一次
    // (两台真实服务器认的形态不同:一台缺 media_source 直接 422,
    //  另一台旧式前缀形态会挂住不返回)
    for (var index = 0; index < 2; index++) {
      final path = await _streamPathForIndex(index);
      try {
        final stream = await _apiClient.streamLines(
          path,
          token: token,
          handleAuth: false,
        );
        if (sessionId != _progressSessionId) return true;
        _searchStreamSubscription = stream.listen(
          (line) {
            if (sessionId != _progressSessionId) return;
            _handleSearchStreamLine(line);
          },
          onError: (Object e, StackTrace st) {
            if (!_consumeStreamTerminal(sessionId)) return;
            _log.handle(e, stackTrace: st, message: '搜索 SSE 失败');
            unawaited(_recoverAfterStream(token: token, sessionId: sessionId));
          },
          onDone: () {
            if (!_consumeStreamTerminal(sessionId)) return;
            unawaited(_completeStreamSearch(token: token, sessionId: sessionId));
          },
          cancelOnError: false,
        );
        return true;
      } on ApiHttpException catch (e, st) {
        _lastStreamStatus = e.statusCode;
        _log.handle(
          e,
          stackTrace: st,
          message: '搜索 SSE HTTP ${e.statusCode}(形态 ${index + 1}) $path',
        );
        // ignore: avoid_print
        print('[Search] 流式搜索 HTTP ${e.statusCode} 形态${index + 1}: $path');
        if (searchType == SearchType.title) return false;
        if (e.statusCode != 422 && e.statusCode != 404) return false;
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '搜索 SSE 不可用，回退阻塞搜索');
        return false;
      }
    }
    return false;
  }

  String _streamPath() {
    final query = Uri(queryParameters: _streamQueryParameters()).query;
    final base = switch (searchType) {
      SearchType.media => '/api/v1/search/media/$mediaSearchKey/stream',
      SearchType.title => '/api/v1/search/title/stream',
    };
    return query.isEmpty ? base : '$base?$query';
  }

  /// 标题搜索/媒体搜索的流式请求地址。
  /// 媒体搜索按 [mediaSearchForms] 的候选形态:优先服务端能力表的形态,
  /// 失败再回退另一种(见 [_startStreamSearch])。
  Future<String> _streamPathForIndex(int index) async {
    if (searchType == SearchType.title) return _streamPath();
    final forms = await _mediaSearchForms(_streamQueryParametersForMedia());
    final form = forms[index.clamp(0, forms.length - 1)];
    final query = Uri(queryParameters: form.query).query;
    final base = '${form.path}/stream';
    return query.isEmpty ? base : '$base?$query';
  }

  /// 媒体搜索的通用查询参数(两种形态共用的一部分)
  Map<String, String> _streamQueryParametersForMedia() => {
        'mtype': mtype,
        'area': area == 'title' ? 'title' : 'imdbid',
        if (searchText.value.isNotEmpty) 'title': searchText.value,
        if (year.isNotEmpty) 'year': year,
        'sites': sites.join(','),
        if (season != null && season!.isNotEmpty && season != '0')
          'season': season!,
      };

  /// 媒体搜索的候选请求形态(按优先级):
  /// ① 有媒体标识(`来源:数字`,如 tmdb:123):
  ///    新式 `/api/v1/search/media/<数字标识>` + `media_source=<来源>`;
  /// ② 无媒体标识(详情页在 tmdb 路径下传进来的是**标题**):
  ///    改走**标题搜索接口** `/api/v1/search/title?keyword=<标题>&sites=...`。
  ///
  /// 为什么必须分开:两台真实服务器(2026-09-28 实测)都是 v3 契约,媒体搜索接口
  /// **强制要求 media_source**,而标题形态拿不到来源值 → 用标题调媒体接口必然 422
  /// (真机日志:`[{location: [query, media_source], message: Field required}]`);
  /// 标题搜索接口不要求该参数,两台实测均 200。
  Future<List<({String path, Map<String, dynamic> query})>> _mediaSearchForms(
    Map<String, dynamic> baseQuery,
  ) async {
    final identity = MediaIdentity.parse(mediaSearchKey);
    // ① 没有媒体标识(拿到的其实是标题):走标题搜索接口;
    //    旧行为(标题当媒体标识调媒体接口)保留为兜底,老服务端仍可用
    if (identity == null) {
      return [
        (
          path: '/api/v1/search/title',
          query: <String, dynamic>{
            'keyword': searchText.value.isNotEmpty
                ? searchText.value
                : mediaSearchKey,
            'sites': sites.join(','),
          },
        ),
        (path: '/api/v1/search/media/$mediaSearchKey', query: baseQuery),
      ];
    }
    // ② 按 IMDb 检索:保持原媒体接口语义,不做形态替换
    if (area != 'title') {
      return [
        (path: '/api/v1/search/media/$mediaSearchKey', query: baseQuery),
      ];
    }
    // ③ 有媒体标识且按标题检索:优先新式(数字标识 + media_source),失败再退回旧式。
    // 形态优先级:搜索自己的实测记忆 > 服务端能力表;已知不需要新形态时不再打探测。
    final legacy =
        (path: '/api/v1/search/media/$mediaSearchKey', query: baseQuery);
    final learned = _serverApiVersionService.searchNeedsMediaSource;
    final preferNew = learned ?? await _serverApiVersionService.isV3();
    final sources = learned == false
        ? null
        : await _serverApiVersionService.mediaSourceValues();
    final newForm = (
      path: '/api/v1/search/media/${identity.id}',
      query: <String, dynamic>{
        ...baseQuery,
        'media_source': _pickSourceValue(identity.source, sources),
      },
    );
    return preferNew ? [newForm, legacy] : [legacy, newForm];
  }

  /// 选服务端认的来源值:优先用服务端能力表里的写法(大小写/别名更稳),
  /// 否则用媒体标识自身归一化后的来源(如 themoviedb)
  String _pickSourceValue(String source, Set<String>? advertised) {
    if (advertised != null && advertised.isNotEmpty) {
      final wanted = source.toLowerCase();
      for (final value in advertised) {
        if (value == wanted) return value;
      }
      // 兼容 tmdb/themoviedb 这类同源不同写法
      if (wanted == 'themoviedb' && advertised.contains('tmdb')) return 'tmdb';
      if (wanted == 'tmdb' && advertised.contains('themoviedb')) {
        return 'themoviedb';
      }
    }
    return source;
  }

  /// 从服务端错误响应里提取可读原因。要兼容三种真实出现的形状:
  /// 1) **裸数组**:服务端自带信封 `{success,message,data:[...]}` 被 ApiClient 解封后,
  ///    校验错误列表直接成为 response.data(真机日志实证:422 拿到的就是这一种);
  /// 2) **FastAPI 原始体**:`{detail:[{loc:[...],msg:'Field required'}]}`;
  /// 3) **未解封的信封**:`{message:..., data:[...]}`。
  /// 字段名取 loc/location 的最后一段,原因取 msg/message;都没有时退回顶层 msg/message。
  String _serverErrorReason(dynamic body) {
    final parts = <String>[];

    void addItem(Object? item) {
      if (item is! Map) return;
      final loc = item['loc'] ?? item['location'];
      var name = '';
      if (loc is List && loc.isNotEmpty) {
        name = loc.last.toString();
      } else if (loc != null) {
        name = loc.toString();
      }
      final reason = (item['msg'] ?? item['message'] ?? '').toString().trim();
      if (name.isNotEmpty && reason.isNotEmpty) {
        parts.add('$name: $reason');
      } else if (reason.isNotEmpty) {
        parts.add(reason);
      }
    }

    if (body is List) {
      for (final item in body) {
        addItem(item);
      }
    } else if (body is Map) {
      for (final key in const ['detail', 'data']) {
        final list = body[key];
        if (list is List) {
          for (final item in list) {
            addItem(item);
          }
        }
      }
      if (parts.isEmpty) {
        final message = (body['message'] ?? body['msg'] ?? '').toString().trim();
        if (message.isNotEmpty) parts.add(message);
      }
    }

    // 去重后拼接(同一字段可能在 detail 与 data 里各出现一次)
    return parts.toSet().join(' | ');
  }

  Map<String, String> _streamQueryParameters() {
    if (searchType == SearchType.title) {
      return {
        if (searchText.value.isNotEmpty) 'keyword': searchText.value,
        'sites': sites.join(','),
      };
    }
    return {
      'mtype': mtype,
      'area': area == 'title' ? 'title' : 'imdbid',
      if (searchText.value.isNotEmpty) 'title': searchText.value,
      if (year.isNotEmpty) 'year': year,
      'sites': sites.join(','),
      if (season != null && season!.isNotEmpty && season != '0')
        'season': season!,
    };
  }

  void _handleSearchStreamLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;

    var payload = trimmed;
    if (payload.startsWith('data:')) {
      payload = payload.substring(5).trimLeft();
    }
    if (payload.isEmpty || payload == '[DONE]') return;

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return;
    }
    if (json == null) return;

    final type = json['type']?.toString() ?? '';
    final text =
        (json['text_i18n'] ?? json['text'])?.toString() ??
        progressMessage.value;
    final value = json['value'];
    if (value is num) {
      final normalized = value <= 1 ? value.toDouble() : value.toDouble() / 100;
      searchProgress.value = normalized.clamp(0.0, 1.0);
    }
    if (text.trim().isNotEmpty) {
      progressMessage.value = text;
    }
    final finished = json['finished'];
    final total = json['total'];
    if (finished is num) progressCurrent.value = finished.toInt();
    if (total is num) progressTotal.value = total.toInt();
    final site = json['site']?.toString() ?? '';
    if (site.isNotEmpty) progressSource.value = site;

    switch (type) {
      case 'append':
        _appendSearchItems(_extractSearchItems(json['items']));
        break;
      case 'replace':
        items
          ..clear()
          ..addAll(_extractSearchItems(json['items']));
        break;
      case 'progress':
        break;
      case 'done':
        _appendSearchItems(_extractSearchItems(json['items']));
        progressStatus.value = 'completed';
        searchProgress.value = 1;
        break;
      default:
        _appendSearchItems(_extractSearchItems(json['items']));
    }
  }

  List<SearchResultItem> _extractSearchItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => parseAndCacheSearchResultItem(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _appendSearchItems(List<SearchResultItem> next) {
    if (next.isEmpty) return;
    final existing = items.map(_itemKey).toSet();
    final unique = <SearchResultItem>[];
    for (final item in next) {
      if (existing.add(_itemKey(item))) unique.add(item);
    }
    if (unique.isEmpty) return;
    items.addAll(unique);
  }

  String _itemKey(SearchResultItem item) {
    final torrent = item.torrent_info;
    final enclosure = torrent?.enclosure?.trim() ?? '';
    if (enclosure.isNotEmpty) return enclosure;
    final pageUrl = torrent?.page_url?.trim() ?? '';
    if (pageUrl.isNotEmpty) return pageUrl;
    return '${torrent?.site}_${torrent?.title}_${torrent?.size}';
  }

  bool _consumeStreamTerminal(int sessionId) {
    if (sessionId != _progressSessionId) return false;
    if (_streamTerminalHandled) return false;
    _streamTerminalHandled = true;
    return true;
  }

  Future<void> _completeStreamSearch({
    required String token,
    required int sessionId,
  }) async {
    if (items.isEmpty) {
      final fallback = await _fetchLastSearchResults(token);
      if (sessionId != _progressSessionId) return;
      _assignSearchResults(fallback);
    }
    _finishSearchSession(sessionId);
  }

  Future<void> _recoverAfterStream({
    required String token,
    required int sessionId,
  }) async {
    if (items.isNotEmpty) {
      _finishSearchSession(sessionId);
      return;
    }
    try {
      await _performBlockingSearch(token: token, sessionId: sessionId);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '搜索 SSE 回退失败');
      _finishSearchSession(sessionId, error: '请求失败，请稍后重试 $e');
    }
  }

  Future<void> _performBlockingSearch({
    required String token,
    required int sessionId,
  }) async {
    _startProgressTracking();
    final baseQuery = <String, dynamic>{
      'mtype': mtype,
      'area': area == 'title' ? 'title' : 'imdbid',
      if (searchText.value.isNotEmpty) 'title': searchText.value,
      if (year.isNotEmpty) 'year': year,
      'sites': sites.join(','),
      'keyword': searchText.value,
      if (season != null && season!.isNotEmpty && season != '0')
        'season': season!,
    };

    final forms = searchType == SearchType.media
        ? await _mediaSearchForms(baseQuery)
        : <({String path, Map<String, dynamic> query})>[
            (path: '/api/v1/search/title', query: baseQuery),
          ];

    dynamic response;
    var failureReason = '';
    var winnerHasSource = false;
    for (var index = 0; index < forms.length; index++) {
      final form = forms[index];
      final printable = Uri(
        queryParameters:
            form.query.map((k, v) => MapEntry(k, v.toString())),
      ).query;
      // ignore: avoid_print
      print('[Search] 请求(${index + 1}/${forms.length}) ${form.path}?$printable');
      response = await _apiClient.get<dynamic>(
        form.path,
        queryParameters: form.query,
        token: token,
        timeout: 60 * max(sites.length, 1),
      );
      if (sessionId != _progressSessionId) return;

      final status = response.statusCode ?? 0;
      if (status < 400) {
        winnerHasSource = form.query.containsKey('media_source');
        // 形态确认:记住这台服务器认哪种,后续搜索不再试错。
        // 只写搜索专用的形态记忆——写进全局 isV3 会连带影响信封解封、详情页、
        // 订阅、字幕搜索、存储等模块的契约判断(评审阻塞项)。
        if (searchType == SearchType.media) {
          _serverApiVersionService.markSearchNeedsMediaSource(winnerHasSource);
        }
        break;
      }

      failureReason = _serverErrorReason(response.data);
      final body = response.data?.toString() ?? '';
      // ignore: avoid_print
      print('[Search] 失败 HTTP $status ${form.path}?$printable '
          '原因=$failureReason 响应=${body.length > 300 ? '${body.substring(0, 300)}…' : body}');
      // 422/404 视为"形态不对":换另一种形态再试一次
      if (index == 0 &&
          forms.length > 1 &&
          (status == 422 || status == 404)) {
        continue;
      }
      break;
    }

    final status = response?.statusCode ?? 0;
    if (status >= 400) {
      _finishSearchSession(
        sessionId,
        error: _searchFailureText(status, failureReason),
      );
      return;
    }

    var list = _extractList(response.data).toList();
    if (_looksStrippedResult(list) && await _serverApiVersionService.isV3()) {
      final fallback = await _fetchLastSearchResults(token);
      if (fallback.isNotEmpty) list = fallback;
    }
    if (sessionId != _progressSessionId) return;
    _assignSearchResults(list);
    _finishSearchSession(sessionId);
  }

  /// 搜索失败文案:带上服务端给的原因(例如"media_source: Field required"),
  /// 并区分流式与本地两次尝试,避免只看到一句 HTTP 码。
  String _searchFailureText(int status, String reason) {
    final buffer = StringBuffer('请求失败 (HTTP $status)');
    if (reason.isNotEmpty) buffer.write('：$reason');
    final streamStatus = _lastStreamStatus;
    if (streamStatus != null) {
      buffer.write('\n流式搜索 HTTP $streamStatus,已回退本地搜索');
    }
    return buffer.toString();
  }

  void _assignSearchResults(List<dynamic> list) {
    items
      ..clear()
      ..addAll(
        list.whereType<Map>().map(
          (e) => parseAndCacheSearchResultItem(Map<String, dynamic>.from(e)),
        ),
      );
  }

  /// 开始 SSE 进度跟踪
  void _startProgressTracking() async {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.disconnect();
    _sseClient = null;

    final baseUrl = _apiClient.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _log.warning('Cannot start progress tracking: baseUrl is null');
      return;
    }

    _log.info('Starting search progress tracking via SSE');
    _log.info('SSE baseUrl: $baseUrl, endpoint: $_progressPath');

    isProgressActive.value = true;

    try {
      // 获取 Cookie
      final cookieHeader = await _apiClient.getCookieHeader();
      _log.info('SSE cookie: $cookieHeader');

      // 创建 SSE 客户端
      _sseClient = SseClient(
        baseUrl: baseUrl,
        headers: _buildSseHeaders(cookieHeader),
      );

      // 连接 SSE 端点
      _sseSubscription = _sseClient!
          .connect(_progressPath)
          .listen(
            _handleProgressEvent,
            onError: _handleProgressError,
            onDone: _handleProgressDone,
          );
      _log.info('SSE connection initiated');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'Failed to start SSE connection');
      // 静默失败，不影响搜索功能
    }
  }

  /// 停止 SSE 进度跟踪
  void _stopProgressTracking({int? sessionId}) {
    if (sessionId != null && sessionId != _progressSessionId) {
      return;
    }

    _log.info('Stopping search progress tracking');
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.disconnect();
    _sseClient = null;
    isProgressActive.value = false;
  }

  /// 构建 SSE 请求头
  Map<String, String> _buildSseHeaders(String? cookieHeader) {
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };

    // 添加 Cookie 认证
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
      _log.info('SSE using Cookie auth');
    } else {
      _log.warning('SSE no cookie available');
    }

    return headers;
  }

  /// 处理进度事件
  void _handleProgressEvent(SseEvent event) {
    _log.debug('Received SSE event: ${event.event}, data: ${event.data}');

    final jsonData = event.jsonData;
    if (jsonData == null) {
      _log.warning('Failed to parse SSE event data as JSON: ${event.data}');
      return;
    }

    try {
      final progressEvent = SearchProgressEvent.fromJson(jsonData);
      _updateProgress(progressEvent);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'Failed to parse progress event');
    }
  }

  /// 更新进度状态
  void _updateProgress(SearchProgressEvent event) {
    searchProgress.value = event.progress;
    progressStatus.value = event.status;
    progressMessage.value = event.message ?? progressMessage.value;
    // 从 data 中提取额外信息
    if (event.data != null) {
      progressCurrent.value =
          event.data!['current'] as int? ?? progressCurrent.value;
      progressTotal.value = event.data!['total'] as int? ?? progressTotal.value;
      progressSource.value =
          event.data!['source']?.toString() ?? progressSource.value;
    }

    _log.info(
      'Search progress: ${(event.progress * 100).toStringAsFixed(1)}% - ${event.status} - ${event.message}',
    );

    // // 如果进度已完成，延迟停止跟踪
    // if (event.isCompleted) {
    //   final sessionId = _progressSessionId;
    //   Future.delayed(const Duration(seconds: 2), () {
    //     _stopProgressTracking(sessionId: sessionId);
    //   });
    // }
  }

  /// 处理进度错误
  void _handleProgressError(Object error) {
    _log.error('SSE progress error: $error');
    // 不显示错误状态，只是静默失败，让搜索请求继续
    // 进度条会继续显示之前的进度或保持搜索中状态
  }

  /// 处理进度完成
  void _handleProgressDone() {
    _log.info('SSE progress stream closed');
    // 流关闭时更新状态
    if (isProgressActive.value && progressStatus.value == 'searching') {
      progressStatus.value = 'completed';
      searchProgress.value = 1.0;
    }
  }

  /// 获取格式化的进度文本
  String get formattedProgress {
    if (!isProgressActive.value) return '';

    final percent = (searchProgress.value * 100).toStringAsFixed(0);
    if (progressTotal.value > 0) {
      return '$percent% (${progressCurrent.value}/${progressTotal.value})';
    }
    return '$percent%';
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreSortPrefs());
  }

  @override
  void onReady() {
    super.onReady();
    performSearch();
  }

  @override
  void onClose() {
    unawaited(_searchStreamSubscription?.cancel());
    _searchStreamSubscription = null;
    _stopProgressTracking();
    super.onClose();
  }

  Future<void> _persistSortPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKeyPrefKey, sortKey.value.name);
    await prefs.setString(_sortDirectionPrefKey, sortDirection.value.name);
  }

  Future<void> _restoreSortPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sortKeyName = prefs.getString(_sortKeyPrefKey);
    final sortDirectionName = prefs.getString(_sortDirectionPrefKey);

    if (sortKeyName != null && sortKeyName.isNotEmpty) {
      final matchedSortKey = SearchResultSortKey.values.where(
        (e) => e.name == sortKeyName,
      );
      if (matchedSortKey.isNotEmpty) {
        sortKey.value = matchedSortKey.first;
      }
    }

    if (sortDirectionName != null && sortDirectionName.isNotEmpty) {
      final matchedDirection = SortDirection.values.where(
        (e) => e.name == sortDirectionName,
      );
      if (matchedDirection.isNotEmpty) {
        sortDirection.value = matchedDirection.first;
      }
    }
  }

  /// 判断搜索结果是否被服务端序列化成了空壳：既没有 Context 的三层结构，
  /// 也没有种子标题，说明这批数据没有可用信息。
  bool _looksStrippedResult(List<dynamic> list) {
    if (list.isEmpty) return false;
    for (final item in list) {
      if (item is! Map) return false;
      if (item['torrent_info'] != null) return false;
      if (item['meta_info'] != null) return false;
      final title = item['title'];
      if (title is String && title.trim().isNotEmpty) return false;
    }
    return true;
  }

  /// 回退获取上次搜索结果（/search/last 返回完整的 Context 列表）。
  Future<List<dynamic>> _fetchLastSearchResults(String? token) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/search/last',
        token: token,
      );
      if ((response.statusCode ?? 0) != 200) return const [];
      return _extractList(response.data).toList();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '回退获取上次搜索结果失败');
      return const [];
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

  List<String> get availableSites => _uniqueOptions(items.map(_siteName));
  List<String> get availableSeasons => _uniqueOptions(items.map(_seasonLabel));
  List<String> get availablePromotions =>
      _uniqueOptions(items.map(_promotionLabel));
  List<String> get availableVideoEncodes =>
      _uniqueOptions(items.map((e) => e.meta_info?.video_encode));
  List<String> get availableQualities =>
      _uniqueOptions(items.map(_qualityLabel));
  List<String> get availableResolutions =>
      _uniqueOptions(items.map((e) => e.meta_info?.resource_pix));
  List<String> get availableTeams =>
      _uniqueOptions(items.map((e) => e.meta_info?.resource_team));

  List<String> _uniqueOptions(Iterable<String?> values) {
    final set = <String>{};
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      set.add(trimmed);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<SearchResultItem> _sortResults(List<SearchResultItem> list) {
    final key = sortKey.value;
    if (key == SearchResultSortKey.defaultSort) {
      return list;
    }
    list.sort((a, b) {
      int result;
      switch (key) {
        case SearchResultSortKey.site:
          result = _siteName(a).compareTo(_siteName(b));
          break;
        case SearchResultSortKey.size:
          result = (_size(a)).compareTo(_size(b));
          break;
        case SearchResultSortKey.seeders:
          result = (_seeders(a)).compareTo(_seeders(b));
          break;
        case SearchResultSortKey.pubdate:
          result = (_pubdate(a)).compareTo(_pubdate(b));
          break;
        case SearchResultSortKey.defaultSort:
          result = 0;
          break;
      }
      return sortDirection.value == SortDirection.asc ? result : -result;
    });
    return list;
  }

  bool _matchKeyword(SearchResultItem item, String keywordLower) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final buffer = StringBuffer()
      ..write(meta?.title ?? '')
      ..write(' ')
      ..write(meta?.subtitle ?? '')
      ..write(' ')
      ..write(meta?.name ?? '')
      ..write(' ')
      ..write(meta?.cn_name ?? '')
      ..write(' ')
      ..write(meta?.en_name ?? '')
      ..write(' ')
      ..write(torrent?.title ?? '')
      ..write(' ')
      ..write(torrent?.description ?? '')
      ..write(' ')
      ..write(_siteName(item));
    final haystack = buffer.toString().toLowerCase();
    return haystack.contains(keywordLower);
  }

  String _siteName(SearchResultItem item) =>
      item.torrent_info?.site_name ?? '未知站点';

  String? _seasonLabel(SearchResultItem item) {
    final meta = item.meta_info;
    if (meta == null) return null;
    final seasonEpisode = meta.season_episode?.trim();
    if (seasonEpisode != null && seasonEpisode.isNotEmpty) {
      return seasonEpisode;
    }
    final season = meta.begin_season ?? meta.total_season;
    if (season != null && season > 0) {
      return 'S${season.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? _promotionLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    if (torrent == null) return null;
    final volume = torrent.volume_factor?.trim();
    final download = torrent.downloadvolumefactor;
    if ((download != null && download == 0) ||
        (volume != null && volume.contains('免费'))) {
      return '免费';
    }
    if (download != null && download < 1) {
      return '优惠';
    }
    if (volume != null && volume.isNotEmpty) return volume;
    return '普通';
  }

  String? _qualityLabel(SearchResultItem item) {
    final meta = item.meta_info;
    final quality = meta?.resource_type ?? meta?.edition;
    return quality?.trim().isEmpty ?? true ? null : quality;
  }

  int _seeders(SearchResultItem item) => item.torrent_info?.seeders ?? 0;

  double _size(SearchResultItem item) => item.torrent_info?.size ?? 0;

  DateTime _pubdate(SearchResultItem item) {
    final raw = item.torrent_info?.pubdate;
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      return _dateFormat.parseUtc(raw).toLocal();
    } catch (_) {
      try {
        return _dateFormat.parse(raw);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }

  Set<String> _filterSet(SearchResultFilterType type) {
    switch (type) {
      case SearchResultFilterType.site:
        return selectedSites.value.toSet();
      case SearchResultFilterType.season:
        return selectedSeasons.value.toSet();
      case SearchResultFilterType.promotion:
        return selectedPromotions.value.toSet();
      case SearchResultFilterType.videoEncode:
        return selectedVideoEncodes.value.toSet();
      case SearchResultFilterType.quality:
        return selectedQualities.value.toSet();
      case SearchResultFilterType.resolution:
        return selectedResolutions.value.toSet();
      case SearchResultFilterType.team:
        return selectedTeams.value.toSet();
    }
  }

  void _assignFilter(SearchResultFilterType type, Set<String> value) {
    switch (type) {
      case SearchResultFilterType.site:
        selectedSites.value = value;
        break;
      case SearchResultFilterType.season:
        selectedSeasons.value = value;
        break;
      case SearchResultFilterType.promotion:
        selectedPromotions.value = value;
        break;
      case SearchResultFilterType.videoEncode:
        selectedVideoEncodes.value = value;
        break;
      case SearchResultFilterType.quality:
        selectedQualities.value = value;
        break;
      case SearchResultFilterType.resolution:
        selectedResolutions.value = value;
        break;
      case SearchResultFilterType.team:
        selectedTeams.value = value;
        break;
    }
  }
}

import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/sse_client.dart';

enum SearchType { media, title }

class SearchMediaController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final searchText = ''.obs;
  var mediaSearchKey = '';
  var mtype = '电影';
  var area = 'title';
  var year = '';
  String? season;
  var sites = <int>[];
  late SearchType searchType;

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
  }

  void toggleSortDirection() {
    sortDirection.value = sortDirection.value == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
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

    isLoading.value = true;
    errorText.value = null;

    // 开始进度跟踪
    _startProgressTracking();

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录后再进行搜索';
        isLoading.value = false;
        _stopProgressTracking();
        return;
      }

      // 构建查询参数
      final queryParameters = <String, dynamic>{
        'mtype': mtype,
        'area': area,
        if (searchText.value.isNotEmpty) 'title': searchText.value,
        if (year.isNotEmpty) 'year': year,
        'sites': sites.join(','),
        'keyword': searchText.value,
      };

      if (season != null && season!.isNotEmpty && season != '0') {
        queryParameters['season'] = season!;
      }
      final endpoint = switch (searchType) {
        SearchType.media => '/api/v1/search/media/$mediaSearchKey',
        SearchType.title => '/api/v1/search/title',
      };
      final response = await _apiClient.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        token: token,
        timeout: 60 * max(sites.length, 1),
      );

      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        isLoading.value = false;
        _stopProgressTracking();
        return;
      }

      final raw = response.data;
      final list = _extractList(raw);
      items
        ..clear()
        ..addAll(
          list.whereType<Map<String, dynamic>>().map(SearchResultItem.fromJson),
        );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '搜索失败');
      errorText.value = '请求失败，请稍后重试 $e';
    } finally {
      isLoading.value = false;
      // 延迟停止进度跟踪，让用户看到完成状态
      final sessionId = _progressSessionId;
      Future.delayed(const Duration(seconds: 1), () {
        _stopProgressTracking(sessionId: sessionId);
      });
    }
  }

  /// 开始 SSE 进度跟踪
  void _startProgressTracking() async {
    _stopProgressTracking();

    final baseUrl = _apiClient.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _log.warning('Cannot start progress tracking: baseUrl is null');
      return;
    }

    _log.info('Starting search progress tracking via SSE');
    _log.info('SSE baseUrl: $baseUrl, endpoint: $_progressPath');

    // 重置进度状态
    isProgressActive.value = true;
    searchProgress.value = 0.0;
    progressMessage.value = '正在搜索...';
    progressStatus.value = 'searching';
    progressCurrent.value = 0;
    progressTotal.value = 0;
    progressSource.value = '';

    _progressSessionId++;
    final sessionId = _progressSessionId;

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
      _sseSubscription = _sseClient!.connect(_progressPath).listen(
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
      progressCurrent.value = event.data!['current'] as int? ?? progressCurrent.value;
      progressTotal.value = event.data!['total'] as int? ?? progressTotal.value;
      progressSource.value = event.data!['source']?.toString() ?? progressSource.value;
    }

    _log.info(
      'Search progress: ${(event.progress * 100).toStringAsFixed(1)}% - ${event.status} - ${event.message}',
    );

    // 如果进度已完成，延迟停止跟踪
    if (event.isCompleted) {
      final sessionId = _progressSessionId;
      Future.delayed(const Duration(seconds: 2), () {
        _stopProgressTracking(sessionId: sessionId);
      });
    }
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
  void onReady() {
    super.onReady();
    performSearch();
  }

  @override
  void onClose() {
    _stopProgressTracking();
    super.onClose();
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
    final freedate = torrent.freedate;
    if ((download != null && download == 0) ||
        (volume != null && volume.contains('免费')) ||
        (freedate != null && freedate.isNotEmpty)) {
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

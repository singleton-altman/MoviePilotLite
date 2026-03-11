import 'dart:async';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/sse_client.dart';

class MediaSearchListController extends GetxController {
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

  final RxString keyword = ''.obs;
  final RxList<RecommendApiItem> items = <RecommendApiItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final RxBool hasMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxnInt totalItems = RxnInt();
  final RxnInt totalPages = RxnInt();
  final RxnInt pageSize = RxnInt();

  // SSE 进度跟踪相关
  final RxBool isProgressActive = false.obs;
  final RxDouble searchProgress = 0.0.obs;
  final RxString progressMessage = ''.obs;
  final RxString progressStatus = ''.obs; // 'searching', 'completed', 'failed'
  final RxInt progressCurrent = 0.obs;
  final RxInt progressTotal = 0.obs;
  final RxString progressSource = ''.obs;

  SseClient? _sseClient;
  StreamSubscription<SseEvent>? _sseSubscription;

  static const _basePath = '/api/v1/media/search';
  static const _progressPath = '/api/v1/system/progress/search';

  @override
  void onReady() {
    super.onReady();
    if (keyword.value.isNotEmpty) {
      search(keyword: keyword.value);
    }
  }

  @override
  void onClose() {
    _stopProgressTracking();
    super.onClose();
  }

  Future<void> search({String? keyword}) async {
    final term = (keyword ?? this.keyword.value).trim();
    if (term.isEmpty) {
      error.value = '请输入搜索关键字';
      items.clear();
      hasMore.value = false;
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
    isLoading.value = true;
    error.value = null;

    // 开始进度跟踪
    _startProgressTracking();

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        error.value = '请先登录后再尝试搜索';
        isLoading.value = false;
        _stopProgressTracking();
        return;
      }
      final params = {'title': term, 'type': type, 'page': page};

      final response = await _apiClient.get<dynamic>(
        _basePath,
        token: token,
        timeout: 30,
        queryParameters: params,
      );
      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        error.value = '登录已过期，请重新登录';
        isLoading.value = false;
        _stopProgressTracking();
        return;
      }
      if (status >= 400) {
        error.value = '请求失败 (HTTP $status)';
        isLoading.value = false;
        _stopProgressTracking();
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
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '媒体搜索失败');
      error.value = '搜索失败，请稍后重试';
    } finally {
      isLoading.value = false;
      // 延迟停止进度跟踪，让用户看到完成状态
      Future.delayed(const Duration(seconds: 1), () {
        _stopProgressTracking();
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
  void _stopProgressTracking() {
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

    // 如果进度已完成，延迟停止跟踪
    if (event.isCompleted) {
      Future.delayed(const Duration(seconds: 2), () {
        _stopProgressTracking();
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
}

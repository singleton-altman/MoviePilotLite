import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subtitle/models/subtitle_search_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubtitleSearchController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  ServerApiVersionService get _serverApiVersionService =>
      Get.find<ServerApiVersionService>();

  var mediaSearchKey = '';
  var mtype = '电影';
  var title = '';
  var year = '';
  String? season;
  var sites = <int>[];
  String? prefillTitle;
  String? prefillBackdrop;

  final items = <SubtitleSearchItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final progressMessage = ''.obs;
  final searchProgress = 0.0.obs;
  final isProgressActive = false.obs;
  final downloadingKeys = <String>{}.obs;

  StreamSubscription<String>? _subscription;
  int _sessionId = 0;

  @override
  void onReady() {
    super.onReady();
    unawaited(startSearch());
  }

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    super.onClose();
  }

  Future<void> startSearch() async {
    if (mediaSearchKey.trim().isEmpty) {
      errorText.value = '缺少媒体标识';
      return;
    }
    if (sites.isEmpty) {
      errorText.value = '请至少选择一个站点';
      return;
    }

    await _subscription?.cancel();
    _subscription = null;
    _sessionId++;
    final sessionId = _sessionId;

    items.clear();
    errorText.value = null;
    isLoading.value = true;
    isProgressActive.value = true;
    searchProgress.value = 0;
    progressMessage.value = '正在搜索字幕...';

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录后再搜索字幕';
        isLoading.value = false;
        isProgressActive.value = false;
        return;
      }

      final query = <String, String>{
        'mtype': mtype,
        'title': title,
        'year': year,
        'sites': sites.join(','),
      };
      final seasonValue = season?.trim();
      if (seasonValue != null && seasonValue.isNotEmpty && seasonValue != '0') {
        query['season'] = seasonValue;
      }
      final identity = MediaIdentity.parse(mediaSearchKey);
      final useV3 = identity != null && await _serverApiVersionService.isV3();
      if (useV3) query['media_source'] = identity.source;
      final requestMediaId = useV3 ? identity.id : mediaSearchKey;

      // 无媒体标识（纯标题关键词）时走标题模糊搜索端点（keyword 参数），
      // 有标识时走媒体精确搜索端点（v2 前缀标识 / v3 media_source）。
      final String path;
      if (identity == null) {
        final titleQuery = <String, String>{
          'keyword': title.trim().isNotEmpty ? title.trim() : mediaSearchKey,
          if (query['sites']?.isNotEmpty == true) 'sites': query['sites']!,
        };
        path =
            '/api/v1/search/subtitle/title/stream?${Uri(queryParameters: titleQuery).query}';
      } else {
        path =
            '/api/v1/search/subtitle/media/$requestMediaId/stream'
            '?${Uri(queryParameters: query).query}';
      }

      final stream = await _apiClient.streamLines(path, token: token);
      _subscription = stream.listen(
        (line) {
          if (sessionId != _sessionId) return;
          _handleLine(line);
        },
        onError: (Object e, StackTrace st) {
          if (sessionId != _sessionId) return;
          _log.handle(e, stackTrace: st, message: '字幕搜索 SSE 失败');
          errorText.value = '搜索失败，请稍后重试';
          isLoading.value = false;
          isProgressActive.value = false;
        },
        onDone: () {
          if (sessionId != _sessionId) return;
          isLoading.value = false;
          isProgressActive.value = false;
          if (progressMessage.value.trim().isEmpty) {
            progressMessage.value = '搜索完成，共 ${items.length} 个字幕';
          }
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '字幕搜索失败');
      errorText.value = '搜索失败，请稍后重试';
      isLoading.value = false;
      isProgressActive.value = false;
    }
  }

  void _handleLine(String line) {
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

    switch (type) {
      case 'append':
        _appendItems(_extractItems(json['items']));
        break;
      case 'replace':
        items
          ..clear()
          ..addAll(_extractItems(json['items']));
        break;
      case 'progress':
        break;
      case 'done':
        isLoading.value = false;
        isProgressActive.value = false;
        unawaited(_subscription?.cancel());
        _subscription = null;
        break;
      default:
        final fallback = _extractItems(json['items']);
        if (fallback.isNotEmpty) {
          _appendItems(fallback);
        }
    }
  }

  List<SubtitleSearchItem> _extractItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SubtitleSearchItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _appendItems(List<SubtitleSearchItem> next) {
    if (next.isEmpty) return;
    final existing = items.map((e) => e.key).toSet();
    for (final item in next) {
      if (existing.add(item.key)) {
        items.add(item);
      }
    }
  }

  Future<bool> downloadSubtitle(
    SubtitleSearchItem item, {
    String? savePath,
  }) async {
    final key = item.key;
    if (downloadingKeys.contains(key)) return false;
    downloadingKeys.add(key);
    downloadingKeys.refresh();
    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        ToastUtil.error('请先登录');
        return false;
      }

      final normalizedPath = savePath?.trim();
      final response = await _apiClient.post<dynamic>(
        '/api/v1/download/subtitle',
        data: {
          'subtitle_in': item.raw,
          'save_path': (normalizedPath == null || normalizedPath.isEmpty)
              ? null
              : normalizedPath,
        },
        token: token,
      );
      final status = response.statusCode ?? 0;
      final data = response.data;
      if (status == 200 || status == 201) {
        final failed = data is Map && data['success'] == false;
        if (!failed) {
          final message = data is Map
              ? (data['message']?.toString() ?? '').trim()
              : '';
          ToastUtil.success(message.isEmpty ? '字幕下载任务已创建' : message);
          return true;
        }
        final message = data['message']?.toString() ??
            data['detail']?.toString() ??
            '下载失败';
        ToastUtil.error(message);
        return false;
      }
      ToastUtil.error('下载失败 (HTTP $status)');
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '字幕下载失败');
      ToastUtil.error('下载失败，请稍后重试');
      return false;
    } finally {
      downloadingKeys.remove(key);
      downloadingKeys.refresh();
    }
  }
}

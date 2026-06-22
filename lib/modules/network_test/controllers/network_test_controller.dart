import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

enum NetworkTestStatus { idle, testing, ok, error }

class NetworkTestItem {
  NetworkTestItem({
    required this.id,
    required this.targetId,
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
    this.proxy = true,
    this.status = NetworkTestStatus.idle,
    this.latencyMs,
    this.statusCode,
    this.error,
    this.lastCheckedAt,
  });

  final String id;
  final String targetId;
  final String title;
  final String url;
  final Widget icon;
  final Color color;
  final bool proxy;

  NetworkTestStatus status;
  int? latencyMs;
  int? statusCode;
  String? error;
  DateTime? lastCheckedAt;
}

class NetTestResult {
  const NetTestResult({this.success, this.timeMs, this.message});

  final bool? success;
  final int? timeMs;
  final String? message;
}

class NetworkTestController extends GetxController {
  final _log = Get.find<AppLog>();
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();

  final isTestingAll = false.obs;
  final lastRunAt = Rxn<DateTime>();
  final items = <NetworkTestItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    items.assignAll(_buildDefaultTargets());
  }

  @override
  void onReady() {
    super.onReady();
    runAll();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> runAll() async {
    if (isTestingAll.value) return;
    isTestingAll.value = true;
    try {
      await Future.wait(items.map(testItem));
      lastRunAt.value = DateTime.now();
    } finally {
      isTestingAll.value = false;
    }
  }

  Future<void> testItem(NetworkTestItem item) async {
    if (item.status == NetworkTestStatus.testing) return;
    _updateItem(item, (target) {
      target.status = NetworkTestStatus.testing;
      target.latencyMs = null;
      target.statusCode = null;
      target.error = null;
    });

    try {
      final token =
          _apiClient.token ?? _appService.latestLoginProfileAccessToken;
      if (token == null || token.isEmpty) {
        _failItem(item, '缺少 Token，请重新登录');
        return;
      }

      final baseUrl = _apiClient.baseUrl ?? '';
      if (baseUrl.isEmpty) {
        _failItem(item, '未配置服务器地址');
        return;
      }

      final uri = Uri(
        path: '/api/v1/system/nettest',
        queryParameters: {
          'url': item.url,
          'proxy': item.proxy ? 'true' : 'false',
          'target_id': item.targetId,
        },
      );

      final response = await _apiClient.get<dynamic>(
        uri.toString(),
        token: token,
      );
      final statusCode = response.statusCode ?? 0;
      final result = _parseNetTestResponse(response.data);

      if (statusCode >= 400) {
        _failItem(item, 'HTTP $statusCode', statusCode: statusCode);
        return;
      }

      if (result.success != true) {
        _failItem(item, result.message ?? '检测失败', statusCode: statusCode);
        return;
      }

      if (result.timeMs == null) {
        _failItem(item, '响应缺少耗时', statusCode: statusCode);
        return;
      }

      _updateItem(item, (target) {
        target.status = NetworkTestStatus.ok;
        target.latencyMs = result.timeMs;
        target.statusCode = statusCode;
        target.error = null;
        target.lastCheckedAt = DateTime.now();
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '网络测试异常: ${item.title}');
      _failItem(item, '请求异常');
    }
  }

  void _failItem(NetworkTestItem item, String message, {int? statusCode}) {
    _updateItem(item, (target) {
      target.status = NetworkTestStatus.error;
      target.latencyMs = null;
      target.statusCode = statusCode;
      target.error = message;
      target.lastCheckedAt = DateTime.now();
    });
  }

  void _updateItem(
    NetworkTestItem item,
    void Function(NetworkTestItem target) update,
  ) {
    update(item);
    items.refresh();
  }

  NetTestResult _parseNetTestResponse(dynamic data) {
    final payload = _decodeToMap(data);
    if (payload == null) {
      return const NetTestResult(message: '响应解析失败');
    }

    final success = payload['success'];
    final message = payload['message'];
    int? timeMs;
    final inner = payload['data'];
    if (inner is Map) {
      timeMs = _parseInt(inner['time']);
    }

    return NetTestResult(
      success: success == true,
      timeMs: timeMs,
      message: message?.toString(),
    );
  }

  Map<String, dynamic>? _decodeToMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<NetworkTestItem> _buildDefaultTargets() {
    return [
      NetworkTestItem(
        id: 'tmdb_api',
        targetId: 'tmdb_api',
        title: 'api.themoviedb.org',
        url: _normalizeUrl(
          'https://api.themoviedb.org/3/movie/550?api_key={TMDBAPIKEY}',
        ),
        icon: Assets.images.logos.tmdb.image(width: 22, height: 22),
        color: const Color(0xFF01B4E4),
      ),
      NetworkTestItem(
        id: 'tmdb_api_alt',
        targetId: 'tmdb_api_alt',
        title: 'api.tmdb.org',
        url: _normalizeUrl(
          'https://api.tmdb.org/3/movie/550?api_key={TMDBAPIKEY}',
        ),
        icon: Assets.images.logos.tmdb.image(width: 22, height: 22),
        color: const Color(0xFF01B4E4),
      ),
      NetworkTestItem(
        id: 'tmdb_web',
        targetId: 'tmdb_web',
        title: 'www.themoviedb.org',
        url: _normalizeUrl('www.themoviedb.org'),
        icon: Assets.images.logos.tmdb.image(width: 22, height: 22),
        color: const Color(0xFF01B4E4),
      ),
      NetworkTestItem(
        id: 'tvdb_api',
        targetId: 'tvdb_api',
        title: 'api.thetvdb.com',
        url: _normalizeUrl('https://api.thetvdb.com/series/81189'),
        icon: Assets.images.logos.thetvdb.image(width: 22, height: 22),
        color: const Color(0xFF1DB954),
      ),
      NetworkTestItem(
        id: 'fanart_api',
        targetId: 'fanart_api',
        title: 'webservice.fanart.tv',
        url: _normalizeUrl('webservice.fanart.tv'),
        icon: Assets.images.logos.fanart.image(width: 22, height: 22),
        color: const Color(0xFF0094FF),
      ),
      NetworkTestItem(
        id: 'telegram_api',
        targetId: 'telegram_api',
        title: 'api.telegram.org',
        url: _normalizeUrl('api.telegram.org'),
        icon: Assets.images.logos.telegram.image(width: 22, height: 22),
        color: const Color(0xFF27A7E7),
      ),
      NetworkTestItem(
        id: 'wechat_api',
        targetId: 'wechat_api',
        title: 'qyapi.weixin.qq.com',
        url: _normalizeUrl('https://qyapi.weixin.qq.com/cgi-bin/gettoken'),
        icon: Assets.images.logos.wechat.image(width: 22, height: 22),
        color: const Color(0xFF07C160),
        proxy: false,
      ),
      NetworkTestItem(
        id: 'douban_api',
        targetId: 'douban_api',
        title: 'frodo.douban.com',
        url: _normalizeUrl('frodo.douban.com'),
        icon: Assets.images.logos.douban.image(width: 22, height: 22),
        color: const Color(0xFF1F7A1F),
        proxy: false,
      ),
      NetworkTestItem(
        id: 'slack_api',
        targetId: 'slack_api',
        title: 'slack.com',
        url: _normalizeUrl('slack.com'),
        icon: Assets.images.logos.slack.image(width: 22, height: 22),
        color: const Color(0xFF4A154B),
      ),
      NetworkTestItem(
        id: 'pip_proxy',
        targetId: 'pip_proxy',
        title: 'pypi.org',
        url: _normalizeUrl('pypi.org'),
        icon: Assets.images.logos.python.image(width: 22, height: 22),
        color: const Color(0xFF3776AB),
      ),
      NetworkTestItem(
        id: 'github_proxy_web',
        targetId: 'github_proxy_web',
        title: 'github.com',
        url: _normalizeUrl('github.com'),
        icon: Assets.images.logos.github.image(width: 22, height: 22),
        color: const Color(0xFF24292E),
      ),
      NetworkTestItem(
        id: 'github_codeload',
        targetId: 'github_codeload',
        title: 'codeload.github.com',
        url: _normalizeUrl('codeload.github.com'),
        icon: Assets.images.logos.github.image(width: 22, height: 22),
        color: const Color(0xFF24292E),
      ),
      NetworkTestItem(
        id: 'github_api',
        targetId: 'github_api',
        title: 'api.github.com',
        url: _normalizeUrl('api.github.com'),
        icon: Assets.images.logos.github.image(width: 22, height: 22),
        color: const Color(0xFF24292E),
      ),
      NetworkTestItem(
        id: 'github_proxy_raw',
        targetId: 'github_proxy_raw',
        title: 'raw.githubusercontent.com',
        url: _normalizeUrl('raw.githubusercontent.com'),
        icon: Assets.images.logos.github.image(width: 22, height: 22),
        color: const Color(0xFF24292E),
      ),
    ];
  }

  String _normalizeUrl(String input) {
    final value = input.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }
}

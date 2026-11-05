// 订阅执行可观测仓库：v3 专有端点的请求封装。
//
// 契约依据 v3 服务端 app/api/endpoints/subexecution.py（挂载于 /api/v1/subscribe）：
// - GET  /{id}/activity           history/kind/before(cursor)/limit，返回 items + next_cursor
// - GET  /{id}/activity/{eventId} history，返回完整活动明细
// - GET  /execution/batches       limit，返回批次状态列表
// - PUT  /execution/batches/{id}/cancel
// - GET  /{id}/logs               length(-1=全部,1~600)；-1 返回纯文本，
//                                 其余返回 SSE 尾随流（先发历史尾部再持续跟随）

import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';

class SubscribeExecutionRepository {
  SubscribeExecutionRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;
  AppLog get _log => Get.find<AppLog>();

  /// 拉取一页订阅活动（游标分页：before 传上一页 next_cursor）
  Future<SubscriptionActivityPage> fetchActivity(
    int subscribeId, {
    required bool history,
    String? kind,
    String? before,
    int limit = 30,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/$subscribeId/activity',
      queryParameters: {
        'history': history,
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (before != null && before.isNotEmpty) 'before': before,
        'limit': limit,
      },
    );
    _ensureOk(response.statusCode, '获取订阅活动', response.data);
    return SubscriptionActivityPage.fromJson(response.data);
  }

  /// 拉取活动完整明细
  Future<SubscriptionActivityEvent> fetchActivityEvent(
    int subscribeId,
    String eventId, {
    required bool history,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/$subscribeId/activity/$eventId',
      queryParameters: {'history': history},
    );
    _ensureOk(response.statusCode, '获取活动详情', response.data);
    final data = response.data;
    if (data is! Map) {
      throw StateError('活动详情返回格式错误');
    }
    return SubscriptionActivityEvent.fromJson(Map<String, dynamic>.from(data));
  }

  /// 拉取最近的搜索批次
  Future<List<SubscriptionBatchStatus>> fetchBatches({int limit = 10}) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/execution/batches',
      queryParameters: {'limit': limit},
    );
    _ensureOk(response.statusCode, '获取搜索批次', response.data);
    final data = response.data;
    final batches = <SubscriptionBatchStatus>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          batches.add(
            SubscriptionBatchStatus.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return batches;
  }

  /// 请求取消一轮尚未越过下载边界的搜索批次
  Future<({bool ok, String message})> cancelBatch(String batchId) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/subscribe/execution/batches/$batchId/cancel',
        null,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return (ok: false, message: '停止搜索失败 (HTTP $status)');
      }
      final data = response.data;
      final ok = data is Map && data['success'] == true;
      final message = data is Map ? data['message']?.toString() ?? '' : '';
      return (
        ok: ok,
        message: message.isNotEmpty
            ? message
            : ok
            ? '已请求停止'
            : '停止搜索失败，请稍后重试',
      );
    } catch (e) {
      _log.handle(e, message: '停止搜索批次异常');
      return (ok: false, message: '停止搜索失败，请稍后重试');
    }
  }

  /// 拉取订阅执行日志快照。
  ///
  /// length >= 1 时服务端是 SSE 尾随流（先发历史尾部，随后每 0.5s 一轮心跳），
  /// 移动端按「快照 + 手动刷新」消费：收到尾部后的首个心跳即断开；
  /// 3 秒兜底超时防止日志尚未生成时空等。
  /// length = -1 时服务端返回整份纯文本（按旧语义倒序，最新在前），本地翻转回时间正序。
  Future<String> fetchLogs(int subscribeId, {required int length}) async {
    if (length < 0) {
      final response = await _apiClient.get<String>(
        '/api/v1/subscribe/$subscribeId/logs',
        queryParameters: {'length': -1},
        skipV3EnvelopeUnwrap: true,
      );
      _ensureOk(response.statusCode, '获取运行日志', response.data);
      final text = response.data ?? '';
      final lines = text.split('\n');
      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }
      return lines.reversed.join('\n');
    }
    return _fetchLogTailSnapshot(subscribeId, length);
  }

  Future<String> _fetchLogTailSnapshot(int subscribeId, int length) async {
    final lines = <String>[];
    final done = Completer<void>();
    StreamSubscription<String>? sub;
    Timer? guard;
    // SSE 单事件可能由多个 data: 行组成（多行日志），以空行作为事件边界
    StringBuffer? dataBuffer;
    var sawData = false;

    void finishEvent() {
      if (dataBuffer != null) {
        lines.add(dataBuffer.toString());
        dataBuffer = null;
        sawData = true;
      }
    }

    void complete() {
      if (!done.isCompleted) done.complete();
    }

    try {
      final stream = await _apiClient.streamLines(
        '/api/v1/subscribe/$subscribeId/logs?length=$length',
      );
      sub = stream.listen(
        (line) {
          if (done.isCompleted) return;
          if (line.isEmpty) {
            finishEvent();
            return;
          }
          if (line.startsWith(':')) {
            // 心跳注释帧：说明本轮尾部已发完，可安全断开
            finishEvent();
            if (sawData) {
              guard?.cancel();
              sub?.cancel();
              complete();
            }
            return;
          }
          if (line.startsWith('data:')) {
            final value = line.substring(5);
            (dataBuffer ??= StringBuffer())
                ..write(value.startsWith(' ') ? value.substring(1) : value)
                ..write('\n');
            return;
          }
          // 兜底：个别代理可能剥离 SSE 帧，直接回传纯文本
          lines.add(line);
          sawData = true;
        },
        onError: (Object e, StackTrace st) {
          _log.handle(e, stackTrace: st, message: '订阅日志流异常');
          complete();
        },
        onDone: complete,
      );
      guard = Timer(const Duration(seconds: 3), () {
        sub?.cancel();
        complete();
      });
      await done.future;
    } finally {
      guard?.cancel();
      await sub?.cancel();
    }
    // data: 拼装时补的分隔符要去掉末尾多余换行
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].endsWith('\n')) {
        lines[i] = lines[i].substring(0, lines[i].length - 1);
      }
    }
    return lines.join('\n');
  }

  void _ensureOk(int? status, String action, [dynamic body]) {
    final code = status ?? 0;
    if (code < 200 || code >= 300) {
      final authFailure = ApiAuthFailure.from(code, body);
      if (authFailure.isAuthFailure) {
        throw ApiAuthException(code, '$action失败：${authFailure.message}');
      }
      final reason = ApiAuthFailure.extractReason(body);
      throw StateError(reason ?? '$action失败 (HTTP $code)');
    }
  }
}

/// 活动详情等场景里 details 值的展示文本；结构化值以缩进 JSON 呈现
String subscribeExecutionDetailValueText(Object? value) {
  if (value == null) return '未设置';
  if (value is String) return value.isEmpty ? '未设置' : value;
  if (value is num || value is bool) return '$value';
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return '$value';
  }
}

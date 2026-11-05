import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// Contracts checked against MoviePilot v2 and v3.1.5 transfer/history endpoints.
/// These endpoints return objects in Response.data, never directory/history lists.
class TransferAssistService extends GetxService {
  TransferAssistService({ApiClient? apiClient, AppLog? log})
    : _apiClient = apiClient ?? Get.find<ApiClient>(),
      _log = log ?? Get.find<AppLog>();

  final ApiClient _apiClient;
  final AppLog _log;

  static const aiRedoEndpoint = '/api/v1/history/transfer/ai-redo';

  /// Check the actual server contract instead of treating all v2/v3 builds alike.
  /// Unknown/unreachable/disabled OpenAPI means no optional destructive action.
  Future<bool> supportsAiRedo() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/openapi.json',
        timeout: 10,
        skipV3EnvelopeUnwrap: true,
      );
      if (response.statusCode != 200 || response.data is! Map) return false;
      final paths = response.data['paths'];
      final operation = paths is Map ? paths[aiRedoEndpoint] : null;
      return operation is Map && operation['post'] is Map;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _parse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw FormatException('请求失败 (HTTP $status)');
    }
    final raw = response.data;
    // ApiClient retains success/message/data when unwrapping a v3 object.
    if (raw is! Map || raw['success'] is! bool) {
      throw const FormatException('服务端响应格式异常');
    }
    if (raw['success'] != true) {
      final message = raw['message']?.toString().trim() ?? '';
      throw FormatException(message.isEmpty ? '服务端未接受请求' : message);
    }
    if (raw['data'] is! Map) {
      throw const FormatException('服务端响应数据格式异常');
    }
    return Map<String, dynamic>.from(raw['data'] as Map);
  }

  String _error(Object error, StackTrace stackTrace, String label) {
    _log.handle(error, stackTrace: stackTrace, message: label);
    return error is FormatException ? error.message.toString() : '$label，请稍后重试';
  }

  /// POST ManualTransferItem -> ManualTransferTargetPath in the response data.
  Future<({bool ok, String? message, Map<String, dynamic>? target})>
  matchTargetPath({
    required Map<String, dynamic> fileitem,
    String? targetStorage,
  }) async {
    try {
      final data = _parse(
        await _apiClient.post<dynamic>(
          '/api/v1/transfer/manual/target-path',
          data: {
            'fileitem': fileitem,
            if (targetStorage?.isNotEmpty == true)
              'target_storage': targetStorage,
          },
        ),
      );
      if ((data['target_path'] != null && data['target_path'] is! String) ||
          (data['target_storage'] != null &&
              data['target_storage'] is! String) ||
          (data['transfer_type'] != null && data['transfer_type'] is! String) ||
          [
            'scrape',
            'library_type_folder',
            'library_category_folder',
          ].any((key) => data[key] != null && data[key] is! bool)) {
        throw const FormatException('目标路径响应格式异常');
      }
      return (ok: true, message: null, target: data);
    } catch (e, st) {
      return (ok: false, message: _error(e, st, '匹配目的路径失败'), target: null);
    }
  }

  /// POST EpisodeFormatRecommendItem -> EpisodeFormatRecommendData in the response data.
  Future<({bool ok, String? message, Map<String, dynamic>? recommendation})>
  recommendEpisodeFormat(Map<String, dynamic> fileitem) async {
    try {
      final data = _parse(
        await _apiClient.post<dynamic>(
          '/api/v1/transfer/episode-format/recommend',
          data: {'fileitem': fileitem},
          timeout: 120,
        ),
      );
      if (data['episode_format'] is! String ||
          (data['episode_format'] as String).trim().isEmpty ||
          data['rule_name'] is! String ||
          data['sample_file'] is! String) {
        throw const FormatException('集数推荐响应格式异常');
      }
      return (ok: true, message: null, recommendation: data);
    } catch (e, st) {
      return (
        ok: false,
        message: _error(e, st, '推荐集数模板失败'),
        recommendation: null,
      );
    }
  }

  /// POST ManualTransferItem -> ManualTransferHistoryInfo in the response data.
  Future<({bool ok, String? message, int? historyCount, bool reorganize})>
  fetchManualHistory(Map<String, dynamic> fileitem) async {
    try {
      final data = _parse(
        await _apiClient.post<dynamic>(
          '/api/v1/transfer/manual/history',
          data: {'fileitem': fileitem},
        ),
      );
      if (data['history_count'] is! int ||
          (data['history_count'] as int) < 0 ||
          data['reorganize'] is! bool) {
        throw const FormatException('整理历史摘要格式异常');
      }
      return (
        ok: true,
        message: null,
        historyCount: data['history_count'] as int,
        reorganize: data['reorganize'] as bool,
      );
    } catch (e, st) {
      return (
        ok: false,
        message: _error(e, st, '查询整理历史失败'),
        historyCount: null,
        reorganize: false,
      );
    }
  }

  /// Submission is not completion; retain the server's progress key for callers.
  Future<({bool ok, String message, String? progressKey})> aiRedoTransfer(
    List<int> historyIds,
  ) async {
    final ids = historyIds.toSet().toList(growable: false);
    if (ids.isEmpty || ids.any((id) => id <= 0)) {
      return (ok: false, message: '请选择有效的整理记录', progressKey: null);
    }
    try {
      final response = await _apiClient.post<dynamic>(
        aiRedoEndpoint,
        data: {'history_ids': ids},
      );
      final data = _parse(response);
      final key = data['progress_key'];
      if (key is! String || key.trim().isEmpty) {
        throw const FormatException('提交回执缺少进度标识，请检查服务端任务后再重试');
      }
      final message = response.data['message']?.toString().trim() ?? '';
      return (
        ok: true,
        message: message.isEmpty ? '已提交 AI 重新整理，请在整理历史中查看结果' : message,
        progressKey: key,
      );
    } catch (e, st) {
      return (
        ok: false,
        message: _error(e, st, '提交 AI 重新整理失败'),
        progressKey: null,
      );
    }
  }
}

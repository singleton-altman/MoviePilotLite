import 'dart:convert';

import 'package:moviepilot_mobile/modules/dynamic_form/models/brush_flow_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class BrushFlowService {
  BrushFlowService(this._apiClient);

  static const pluginId = 'BrushFlow';
  static const basePath = '/api/v1/plugin/BrushFlow';

  final ApiClient _apiClient;

  Future<BrushFlowStatusData> fetchStatus({String? token}) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/status',
      token: token,
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw BrushFlowApiException('获取状态失败 (HTTP $status)');
    }
    final data = _extractDataMap(response.data);
    if (data == null) {
      throw BrushFlowApiException('状态数据格式错误');
    }
    return BrushFlowStatusData.fromJson(data);
  }

  Future<void> updateSettings({
    required bool enabled,
    required bool showSidebarNav,
    String? token,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '$basePath/settings',
      token: token,
      data: {
        'enabled': enabled,
        'show_sidebar_nav': showSidebarNav,
      },
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw BrushFlowApiException('更新设置失败 (HTTP $status)');
    }
    final map = _asMap(response.data);
    if (map != null && map['success'] == false) {
      final message = map['message']?.toString().trim();
      throw BrushFlowApiException(
        (message != null && message.isNotEmpty) ? message : '更新设置失败',
      );
    }
  }

  Future<BrushFlowTaskDetail> fetchTaskDetail({
    required String taskId,
    String state = 'active',
    int page = 1,
    int pageSize = 50,
    String? token,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/tasks/$taskId',
      token: token,
      queryParameters: {
        'state': state,
        'page': page,
        'page_size': pageSize,
      },
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw BrushFlowApiException('获取任务详情失败 (HTTP $status)');
    }
    final data = _extractDataMap(response.data);
    if (data == null) {
      throw BrushFlowApiException('任务详情数据格式错误');
    }
    return BrushFlowTaskDetail.fromJson(data);
  }

  Future<void> createTask({
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '$basePath/tasks',
      token: token,
      data: body,
    );
    _ensureSuccess(response.statusCode, response.data, '创建任务失败');
  }

  Future<void> updateTask({
    required String taskId,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _apiClient.put<dynamic>(
      '$basePath/tasks/$taskId',
      body,
      token: token,
    );
    _ensureSuccess(response.statusCode, response.data, '更新任务失败');
  }

  Future<void> updateTaskState({
    required String taskId,
    required bool enabled,
    String? token,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '$basePath/tasks/$taskId/state',
      token: token,
      data: {'enabled': enabled},
    );
    _ensureSuccess(
      response.statusCode,
      response.data,
      enabled ? '重启任务失败' : '暂停任务失败',
    );
  }

  Future<void> clearTask({
    required String taskId,
    String? token,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '$basePath/tasks/$taskId/clear',
      token: token,
      data: const <String, dynamic>{},
    );
    _ensureSuccess(response.statusCode, response.data, '清理任务失败');
  }

  Future<void> deleteTask({
    required String taskId,
    String? token,
  }) async {
    final response = await _apiClient.delete<dynamic>(
      '$basePath/tasks/$taskId',
      token: token,
    );
    _ensureSuccess(response.statusCode, response.data, '删除任务失败');
  }

  void _ensureSuccess(int? statusCode, dynamic data, String fallback) {
    final status = statusCode ?? 0;
    if (status >= 400) {
      throw BrushFlowApiException('$fallback (HTTP $status)');
    }
    final map = _asMap(data);
    if (map != null && map['success'] == false) {
      final message = map['message']?.toString().trim();
      throw BrushFlowApiException(
        (message != null && message.isNotEmpty) ? message : fallback,
      );
    }
  }

  Map<String, dynamic>? _extractDataMap(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    if (map.containsKey('data')) {
      final data = map['data'];
      if (data == null) return null;
      return _asMap(data);
    }
    return map;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class BrushFlowApiException implements Exception {
  BrushFlowApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

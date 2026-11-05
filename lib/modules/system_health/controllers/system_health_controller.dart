import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

enum SystemHealthStatus {
  idle,
  checking,
  ok,
  warning,
  error,
  disabled,
  unknown,
}

class SystemHealthItem {
  SystemHealthItem({
    required this.id,
    required this.title,
    this.status = SystemHealthStatus.idle,
    this.detail,
    this.message,
    this.lastCheckedAt,
  });

  final String id;
  final String title;
  SystemHealthStatus status;
  String? detail;
  String? message;
  DateTime? lastCheckedAt;
}

class SystemHealthController extends GetxController {
  SystemHealthController({
    ApiClient? apiClient,
    AppLog? log,
    AppService? appService,
  }) : _apiClient = apiClient ?? Get.find<ApiClient>(),
       _log = log ?? Get.find<AppLog>(),
       _appService = appService ?? Get.find<AppService>();

  static const String _moduleListEndpoint = '/api/v1/system/modulelist';
  static const String _moduleTestEndpointBase = '/api/v1/system/moduletest';

  /// 回退探测仅用 /system/ping:它在 v2/v3 均存在,只表示"服务可达"。
  /// /system/versions 返回的是 GitHub Release 列表,不是健康状态,
  /// 不能当作模块级健康检查结果展示。
  static const String _pingEndpoint = '/api/v1/system/ping';

  final AppLog _log;
  final ApiClient _apiClient;
  final AppService _appService;

  final isLoading = false.obs;
  final lastRunAt = Rxn<DateTime>();
  final errorMessage = RxnString();
  final items = <SystemHealthItem>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchHealth();
  }

  Future<void> fetchHealth() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token =
          _apiClient.token ?? _appService.latestLoginProfileAccessToken;
      if (token == null || token.isEmpty) {
        errorMessage.value = ApiAuthFailure.notLoggedInMessage;
        items.clear();
        return;
      }

      final moduleList = await _fetchModuleList(token);
      if (moduleList.isNotEmpty) {
        items.assignAll(moduleList);
        await _runModuleTests(token);
        lastRunAt.value = DateTime.now();
        return;
      }

      final response = await _requestPing(token);
      if (response == null) {
        errorMessage.value = '无法连接健康检查接口';
        items.clear();
        return;
      }

      final item = _buildPingItem(response);
      items.assignAll([item]);
      if (item.status == SystemHealthStatus.ok) {
        errorMessage.value = null;
        lastRunAt.value = DateTime.now();
      } else if (errorMessage.value == null) {
        errorMessage.value = '服务连通性检查未通过';
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '系统健康检查异常');
      errorMessage.value = '请求异常';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<SystemHealthItem>> _fetchModuleList(String token) async {
    try {
      final response = await _apiClient.get<dynamic>(
        _moduleListEndpoint,
        token: token,
      );
      final payload = _decodePayload(response.data);
      if (payload == null) return const [];
      if (payload['success'] == false) {
        return const [];
      }
      final list = _extractModuleList(payload);
      if (list.isEmpty) return const [];
      return _parseModuleList(list);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取模块列表失败');
      return const [];
    }
  }

  Future<Response<dynamic>?> _requestPing(String token) async {
    try {
      return await _apiClient.get<dynamic>(_pingEndpoint, token: token);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '服务连通性探测失败');
      return null;
    }
  }

  /// 把 ping 响应建模为单条「服务连接」结果。
  /// ping 只证明服务可达:该服务端版本不提供模块级健康检查时,
  /// 不得把结果伪装成全部模块正常。
  SystemHealthItem _buildPingItem(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 0;
    final checkedAt = DateTime.now();
    if (statusCode >= 400) {
      return SystemHealthItem(
        id: 'server-ping',
        title: '服务连接',
        status: SystemHealthStatus.error,
        message: 'HTTP $statusCode',
        lastCheckedAt: checkedAt,
      );
    }
    final payload = _decodePayload(response.data);
    if (payload == null) {
      return SystemHealthItem(
        id: 'server-ping',
        title: '服务连接',
        status: SystemHealthStatus.unknown,
        message: '响应解析失败',
        lastCheckedAt: checkedAt,
      );
    }
    final success = payload['success'];
    final message = payload['message']?.toString();
    if (success is bool && success) {
      return SystemHealthItem(
        id: 'server-ping',
        title: '服务连接',
        status: SystemHealthStatus.ok,
        message: message,
        detail: '该服务端版本不提供模块级健康检查，仅确认服务可达',
        lastCheckedAt: checkedAt,
      );
    }
    if (success is bool) {
      return SystemHealthItem(
        id: 'server-ping',
        title: '服务连接',
        status: SystemHealthStatus.error,
        message:
            (message == null || message.isEmpty) ? '服务返回失败' : message,
        lastCheckedAt: checkedAt,
      );
    }
    return SystemHealthItem(
      id: 'server-ping',
      title: '服务连接',
      status: SystemHealthStatus.unknown,
      message: '响应解析失败',
      lastCheckedAt: checkedAt,
    );
  }

  Future<void> _runModuleTests(String token) async {
    if (items.isEmpty) return;
    for (final item in items) {
      _updateItem(item, (target) {
        target.status = SystemHealthStatus.checking;
        target.message = null;
        target.detail = null;
      });
    }

    var hasFailure = false;
    for (final item in items) {
      final success = await _testModule(item, token);
      if (!success) hasFailure = true;
    }
    if (hasFailure && errorMessage.value == null) {
      errorMessage.value = '部分模块检测失败';
    }
  }

  Future<bool> _testModule(SystemHealthItem item, String token) async {
    try {
      final endpoint =
          '$_moduleTestEndpointBase/${Uri.encodeComponent(item.id)}';
      final response = await _apiClient.get<dynamic>(endpoint, token: token);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        _updateItem(item, (target) {
          target.status = SystemHealthStatus.error;
          target.message = 'HTTP $statusCode';
          target.detail = null;
          target.lastCheckedAt = DateTime.now();
        });
        return false;
      }

      final result = _parseModuleTestResponse(response.data);
      _updateItem(item, (target) {
        target.status = result.status;
        target.message = result.message;
        target.detail = result.detail;
        target.lastCheckedAt = DateTime.now();
      });
      return result.status != SystemHealthStatus.error;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '模块检测失败: ${item.title}');
      _updateItem(item, (target) {
        target.status = SystemHealthStatus.error;
        target.message = '请求异常';
        target.detail = null;
        target.lastCheckedAt = DateTime.now();
      });
      return false;
    }
  }

  List<SystemHealthItem> _parseModuleList(List<dynamic> list) {
    final results = <SystemHealthItem>[];
    for (var i = 0; i < list.length; i += 1) {
      final raw = list[i];
      final map = _toMap(raw);
      if (map == null) {
        final title = raw?.toString() ?? 'module-$i';
        results.add(
          SystemHealthItem(
            id: 'module-$i',
            title: title,
            status: SystemHealthStatus.idle,
          ),
        );
        continue;
      }

      final id = _stringValue(
            map['id'],
            fallback: _stringValue(map['key']),
          ) ??
          'module-$i';
      final title = _stringValue(
            map['name'],
            fallback: _stringValue(map['title'], fallback: id),
          ) ??
          id;

      final enabled = _parseBool(
        map['enabled'] ??
            map['enable'] ??
            map['active'] ??
            map['is_enabled'] ??
            map['isEnabled'],
      );
      final statusValue = map['status'] ??
          map['state'] ??
          map['health'] ??
          map['ok'] ??
          map['success'] ??
          map['result'];

      var status = _mapStatus(statusValue, enabled: enabled);
      if (status == SystemHealthStatus.unknown) {
        status = SystemHealthStatus.idle;
      }

      results.add(
        SystemHealthItem(
          id: id,
          title: title,
          status: status,
        ),
      );
    }
    return results;
  }

  _ModuleTestResult _parseModuleTestResponse(dynamic data) {
    final payload = _decodePayload(data);
    if (payload == null) {
      if (data is String && data.trim().isNotEmpty) {
        final mapped = _mapStatusFromText(data);
        return _ModuleTestResult(
          status: mapped ?? SystemHealthStatus.unknown,
          message: data,
        );
      }
      return const _ModuleTestResult(
        status: SystemHealthStatus.unknown,
        message: '响应解析失败',
      );
    }

    final success = payload['success'];
    final message = payload['message']?.toString();
    final detail = payload['detail']?.toString();

    SystemHealthStatus status;
    if (success is bool) {
      if (success) {
        status = _mapStatusFromText(message) ?? SystemHealthStatus.ok;
      } else {
        // 测试失败就是失败:仅当消息明确表达"未启用"等状态时才归类,
        // 否则一律 error,不能把业务失败伪装成 disabled 或正常。
        final mapped = _mapStatusFromText(message);
        if (mapped == null || mapped == SystemHealthStatus.ok) {
          status = SystemHealthStatus.error;
        } else {
          status = mapped;
        }
      }
    } else {
      status = _mapStatusFromText(message) ?? SystemHealthStatus.unknown;
    }

    return _ModuleTestResult(status: status, message: message, detail: detail);
  }

  void _updateItem(
    SystemHealthItem item,
    void Function(SystemHealthItem target) update,
  ) {
    update(item);
    items.refresh();
  }

  SystemHealthStatus _mapStatus(dynamic status, {bool? enabled}) {
    if (enabled == false) return SystemHealthStatus.disabled;
    if (status is bool) {
      return status ? SystemHealthStatus.ok : SystemHealthStatus.error;
    }
    if (status is num) {
      final value = status.toInt();
      if (value <= -1) return SystemHealthStatus.disabled;
      if (value == 0) return SystemHealthStatus.error;
      if (value == 1) return SystemHealthStatus.ok;
      if (value == 2) return SystemHealthStatus.warning;
      if (value == 3) return SystemHealthStatus.disabled;
    }
    if (status is String) {
      final mapped = _mapStatusFromText(status);
      if (mapped != null) return mapped;
    }
    return SystemHealthStatus.unknown;
  }

  SystemHealthStatus? _mapStatusFromText(String? text) {
    if (text == null) return null;
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return null;
    if (_containsAny(value, ['disabled', 'off', '未启用', '未开启', '禁用'])) {
      return SystemHealthStatus.disabled;
    }
    if (_containsAny(value, ['checking', 'testing', 'pending', '检测'])) {
      return SystemHealthStatus.checking;
    }
    if (_containsAny(value, ['warn', 'warning', 'degraded', '偏慢', '警告'])) {
      return SystemHealthStatus.warning;
    }
    if (_containsAny(value, [
      'error',
      'fail',
      'failed',
      '异常',
      '错误',
      '不可用',
      'down',
    ])) {
      return SystemHealthStatus.error;
    }
    if (_containsAny(value, [
      'ok',
      'normal',
      'healthy',
      'success',
      '正常',
      '运行中',
      'up',
    ])) {
      return SystemHealthStatus.ok;
    }
    return null;
  }

  List<dynamic> _extractModuleList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final modules = data['modules'] ?? data['items'] ?? data['list'];
      if (modules is List) return modules;
    }
    if (data is List) return data;
    final modules = payload['modules'];
    if (modules is List) return modules;
    return const [];
  }

  bool _containsAny(String input, List<String> keys) {
    for (final key in keys) {
      if (input.contains(key.toLowerCase())) return true;
    }
    return false;
  }

  Map<String, dynamic>? _decodePayload(dynamic data) {
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

  Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String? _stringValue(dynamic value, {String? fallback}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return null;
      if (['true', '1', 'yes', 'y', 'on', 'enabled'].contains(normalized)) {
        return true;
      }
      if (['false', '0', 'no', 'n', 'off', 'disabled'].contains(normalized)) {
        return false;
      }
    }
    return null;
  }
}

class _ModuleTestResult {
  const _ModuleTestResult({
    required this.status,
    this.message,
    this.detail,
  });

  final SystemHealthStatus status;
  final String? message;
  final String? detail;
}

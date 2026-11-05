import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// Preferences belong to the authenticated server user, not the device.
/// Deliberately uncached so switching accounts cannot reuse another user's data.
class UserConfigService {
  UserConfigService({ApiClient? apiClient})
    : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;

  Future<Object?> read(String key) async {
    final response = await _apiClient.get<dynamic>(
      _path(key),
      skipV3EnvelopeUnwrap: true,
    );
    final body = _checkedBody(response.statusCode, response.data);
    final data = body['data'];
    if (data is! Map || !data.containsKey('value')) {
      throw const FormatException('用户配置响应缺少 value');
    }
    return data['value'];
  }

  Future<void> write(String key, Object? value) async {
    // The body is the value itself, not {value: ...} (V2 and V3).
    final response = await _apiClient.postJson<dynamic>(_path(key), value);
    _checkedBody(response.statusCode, response.data);
  }

  static String _path(String key) {
    if (key.trim().isEmpty) throw ArgumentError.value(key, 'key');
    return '/api/v1/user/config/${Uri.encodeComponent(key)}';
  }

  static Map _checkedBody(int? status, dynamic raw) {
    if (status == null || status < 200 || status >= 300) {
      throw ApiHttpException(status ?? 0, '用户配置请求失败');
    }
    final body = raw is String ? jsonDecode(raw) : raw;
    if (body is! Map || body['success'] != true) {
      throw StateError(
        body is Map ? '${body['message'] ?? '用户配置请求失败'}' : '用户配置响应无效',
      );
    }
    return body;
  }
}

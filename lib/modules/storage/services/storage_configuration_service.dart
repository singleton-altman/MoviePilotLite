import 'package:dio/dio.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class StorageQrCode {
  const StorageQrCode({this.content, this.imageUrl});
  final String? content;
  final String? imageUrl;
}

class StorageLoginStatus {
  const StorageLoginStatus({required this.complete, required this.tip});
  final bool complete;
  final String tip;
}

/// Contracts verified against v2 storage endpoints and v3.1.5's
/// ManageRequest, StorageAction and FileManagerModule.storage_manage.
class StorageConfigurationService {
  StorageConfigurationService({
    required ApiClient apiClient,
    required Future<bool> Function() isV3,
    required bool Function() canManage,
  }) : _api = apiClient,
       _isV3 = isV3,
       _canManage = canManage;

  final ApiClient _api;
  final Future<bool> Function() _isV3;
  final bool Function() _canManage;

  void _requirePermission() {
    if (!_canManage()) throw StateError('当前帐号无管理权限');
  }

  Future<dynamic> _action(
    String name,
    String legacy,
    String action, {
    Map<String, dynamic> params = const {},
    Map<String, dynamic>? config,
  }) async {
    _requirePermission();
    final v3 = await _isV3();
    _requirePermission();
    final Response<dynamic> response;
    if (v3) {
      response = await _api.postJson<dynamic>('/api/v1/storage/manage', {
        'target': name,
        'action': action,
        'params': config == null ? params : {'conf': config},
      });
    } else if (config != null) {
      response = await _api.postJson<dynamic>(
        '/api/v1/storage/save/${Uri.encodeComponent(name)}',
        config,
      );
    } else {
      response = await _api.get<dynamic>(
        '/api/v1/storage/$legacy/${Uri.encodeComponent(name)}',
        queryParameters: params.isEmpty ? null : params,
        skipV3EnvelopeUnwrap: true,
      );
    }
    final body = _successful(response);
    return body['data'];
  }

  static Map<String, dynamic> _successful(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('请求失败 (HTTP $status)');
    }
    final body = response.data;
    if (body is! Map || body['success'] is! bool) {
      throw const FormatException('服务端响应格式异常');
    }
    if (body['success'] != true) {
      throw StateError(body['message']?.toString() ?? '服务端拒绝了此操作');
    }
    return Map<String, dynamic>.from(body);
  }

  Future<StorageQrCode> acquireQrCode(String name) async {
    final data = await _action(name, 'qrcode', 'generate_qrcode');
    if (data is! Map) throw const FormatException('未返回二维码');
    final content = data['codeContent'];
    final image = data['codeUrl'];
    if (content is String && content.trim().isNotEmpty) {
      return StorageQrCode(content: content);
    }
    if (image is String && _httpUrl(image)) {
      return StorageQrCode(imageUrl: image);
    }
    throw const FormatException('未返回有效二维码');
  }

  Future<String> acquireAuthUrl(String name) async {
    final data = await _action(name, 'auth_url', 'generate_auth_url');
    if (data is! Map ||
        data['authUrl'] is! String ||
        !_httpUrl(data['authUrl'] as String) ||
        data['state'] is! String ||
        (data['state'] as String).isEmpty) {
      throw const FormatException('未返回有效授权地址或授权状态');
    }
    // state remains server-owned; do not invent a state query on check_login.
    return data['authUrl'] as String;
  }

  Future<StorageLoginStatus> checkLogin(
    String name, {
    String? ck,
    String? t,
  }) async {
    final data = await _action(
      name,
      'check',
      'check_login',
      params: {if (ck != null) 'ck': ck, if (t != null) 't': t},
    );
    if (data is! Map ||
        (data['status'] is! String && data['status'] is! int) ||
        data['tip'] is! String) {
      throw const FormatException('登录状态格式异常');
    }
    // Both providers persist tokens themselves. NEVER save status/tip as conf.
    final complete = switch (name) {
      'alipan' => data['status'] == 'LoginSuccess',
      'u115' => data['status'] == 2,
      _ => false,
    };
    return StorageLoginStatus(complete: complete, tip: data['tip'] as String);
  }

  Future<List<StorageSetting>> loadStorages() async {
    _requirePermission();
    final response = await _api.get<dynamic>(
      '/api/v1/system/setting/Storages',
      skipV3EnvelopeUnwrap: true,
    );
    final body = _successful(response);
    final data = body['data'];
    final value = data is Map ? data['value'] : null;
    if (value is! List) throw const FormatException('存储配置格式异常');
    return value.map((raw) {
      if (raw is! Map) throw const FormatException('存储配置格式异常');
      return StorageSetting.fromJson(Map<String, dynamic>.from(raw));
    }).toList();
  }

  Future<StorageSetting> loadStorage(String type) async {
    final matches = (await loadStorages()).where((item) => item.type == type);
    if (matches.length != 1) throw StateError('存储配置已变化，请刷新列表');
    return matches.single;
  }

  Future<void> saveConfiguration(
    StorageSetting original,
    Map<String, dynamic> config,
  ) async {
    _requirePermission();
    if (config.isEmpty ||
        config.containsKey('status') ||
        config.containsKey('tip') ||
        config.containsKey('success')) {
      throw const FormatException('配置不能为空或使用登录状态；清空配置请使用重置');
    }
    // Server replaces the whole config, not a patch. Refuse a stale editor
    // rather than clobber credentials refreshed by OAuth or another client.
    final latest = await loadStorage(original.type);
    if (!_equal(latest.config, original.config)) {
      throw StateError('服务端配置已变化，请关闭编辑器并重新读取后再保存');
    }
    await _action(original.type, 'save', 'save_config', config: config);
  }

  Future<void> reset(String name, {required bool confirmed}) async {
    _requirePermission();
    if (!confirmed) throw StateError('请先确认重置存储配置');
    await _action(name, 'reset', 'reset_config');
  }

  static bool _httpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  static bool _equal(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((key) => b.containsKey(key) && _equal(a[key], b[key]));
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(
            a.length,
            (index) => index,
          ).every((index) => _equal(a[index], b[index]));
    }
    return a == b;
  }
}

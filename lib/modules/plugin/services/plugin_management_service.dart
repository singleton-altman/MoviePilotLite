import 'package:dio/dio.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_folder_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class PluginManagementException implements Exception {
  const PluginManagementException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// V2: app/api/endpoints/plugin.py; V3: pluginfolder.py / pluginclone.py.
/// Use the full-document folder POST supported by both generations, preserving
/// object metadata. V2 has no rename or conditional-write endpoint.
class PluginManagementService {
  PluginManagementService(this._api);
  final ApiClient _api;
  bool _mutating = false;

  String get scope => '${_api.baseUrl ?? ''}\n${_api.token ?? ''}';

  void _checkScope(String expectedScope) {
    if (scope != expectedScope) {
      throw const PluginManagementException('服务器或帐号已切换，请关闭面板后重新打开');
    }
  }

  Future<PluginFolders> fetchFolders(String expectedScope) async {
    _checkScope(expectedScope);
    final response = await _api.get<dynamic>(
      '/api/v1/plugin/folders',
      skipV3EnvelopeUnwrap: true,
    );
    _checkScope(expectedScope);
    return PluginFolders.fromJson(_read(response));
  }

  Future<void> saveFolders({
    required PluginFolders expected,
    required PluginFolders updated,
    required String expectedScope,
  }) => _exclusive(() async {
    // A failed/stale read must never turn into an empty full-document write.
    final latest = await fetchFolders(expectedScope);
    if (!latest.sameAs(expected)) {
      throw const PluginManagementException('文件夹已被其他请求修改，请刷新后重试');
    }
    _checkScope(expectedScope);
    _readMutation(
      await _api.post<dynamic>(
        '/api/v1/plugin/folders',
        data: updated.toJson(),
      ),
    );
    _checkScope(expectedScope);
  });

  Future<List<PluginRemote>> fetchRemotes(String expectedScope) async {
    _checkScope(expectedScope);
    final response = await _api.get<dynamic>(
      '/api/v1/plugin/remotes',
      queryParameters: {'token': 'moviepilot'},
      skipV3EnvelopeUnwrap: true,
    );
    _checkScope(expectedScope);
    final raw = _read(response);
    if (raw is! List || raw.any((entry) => entry is! Map)) {
      throw const FormatException('插件联邦组件响应格式无效');
    }
    return raw.map((entry) => PluginRemote.fromJson(entry as Map)).toList();
  }

  Future<String> clonePlugin(String id, String suffix) => _exclusive(() async {
    final normalized = suffix.trim();
    if (!RegExp(r'^[A-Za-z0-9]{1,20}$').hasMatch(normalized)) {
      throw const PluginManagementException('后缀需为 1–20 个 ASCII 字母或数字');
    }
    final expectedScope = scope;
    final response = await _api.post<dynamic>(
      '/api/v1/plugin/clone/${Uri.encodeComponent(id)}',
      data: {'suffix': normalized},
    );
    _checkScope(expectedScope);
    _readMutation(response);
    final raw = response.data;
    final message = raw is Map ? raw['message']?.toString().trim() : null;
    return message == null || message.isEmpty ? '分身已创建' : message;
  });

  Future<void> reloadPlugin(String id) => _exclusive(() async {
    final expectedScope = scope;
    final path = '/api/v1/plugin/reload/${Uri.encodeComponent(id)}';
    // V2 GET; V3 POST. Only method-not-allowed is safe to retry as POST.
    var response = await _api.get<dynamic>(path);
    _checkScope(expectedScope);
    if (response.statusCode == 405) response = await _api.post<dynamic>(path);
    _checkScope(expectedScope);
    _readMutation(response);
  });

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    if (_mutating) {
      throw const PluginManagementException('另一项插件操作正在进行，请稍候');
    }
    _mutating = true;
    try {
      return await operation();
    } finally {
      _mutating = false;
    }
  }

  static Object? _read(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final raw = response.data;
    if (status < 200 ||
        status >= 300 ||
        (raw is Map && raw['success'] == false)) {
      final detail = raw is Map ? raw['message'] ?? raw['detail'] : null;
      throw PluginManagementException(
        detail?.toString().trim().isNotEmpty == true
            ? detail.toString()
            : '请求失败 (HTTP $status)',
      );
    }
    if (raw is Map && raw['success'] is bool && raw.containsKey('data')) {
      return raw['data'];
    }
    return raw;
  }

  static void _readMutation(Response<dynamic> response) {
    _read(response);
    if (response.data is! Map || response.data['success'] != true) {
      throw const PluginManagementException('服务器未确认操作成功，请刷新后检查');
    }
  }
}

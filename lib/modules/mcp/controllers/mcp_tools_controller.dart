import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// MCP REST tool summary, shared by the v2 and v3 APIs.
class McpToolInfo {
  const McpToolInfo({required this.name, this.description, this.inputSchema});

  final String name;
  final String? description;
  final Map<String, dynamic>? inputSchema;

  factory McpToolInfo.fromJson(Map<String, dynamic> json) => McpToolInfo(
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    inputSchema: json['inputSchema'] is Map
        ? Map<String, dynamic>.from(json['inputSchema'] as Map)
        : null,
  );
}

/// Keep the complete JSON document, including unknown keys and explicit nulls.
/// JSON copies at both boundaries prevent nested args/env/header aliasing.
class McpServerConfig {
  McpServerConfig({
    required String id,
    required String name,
    bool enabled = true,
    String? transport,
    String? url,
    String? command,
    String? description,
  }) : this.fromJson({
         'id': id,
         'name': name,
         'enabled': enabled,
         if (transport != null) 'transport': transport,
         if (url != null) 'url': url,
         if (command != null) 'command': command,
         if (description != null) 'description': description,
       });

  McpServerConfig.fromJson(Map<String, dynamic> json) : _raw = _copy(json);

  final Map<String, dynamic> _raw;
  String get id => _raw['id']?.toString() ?? '';
  String get name => _raw['name']?.toString() ?? '';
  // AgentMcpServerConfig defaults to enabled when the field is absent.
  bool get enabled => _raw['enabled'] is bool ? _raw['enabled'] as bool : true;
  String? get transport => _raw['transport']?.toString();
  String? get url => _raw['url']?.toString();
  String? get command => _raw['command']?.toString();
  String? get description => _raw['description']?.toString();

  Map<String, dynamic> toJson() => _copy(_raw);

  McpServerConfig withEnabled(bool value) =>
      McpServerConfig.fromJson({..._raw, 'enabled': value});

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  /// Validate documented field types without stripping extension fields or
  /// injecting defaults. The server remains authoritative for validation.
  static McpServerConfig parseEditorJson(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const FormatException('配置 JSON 格式错误');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('服务器配置必须是 JSON 对象');
    }
    for (final key in ['id', 'name']) {
      if (decoded[key] is! String || (decoded[key] as String).trim().isEmpty) {
        throw FormatException('$key 必须是非空字符串');
      }
    }
    for (final key in ['enabled', 'require_admin']) {
      if (decoded.containsKey(key) && decoded[key] is! bool) {
        throw FormatException('$key 必须是布尔值');
      }
    }
    for (final key in ['description', 'command', 'url', 'tool_prefix']) {
      if (decoded[key] != null && decoded[key] is! String) {
        throw FormatException('$key 必须是字符串或 null');
      }
    }
    if (decoded.containsKey('transport') &&
        ![
          'stdio',
          'sse',
          'http',
          'streamable_http',
        ].contains(decoded['transport'])) {
      throw const FormatException(
        'transport 必须是 stdio、sse、http 或 streamable_http',
      );
    }
    if (decoded.containsKey('timeout') && decoded['timeout'] is! int) {
      throw const FormatException('timeout 必须是整数（秒）');
    }
    if (decoded.containsKey('args') &&
        (decoded['args'] is! List ||
            (decoded['args'] as List).any((value) => value is! String))) {
      throw const FormatException('args 必须是字符串数组');
    }
    for (final key in ['env', 'headers']) {
      if (decoded.containsKey(key) &&
          (decoded[key] is! Map ||
              (decoded[key] as Map).values.any((value) => value is! String))) {
        throw FormatException('$key 必须是字符串键值对象');
      }
    }
    return McpServerConfig.fromJson(decoded);
  }
}

/// Server configuration writes replace the complete list, not individual entries.
class McpToolsController extends GetxController {
  McpToolsController({ApiClient? apiClient, AppLog? log})
    : _injectedApiClient = apiClient,
      _injectedLog = log;

  final ApiClient? _injectedApiClient;
  final AppLog? _injectedLog;
  ApiClient get _apiClient => _injectedApiClient ?? Get.find<ApiClient>();
  AppLog get _log => _injectedLog ?? Get.find<AppLog>();

  String? _apiToken;
  Future<void>? _tokenRequest;
  Future<void>? _initialization;
  final apiTokenResolved = false.obs;
  final tools = <McpToolInfo>[].obs;
  final isLoadingTools = false.obs;
  final toolsError = RxnString();
  final isCallingTool = false.obs;
  final servers = <McpServerConfig>[].obs;
  final isLoadingServers = false.obs;
  final serversLoaded = false.obs;
  final serversError = RxnString();
  final isSavingServers = false.obs;
  final isTestingServer = false.obs;
  final _schemaRequests = <String>{};

  ({AppService app, String account, String appUrl, String apiUrl})? _boundScope;
  String? _boundBearerToken;
  Worker? _scopeWorker;
  bool _scopeInvalidated = false;
  static const _adminError = '仅超级管理员可管理和执行 MCP 工具';
  static const _scopeError = '登录用户或服务器已变更，请关闭并重新打开 MCP 页面';
  String get _accessError => _scopeInvalidated ? _scopeError : _adminError;

  bool get _adminAllowed => _checkScope();

  bool _checkScope() {
    if (_scopeInvalidated) return false;
    if (!Get.isRegistered<AppService>()) {
      if (_boundScope != null) _invalidateScope();
      return false;
    }
    final app = Get.find<AppService>();
    final account = app.agentCacheScopeKey.value;
    final appUrl = app.baseUrl;
    final apiUrl = _apiClient.baseUrl;
    if (!app.isSuperuser ||
        account.isEmpty ||
        appUrl == null ||
        appUrl.isEmpty ||
        apiUrl == null ||
        apiUrl.isEmpty) {
      if (_boundScope != null) _invalidateScope();
      return false;
    }
    final scope = (app: app, account: account, appUrl: appUrl, apiUrl: apiUrl);
    if (_boundScope == null) {
      _boundScope = scope;
      _boundBearerToken = _apiClient.token ?? '';
      _scopeWorker = ever(app.agentCacheScopeKey, (_) {
        _checkScope();
      });
    } else if (_boundScope != scope) {
      _invalidateScope();
      return false;
    }
    return true;
  }

  void _invalidateScope() {
    _scopeInvalidated = true;
    _apiToken = null;
    _boundBearerToken = null;
    _tokenRequest = null;
    apiTokenResolved.value = false;
    tools.clear();
    servers.clear();
    serversLoaded.value = false;
    toolsError.value = _scopeError;
    serversError.value = _scopeError;
  }

  // ApiClient awaits readiness before dispatch. Pin target/auth now so a server
  // or account switch during that await cannot redirect an old-scope request.
  String _path(String endpoint) {
    final base = _boundScope!.apiUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$base$endpoint';
  }

  @override
  void onClose() {
    _scopeWorker?.dispose();
    _invalidateScope();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    initialize();
  }

  /// Start once from lifecycle, never from a widget build/Obx callback.
  Future<void> initialize() async {
    if (!_adminAllowed) {
      toolsError.value = _accessError;
      serversError.value = _accessError;
      return;
    }
    await (_initialization ??= Future.wait([
      loadTools(),
      loadServers(),
    ]).then((_) {}));
  }

  Future<void> _resolveApiToken() => _tokenRequest ??= _readApiToken();

  Future<void> _readApiToken() async {
    try {
      final response = await _apiClient.get<dynamic>(
        _path('/api/v1/system/env'),
        token: _boundBearerToken,
        skipV3EnvelopeUnwrap: true,
      );
      if (!_adminAllowed) return;
      if (_responseError(response, '读取 API_TOKEN 失败') != null) return;
      final data = _payload(response.data);
      final token = data is Map ? data['API_TOKEN'] : null;
      if (token is String && token.trim().isNotEmpty) _apiToken = token.trim();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取 API_TOKEN 失败');
    } finally {
      if (_adminAllowed) apiTokenResolved.value = true;
    }
  }

  Future<bool> _ensureMcpAuth() async {
    if (!_adminAllowed) return false;
    await _resolveApiToken();
    return _adminAllowed && _apiToken != null;
  }

  Map<String, String> get _mcpHeaders => {'X-API-KEY': _apiToken!};
  static const _authError = 'MCP 工具需要服务端 API_TOKEN（X-API-KEY），请检查管理员权限';

  Future<void> loadTools() async {
    if (!_adminAllowed) {
      toolsError.value = _accessError;
      return;
    }
    if (isLoadingTools.value) return;
    isLoadingTools.value = true;
    toolsError.value = null;
    try {
      // Explicit retry may also retry a previously unsuccessful token lookup.
      if (apiTokenResolved.value && _apiToken == null) _tokenRequest = null;
      if (!await _ensureMcpAuth() || !_adminAllowed) {
        toolsError.value = _adminAllowed ? _authError : _accessError;
        return;
      }
      final response = await _apiClient.get<dynamic>(
        _path('/api/v1/mcp/tools'),
        token: _boundBearerToken,
        headers: _mcpHeaders,
        skipUnauthorizedHandling: true,
        skipV3EnvelopeUnwrap: true,
      );
      if (!_adminAllowed) return;
      final error = _responseError(response, '获取工具失败');
      if (error != null) {
        toolsError.value = error;
        return;
      }
      final list = _payload(response.data);
      if (list is! List || list.any((item) => item is! Map)) {
        toolsError.value = '工具列表数据格式异常';
        return;
      }
      tools.assignAll(
        list.map(
          (item) =>
              McpToolInfo.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 MCP 工具列表失败');
      toolsError.value = '请求失败，请稍后重试';
    } finally {
      isLoadingTools.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchToolSchema(String toolName) async {
    if (!_schemaRequests.add(toolName)) return null;
    try {
      if (!await _ensureMcpAuth() || !_adminAllowed) return null;
      final response = await _apiClient.get<dynamic>(
        _path('/api/v1/mcp/tools/${Uri.encodeComponent(toolName)}/schema'),
        token: _boundBearerToken,
        headers: _mcpHeaders,
        skipUnauthorizedHandling: true,
        skipV3EnvelopeUnwrap: true,
      );
      if (!_adminAllowed) return null;
      if (_responseError(response, '获取 Schema 失败') != null) return null;
      final data = _payload(response.data);
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取工具 Schema 失败');
      return null;
    } finally {
      _schemaRequests.remove(toolName);
    }
  }

  /// UI must obtain explicit confirmation for this particular invocation.
  Future<({bool ok, String result})> callTool(
    String toolName,
    String argumentsJson, {
    bool confirmed = false,
  }) async {
    if (!_adminAllowed) return (ok: false, result: _accessError);
    if (!confirmed) return (ok: false, result: '请先确认执行工具');
    if (isCallingTool.value) return (ok: false, result: '已有工具正在执行，请勿重复提交');
    final Map<String, dynamic> arguments;
    try {
      final decoded = jsonDecode(
        argumentsJson.trim().isEmpty ? '{}' : argumentsJson,
      );
      if (decoded is! Map<String, dynamic>) {
        return (ok: false, result: '参数必须是 JSON 对象');
      }
      arguments = decoded;
    } catch (_) {
      return (ok: false, result: '参数 JSON 格式错误');
    }
    isCallingTool.value = true;
    try {
      if (!await _ensureMcpAuth() || !_adminAllowed) {
        return (ok: false, result: _adminAllowed ? _authError : _accessError);
      }
      final response = await _apiClient.post<dynamic>(
        _path('/api/v1/mcp/tools/call'),
        token: _boundBearerToken,
        data: {'tool_name': toolName, 'arguments': arguments},
        headers: _mcpHeaders,
        skipUnauthorizedHandling: true,
      );
      if (!_adminAllowed) return (ok: false, result: _accessError);
      final error = _responseError(response, '调用失败');
      if (error != null) return (ok: false, result: error);
      final data = response.data;
      // v2: {success, result, error}; v3: {success, data: {result}}.
      final payload = _payload(data);
      if (data is! Map ||
          data['success'] != true ||
          payload is! Map ||
          !payload.containsKey('result')) {
        return (ok: false, result: '工具响应格式异常，执行状态未知；请勿直接重复执行');
      }
      final result = payload['result'];
      return (ok: true, result: result is String ? result : _pretty(result));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '调用 MCP 工具失败');
      return (ok: false, result: '请求失败，工具可能已执行；请先检查服务端状态，勿直接重试');
    } finally {
      isCallingTool.value = false;
    }
  }

  Future<void> loadServers() async {
    if (!_adminAllowed) {
      serversError.value = _accessError;
      return;
    }
    if (isLoadingServers.value || isSavingServers.value) return;
    isLoadingServers.value = true;
    serversLoaded.value = false;
    serversError.value = null;
    try {
      final response = await _apiClient.get<dynamic>(
        _path('/api/v1/message/agent/mcp/servers'),
        token: _boundBearerToken,
        skipV3EnvelopeUnwrap: true,
      );
      if (!_adminAllowed) return;
      final error = _responseError(response, '获取服务器配置失败');
      if (error != null) {
        serversError.value = error;
        return;
      }
      final data = _payload(response.data);
      final list = data is Map ? data['servers'] : null;
      // Never silently drop malformed entries: this is a whole-list save API.
      if (list is! List || list.any((item) => item is! Map)) {
        serversError.value = '服务器列表数据格式异常，已禁止保存以避免丢失配置';
        serversLoaded.value = false;
        return;
      }
      servers.assignAll(
        list.map(
          (item) =>
              McpServerConfig.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
      serversLoaded.value = true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 MCP 服务器配置失败');
      serversError.value = '请求失败，请稍后重试';
    } finally {
      isLoadingServers.value = false;
    }
  }

  String? get _saveBlocked {
    if (!_adminAllowed) return _accessError;
    if (isSavingServers.value) return '正在保存，请勿重复提交';
    if (isLoadingServers.value) return '正在读取配置，请稍后重试';
    if (!serversLoaded.value) return '请先成功加载完整服务器列表';
    if (serversError.value != null) return '请先重新加载服务器列表';
    return null;
  }

  Future<String?> setServerEnabled(McpServerConfig server, bool enabled) async {
    if (!_adminAllowed) return _accessError;
    final index = servers.indexOf(server);
    if (index < 0) return '配置已更新，请重新打开';
    final candidate = servers.toList();
    candidate[index] = server.withEnabled(enabled);
    return _saveServers(candidate);
  }

  Future<String?> upsertServerJson(
    String text, {
    McpServerConfig? original,
  }) async {
    final blocked = _saveBlocked;
    if (blocked != null) return blocked;
    final McpServerConfig server;
    try {
      server = McpServerConfig.parseEditorJson(text);
    } on FormatException catch (e) {
      return e.message;
    }
    final index = original == null ? -1 : servers.indexOf(original);
    if (original != null && index < 0) return '配置已更新，请重新打开编辑';
    if (servers.asMap().entries.any(
      (entry) => entry.key != index && entry.value.id == server.id,
    )) {
      return '服务器 ID 已存在';
    }
    final candidate = servers.toList();
    if (index < 0) {
      candidate.add(server);
    } else {
      candidate[index] = server;
    }
    return _saveServers(candidate);
  }

  Future<String?> deleteServer(McpServerConfig server) async {
    if (!_adminAllowed) return _accessError;
    if (!servers.contains(server)) return '配置已更新，请重新打开';
    return _saveServers(
      servers.where((item) => !identical(item, server)).toList(),
    );
  }

  Future<String?> _saveServers(List<McpServerConfig> candidate) async {
    final blocked = _saveBlocked;
    if (blocked != null) return blocked;
    isSavingServers.value = true;
    final previous = servers.toList();
    final body = {'servers': candidate.map((item) => item.toJson()).toList()};
    servers.assignAll(candidate);
    var saved = false;
    try {
      final response = await _apiClient.post<dynamic>(
        _path('/api/v1/message/agent/mcp/servers'),
        token: _boundBearerToken,
        data: body,
      );
      if (!_adminAllowed) return _accessError;
      final error = _responseError(response, '保存失败');
      if (error != null) return error;
      if (response.data is! Map || response.data['success'] != true) {
        serversError.value = '保存响应异常，请重新加载确认服务端状态';
        return serversError.value;
      }
      saved = true;
      return null;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 MCP 服务器配置失败');
      if (!_adminAllowed) return _accessError;
      serversError.value = '保存结果未知，请重新加载确认服务端状态';
      return serversError.value;
    } finally {
      if (!saved && _adminAllowed) servers.assignAll(previous);
      isSavingServers.value = false;
    }
  }

  Future<({bool ok, String message})> testServer(McpServerConfig server) async {
    if (!_adminAllowed) return (ok: false, message: _accessError);
    if (isTestingServer.value) return (ok: false, message: '正在测试，请勿重复提交');
    isTestingServer.value = true;
    try {
      final response = await _apiClient.post<dynamic>(
        _path('/api/v1/message/agent/mcp/servers/test'),
        token: _boundBearerToken,
        data: {'server': server.toJson()},
      );
      if (!_adminAllowed) return (ok: false, message: _accessError);
      final error = _responseError(response, '测试失败');
      if (error != null) return (ok: false, message: error);
      final result = _payload(response.data);
      if (result is! Map || result['success'] != true) {
        return (
          ok: false,
          message: result is Map
              ? result['message']?.toString() ?? '测试响应格式异常'
              : '测试响应格式异常',
        );
      }
      final count =
          result['tool_count'] ??
          (result['tools'] is List ? (result['tools'] as List).length : 0);
      return (ok: true, message: '连接正常，发现 $count 个工具');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '测试 MCP 服务器失败');
      return (ok: false, message: '测试失败，请稍后重试');
    } finally {
      isTestingServer.value = false;
    }
  }

  static dynamic _payload(dynamic value) =>
      value is Map && value['success'] is bool && value['data'] != null
      ? value['data']
      : value;

  static String? _responseError(Response<dynamic> response, String fallback) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status < 200 || status >= 300) {
      return '$fallback (HTTP $status)';
    }
    if (data is Map && data['success'] == false) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          fallback;
    }
    return null;
  }

  static String _pretty(dynamic value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}

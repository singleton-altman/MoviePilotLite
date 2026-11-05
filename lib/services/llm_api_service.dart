import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/dio_adapter_config_stub.dart'
    if (dart.library.io) 'package:moviepilot_mobile/utils/dio_adapter_config_io.dart'
    if (dart.library.js_interop) 'package:moviepilot_mobile/utils/dio_adapter_config_web.dart';

class LlmApiException implements Exception {
  const LlmApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LlmModel {
  const LlmModel({required this.id, required this.name});

  final String id;
  final String name;
}

class LlmModelCatalog {
  const LlmModelCatalog({required this.models, this.provider, this.authStatus});

  final List<LlmModel> models;
  final String? provider;
  final Map<String, dynamic>? authStatus;
}

/// Model contracts verified against the V2 OpenAPI and V3.1.5's
/// LLMProviderManager.provider_manage/_manage_list_models (99ee18d0).
/// The provider registry resolves target as a provider id, not a resource name.
class LlmApiService {
  LlmApiService({
    required ApiClient apiClient,
    Future<bool> Function()? isV3,
    Dio? dio,
  }) : _api = apiClient,
       _isV3 = isV3 ??
           (Get.isRegistered<ServerApiVersionService>()
                   ? Get.find<ServerApiVersionService>()
                   : ServerApiVersionService(apiClient: apiClient))
               .isV3,
       _http = dio ?? Dio() {
    // ApiClient's shared logger includes the full URI, exposing V2 query keys.
    // Use the same adapter/session credentials, but no logging or unwrapping
    // interceptors. Never attach these credentials to the provider base_url.
    if (dio == null) configureDioHttpClientAdapter(_http);
  }

  final ApiClient _api;
  final Future<bool> Function() _isV3;
  final Dio _http;

  Future<LlmModelCatalog> listModels({
    required String provider,
    String? apiKey,
    String? baseUrl,
    String? baseUrlPreset,
    String? userAgent,
    bool? useProxy,
    bool? forceRefresh,
  }) async {
    if (provider.trim().isEmpty) {
      throw const LlmApiException('请先填写 LLM 提供商');
    }
    final server = _api.baseUrl;
    final token = _api.token;
    String? cookie;
    try {
      final v3 = await _isV3();
      if (server == null || server.isEmpty) {
        throw const LlmApiException('请先连接服务器');
      }
      cookie = await _api.getCookieHeader(url: server);
      if (_api.baseUrl != server || _api.token != token) {
        throw const LlmApiException('服务器或登录状态已变化，请重试');
      }
      final params = <String, dynamic>{
        if (apiKey != null) 'api_key': apiKey,
        if (baseUrl != null) 'base_url': baseUrl,
        if (baseUrlPreset != null) 'base_url_preset': baseUrlPreset,
        if (userAgent != null) 'user_agent': userAgent,
        if (useProxy != null) 'use_proxy': useProxy,
        if (forceRefresh != null) 'force_refresh': forceRefresh,
      };
      final response = await _http.request<dynamic>(
        '${server.replaceFirst(RegExp(r'/+$'), '')}/api/v1/llm/${v3 ? 'manage' : 'models'}',
        queryParameters: v3 ? null : {'provider': provider, ...params},
        data: v3
            ? {'target': provider, 'action': 'list_models', 'params': params}
            : null,
        options: Options(
          method: v3 ? 'POST' : 'GET',
          responseType: ResponseType.json,
          contentType: Headers.jsonContentType,
          headers: {
            'accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'authorization': 'Bearer $token',
            if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
          },
          // Do not forward session credentials to a redirected host.
          followRedirects: false,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw LlmApiException('请求失败($status)');
      }
      final body = response.data;
      // Inspect the original envelope before accessing data; a failed response
      // must not become a successful catalog through global V3 unwrapping.
      if (body is! Map || body['success'] is! bool) {
        throw const LlmApiException('响应数据格式错误');
      }
      if (body['success'] != true) {
        final message = body['message'];
        throw LlmApiException(
          message is String && message.isNotEmpty
              ? _redact(message, [apiKey, baseUrl, token, cookie])
              : '请求失败',
        );
      }
      return _catalog(body['data']);
    } on LlmApiException {
      rethrow;
    } catch (_) {
      // Dio exceptions can contain credential-bearing URIs/headers/bodies.
      throw const LlmApiException('LLM 模型列表请求失败，请检查连接后重试');
    }
  }

  static LlmModelCatalog _catalog(dynamic data) {
    final dynamic entries = data is Map ? data['models'] : data;
    if (entries is! List) {
      throw const LlmApiException('响应数据格式错误');
    }
    final models = <LlmModel>[];
    final seen = <String>{};
    for (final entry in entries) {
      // Older V2 servers returned a flat string list. Current V2/V3 return
      // data.models records; never stringify a record into a model value.
      final dynamic rawId = entry is Map ? entry['id'] : entry;
      if (rawId is! String) {
        throw const LlmApiException('响应数据格式错误');
      }
      final id = rawId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      final dynamic name = entry is Map ? entry['name'] : null;
      models.add(LlmModel(
        id: id,
        name: name is String && name.trim().isNotEmpty ? name.trim() : id,
      ));
    }
    final authStatus = data is Map ? data['auth_status'] : null;
    return LlmModelCatalog(
      models: List.unmodifiable(models),
      provider: data is Map && data['provider'] is String
          ? data['provider'] as String
          : null,
      authStatus: authStatus is Map
          ? Map<String, dynamic>.unmodifiable(authStatus)
          : null,
    );
  }

  static String _redact(String message, List<String?> secrets) {
    var result = message;
    for (final secret in secrets) {
      if (secret == null || secret.isEmpty) continue;
      for (final value in {secret, Uri.encodeComponent(secret), Uri.encodeQueryComponent(secret)}) {
        result = result.replaceAll(value, '***');
      }
    }
    return result
        .replaceAll(RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false), 'Bearer ***')
        .replaceAllMapped(
          RegExp(r'(api[_-]?key\s*[:=]\s*)[^\s,;&]+', caseSensitive: false),
          (match) => '${match[1]}***',
        );
  }

  void close() => _http.close(force: true);
}

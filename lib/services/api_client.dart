import 'dart:async';
import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/dio_adapter_config_stub.dart'
    if (dart.library.io) 'package:moviepilot_mobile/utils/dio_adapter_config_io.dart'
    if (dart.library.js_interop) 'package:moviepilot_mobile/utils/dio_adapter_config_web.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:get/get.dart' as g;

enum RequestMethod { get, post, put, delete }

class ApiAuthException implements Exception {
  ApiAuthException(this.statusCode, [this.message]);

  final int statusCode;
  final String? message;

  @override
  String toString() =>
      'ApiAuthException(statusCode: $statusCode, message: $message)';
}

class ApiHttpException implements Exception {
  ApiHttpException(this.statusCode, [this.message]);

  final int statusCode;
  final String? message;

  @override
  String toString() =>
      'ApiHttpException(statusCode: $statusCode, message: $message)';
}

class ApiClient extends g.GetxController {
  static const _skipV3EnvelopeUnwrapKey = 'skipV3EnvelopeUnwrap';

  final _appService = g.Get.find<AppService>();
  final _iosSharedSessionService = g.Get.find<IosSharedSessionService>();
  final _hiveService = g.Get.find<HiveService>();
  final _log = g.Get.find<AppLog>();
  late final Dio _dio;
  late final CookieJar _cookieJar;
  late final Future<void> _ready;
  bool _dioReady = false;
  String? _pendingBaseUrl;
  String? _cachedCookieHeader;
  Uri? _cachedCookieUri;
  DateTime? _cachedCookieAt;
  bool _authRedirecting = false;
  bool _authClearing = false;

  /// 401/403 时的静默恢复钩子，由 AuthRepository 注册；返回 true 表示已重新登录成功。
  Future<bool> Function()? _authRecoveryHandler;
  bool _silentRecoveryInProgress = false;
  DateTime? _lastSilentRecoveryAt;

  /// 两次静默重登尝试之间的最小间隔，避免旧 token 的并发 401 反复触发重登。
  static const Duration _silentRecoveryCooldown = Duration(seconds: 15);

  static const Duration _cookieCacheTtl = Duration(seconds: 30);

  String? get baseUrl {
    if (_dioReady) return _dio.options.baseUrl;
    return _pendingBaseUrl ?? _appService.baseUrl;
  }

  @override
  void onInit() {
    super.onInit();
    _ready = _initClient();
  }

  Future<void> _initClient() async {
    _dio = Dio(
      BaseOptions(
        // 初始时 baseUrl 为空，后续在登录时根据服务器地址进行配置。
        baseUrl: _appService.baseUrl ?? '',
        // 连接超时收紧到 10 秒：服务器不可达时快速失败，而不是挂 2 分钟。
        connectTimeout: const Duration(seconds: 10),
        // 接收超时保留较大值：搜索等长耗时接口依赖它。
        receiveTimeout: const Duration(seconds: 120),
        // FormData 需要 multipart/form-data；这里不强行设置，
        // 让 dio 根据 data 类型自动推导 Content-Type。
        headers: const {'accept': 'application/json'},
      ),
    );
    if ((_pendingBaseUrl ?? '').isNotEmpty) {
      _dio.options.baseUrl = _pendingBaseUrl!;
    } else if (_appService.hasBaseUrl) {
      _dio.options.baseUrl = _appService.baseUrl!;
    }
    _dioReady = true;
    configureDioHttpClientAdapter(_dio);

    final CookieJar cookieJar;
    if (kIsWeb) {
      cookieJar = CookieJar();
    } else {
      final dir = await getApplicationSupportDirectory();
      cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    }
    _cookieJar = cookieJar;
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          _maybeHandleUnauthorized(
            response.requestOptions,
            response.statusCode,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _maybeHandleUnauthorized(
            error.requestOptions,
            error.response?.statusCode,
          );
          handler.next(error);
        },
      ),
    );
    _dio.interceptors.add(
      TalkerDioLogger(
        talker: _log.talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printResponseMessage: true,
          printRequestData: true,
          printResponseData: true,
          logLevel: LogLevel.debug,
        ),
      ),
    );
    if (kIsWeb) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            final data = response.data;
            if (data is! String) {
              handler.next(response);
              return;
            }
            final raw = data.trim();
            final status = response.statusCode ?? 0;
            if (status >= 400) {
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message: raw.isEmpty ? 'HTTP $status' : raw,
                ),
              );
              return;
            }
            if (raw.isEmpty) {
              response.data = null;
              handler.next(response);
              return;
            }
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                response.data = decoded;
              } else if (decoded is Map) {
                response.data = Map<String, dynamic>.from(decoded);
              } else {
                handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    type: DioExceptionType.badResponse,
                    message: 'Unexpected JSON root: ${decoded.runtimeType}',
                  ),
                );
                return;
              }
            } catch (_) {
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message: raw,
                ),
              );
              return;
            }
            handler.next(response);
          },
        ),
      );
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.requestOptions.extra[_skipV3EnvelopeUnwrapKey] == true ||
              response.requestOptions.responseType != ResponseType.json) {
            handler.next(response);
            return;
          }

          final envelope = response.data;
          if (envelope is! Map ||
              envelope['success'] is! bool ||
              !envelope.containsKey('data')) {
            handler.next(response);
            return;
          }

          if (!g.Get.isRegistered<ServerApiVersionService>()) {
            handler.next(response);
            return;
          }

          try {
            final isV3 = await g.Get.find<ServerApiVersionService>().isV3();
            if (!isV3) {
              handler.next(response);
              return;
            }
          } catch (_) {
            handler.next(response);
            return;
          }

          final data = envelope['data'];
          if (data == null) {
            handler.next(response);
            return;
          }
          if (data is Map) {
            // 业务字段优先：仅在原始数据没有同名键时才补 envelope 的字段，
            // 避免把接口本身返回的 success / message / data 覆盖掉。
            final merged = Map<String, dynamic>.from(data);
            merged.putIfAbsent('success', () => envelope['success']);
            merged.putIfAbsent('message', () => envelope['message']);
            merged.putIfAbsent('data', () => data);
            response.data = merged;
          } else {
            response.data = data;
          }
          handler.next(response);
        },
      ),
    );
  }

  Future<void> _ensureReady() => _ready;

  void _maybeHandleUnauthorized(RequestOptions? opts, int? status) {
    if (opts?.extra['skipUnauthorizedHandling'] == true) return;
    _handleUnauthorized(status);
  }

  Future<Uint8List?> fetchResourceProxyImage(String absoluteUrl) async {
    await _ensureReady();
    if (absoluteUrl.isEmpty) return null;
    try {
      final r = await _dio.get<List<int>>(
        absoluteUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {
            if (token != null && token!.isNotEmpty)
              'authorization': 'Bearer $token',
          },
          validateStatus: (s) => s == 200,
          receiveTimeout: const Duration(seconds: 120),
          extra: {
            'skipUnauthorizedHandling': true,
            if (kIsWeb) 'withCredentials': true,
          },
        ),
      );
      final data = r.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } catch (e) {
      _log.warning('fetchResourceProxyImage failed: $e');
      return null;
    }
  }

  String? token;

  /// 获取 Cookie Header（优先根据传入 url，否则使用 baseUrl）
  Future<String?> getCookieHeader({
    String? url,
    bool preferCache = true,
  }) async {
    if (!_dioReady) return _cachedCookieHeader;

    final uri = _resolveCookieUri(url);
    if (uri == null) return _cachedCookieHeader;

    if (preferCache && _isCookieCacheFresh(uri)) {
      return _cachedCookieHeader;
    }

    if (kIsWeb) {
      final header = _appService.cookie?.trim();
      final value = (header == null || header.isEmpty) ? null : header;
      _cacheCookieHeader(uri, value);
      return value;
    }

    final cookies = await _cookieJar.loadForRequest(uri);
    final header = cookies.isEmpty
        ? null
        : cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    _cacheCookieHeader(uri, header);
    return header;
  }

  Uri? _resolveCookieUri(String? url) {
    if (url != null && url.isNotEmpty) {
      var uri = Uri.tryParse(url);
      if (uri == null) return null;
      if (!uri.hasScheme) {
        final base = baseUrl ?? '';
        if (base.isEmpty) return null;
        uri = Uri.parse(base).resolve(url);
      }
      return uri;
    }

    final base = baseUrl ?? '';
    if (base.isEmpty) return null;
    return Uri.parse(base);
  }

  bool _isCookieCacheFresh(Uri uri) {
    if (_cachedCookieHeader == null) return false;
    if (_cachedCookieUri?.host != uri.host) return false;
    final cachedAt = _cachedCookieAt;
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < _cookieCacheTtl;
  }

  void _cacheCookieHeader(Uri uri, String? header) {
    _cachedCookieHeader = header;
    _cachedCookieUri = uri;
    _cachedCookieAt = DateTime.now();
  }

  /// 配置服务端基础地址。
  ///
  /// 登录时会根据用户输入的 serverUrl 调用该方法，
  /// 之后所有以 `/api/...` 开头的请求都会以此为前缀。
  void setBaseUrl(String baseUrl) {
    _pendingBaseUrl = baseUrl;
    if (_dioReady) {
      _dio.options.baseUrl = baseUrl;
      configureDioHttpClientAdapter(_dio);
    }
    _log.info('设置 API baseUrl: $baseUrl');
  }

  /// 设置当前使用的访问 Token，后续 GET 请求会自动带上该 Token。
  void setToken(String token) {
    this.token = token;
    _log.info('更新 API Token');
  }

  /// 注册 401/403 时的静默恢复钩子（由 AuthRepository 在初始化时调用）。
  void setAuthRecoveryHandler(Future<bool> Function()? handler) {
    _authRecoveryHandler = handler;
  }

  /// 探测服务器连通性：请求 GET /api/v1/system/ping（Swagger 定义），
  /// 短超时；只要收到任意 HTTP 响应（含 401/403）即视为网络可达。
  Future<bool> probeConnectivity({
    required String server,
    String? accessToken,
    Duration connectTimeout = const Duration(seconds: 5),
    Duration receiveTimeout = const Duration(seconds: 8),
  }) async {
    final normalized = server.trim();
    if (normalized.isEmpty) return false;
    final probe = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {'accept': 'application/json'},
        validateStatus: (_) => true,
      ),
    );
    try {
      final response = await probe.get<dynamic>(
        '$normalized/api/v1/system/ping',
        options: Options(
          headers: {
            if (accessToken != null && accessToken.isNotEmpty)
              'authorization': 'Bearer $accessToken',
          },
        ),
      );
      return response.statusCode != null;
    } catch (_) {
      return false;
    }
  }

  /// 清理当前传输层会话，避免切换账号时复用上一个账号的 Cookie。
  Future<void> clearSessionCookies() async {
    _cachedCookieHeader = null;
    _cachedCookieUri = null;
    _cachedCookieAt = null;
    try {
      await _cookieJar.deleteAll();
    } catch (_) {}
  }

  Future<Response<T>> request<T>(
    String url,
    RequestMethod method,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    final options = Options(
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        ...?headers,
      },
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
    );
    if (method == RequestMethod.get) {
      final response = await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
      );
      _handleUnauthorized(response.statusCode);
      return response;
    } else if (method == RequestMethod.post) {
      final response = await _dio.post<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _handleUnauthorized(response.statusCode);
      return response;
    } else if (method == RequestMethod.put) {
      final response = await _dio.put<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _handleUnauthorized(response.statusCode);
      return response;
    } else if (method == RequestMethod.delete) {
      final response = await _dio.delete<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _handleUnauthorized(response.statusCode);
      return response;
    } else {
      throw ArgumentError('Invalid method: $method');
    }
  }

  Future<Response<T>> postForm<T>(
    String path,
    Map<String, dynamic> data, {
    int? timeout,
  }) async {
    await _ensureReady();
    final formData = FormData.fromMap(data);
    final response = await _dio.post<T>(
      path,
      data: formData,
      options: kIsWeb
          ? Options(
              receiveTimeout: Duration(seconds: timeout ?? 30),
              validateStatus: (_) => true,
            )
          : Options(receiveTimeout: Duration(seconds: timeout ?? 30)),
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<Response<T>> postMultipart<T>(
    String path,
    FormData formData, {
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    final response = await _dio.post<T>(
      path,
      data: formData,
      options: Options(
        receiveTimeout: Duration(seconds: timeout ?? 120),
        sendTimeout: Duration(seconds: timeout ?? 120),
        headers: {
          if (authToken != null) 'authorization': 'Bearer $authToken',
          ...?headers,
        },
        validateStatus: (_) => true,
      ),
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API POST请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final options = Options(
      receiveTimeout: Duration(seconds: timeout ?? 30),
      sendTimeout: Duration(seconds: timeout ?? 30),
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        ...?headers,
      },
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
    );
    final response = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<Response<T>> put<T>(
    String path,
    Map<String, dynamic>? data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API PUT请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final options = Options(
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        ...?headers,
      },
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
    );
    final response = await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  /// POST 请求，data 可为 List 等可 JSON 序列化的对象（如 TorrentsPriority 的字符串数组）
  Future<Response<T>> postJson<T>(
    String path,
    Object? data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API POST请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final options = Options(
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        'content-type': 'application/json',
        ...?headers,
      },
      sendTimeout: Duration(seconds: timeout ?? 120),
      receiveTimeout: Duration(seconds: timeout ?? 120),
      validateStatus: (status) => true,
    );
    final response = await _dio.post<T>(path, data: data, options: options);
    _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
    bool skipV3EnvelopeUnwrap = false,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final options = Options(
      sendTimeout: Duration(seconds: timeout ?? 120),
      receiveTimeout: Duration(seconds: timeout ?? 120),
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        ...?headers,
      },
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
      extra: {
        if (skipUnauthorizedHandling) 'skipUnauthorizedHandling': true,
        if (skipV3EnvelopeUnwrap) _skipV3EnvelopeUnwrapKey: true,
      },
    );
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    if (!skipUnauthorizedHandling) {
      _handleUnauthorized(response.statusCode);
    }
    return response;
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API DELETE请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final options = Options(
      sendTimeout: Duration(seconds: timeout ?? 30),
      receiveTimeout: Duration(seconds: timeout ?? 30),
      headers: {
        if (authToken != null) 'authorization': 'Bearer $authToken',
        ...?headers,
      },
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
    );
    final response = await _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  /// SSE / 流式 GET，请求 `text/event-stream` 并返回按行解码后的字符串流。
  Future<Stream<String>> streamLines(
    String path, {
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool handleAuth = true,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API流式请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final requestHeaders = <String, dynamic>{
      'accept': 'text/event-stream',
      'cache-control': 'no-cache',
      if (authToken != null) 'authorization': 'Bearer $authToken',
      ...?headers,
    };
    if (!kIsWeb && !requestHeaders.containsKey('Cookie')) {
      final cookieHeader = await getCookieHeader() ?? _appService.cookie;
      if (cookieHeader != null && cookieHeader.isNotEmpty) {
        requestHeaders['Cookie'] = cookieHeader;
      }
    }
    final response = await _dio.get<ResponseBody>(
      path,
      options: Options(
        responseType: ResponseType.stream,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: timeout == null ? null : Duration(seconds: timeout),
        headers: requestHeaders,
        validateStatus: (status) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      if (handleAuth) {
        _handleUnauthorized(status);
        throw ApiAuthException(status, response.statusMessage);
      }
      throw ApiHttpException(status, response.statusMessage);
    }
    if (status >= 400) {
      throw ApiHttpException(status, response.statusMessage);
    }
    final body = response.data;
    if (body == null) {
      return const Stream<String>.empty();
    }
    // 将底层字节流转换为按行分隔的 UTF8 字符串流
    final byteStream = body.stream.map((chunk) => chunk as List<int>);
    return byteStream.transform(utf8.decoder).transform(const LineSplitter());
  }

  /// SSE / 流式 POST，请求 `text/event-stream` 并返回按行解码后的字符串流。
  Future<Stream<String>> streamPostLines(
    String path, {
    Object? data,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API流式POST请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final response = await _dio.post<ResponseBody>(
      path,
      data: data,
      options: Options(
        responseType: ResponseType.stream,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: timeout == null ? null : Duration(seconds: timeout),
        headers: {
          'accept': 'text/event-stream',
          'content-type': 'application/json',
          if (authToken != null) 'authorization': 'Bearer $authToken',
          ...?headers,
        },
        validateStatus: (status) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      _handleUnauthorized(status);
      throw ApiAuthException(status, response.statusMessage);
    }
    if (status >= 400) {
      throw ApiHttpException(status, response.statusMessage);
    }
    final body = response.data;
    if (body == null) {
      return const Stream<String>.empty();
    }
    final byteStream = body.stream.map((chunk) => chunk as List<int>);
    return byteStream.transform(utf8.decoder).transform(const LineSplitter());
  }

  void _handleUnauthorized(int? status) {
    if (status != 401 && status != 403) return;
    if (_authRedirecting) return;
    if (!_hasEnteredMain()) return;
    unawaited(_recoverOrLogout());
  }

  /// 401/403 的处理：优先尝试用本地保存的账号静默重登恢复会话；
  /// 恢复失败或无法恢复时才清理会话并踢回登录页。
  Future<void> _recoverOrLogout() async {
    final handler = _authRecoveryHandler;
    if (handler != null) {
      if (_silentRecoveryInProgress) return;
      final last = _lastSilentRecoveryAt;
      if (last != null &&
          DateTime.now().difference(last) < _silentRecoveryCooldown) {
        // 冷却期内：最近一次恢复要么成功要么正在进行，静默忽略而非踢出。
        return;
      }
      _silentRecoveryInProgress = true;
      bool recovered = false;
      try {
        recovered = await handler();
      } catch (_) {
        recovered = false;
      } finally {
        _silentRecoveryInProgress = false;
        _lastSilentRecoveryAt = DateTime.now();
      }
      if (recovered) {
        _log.info('会话已通过静默重登恢复');
        return;
      }
    }

    _authRedirecting = true;
    _clearSession();
    ToastUtil.error('会话已过期，请重新登录');
    g.Get.offAllNamed('/login');
    Future.delayed(const Duration(seconds: 1), () {
      _authRedirecting = false;
    });
  }

  bool _hasEnteredMain() {
    final route = g.Get.currentRoute;
    if (route.isEmpty) return false;
    return route != '/login';
  }

  Future<void> _clearSession() async {
    if (_authClearing) return;
    _authClearing = true;
    try {
      token = null;
      _appService.clearLoginState();
      _cachedCookieHeader = null;
      _cachedCookieUri = null;
      _cachedCookieAt = null;
      try {
        await _cookieJar.deleteAll();
      } catch (_) {}
      if (!kIsWeb) {
        try {
          final profiles = _hiveService.loginProfileBox.values.toList();
          if (profiles.isNotEmpty) {
            profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final latest = profiles.first;
            latest.accessToken = '';
            _hiveService.loginProfileBox.put(latest.id, latest);
          }
        } catch (_) {}
      }
      await _iosSharedSessionService.clearSession();
    } finally {
      _authClearing = false;
    }
  }
}

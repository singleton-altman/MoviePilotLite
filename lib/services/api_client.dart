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
  final _appService = g.Get.find<AppService>();
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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        // FormData 需要 multipart/form-data；这里不强行设置，
        // 让 dio 根据 data 类型自动推导 Content-Type。
        headers: const {'accept': 'application/json'},
      ),
    );
    _dioReady = true;

    if ((_pendingBaseUrl ?? '').isNotEmpty) {
      _dio.options.baseUrl = _pendingBaseUrl!;
    } else if (_appService.hasBaseUrl) {
      _dio.options.baseUrl = _appService.baseUrl!;
    }

    final CookieJar cookieJar;
    if (kIsWeb) {
      cookieJar = CookieJar();
    } else {
      final dir = await getApplicationSupportDirectory();
      cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    }
    _cookieJar = cookieJar;
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          _handleUnauthorized(response.statusCode);
          handler.next(response);
        },
        onError: (error, handler) {
          _handleUnauthorized(error.response?.statusCode);
          handler.next(error);
        },
      ),
    );
    _dio.interceptors.add(
      TalkerDioLogger(
        talker: _log.talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: false,
          printResponseHeaders: false,
          printResponseMessage: false,
          printRequestData: false,
          printResponseData: false,
          logLevel: LogLevel.info,
        ),
      ),
    );
  }

  Future<void> _ensureReady() => _ready;

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
    }
    _log.info('设置 API baseUrl: $baseUrl');
  }

  /// 设置当前使用的访问 Token，后续 GET 请求会自动带上该 Token。
  void setToken(String token) {
    this.token = token;
    _log.info('更新 API Token');
  }

  Future<Response<T>> request<T>(
    String url,
    RequestMethod method,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    final options = Options(
      headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
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
      options: Options(receiveTimeout: Duration(seconds: timeout ?? 30)),
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
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API POST请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final options = Options(
      receiveTimeout: Duration(seconds: timeout ?? 30),
      sendTimeout: Duration(seconds: timeout ?? 30),
      headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
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
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API PUT请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final options = Options(
      headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
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
      },
      sendTimeout: Duration(seconds: timeout ?? 30),
      receiveTimeout: Duration(seconds: timeout ?? 30),
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
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final options = Options(
      sendTimeout: Duration(seconds: timeout ?? 30),
      receiveTimeout: Duration(seconds: timeout ?? 30),
      headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
      validateStatus: (status) {
        // 允许所有状态码，让调用者自己处理错误
        return true;
      },
    );
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info(
      'API DELETE请求: $path, token: ${authToken != null ? '***' : 'null'}',
    );
    final options = Options(
      sendTimeout: Duration(seconds: timeout ?? 30),
      receiveTimeout: Duration(seconds: timeout ?? 30),
      headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
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
    int? timeout = 30,
  }) async {
    await _ensureReady();
    final authToken = token ?? this.token;
    _log.info('API流式请求: $path, token: ${authToken != null ? '***' : 'null'}');
    final response = await _dio.get<ResponseBody>(
      path,
      options: Options(
        responseType: ResponseType.stream,
        sendTimeout: Duration(seconds: timeout ?? 30),
        receiveTimeout: Duration(seconds: timeout ?? 30),
        headers: {
          'accept': 'text/event-stream',
          if (authToken != null) 'authorization': 'Bearer $authToken',
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
    // 将底层字节流转换为按行分隔的 UTF8 字符串流
    final byteStream = body.stream.map((chunk) => chunk as List<int>);
    return byteStream.transform(utf8.decoder).transform(const LineSplitter());
  }

  void _handleUnauthorized(int? status) {
    if (status != 401 && status != 403) return;
    if (_authRedirecting) return;
    if (!_hasEnteredMain()) return;
    _authRedirecting = true;
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
}

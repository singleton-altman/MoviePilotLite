import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import '../utils/app_log.dart';

/// 统一 HTTP 客户端
///
/// 基于 Dio 实现，提供 getJson / postJson / postForm / putJson / deleteJson / getBytes
/// 等简洁接口。所有方法共享统一的超时和错误处理策略。
///
/// 调用方只需依赖 [HttpClient] 的静态方法，无需关心底层实现。
class HttpClient {
  static bool _initialized = false;

  /// 初始化（幂等，必须在 app 启动时调用）
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    AppLog.i('Http', 'HttpClient (Dio) 初始化成功');
  }

  // ─── JSON 请求 ───

  /// GET 请求，返回解析后的 JSON（Map 或 List）
  static Future<dynamic> getJson(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final d = _createDio(headers: headers, timeout: timeout);
    try {
      final resp = await d.get(url, queryParameters: query);
      return resp.data;
    } finally {
      d.close();
    }
  }

  /// POST 请求（JSON body），返回解析后的 JSON
  static Future<dynamic> postJson(
    String url, {
    required dynamic data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final d = _createDio(headers: headers, timeout: timeout);
    try {
      final resp = await d.post(url, data: data);
      return resp.data;
    } finally {
      d.close();
    }
  }

  /// POST 请求（form-urlencoded），返回解析后的 JSON
  static Future<dynamic> postForm(
    String url, {
    required Map<String, String> data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final d = _createDio(headers: headers, timeout: timeout);
    try {
      final resp = await d.post(
        url,
        data: data,
        options: dio.Options(contentType: dio.Headers.formUrlEncodedContentType),
      );
      return resp.data;
    } finally {
      d.close();
    }
  }

  /// PUT 请求
  static Future<dynamic> putJson(
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final d = _createDio(headers: headers, timeout: timeout);
    try {
      final resp = await d.put(url, data: data);
      return resp.data;
    } finally {
      d.close();
    }
  }

  /// DELETE 请求
  static Future<dynamic> deleteJson(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final d = _createDio(headers: headers, timeout: timeout);
    try {
      final resp = await d.delete(url);
      return resp.data;
    } finally {
      d.close();
    }
  }

  // ─── 字节请求 ───

  /// GET 请求，返回字节数据（用于图片/文件下载）
  static Future<Uint8List> getBytes(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final d = dio.Dio(dio.BaseOptions(
      connectTimeout: timeout ?? const Duration(seconds: 8),
      receiveTimeout: timeout ?? const Duration(seconds: 15),
      responseType: dio.ResponseType.bytes,
    ));
    try {
      final resp = await d.get<List<int>>(url, options: dio.Options(headers: headers));
      return Uint8List.fromList(resp.data ?? []);
    } finally {
      d.close();
    }
  }

  // ─── 内部工具方法 ───

  static dio.Dio _createDio({
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return dio.Dio(dio.BaseOptions(
      connectTimeout: timeout ?? const Duration(seconds: 10),
      receiveTimeout: timeout ?? const Duration(seconds: 15),
      headers: headers ?? {'Accept': 'application/json'},
    ));
  }
}

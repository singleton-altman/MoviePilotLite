import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as g;
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

/// RequestOptions.extra 里标记跳过 V3 信封解包的键。
/// 与 [unwrapV3EnvelopeOnResponse] 的拦截判断、调用方构造 Options 共用。
const kSkipV3EnvelopeUnwrapKey = 'skipV3EnvelopeUnwrap';

/// (仅 Web)把字符串响应体解码为 JSON Map,解析失败按错误拒绝。
Future<void> decodeJsonResponseOnResponse(
  Response<dynamic> response,
  ResponseInterceptorHandler handler,
) async {
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
}

/// V3 服务端把业务数据包在 {success, data} 信封里;为兼容 V2 调用方,
/// 在 V3 上把 data 字段合并回响应顶层。
Future<void> unwrapV3EnvelopeOnResponse(
  Response<dynamic> response,
  ResponseInterceptorHandler handler,
) async {
  if (response.requestOptions.extra[kSkipV3EnvelopeUnwrapKey] == true ||
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
}

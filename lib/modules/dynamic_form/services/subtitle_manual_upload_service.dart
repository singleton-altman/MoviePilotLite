import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class SubtitleManualUploadApiResult {
  const SubtitleManualUploadApiResult({
    required this.data,
    this.message,
    this.raw,
  });

  final dynamic data;
  final String? message;
  final Map<String, dynamic>? raw;
}

class SubtitleManualUploadService {
  SubtitleManualUploadService(this._apiClient);

  final ApiClient _apiClient;

  static const pluginId = 'SubtitleManualUpload';
  static const basePath = '/api/v1/plugin/SubtitleManualUpload';

  Future<SubtitleManualUploadApiResult> getForm(String token) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/plugin/form/$pluginId',
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> saveConfig(
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _apiClient.put<dynamic>(
      basePath,
      body,
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> status(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/status',
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> onlineStatus(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/online_status',
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> autoTransferQueue(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/auto_transfer_queue',
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> refreshIndex(String token) async {
    final response = await _apiClient.postJson<dynamic>(
      '$basePath/refresh_index',
      const <String, dynamic>{},
      token: token,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> search({
    required String token,
    required String keyword,
    required String mediaType,
    required int page,
    required int pageSize,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/search',
      token: token,
      queryParameters: {
        'keyword': keyword,
        'media_type': mediaType,
        'page': page,
        'page_size': pageSize,
      },
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> matchHistory({
    required String token,
    required String keyword,
    required String mediaType,
    required int page,
    required int pageSize,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/match_history',
      token: token,
      queryParameters: {
        'keyword': keyword,
        'media_type': mediaType,
        'page': page,
        'page_size': pageSize,
      },
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> targets({
    required String token,
    required Map<String, dynamic> media,
    required String season,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/targets',
      token: token,
      queryParameters: {
        'media_type': _text(media['media_type']),
        if (_text(media['tmdb_id']).isNotEmpty) 'tmdb_id': media['tmdb_id'],
        if (_text(media['douban_id']).isNotEmpty)
          'douban_id': media['douban_id'],
        if (_text(media['title']).isNotEmpty) 'title': media['title'],
        if (_text(media['year']).isNotEmpty) 'year': media['year'],
        'season': season,
      },
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> prepareUpload({
    required String token,
    required FormData formData,
  }) async {
    final response = await _apiClient.postMultipart<dynamic>(
      '$basePath/prepare_upload',
      formData,
      token: token,
      timeout: 180,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> applyUpload(
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _apiClient.postJson<dynamic>(
      '$basePath/apply_upload',
      body,
      token: token,
      timeout: 180,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> postJsonAction(
    String endpoint,
    Map<String, dynamic> body,
    String token, {
    int timeout = 120,
  }) async {
    final response = await _apiClient.postJson<dynamic>(
      '$basePath/$endpoint',
      body,
      token: token,
      timeout: timeout,
    );
    return _unwrap(response);
  }

  Future<SubtitleManualUploadApiResult> getJsonAction(
    String endpoint,
    String token,
  ) async {
    final response = await _apiClient.get<dynamic>(
      '$basePath/$endpoint',
      token: token,
    );
    return _unwrap(response);
  }

  SubtitleManualUploadApiResult _unwrap(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final map = _extractMap(response.data);
    if (status >= 400) {
      throw SubtitleManualUploadApiException(
        _extractMessage(map, response.data, '请求失败'),
        status,
      );
    }
    if (map == null) {
      return SubtitleManualUploadApiResult(data: response.data);
    }
    final success = map['success'];
    if (success == false) {
      throw SubtitleManualUploadApiException(
        _extractMessage(map, response.data, '操作失败'),
        status,
      );
    }
    return SubtitleManualUploadApiResult(
      data: map.containsKey('data') ? map['data'] : map,
      message: _optionalText(map['message']) ?? _optionalText(map['msg']),
      raw: map,
    );
  }

  static String errorMessage(Object error, String fallback) {
    if (error is SubtitleManualUploadApiException) {
      return error.message.isEmpty ? fallback : error.message;
    }
    if (error is DioException) {
      final map = _extractMap(error.response?.data);
      return _extractMessage(map, error.message, fallback);
    }
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _extractMessage(
    Map<String, dynamic>? map,
    dynamic raw,
    String fallback,
  ) {
    final fromMap =
        _optionalText(map?['detail']) ??
        _optionalText(map?['message']) ??
        _optionalText(map?['msg']) ??
        _optionalText(map?['error']);
    if (fromMap != null) return fromMap;
    final rawText = _optionalText(raw);
    return rawText ?? fallback;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String? _optionalText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class SubtitleManualUploadApiException implements Exception {
  const SubtitleManualUploadApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

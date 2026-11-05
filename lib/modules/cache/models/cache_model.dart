import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_model.freezed.dart';
part 'cache_model.g.dart';

@freezed
class CacheResponse with _$CacheResponse {
  const factory CacheResponse({
    required bool success,
    String? message,
    CachePayload? data,
  }) = _CacheResponse;

  factory CacheResponse.fromJson(Map<String, dynamic> json) =>
      _$CacheResponseFromJson(json);
}

/// 解析 GET /api/v1/torrent/cache 的响应体，兼容三种运行时形态：
/// 1. 原始信封 `{success, message, data: {count, sites, data}}`（未拆包）；
/// 2. v3 拆包后的载荷 `{count, sites, data, success?, message?}`，顶层
///    `data` 是条目列表（unwrapV3EnvelopeOnResponse 的合并结果）；
/// 3. 纯条目列表。
/// 解析不了时返回 null，由调用方按请求失败处理。
CacheResponse? parseCacheResponse(Object? data) {
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    final looksLikeJson =
        (first == '{' && last == '}') || (first == '[' && last == ']');
    if (!looksLikeJson) return null;
    try {
      return parseCacheResponse(jsonDecode(trimmed));
    } catch (_) {
      return null;
    }
  }
  if (data is Map) {
    final inner = data['data'];
    if (inner is List) {
      final payload = CachePayload.fromJson(Map<String, dynamic>.from(data));
      return CacheResponse(
        success: data['success'] is bool ? data['success'] as bool : true,
        message: data['message'] is String ? data['message'] as String : null,
        data: payload,
      );
    }
    if (inner is Map || data['success'] is bool) {
      return CacheResponse.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
  if (data is List) {
    return CacheResponse(
      success: true,
      data: CachePayload(
        items: data
            .whereType<Map>()
            .map((e) => CacheItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      ),
    );
  }
  return null;
}

@freezed
class CachePayload with _$CachePayload {
  const factory CachePayload({
    @JsonKey(fromJson: _intFromJson) int? count,
    @JsonKey(fromJson: _intFromJson) int? sites,
    @JsonKey(name: 'data') List<CacheItem>? items,
  }) = _CachePayload;

  factory CachePayload.fromJson(Map<String, dynamic> json) =>
      _$CachePayloadFromJson(json);
}

@freezed
class CacheItem with _$CacheItem {
  const factory CacheItem({
    String? hash,
    String? domain,
    String? title,
    String? description,
    @JsonKey(fromJson: _intFromJson) int? size,
    String? pubdate,
    @JsonKey(name: 'site_name') String? siteName,
    @JsonKey(name: 'media_name') String? mediaName,
    @JsonKey(name: 'media_year', fromJson: _strFromJson) String? mediaYear,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'season_episode') String? seasonEpisode,
    @JsonKey(name: 'resource_term') String? resourceTerm,
    String? enclosure,
    @JsonKey(name: 'page_url') String? pageUrl,
    @JsonKey(name: 'poster_path') String? posterPath,
    @JsonKey(name: 'backdrop_path') String? backdropPath,
  }) = _CacheItem;

  factory CacheItem.fromJson(Map<String, dynamic> json) =>
      _$CacheItemFromJson(json);
}

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

// 服务端 media_year 可为 str | int（MediaInfo.year 是数字）
String? _strFromJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num) return value.toString();
  return null;
}

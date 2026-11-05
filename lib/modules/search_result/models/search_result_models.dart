import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
part 'search_result_models.freezed.dart';
part 'search_result_models.g.dart';

@freezed
class SearchResultItem with _$SearchResultItem {
  const factory SearchResultItem({
    @JsonKey(name: 'meta_info') SearchMetaInfo? meta_info,
    @JsonKey(name: 'media_info') RecommendApiItem? media_info,
    @JsonKey(name: 'torrent_info') SearchTorrentInfo? torrent_info,
  }) = _SearchResultItem;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    var normalized = Map<String, dynamic>.from(json);
    // v3 的实时搜索接口（/search/media/{media_id}、/search/title）直接返回种子信息，
    // 不再包一层 Context；这里补回 App 内部使用的 meta_info / media_info / torrent_info 结构。
    // v2 以及 v3 的 /search/last 仍返回 Context，带这三个键，不会走到这个分支。
    if (!normalized.containsKey('torrent_info') &&
        !normalized.containsKey('meta_info') &&
        !normalized.containsKey('media_info')) {
      normalized = <String, dynamic>{'torrent_info': normalized};
    }
    final mediaInfo = normalized['media_info'];
    if (mediaInfo is Map) {
      normalized['media_info'] = normalizeMediaJson(
        Map<String, dynamic>.from(mediaInfo),
      );
    }
    return _$SearchResultItemFromJson(normalized);
  }
}

@freezed
class SearchMetaInfo with _$SearchMetaInfo {
  const factory SearchMetaInfo({
    bool? isfile,
    String? org_string,
    String? title,
    String? subtitle,
    String? type,
    String? name,
    String? cn_name,
    String? en_name,
    String? year,
    @JsonKey(fromJson: _intFromJson) int? total_season,
    @JsonKey(fromJson: _intFromJson) int? begin_season,
    @JsonKey(fromJson: _intFromJson) int? end_season,
    @JsonKey(fromJson: _intFromJson) int? total_episode,
    @JsonKey(fromJson: _intFromJson) int? begin_episode,
    @JsonKey(fromJson: _intFromJson) int? end_episode,
    String? season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_list,
    String? part,
    String? resource_type,
    String? resource_effect,
    String? resource_pix,
    String? resource_team,
    String? video_encode,
    String? audio_encode,
    String? edition,
    String? web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? apply_words,
  }) = _SearchMetaInfo;

  factory SearchMetaInfo.fromJson(Map<String, dynamic> json) =>
      _$SearchMetaInfoFromJson(json);
}

@freezed
class SearchTorrentInfo with _$SearchTorrentInfo {
  const factory SearchTorrentInfo({
    @JsonKey(fromJson: _intFromJson) int? site,
    String? site_name,
    String? site_cookie,
    String? site_ua,
    @JsonKey(fromJson: _boolFromJson) bool? site_proxy,
    @JsonKey(fromJson: _intFromJson) int? site_order,
    String? site_downloader,
    String? title,
    String? description,
    String? imdbid,
    String? enclosure,
    String? page_url,
    @JsonKey(fromJson: _doubleFromJson) double? size,
    @JsonKey(fromJson: _intFromJson) int? seeders,
    @JsonKey(fromJson: _intFromJson) int? peers,
    @JsonKey(fromJson: _intFromJson) int? grabs,
    String? pubdate,
    String? date_elapsed,
    String? freedate,
    @JsonKey(fromJson: _doubleFromJson) double? uploadvolumefactor,
    @JsonKey(fromJson: _doubleFromJson) double? downloadvolumefactor,
    @JsonKey(fromJson: _boolFromJson) bool? hit_and_run,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? labels,
    @JsonKey(fromJson: _intFromJson) int? pri_order,
    String? volume_factor,
    String? freedate_diff,
  }) = _SearchTorrentInfo;

  factory SearchTorrentInfo.fromJson(Map<String, dynamic> json) =>
      _$SearchTorrentInfoFromJson(json);
}

bool? _boolFromJson(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<int> _intListFromJson(Object? value) {
  if (value is List) {
    return value.map(_intFromJson).whereType<int>().toList();
  }
  return const [];
}

List<int>? _intListToJson(List<int>? value) => value;

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

List<String>? _stringListToJson(List<String>? value) => value;

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CacheResponseImpl _$$CacheResponseImplFromJson(Map<String, dynamic> json) =>
    _$CacheResponseImpl(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : CachePayload.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CacheResponseImplToJson(_$CacheResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

_$CachePayloadImpl _$$CachePayloadImplFromJson(Map<String, dynamic> json) =>
    _$CachePayloadImpl(
      count: _intFromJson(json['count']),
      sites: _intFromJson(json['sites']),
      items: (json['data'] as List<dynamic>?)
          ?.map((e) => CacheItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$CachePayloadImplToJson(_$CachePayloadImpl instance) =>
    <String, dynamic>{
      'count': instance.count,
      'sites': instance.sites,
      'data': instance.items,
    };

_$CacheItemImpl _$$CacheItemImplFromJson(Map<String, dynamic> json) =>
    _$CacheItemImpl(
      hash: json['hash'] as String?,
      domain: json['domain'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      size: _intFromJson(json['size']),
      pubdate: json['pubdate'] as String?,
      siteName: json['site_name'] as String?,
      mediaName: json['media_name'] as String?,
      mediaYear: _strFromJson(json['media_year']),
      mediaType: json['media_type'] as String?,
      seasonEpisode: json['season_episode'] as String?,
      resourceTerm: json['resource_term'] as String?,
      enclosure: json['enclosure'] as String?,
      pageUrl: json['page_url'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );

Map<String, dynamic> _$$CacheItemImplToJson(_$CacheItemImpl instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'domain': instance.domain,
      'title': instance.title,
      'description': instance.description,
      'size': instance.size,
      'pubdate': instance.pubdate,
      'site_name': instance.siteName,
      'media_name': instance.mediaName,
      'media_year': instance.mediaYear,
      'media_type': instance.mediaType,
      'season_episode': instance.seasonEpisode,
      'resource_term': instance.resourceTerm,
      'enclosure': instance.enclosure,
      'page_url': instance.pageUrl,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
    };

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recognize_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecognizeResponse _$RecognizeResponseFromJson(Map<String, dynamic> json) {
  return _RecognizeResponse.fromJson(json);
}

/// @nodoc
mixin _$RecognizeResponse {
  @JsonKey(name: 'meta_info')
  MetaInfo? get meta_info => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_info')
  MediaInfo? get media_info => throw _privateConstructorUsedError;
  @JsonKey(name: 'torrent_info')
  TorrentInfo? get torrent_info => throw _privateConstructorUsedError;

  /// Serializes this RecognizeResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecognizeResponseCopyWith<RecognizeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecognizeResponseCopyWith<$Res> {
  factory $RecognizeResponseCopyWith(
    RecognizeResponse value,
    $Res Function(RecognizeResponse) then,
  ) = _$RecognizeResponseCopyWithImpl<$Res, RecognizeResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'meta_info') MetaInfo? meta_info,
    @JsonKey(name: 'media_info') MediaInfo? media_info,
    @JsonKey(name: 'torrent_info') TorrentInfo? torrent_info,
  });

  $MetaInfoCopyWith<$Res>? get meta_info;
  $MediaInfoCopyWith<$Res>? get media_info;
  $TorrentInfoCopyWith<$Res>? get torrent_info;
}

/// @nodoc
class _$RecognizeResponseCopyWithImpl<$Res, $Val extends RecognizeResponse>
    implements $RecognizeResponseCopyWith<$Res> {
  _$RecognizeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meta_info = freezed,
    Object? media_info = freezed,
    Object? torrent_info = freezed,
  }) {
    return _then(
      _value.copyWith(
            meta_info: freezed == meta_info
                ? _value.meta_info
                : meta_info // ignore: cast_nullable_to_non_nullable
                      as MetaInfo?,
            media_info: freezed == media_info
                ? _value.media_info
                : media_info // ignore: cast_nullable_to_non_nullable
                      as MediaInfo?,
            torrent_info: freezed == torrent_info
                ? _value.torrent_info
                : torrent_info // ignore: cast_nullable_to_non_nullable
                      as TorrentInfo?,
          )
          as $Val,
    );
  }

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MetaInfoCopyWith<$Res>? get meta_info {
    if (_value.meta_info == null) {
      return null;
    }

    return $MetaInfoCopyWith<$Res>(_value.meta_info!, (value) {
      return _then(_value.copyWith(meta_info: value) as $Val);
    });
  }

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MediaInfoCopyWith<$Res>? get media_info {
    if (_value.media_info == null) {
      return null;
    }

    return $MediaInfoCopyWith<$Res>(_value.media_info!, (value) {
      return _then(_value.copyWith(media_info: value) as $Val);
    });
  }

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TorrentInfoCopyWith<$Res>? get torrent_info {
    if (_value.torrent_info == null) {
      return null;
    }

    return $TorrentInfoCopyWith<$Res>(_value.torrent_info!, (value) {
      return _then(_value.copyWith(torrent_info: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecognizeResponseImplCopyWith<$Res>
    implements $RecognizeResponseCopyWith<$Res> {
  factory _$$RecognizeResponseImplCopyWith(
    _$RecognizeResponseImpl value,
    $Res Function(_$RecognizeResponseImpl) then,
  ) = __$$RecognizeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'meta_info') MetaInfo? meta_info,
    @JsonKey(name: 'media_info') MediaInfo? media_info,
    @JsonKey(name: 'torrent_info') TorrentInfo? torrent_info,
  });

  @override
  $MetaInfoCopyWith<$Res>? get meta_info;
  @override
  $MediaInfoCopyWith<$Res>? get media_info;
  @override
  $TorrentInfoCopyWith<$Res>? get torrent_info;
}

/// @nodoc
class __$$RecognizeResponseImplCopyWithImpl<$Res>
    extends _$RecognizeResponseCopyWithImpl<$Res, _$RecognizeResponseImpl>
    implements _$$RecognizeResponseImplCopyWith<$Res> {
  __$$RecognizeResponseImplCopyWithImpl(
    _$RecognizeResponseImpl _value,
    $Res Function(_$RecognizeResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meta_info = freezed,
    Object? media_info = freezed,
    Object? torrent_info = freezed,
  }) {
    return _then(
      _$RecognizeResponseImpl(
        meta_info: freezed == meta_info
            ? _value.meta_info
            : meta_info // ignore: cast_nullable_to_non_nullable
                  as MetaInfo?,
        media_info: freezed == media_info
            ? _value.media_info
            : media_info // ignore: cast_nullable_to_non_nullable
                  as MediaInfo?,
        torrent_info: freezed == torrent_info
            ? _value.torrent_info
            : torrent_info // ignore: cast_nullable_to_non_nullable
                  as TorrentInfo?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecognizeResponseImpl implements _RecognizeResponse {
  const _$RecognizeResponseImpl({
    @JsonKey(name: 'meta_info') this.meta_info,
    @JsonKey(name: 'media_info') this.media_info,
    @JsonKey(name: 'torrent_info') this.torrent_info,
  });

  factory _$RecognizeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecognizeResponseImplFromJson(json);

  @override
  @JsonKey(name: 'meta_info')
  final MetaInfo? meta_info;
  @override
  @JsonKey(name: 'media_info')
  final MediaInfo? media_info;
  @override
  @JsonKey(name: 'torrent_info')
  final TorrentInfo? torrent_info;

  @override
  String toString() {
    return 'RecognizeResponse(meta_info: $meta_info, media_info: $media_info, torrent_info: $torrent_info)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecognizeResponseImpl &&
            (identical(other.meta_info, meta_info) ||
                other.meta_info == meta_info) &&
            (identical(other.media_info, media_info) ||
                other.media_info == media_info) &&
            (identical(other.torrent_info, torrent_info) ||
                other.torrent_info == torrent_info));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, meta_info, media_info, torrent_info);

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecognizeResponseImplCopyWith<_$RecognizeResponseImpl> get copyWith =>
      __$$RecognizeResponseImplCopyWithImpl<_$RecognizeResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecognizeResponseImplToJson(this);
  }
}

abstract class _RecognizeResponse implements RecognizeResponse {
  const factory _RecognizeResponse({
    @JsonKey(name: 'meta_info') final MetaInfo? meta_info,
    @JsonKey(name: 'media_info') final MediaInfo? media_info,
    @JsonKey(name: 'torrent_info') final TorrentInfo? torrent_info,
  }) = _$RecognizeResponseImpl;

  factory _RecognizeResponse.fromJson(Map<String, dynamic> json) =
      _$RecognizeResponseImpl.fromJson;

  @override
  @JsonKey(name: 'meta_info')
  MetaInfo? get meta_info;
  @override
  @JsonKey(name: 'media_info')
  MediaInfo? get media_info;
  @override
  @JsonKey(name: 'torrent_info')
  TorrentInfo? get torrent_info;

  /// Create a copy of RecognizeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecognizeResponseImplCopyWith<_$RecognizeResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MetaInfo _$MetaInfoFromJson(Map<String, dynamic> json) {
  return _MetaInfo.fromJson(json);
}

/// @nodoc
mixin _$MetaInfo {
  @JsonKey(fromJson: _boolFromJson)
  bool? get isfile => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get org_string => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get subtitle => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get cn_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get en_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get year => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get total_season => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get begin_season => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get end_season => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get total_episode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get begin_episode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get end_episode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get season_episode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_list => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get part => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_effect => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_pix => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_team => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get video_encode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get audio_encode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get edition => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get web_source => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get apply_words => throw _privateConstructorUsedError;

  /// Serializes this MetaInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MetaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MetaInfoCopyWith<MetaInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetaInfoCopyWith<$Res> {
  factory $MetaInfoCopyWith(MetaInfo value, $Res Function(MetaInfo) then) =
      _$MetaInfoCopyWithImpl<$Res, MetaInfo>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _boolFromJson) bool? isfile,
    @JsonKey(fromJson: _stringFromJson) String? org_string,
    @JsonKey(fromJson: _stringFromJson) String? title,
    @JsonKey(fromJson: _stringFromJson) String? subtitle,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? cn_name,
    @JsonKey(fromJson: _stringFromJson) String? en_name,
    @JsonKey(fromJson: _stringFromJson) String? year,
    @JsonKey(fromJson: _intFromJson) int? total_season,
    @JsonKey(fromJson: _intFromJson) int? begin_season,
    @JsonKey(fromJson: _intFromJson) int? end_season,
    @JsonKey(fromJson: _intFromJson) int? total_episode,
    @JsonKey(fromJson: _intFromJson) int? begin_episode,
    @JsonKey(fromJson: _intFromJson) int? end_episode,
    @JsonKey(fromJson: _stringFromJson) String? season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_list,
    @JsonKey(fromJson: _stringFromJson) String? part,
    @JsonKey(fromJson: _stringFromJson) String? resource_type,
    @JsonKey(fromJson: _stringFromJson) String? resource_effect,
    @JsonKey(fromJson: _stringFromJson) String? resource_pix,
    @JsonKey(fromJson: _stringFromJson) String? resource_team,
    @JsonKey(fromJson: _stringFromJson) String? video_encode,
    @JsonKey(fromJson: _stringFromJson) String? audio_encode,
    @JsonKey(fromJson: _stringFromJson) String? edition,
    @JsonKey(fromJson: _stringFromJson) String? web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? apply_words,
  });
}

/// @nodoc
class _$MetaInfoCopyWithImpl<$Res, $Val extends MetaInfo>
    implements $MetaInfoCopyWith<$Res> {
  _$MetaInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MetaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isfile = freezed,
    Object? org_string = freezed,
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? type = freezed,
    Object? name = freezed,
    Object? cn_name = freezed,
    Object? en_name = freezed,
    Object? year = freezed,
    Object? total_season = freezed,
    Object? begin_season = freezed,
    Object? end_season = freezed,
    Object? total_episode = freezed,
    Object? begin_episode = freezed,
    Object? end_episode = freezed,
    Object? season_episode = freezed,
    Object? episode_list = freezed,
    Object? part = freezed,
    Object? resource_type = freezed,
    Object? resource_effect = freezed,
    Object? resource_pix = freezed,
    Object? resource_team = freezed,
    Object? video_encode = freezed,
    Object? audio_encode = freezed,
    Object? edition = freezed,
    Object? web_source = freezed,
    Object? apply_words = freezed,
  }) {
    return _then(
      _value.copyWith(
            isfile: freezed == isfile
                ? _value.isfile
                : isfile // ignore: cast_nullable_to_non_nullable
                      as bool?,
            org_string: freezed == org_string
                ? _value.org_string
                : org_string // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            cn_name: freezed == cn_name
                ? _value.cn_name
                : cn_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            en_name: freezed == en_name
                ? _value.en_name
                : en_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as String?,
            total_season: freezed == total_season
                ? _value.total_season
                : total_season // ignore: cast_nullable_to_non_nullable
                      as int?,
            begin_season: freezed == begin_season
                ? _value.begin_season
                : begin_season // ignore: cast_nullable_to_non_nullable
                      as int?,
            end_season: freezed == end_season
                ? _value.end_season
                : end_season // ignore: cast_nullable_to_non_nullable
                      as int?,
            total_episode: freezed == total_episode
                ? _value.total_episode
                : total_episode // ignore: cast_nullable_to_non_nullable
                      as int?,
            begin_episode: freezed == begin_episode
                ? _value.begin_episode
                : begin_episode // ignore: cast_nullable_to_non_nullable
                      as int?,
            end_episode: freezed == end_episode
                ? _value.end_episode
                : end_episode // ignore: cast_nullable_to_non_nullable
                      as int?,
            season_episode: freezed == season_episode
                ? _value.season_episode
                : season_episode // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_list: freezed == episode_list
                ? _value.episode_list
                : episode_list // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            part: freezed == part
                ? _value.part
                : part // ignore: cast_nullable_to_non_nullable
                      as String?,
            resource_type: freezed == resource_type
                ? _value.resource_type
                : resource_type // ignore: cast_nullable_to_non_nullable
                      as String?,
            resource_effect: freezed == resource_effect
                ? _value.resource_effect
                : resource_effect // ignore: cast_nullable_to_non_nullable
                      as String?,
            resource_pix: freezed == resource_pix
                ? _value.resource_pix
                : resource_pix // ignore: cast_nullable_to_non_nullable
                      as String?,
            resource_team: freezed == resource_team
                ? _value.resource_team
                : resource_team // ignore: cast_nullable_to_non_nullable
                      as String?,
            video_encode: freezed == video_encode
                ? _value.video_encode
                : video_encode // ignore: cast_nullable_to_non_nullable
                      as String?,
            audio_encode: freezed == audio_encode
                ? _value.audio_encode
                : audio_encode // ignore: cast_nullable_to_non_nullable
                      as String?,
            edition: freezed == edition
                ? _value.edition
                : edition // ignore: cast_nullable_to_non_nullable
                      as String?,
            web_source: freezed == web_source
                ? _value.web_source
                : web_source // ignore: cast_nullable_to_non_nullable
                      as String?,
            apply_words: freezed == apply_words
                ? _value.apply_words
                : apply_words // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MetaInfoImplCopyWith<$Res>
    implements $MetaInfoCopyWith<$Res> {
  factory _$$MetaInfoImplCopyWith(
    _$MetaInfoImpl value,
    $Res Function(_$MetaInfoImpl) then,
  ) = __$$MetaInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _boolFromJson) bool? isfile,
    @JsonKey(fromJson: _stringFromJson) String? org_string,
    @JsonKey(fromJson: _stringFromJson) String? title,
    @JsonKey(fromJson: _stringFromJson) String? subtitle,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? cn_name,
    @JsonKey(fromJson: _stringFromJson) String? en_name,
    @JsonKey(fromJson: _stringFromJson) String? year,
    @JsonKey(fromJson: _intFromJson) int? total_season,
    @JsonKey(fromJson: _intFromJson) int? begin_season,
    @JsonKey(fromJson: _intFromJson) int? end_season,
    @JsonKey(fromJson: _intFromJson) int? total_episode,
    @JsonKey(fromJson: _intFromJson) int? begin_episode,
    @JsonKey(fromJson: _intFromJson) int? end_episode,
    @JsonKey(fromJson: _stringFromJson) String? season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_list,
    @JsonKey(fromJson: _stringFromJson) String? part,
    @JsonKey(fromJson: _stringFromJson) String? resource_type,
    @JsonKey(fromJson: _stringFromJson) String? resource_effect,
    @JsonKey(fromJson: _stringFromJson) String? resource_pix,
    @JsonKey(fromJson: _stringFromJson) String? resource_team,
    @JsonKey(fromJson: _stringFromJson) String? video_encode,
    @JsonKey(fromJson: _stringFromJson) String? audio_encode,
    @JsonKey(fromJson: _stringFromJson) String? edition,
    @JsonKey(fromJson: _stringFromJson) String? web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? apply_words,
  });
}

/// @nodoc
class __$$MetaInfoImplCopyWithImpl<$Res>
    extends _$MetaInfoCopyWithImpl<$Res, _$MetaInfoImpl>
    implements _$$MetaInfoImplCopyWith<$Res> {
  __$$MetaInfoImplCopyWithImpl(
    _$MetaInfoImpl _value,
    $Res Function(_$MetaInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MetaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isfile = freezed,
    Object? org_string = freezed,
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? type = freezed,
    Object? name = freezed,
    Object? cn_name = freezed,
    Object? en_name = freezed,
    Object? year = freezed,
    Object? total_season = freezed,
    Object? begin_season = freezed,
    Object? end_season = freezed,
    Object? total_episode = freezed,
    Object? begin_episode = freezed,
    Object? end_episode = freezed,
    Object? season_episode = freezed,
    Object? episode_list = freezed,
    Object? part = freezed,
    Object? resource_type = freezed,
    Object? resource_effect = freezed,
    Object? resource_pix = freezed,
    Object? resource_team = freezed,
    Object? video_encode = freezed,
    Object? audio_encode = freezed,
    Object? edition = freezed,
    Object? web_source = freezed,
    Object? apply_words = freezed,
  }) {
    return _then(
      _$MetaInfoImpl(
        isfile: freezed == isfile
            ? _value.isfile
            : isfile // ignore: cast_nullable_to_non_nullable
                  as bool?,
        org_string: freezed == org_string
            ? _value.org_string
            : org_string // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        cn_name: freezed == cn_name
            ? _value.cn_name
            : cn_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        en_name: freezed == en_name
            ? _value.en_name
            : en_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as String?,
        total_season: freezed == total_season
            ? _value.total_season
            : total_season // ignore: cast_nullable_to_non_nullable
                  as int?,
        begin_season: freezed == begin_season
            ? _value.begin_season
            : begin_season // ignore: cast_nullable_to_non_nullable
                  as int?,
        end_season: freezed == end_season
            ? _value.end_season
            : end_season // ignore: cast_nullable_to_non_nullable
                  as int?,
        total_episode: freezed == total_episode
            ? _value.total_episode
            : total_episode // ignore: cast_nullable_to_non_nullable
                  as int?,
        begin_episode: freezed == begin_episode
            ? _value.begin_episode
            : begin_episode // ignore: cast_nullable_to_non_nullable
                  as int?,
        end_episode: freezed == end_episode
            ? _value.end_episode
            : end_episode // ignore: cast_nullable_to_non_nullable
                  as int?,
        season_episode: freezed == season_episode
            ? _value.season_episode
            : season_episode // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_list: freezed == episode_list
            ? _value._episode_list
            : episode_list // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        part: freezed == part
            ? _value.part
            : part // ignore: cast_nullable_to_non_nullable
                  as String?,
        resource_type: freezed == resource_type
            ? _value.resource_type
            : resource_type // ignore: cast_nullable_to_non_nullable
                  as String?,
        resource_effect: freezed == resource_effect
            ? _value.resource_effect
            : resource_effect // ignore: cast_nullable_to_non_nullable
                  as String?,
        resource_pix: freezed == resource_pix
            ? _value.resource_pix
            : resource_pix // ignore: cast_nullable_to_non_nullable
                  as String?,
        resource_team: freezed == resource_team
            ? _value.resource_team
            : resource_team // ignore: cast_nullable_to_non_nullable
                  as String?,
        video_encode: freezed == video_encode
            ? _value.video_encode
            : video_encode // ignore: cast_nullable_to_non_nullable
                  as String?,
        audio_encode: freezed == audio_encode
            ? _value.audio_encode
            : audio_encode // ignore: cast_nullable_to_non_nullable
                  as String?,
        edition: freezed == edition
            ? _value.edition
            : edition // ignore: cast_nullable_to_non_nullable
                  as String?,
        web_source: freezed == web_source
            ? _value.web_source
            : web_source // ignore: cast_nullable_to_non_nullable
                  as String?,
        apply_words: freezed == apply_words
            ? _value._apply_words
            : apply_words // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MetaInfoImpl implements _MetaInfo {
  const _$MetaInfoImpl({
    @JsonKey(fromJson: _boolFromJson) this.isfile,
    @JsonKey(fromJson: _stringFromJson) this.org_string,
    @JsonKey(fromJson: _stringFromJson) this.title,
    @JsonKey(fromJson: _stringFromJson) this.subtitle,
    @JsonKey(fromJson: _stringFromJson) this.type,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.cn_name,
    @JsonKey(fromJson: _stringFromJson) this.en_name,
    @JsonKey(fromJson: _stringFromJson) this.year,
    @JsonKey(fromJson: _intFromJson) this.total_season,
    @JsonKey(fromJson: _intFromJson) this.begin_season,
    @JsonKey(fromJson: _intFromJson) this.end_season,
    @JsonKey(fromJson: _intFromJson) this.total_episode,
    @JsonKey(fromJson: _intFromJson) this.begin_episode,
    @JsonKey(fromJson: _intFromJson) this.end_episode,
    @JsonKey(fromJson: _stringFromJson) this.season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_list,
    @JsonKey(fromJson: _stringFromJson) this.part,
    @JsonKey(fromJson: _stringFromJson) this.resource_type,
    @JsonKey(fromJson: _stringFromJson) this.resource_effect,
    @JsonKey(fromJson: _stringFromJson) this.resource_pix,
    @JsonKey(fromJson: _stringFromJson) this.resource_team,
    @JsonKey(fromJson: _stringFromJson) this.video_encode,
    @JsonKey(fromJson: _stringFromJson) this.audio_encode,
    @JsonKey(fromJson: _stringFromJson) this.edition,
    @JsonKey(fromJson: _stringFromJson) this.web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? apply_words,
  }) : _episode_list = episode_list,
       _apply_words = apply_words;

  factory _$MetaInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MetaInfoImplFromJson(json);

  @override
  @JsonKey(fromJson: _boolFromJson)
  final bool? isfile;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? org_string;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? subtitle;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? cn_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? en_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? year;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? total_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? begin_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? end_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? total_episode;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? begin_episode;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? end_episode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? season_episode;
  final List<int>? _episode_list;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_list {
    final value = _episode_list;
    if (value == null) return null;
    if (_episode_list is EqualUnmodifiableListView) return _episode_list;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? part;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? resource_type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? resource_effect;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? resource_pix;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? resource_team;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? video_encode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? audio_encode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? edition;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? web_source;
  final List<String>? _apply_words;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get apply_words {
    final value = _apply_words;
    if (value == null) return null;
    if (_apply_words is EqualUnmodifiableListView) return _apply_words;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'MetaInfo(isfile: $isfile, org_string: $org_string, title: $title, subtitle: $subtitle, type: $type, name: $name, cn_name: $cn_name, en_name: $en_name, year: $year, total_season: $total_season, begin_season: $begin_season, end_season: $end_season, total_episode: $total_episode, begin_episode: $begin_episode, end_episode: $end_episode, season_episode: $season_episode, episode_list: $episode_list, part: $part, resource_type: $resource_type, resource_effect: $resource_effect, resource_pix: $resource_pix, resource_team: $resource_team, video_encode: $video_encode, audio_encode: $audio_encode, edition: $edition, web_source: $web_source, apply_words: $apply_words)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetaInfoImpl &&
            (identical(other.isfile, isfile) || other.isfile == isfile) &&
            (identical(other.org_string, org_string) ||
                other.org_string == org_string) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.cn_name, cn_name) || other.cn_name == cn_name) &&
            (identical(other.en_name, en_name) || other.en_name == en_name) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.total_season, total_season) ||
                other.total_season == total_season) &&
            (identical(other.begin_season, begin_season) ||
                other.begin_season == begin_season) &&
            (identical(other.end_season, end_season) ||
                other.end_season == end_season) &&
            (identical(other.total_episode, total_episode) ||
                other.total_episode == total_episode) &&
            (identical(other.begin_episode, begin_episode) ||
                other.begin_episode == begin_episode) &&
            (identical(other.end_episode, end_episode) ||
                other.end_episode == end_episode) &&
            (identical(other.season_episode, season_episode) ||
                other.season_episode == season_episode) &&
            const DeepCollectionEquality().equals(
              other._episode_list,
              _episode_list,
            ) &&
            (identical(other.part, part) || other.part == part) &&
            (identical(other.resource_type, resource_type) ||
                other.resource_type == resource_type) &&
            (identical(other.resource_effect, resource_effect) ||
                other.resource_effect == resource_effect) &&
            (identical(other.resource_pix, resource_pix) ||
                other.resource_pix == resource_pix) &&
            (identical(other.resource_team, resource_team) ||
                other.resource_team == resource_team) &&
            (identical(other.video_encode, video_encode) ||
                other.video_encode == video_encode) &&
            (identical(other.audio_encode, audio_encode) ||
                other.audio_encode == audio_encode) &&
            (identical(other.edition, edition) || other.edition == edition) &&
            (identical(other.web_source, web_source) ||
                other.web_source == web_source) &&
            const DeepCollectionEquality().equals(
              other._apply_words,
              _apply_words,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    isfile,
    org_string,
    title,
    subtitle,
    type,
    name,
    cn_name,
    en_name,
    year,
    total_season,
    begin_season,
    end_season,
    total_episode,
    begin_episode,
    end_episode,
    season_episode,
    const DeepCollectionEquality().hash(_episode_list),
    part,
    resource_type,
    resource_effect,
    resource_pix,
    resource_team,
    video_encode,
    audio_encode,
    edition,
    web_source,
    const DeepCollectionEquality().hash(_apply_words),
  ]);

  /// Create a copy of MetaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MetaInfoImplCopyWith<_$MetaInfoImpl> get copyWith =>
      __$$MetaInfoImplCopyWithImpl<_$MetaInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MetaInfoImplToJson(this);
  }
}

abstract class _MetaInfo implements MetaInfo {
  const factory _MetaInfo({
    @JsonKey(fromJson: _boolFromJson) final bool? isfile,
    @JsonKey(fromJson: _stringFromJson) final String? org_string,
    @JsonKey(fromJson: _stringFromJson) final String? title,
    @JsonKey(fromJson: _stringFromJson) final String? subtitle,
    @JsonKey(fromJson: _stringFromJson) final String? type,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? cn_name,
    @JsonKey(fromJson: _stringFromJson) final String? en_name,
    @JsonKey(fromJson: _stringFromJson) final String? year,
    @JsonKey(fromJson: _intFromJson) final int? total_season,
    @JsonKey(fromJson: _intFromJson) final int? begin_season,
    @JsonKey(fromJson: _intFromJson) final int? end_season,
    @JsonKey(fromJson: _intFromJson) final int? total_episode,
    @JsonKey(fromJson: _intFromJson) final int? begin_episode,
    @JsonKey(fromJson: _intFromJson) final int? end_episode,
    @JsonKey(fromJson: _stringFromJson) final String? season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_list,
    @JsonKey(fromJson: _stringFromJson) final String? part,
    @JsonKey(fromJson: _stringFromJson) final String? resource_type,
    @JsonKey(fromJson: _stringFromJson) final String? resource_effect,
    @JsonKey(fromJson: _stringFromJson) final String? resource_pix,
    @JsonKey(fromJson: _stringFromJson) final String? resource_team,
    @JsonKey(fromJson: _stringFromJson) final String? video_encode,
    @JsonKey(fromJson: _stringFromJson) final String? audio_encode,
    @JsonKey(fromJson: _stringFromJson) final String? edition,
    @JsonKey(fromJson: _stringFromJson) final String? web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? apply_words,
  }) = _$MetaInfoImpl;

  factory _MetaInfo.fromJson(Map<String, dynamic> json) =
      _$MetaInfoImpl.fromJson;

  @override
  @JsonKey(fromJson: _boolFromJson)
  bool? get isfile;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get org_string;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get subtitle;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get cn_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get en_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get year;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get total_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get begin_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get end_season;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get total_episode;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get begin_episode;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get end_episode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get season_episode;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_list;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get part;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_effect;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_pix;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get resource_team;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get video_encode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get audio_encode;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get edition;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get web_source;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get apply_words;

  /// Create a copy of MetaInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MetaInfoImplCopyWith<_$MetaInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MediaInfo _$MediaInfoFromJson(Map<String, dynamic> json) {
  return _MediaInfo.fromJson(json);
}

/// @nodoc
mixin _$MediaInfo {
  @JsonKey(fromJson: _stringFromJson)
  String? get source => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get en_title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get year => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get title_year => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get tmdb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get imdb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get tvdb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get douban_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get bangumi_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get collection_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get mediaid_prefix => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get media_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_language => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get backdrop_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get poster_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons => throw _privateConstructorUsedError;
  List<SeasonInfo>? get season_info => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names => throw _privateConstructorUsedError;
  List<Actor>? get actors => throw _privateConstructorUsedError;
  List<Director>? get directors => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get detail_link => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult => throw _privateConstructorUsedError;
  List<CreatedBy>? get created_by => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time => throw _privateConstructorUsedError;
  List<Genre>? get genres => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get first_air_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get homepage => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get last_air_date => throw _privateConstructorUsedError;
  List<Network>? get networks => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_episodes => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_seasons => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name => throw _privateConstructorUsedError;
  List<ProductionCompany>? get production_companies =>
      throw _privateConstructorUsedError;
  List<ProductionCountry>? get production_countries =>
      throw _privateConstructorUsedError;
  List<SpokenLanguage>? get spoken_languages =>
      throw _privateConstructorUsedError;
  List<ReleaseDate>? get release_dates => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get tagline => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get runtime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  NextEpisodeToAir? get next_episode_to_air =>
      throw _privateConstructorUsedError;
  @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
  List<EpisodeGroup>? get episode_groups => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
  EpisodeGroup? get episode_group => throw _privateConstructorUsedError;

  /// Serializes this MediaInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaInfoCopyWith<MediaInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaInfoCopyWith<$Res> {
  factory $MediaInfoCopyWith(MediaInfo value, $Res Function(MediaInfo) then) =
      _$MediaInfoCopyWithImpl<$Res, MediaInfo>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? source,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _stringFromJson) String? title,
    @JsonKey(fromJson: _stringFromJson) String? en_title,
    @JsonKey(fromJson: _stringFromJson) String? year,
    @JsonKey(fromJson: _stringFromJson) String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    @JsonKey(fromJson: _stringFromJson) String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    @JsonKey(fromJson: _stringFromJson) String? mediaid_prefix,
    @JsonKey(fromJson: _stringFromJson) String? media_id,
    @JsonKey(fromJson: _stringFromJson) String? original_language,
    @JsonKey(fromJson: _stringFromJson) String? original_title,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _stringFromJson) String? backdrop_path,
    @JsonKey(fromJson: _stringFromJson) String? poster_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? category,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    List<SeasonEpisodes>? seasons,
    List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? names,
    List<Actor>? actors,
    List<Director>? directors,
    @JsonKey(fromJson: _stringFromJson) String? detail_link,
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_run_time,
    List<Genre>? genres,
    @JsonKey(fromJson: _stringFromJson) String? first_air_date,
    @JsonKey(fromJson: _stringFromJson) String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? languages,
    @JsonKey(fromJson: _stringFromJson) String? last_air_date,
    List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? origin_country,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    List<ProductionCompany>? production_companies,
    List<ProductionCountry>? production_countries,
    List<SpokenLanguage>? spoken_languages,
    List<ReleaseDate>? release_dates,
    @JsonKey(fromJson: _stringFromJson) String? status,
    @JsonKey(fromJson: _stringFromJson) String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    NextEpisodeToAir? next_episode_to_air,
    @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
    List<EpisodeGroup>? episode_groups,
    @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
    EpisodeGroup? episode_group,
  });

  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air;
  $EpisodeGroupCopyWith<$Res>? get episode_group;
}

/// @nodoc
class _$MediaInfoCopyWithImpl<$Res, $Val extends MediaInfo>
    implements $MediaInfoCopyWith<$Res> {
  _$MediaInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? type = freezed,
    Object? title = freezed,
    Object? en_title = freezed,
    Object? year = freezed,
    Object? title_year = freezed,
    Object? season = freezed,
    Object? tmdb_id = freezed,
    Object? imdb_id = freezed,
    Object? tvdb_id = freezed,
    Object? douban_id = freezed,
    Object? bangumi_id = freezed,
    Object? collection_id = freezed,
    Object? mediaid_prefix = freezed,
    Object? media_id = freezed,
    Object? original_language = freezed,
    Object? original_title = freezed,
    Object? release_date = freezed,
    Object? backdrop_path = freezed,
    Object? poster_path = freezed,
    Object? vote_average = freezed,
    Object? overview = freezed,
    Object? category = freezed,
    Object? seasons = freezed,
    Object? season_info = freezed,
    Object? names = freezed,
    Object? actors = freezed,
    Object? directors = freezed,
    Object? detail_link = freezed,
    Object? adult = freezed,
    Object? created_by = freezed,
    Object? episode_run_time = freezed,
    Object? genres = freezed,
    Object? first_air_date = freezed,
    Object? homepage = freezed,
    Object? languages = freezed,
    Object? last_air_date = freezed,
    Object? networks = freezed,
    Object? number_of_episodes = freezed,
    Object? number_of_seasons = freezed,
    Object? origin_country = freezed,
    Object? original_name = freezed,
    Object? production_companies = freezed,
    Object? production_countries = freezed,
    Object? spoken_languages = freezed,
    Object? release_dates = freezed,
    Object? status = freezed,
    Object? tagline = freezed,
    Object? genre_ids = freezed,
    Object? vote_count = freezed,
    Object? popularity = freezed,
    Object? runtime = freezed,
    Object? next_episode_to_air = freezed,
    Object? episode_groups = freezed,
    Object? episode_group = freezed,
  }) {
    return _then(
      _value.copyWith(
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            en_title: freezed == en_title
                ? _value.en_title
                : en_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as String?,
            title_year: freezed == title_year
                ? _value.title_year
                : title_year // ignore: cast_nullable_to_non_nullable
                      as String?,
            season: freezed == season
                ? _value.season
                : season // ignore: cast_nullable_to_non_nullable
                      as int?,
            tmdb_id: freezed == tmdb_id
                ? _value.tmdb_id
                : tmdb_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            imdb_id: freezed == imdb_id
                ? _value.imdb_id
                : imdb_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            tvdb_id: freezed == tvdb_id
                ? _value.tvdb_id
                : tvdb_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            douban_id: freezed == douban_id
                ? _value.douban_id
                : douban_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            bangumi_id: freezed == bangumi_id
                ? _value.bangumi_id
                : bangumi_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            collection_id: freezed == collection_id
                ? _value.collection_id
                : collection_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            mediaid_prefix: freezed == mediaid_prefix
                ? _value.mediaid_prefix
                : mediaid_prefix // ignore: cast_nullable_to_non_nullable
                      as String?,
            media_id: freezed == media_id
                ? _value.media_id
                : media_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_language: freezed == original_language
                ? _value.original_language
                : original_language // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_title: freezed == original_title
                ? _value.original_title
                : original_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            release_date: freezed == release_date
                ? _value.release_date
                : release_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            backdrop_path: freezed == backdrop_path
                ? _value.backdrop_path
                : backdrop_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            poster_path: freezed == poster_path
                ? _value.poster_path
                : poster_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            seasons: freezed == seasons
                ? _value.seasons
                : seasons // ignore: cast_nullable_to_non_nullable
                      as List<SeasonEpisodes>?,
            season_info: freezed == season_info
                ? _value.season_info
                : season_info // ignore: cast_nullable_to_non_nullable
                      as List<SeasonInfo>?,
            names: freezed == names
                ? _value.names
                : names // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            actors: freezed == actors
                ? _value.actors
                : actors // ignore: cast_nullable_to_non_nullable
                      as List<Actor>?,
            directors: freezed == directors
                ? _value.directors
                : directors // ignore: cast_nullable_to_non_nullable
                      as List<Director>?,
            detail_link: freezed == detail_link
                ? _value.detail_link
                : detail_link // ignore: cast_nullable_to_non_nullable
                      as String?,
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            created_by: freezed == created_by
                ? _value.created_by
                : created_by // ignore: cast_nullable_to_non_nullable
                      as List<CreatedBy>?,
            episode_run_time: freezed == episode_run_time
                ? _value.episode_run_time
                : episode_run_time // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            genres: freezed == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<Genre>?,
            first_air_date: freezed == first_air_date
                ? _value.first_air_date
                : first_air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            homepage: freezed == homepage
                ? _value.homepage
                : homepage // ignore: cast_nullable_to_non_nullable
                      as String?,
            languages: freezed == languages
                ? _value.languages
                : languages // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            last_air_date: freezed == last_air_date
                ? _value.last_air_date
                : last_air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            networks: freezed == networks
                ? _value.networks
                : networks // ignore: cast_nullable_to_non_nullable
                      as List<Network>?,
            number_of_episodes: freezed == number_of_episodes
                ? _value.number_of_episodes
                : number_of_episodes // ignore: cast_nullable_to_non_nullable
                      as int?,
            number_of_seasons: freezed == number_of_seasons
                ? _value.number_of_seasons
                : number_of_seasons // ignore: cast_nullable_to_non_nullable
                      as int?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            production_companies: freezed == production_companies
                ? _value.production_companies
                : production_companies // ignore: cast_nullable_to_non_nullable
                      as List<ProductionCompany>?,
            production_countries: freezed == production_countries
                ? _value.production_countries
                : production_countries // ignore: cast_nullable_to_non_nullable
                      as List<ProductionCountry>?,
            spoken_languages: freezed == spoken_languages
                ? _value.spoken_languages
                : spoken_languages // ignore: cast_nullable_to_non_nullable
                      as List<SpokenLanguage>?,
            release_dates: freezed == release_dates
                ? _value.release_dates
                : release_dates // ignore: cast_nullable_to_non_nullable
                      as List<ReleaseDate>?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            tagline: freezed == tagline
                ? _value.tagline
                : tagline // ignore: cast_nullable_to_non_nullable
                      as String?,
            genre_ids: freezed == genre_ids
                ? _value.genre_ids
                : genre_ids // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            vote_count: freezed == vote_count
                ? _value.vote_count
                : vote_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            runtime: freezed == runtime
                ? _value.runtime
                : runtime // ignore: cast_nullable_to_non_nullable
                      as int?,
            next_episode_to_air: freezed == next_episode_to_air
                ? _value.next_episode_to_air
                : next_episode_to_air // ignore: cast_nullable_to_non_nullable
                      as NextEpisodeToAir?,
            episode_groups: freezed == episode_groups
                ? _value.episode_groups
                : episode_groups // ignore: cast_nullable_to_non_nullable
                      as List<EpisodeGroup>?,
            episode_group: freezed == episode_group
                ? _value.episode_group
                : episode_group // ignore: cast_nullable_to_non_nullable
                      as EpisodeGroup?,
          )
          as $Val,
    );
  }

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air {
    if (_value.next_episode_to_air == null) {
      return null;
    }

    return $NextEpisodeToAirCopyWith<$Res>(_value.next_episode_to_air!, (
      value,
    ) {
      return _then(_value.copyWith(next_episode_to_air: value) as $Val);
    });
  }

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpisodeGroupCopyWith<$Res>? get episode_group {
    if (_value.episode_group == null) {
      return null;
    }

    return $EpisodeGroupCopyWith<$Res>(_value.episode_group!, (value) {
      return _then(_value.copyWith(episode_group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MediaInfoImplCopyWith<$Res>
    implements $MediaInfoCopyWith<$Res> {
  factory _$$MediaInfoImplCopyWith(
    _$MediaInfoImpl value,
    $Res Function(_$MediaInfoImpl) then,
  ) = __$$MediaInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? source,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _stringFromJson) String? title,
    @JsonKey(fromJson: _stringFromJson) String? en_title,
    @JsonKey(fromJson: _stringFromJson) String? year,
    @JsonKey(fromJson: _stringFromJson) String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    @JsonKey(fromJson: _stringFromJson) String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    @JsonKey(fromJson: _stringFromJson) String? mediaid_prefix,
    @JsonKey(fromJson: _stringFromJson) String? media_id,
    @JsonKey(fromJson: _stringFromJson) String? original_language,
    @JsonKey(fromJson: _stringFromJson) String? original_title,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _stringFromJson) String? backdrop_path,
    @JsonKey(fromJson: _stringFromJson) String? poster_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? category,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    List<SeasonEpisodes>? seasons,
    List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? names,
    List<Actor>? actors,
    List<Director>? directors,
    @JsonKey(fromJson: _stringFromJson) String? detail_link,
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_run_time,
    List<Genre>? genres,
    @JsonKey(fromJson: _stringFromJson) String? first_air_date,
    @JsonKey(fromJson: _stringFromJson) String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? languages,
    @JsonKey(fromJson: _stringFromJson) String? last_air_date,
    List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? origin_country,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    List<ProductionCompany>? production_companies,
    List<ProductionCountry>? production_countries,
    List<SpokenLanguage>? spoken_languages,
    List<ReleaseDate>? release_dates,
    @JsonKey(fromJson: _stringFromJson) String? status,
    @JsonKey(fromJson: _stringFromJson) String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    NextEpisodeToAir? next_episode_to_air,
    @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
    List<EpisodeGroup>? episode_groups,
    @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
    EpisodeGroup? episode_group,
  });

  @override
  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air;
  @override
  $EpisodeGroupCopyWith<$Res>? get episode_group;
}

/// @nodoc
class __$$MediaInfoImplCopyWithImpl<$Res>
    extends _$MediaInfoCopyWithImpl<$Res, _$MediaInfoImpl>
    implements _$$MediaInfoImplCopyWith<$Res> {
  __$$MediaInfoImplCopyWithImpl(
    _$MediaInfoImpl _value,
    $Res Function(_$MediaInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? type = freezed,
    Object? title = freezed,
    Object? en_title = freezed,
    Object? year = freezed,
    Object? title_year = freezed,
    Object? season = freezed,
    Object? tmdb_id = freezed,
    Object? imdb_id = freezed,
    Object? tvdb_id = freezed,
    Object? douban_id = freezed,
    Object? bangumi_id = freezed,
    Object? collection_id = freezed,
    Object? mediaid_prefix = freezed,
    Object? media_id = freezed,
    Object? original_language = freezed,
    Object? original_title = freezed,
    Object? release_date = freezed,
    Object? backdrop_path = freezed,
    Object? poster_path = freezed,
    Object? vote_average = freezed,
    Object? overview = freezed,
    Object? category = freezed,
    Object? seasons = freezed,
    Object? season_info = freezed,
    Object? names = freezed,
    Object? actors = freezed,
    Object? directors = freezed,
    Object? detail_link = freezed,
    Object? adult = freezed,
    Object? created_by = freezed,
    Object? episode_run_time = freezed,
    Object? genres = freezed,
    Object? first_air_date = freezed,
    Object? homepage = freezed,
    Object? languages = freezed,
    Object? last_air_date = freezed,
    Object? networks = freezed,
    Object? number_of_episodes = freezed,
    Object? number_of_seasons = freezed,
    Object? origin_country = freezed,
    Object? original_name = freezed,
    Object? production_companies = freezed,
    Object? production_countries = freezed,
    Object? spoken_languages = freezed,
    Object? release_dates = freezed,
    Object? status = freezed,
    Object? tagline = freezed,
    Object? genre_ids = freezed,
    Object? vote_count = freezed,
    Object? popularity = freezed,
    Object? runtime = freezed,
    Object? next_episode_to_air = freezed,
    Object? episode_groups = freezed,
    Object? episode_group = freezed,
  }) {
    return _then(
      _$MediaInfoImpl(
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        en_title: freezed == en_title
            ? _value.en_title
            : en_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as String?,
        title_year: freezed == title_year
            ? _value.title_year
            : title_year // ignore: cast_nullable_to_non_nullable
                  as String?,
        season: freezed == season
            ? _value.season
            : season // ignore: cast_nullable_to_non_nullable
                  as int?,
        tmdb_id: freezed == tmdb_id
            ? _value.tmdb_id
            : tmdb_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        imdb_id: freezed == imdb_id
            ? _value.imdb_id
            : imdb_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        tvdb_id: freezed == tvdb_id
            ? _value.tvdb_id
            : tvdb_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        douban_id: freezed == douban_id
            ? _value.douban_id
            : douban_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        bangumi_id: freezed == bangumi_id
            ? _value.bangumi_id
            : bangumi_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        collection_id: freezed == collection_id
            ? _value.collection_id
            : collection_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        mediaid_prefix: freezed == mediaid_prefix
            ? _value.mediaid_prefix
            : mediaid_prefix // ignore: cast_nullable_to_non_nullable
                  as String?,
        media_id: freezed == media_id
            ? _value.media_id
            : media_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_language: freezed == original_language
            ? _value.original_language
            : original_language // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_title: freezed == original_title
            ? _value.original_title
            : original_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        release_date: freezed == release_date
            ? _value.release_date
            : release_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        backdrop_path: freezed == backdrop_path
            ? _value.backdrop_path
            : backdrop_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        poster_path: freezed == poster_path
            ? _value.poster_path
            : poster_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        seasons: freezed == seasons
            ? _value._seasons
            : seasons // ignore: cast_nullable_to_non_nullable
                  as List<SeasonEpisodes>?,
        season_info: freezed == season_info
            ? _value._season_info
            : season_info // ignore: cast_nullable_to_non_nullable
                  as List<SeasonInfo>?,
        names: freezed == names
            ? _value._names
            : names // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        actors: freezed == actors
            ? _value._actors
            : actors // ignore: cast_nullable_to_non_nullable
                  as List<Actor>?,
        directors: freezed == directors
            ? _value._directors
            : directors // ignore: cast_nullable_to_non_nullable
                  as List<Director>?,
        detail_link: freezed == detail_link
            ? _value.detail_link
            : detail_link // ignore: cast_nullable_to_non_nullable
                  as String?,
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        created_by: freezed == created_by
            ? _value._created_by
            : created_by // ignore: cast_nullable_to_non_nullable
                  as List<CreatedBy>?,
        episode_run_time: freezed == episode_run_time
            ? _value._episode_run_time
            : episode_run_time // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        genres: freezed == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<Genre>?,
        first_air_date: freezed == first_air_date
            ? _value.first_air_date
            : first_air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        homepage: freezed == homepage
            ? _value.homepage
            : homepage // ignore: cast_nullable_to_non_nullable
                  as String?,
        languages: freezed == languages
            ? _value._languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        last_air_date: freezed == last_air_date
            ? _value.last_air_date
            : last_air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        networks: freezed == networks
            ? _value._networks
            : networks // ignore: cast_nullable_to_non_nullable
                  as List<Network>?,
        number_of_episodes: freezed == number_of_episodes
            ? _value.number_of_episodes
            : number_of_episodes // ignore: cast_nullable_to_non_nullable
                  as int?,
        number_of_seasons: freezed == number_of_seasons
            ? _value.number_of_seasons
            : number_of_seasons // ignore: cast_nullable_to_non_nullable
                  as int?,
        origin_country: freezed == origin_country
            ? _value._origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        production_companies: freezed == production_companies
            ? _value._production_companies
            : production_companies // ignore: cast_nullable_to_non_nullable
                  as List<ProductionCompany>?,
        production_countries: freezed == production_countries
            ? _value._production_countries
            : production_countries // ignore: cast_nullable_to_non_nullable
                  as List<ProductionCountry>?,
        spoken_languages: freezed == spoken_languages
            ? _value._spoken_languages
            : spoken_languages // ignore: cast_nullable_to_non_nullable
                  as List<SpokenLanguage>?,
        release_dates: freezed == release_dates
            ? _value._release_dates
            : release_dates // ignore: cast_nullable_to_non_nullable
                  as List<ReleaseDate>?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        tagline: freezed == tagline
            ? _value.tagline
            : tagline // ignore: cast_nullable_to_non_nullable
                  as String?,
        genre_ids: freezed == genre_ids
            ? _value._genre_ids
            : genre_ids // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        vote_count: freezed == vote_count
            ? _value.vote_count
            : vote_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        runtime: freezed == runtime
            ? _value.runtime
            : runtime // ignore: cast_nullable_to_non_nullable
                  as int?,
        next_episode_to_air: freezed == next_episode_to_air
            ? _value.next_episode_to_air
            : next_episode_to_air // ignore: cast_nullable_to_non_nullable
                  as NextEpisodeToAir?,
        episode_groups: freezed == episode_groups
            ? _value._episode_groups
            : episode_groups // ignore: cast_nullable_to_non_nullable
                  as List<EpisodeGroup>?,
        episode_group: freezed == episode_group
            ? _value.episode_group
            : episode_group // ignore: cast_nullable_to_non_nullable
                  as EpisodeGroup?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaInfoImpl implements _MediaInfo {
  const _$MediaInfoImpl({
    @JsonKey(fromJson: _stringFromJson) this.source,
    @JsonKey(fromJson: _stringFromJson) this.type,
    @JsonKey(fromJson: _stringFromJson) this.title,
    @JsonKey(fromJson: _stringFromJson) this.en_title,
    @JsonKey(fromJson: _stringFromJson) this.year,
    @JsonKey(fromJson: _stringFromJson) this.title_year,
    @JsonKey(fromJson: _intFromJson) this.season,
    @JsonKey(fromJson: _intFromJson) this.tmdb_id,
    @JsonKey(fromJson: _stringFromJson) this.imdb_id,
    @JsonKey(fromJson: _intFromJson) this.tvdb_id,
    @JsonKey(fromJson: _intFromJson) this.douban_id,
    @JsonKey(fromJson: _intFromJson) this.bangumi_id,
    @JsonKey(fromJson: _intFromJson) this.collection_id,
    @JsonKey(fromJson: _stringFromJson) this.mediaid_prefix,
    @JsonKey(fromJson: _stringFromJson) this.media_id,
    @JsonKey(fromJson: _stringFromJson) this.original_language,
    @JsonKey(fromJson: _stringFromJson) this.original_title,
    @JsonKey(fromJson: _stringFromJson) this.release_date,
    @JsonKey(fromJson: _stringFromJson) this.backdrop_path,
    @JsonKey(fromJson: _stringFromJson) this.poster_path,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
    @JsonKey(fromJson: _stringFromJson) this.overview,
    @JsonKey(fromJson: _stringFromJson) this.category,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    final List<SeasonEpisodes>? seasons,
    final List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? names,
    final List<Actor>? actors,
    final List<Director>? directors,
    @JsonKey(fromJson: _stringFromJson) this.detail_link,
    @JsonKey(fromJson: _boolFromJson) this.adult,
    final List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_run_time,
    final List<Genre>? genres,
    @JsonKey(fromJson: _stringFromJson) this.first_air_date,
    @JsonKey(fromJson: _stringFromJson) this.homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? languages,
    @JsonKey(fromJson: _stringFromJson) this.last_air_date,
    final List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) this.number_of_episodes,
    @JsonKey(fromJson: _intFromJson) this.number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? origin_country,
    @JsonKey(fromJson: _stringFromJson) this.original_name,
    final List<ProductionCompany>? production_companies,
    final List<ProductionCountry>? production_countries,
    final List<SpokenLanguage>? spoken_languages,
    final List<ReleaseDate>? release_dates,
    @JsonKey(fromJson: _stringFromJson) this.status,
    @JsonKey(fromJson: _stringFromJson) this.tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) this.vote_count,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    @JsonKey(fromJson: _intFromJson) this.runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    this.next_episode_to_air,
    @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
    final List<EpisodeGroup>? episode_groups,
    @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
    this.episode_group,
  }) : _seasons = seasons,
       _season_info = season_info,
       _names = names,
       _actors = actors,
       _directors = directors,
       _created_by = created_by,
       _episode_run_time = episode_run_time,
       _genres = genres,
       _languages = languages,
       _networks = networks,
       _origin_country = origin_country,
       _production_companies = production_companies,
       _production_countries = production_countries,
       _spoken_languages = spoken_languages,
       _release_dates = release_dates,
       _genre_ids = genre_ids,
       _episode_groups = episode_groups;

  factory _$MediaInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaInfoImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? source;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? en_title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? year;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? title_year;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? tmdb_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? imdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? tvdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? douban_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? bangumi_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? collection_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? mediaid_prefix;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? media_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_language;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? release_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? backdrop_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? poster_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? category;
  final List<SeasonEpisodes>? _seasons;
  @override
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons {
    final value = _seasons;
    if (value == null) return null;
    if (_seasons is EqualUnmodifiableListView) return _seasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<SeasonInfo>? _season_info;
  @override
  List<SeasonInfo>? get season_info {
    final value = _season_info;
    if (value == null) return null;
    if (_season_info is EqualUnmodifiableListView) return _season_info;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _names;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names {
    final value = _names;
    if (value == null) return null;
    if (_names is EqualUnmodifiableListView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Actor>? _actors;
  @override
  List<Actor>? get actors {
    final value = _actors;
    if (value == null) return null;
    if (_actors is EqualUnmodifiableListView) return _actors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Director>? _directors;
  @override
  List<Director>? get directors {
    final value = _directors;
    if (value == null) return null;
    if (_directors is EqualUnmodifiableListView) return _directors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? detail_link;
  @override
  @JsonKey(fromJson: _boolFromJson)
  final bool? adult;
  final List<CreatedBy>? _created_by;
  @override
  List<CreatedBy>? get created_by {
    final value = _created_by;
    if (value == null) return null;
    if (_created_by is EqualUnmodifiableListView) return _created_by;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<int>? _episode_run_time;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time {
    final value = _episode_run_time;
    if (value == null) return null;
    if (_episode_run_time is EqualUnmodifiableListView)
      return _episode_run_time;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Genre>? _genres;
  @override
  List<Genre>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? first_air_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? homepage;
  final List<String>? _languages;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages {
    final value = _languages;
    if (value == null) return null;
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? last_air_date;
  final List<Network>? _networks;
  @override
  List<Network>? get networks {
    final value = _networks;
    if (value == null) return null;
    if (_networks is EqualUnmodifiableListView) return _networks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? number_of_episodes;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? number_of_seasons;
  final List<String>? _origin_country;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country {
    final value = _origin_country;
    if (value == null) return null;
    if (_origin_country is EqualUnmodifiableListView) return _origin_country;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_name;
  final List<ProductionCompany>? _production_companies;
  @override
  List<ProductionCompany>? get production_companies {
    final value = _production_companies;
    if (value == null) return null;
    if (_production_companies is EqualUnmodifiableListView)
      return _production_companies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ProductionCountry>? _production_countries;
  @override
  List<ProductionCountry>? get production_countries {
    final value = _production_countries;
    if (value == null) return null;
    if (_production_countries is EqualUnmodifiableListView)
      return _production_countries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<SpokenLanguage>? _spoken_languages;
  @override
  List<SpokenLanguage>? get spoken_languages {
    final value = _spoken_languages;
    if (value == null) return null;
    if (_spoken_languages is EqualUnmodifiableListView)
      return _spoken_languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ReleaseDate>? _release_dates;
  @override
  List<ReleaseDate>? get release_dates {
    final value = _release_dates;
    if (value == null) return null;
    if (_release_dates is EqualUnmodifiableListView) return _release_dates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? status;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? tagline;
  final List<int>? _genre_ids;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids {
    final value = _genre_ids;
    if (value == null) return null;
    if (_genre_ids is EqualUnmodifiableListView) return _genre_ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? vote_count;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? runtime;
  @override
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  final NextEpisodeToAir? next_episode_to_air;
  final List<EpisodeGroup>? _episode_groups;
  @override
  @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
  List<EpisodeGroup>? get episode_groups {
    final value = _episode_groups;
    if (value == null) return null;
    if (_episode_groups is EqualUnmodifiableListView) return _episode_groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
  final EpisodeGroup? episode_group;

  @override
  String toString() {
    return 'MediaInfo(source: $source, type: $type, title: $title, en_title: $en_title, year: $year, title_year: $title_year, season: $season, tmdb_id: $tmdb_id, imdb_id: $imdb_id, tvdb_id: $tvdb_id, douban_id: $douban_id, bangumi_id: $bangumi_id, collection_id: $collection_id, mediaid_prefix: $mediaid_prefix, media_id: $media_id, original_language: $original_language, original_title: $original_title, release_date: $release_date, backdrop_path: $backdrop_path, poster_path: $poster_path, vote_average: $vote_average, overview: $overview, category: $category, seasons: $seasons, season_info: $season_info, names: $names, actors: $actors, directors: $directors, detail_link: $detail_link, adult: $adult, created_by: $created_by, episode_run_time: $episode_run_time, genres: $genres, first_air_date: $first_air_date, homepage: $homepage, languages: $languages, last_air_date: $last_air_date, networks: $networks, number_of_episodes: $number_of_episodes, number_of_seasons: $number_of_seasons, origin_country: $origin_country, original_name: $original_name, production_companies: $production_companies, production_countries: $production_countries, spoken_languages: $spoken_languages, release_dates: $release_dates, status: $status, tagline: $tagline, genre_ids: $genre_ids, vote_count: $vote_count, popularity: $popularity, runtime: $runtime, next_episode_to_air: $next_episode_to_air, episode_groups: $episode_groups, episode_group: $episode_group)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaInfoImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.en_title, en_title) ||
                other.en_title == en_title) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.title_year, title_year) ||
                other.title_year == title_year) &&
            (identical(other.season, season) || other.season == season) &&
            (identical(other.tmdb_id, tmdb_id) || other.tmdb_id == tmdb_id) &&
            (identical(other.imdb_id, imdb_id) || other.imdb_id == imdb_id) &&
            (identical(other.tvdb_id, tvdb_id) || other.tvdb_id == tvdb_id) &&
            (identical(other.douban_id, douban_id) ||
                other.douban_id == douban_id) &&
            (identical(other.bangumi_id, bangumi_id) ||
                other.bangumi_id == bangumi_id) &&
            (identical(other.collection_id, collection_id) ||
                other.collection_id == collection_id) &&
            (identical(other.mediaid_prefix, mediaid_prefix) ||
                other.mediaid_prefix == mediaid_prefix) &&
            (identical(other.media_id, media_id) ||
                other.media_id == media_id) &&
            (identical(other.original_language, original_language) ||
                other.original_language == original_language) &&
            (identical(other.original_title, original_title) ||
                other.original_title == original_title) &&
            (identical(other.release_date, release_date) ||
                other.release_date == release_date) &&
            (identical(other.backdrop_path, backdrop_path) ||
                other.backdrop_path == backdrop_path) &&
            (identical(other.poster_path, poster_path) ||
                other.poster_path == poster_path) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._seasons, _seasons) &&
            const DeepCollectionEquality().equals(
              other._season_info,
              _season_info,
            ) &&
            const DeepCollectionEquality().equals(other._names, _names) &&
            const DeepCollectionEquality().equals(other._actors, _actors) &&
            const DeepCollectionEquality().equals(
              other._directors,
              _directors,
            ) &&
            (identical(other.detail_link, detail_link) ||
                other.detail_link == detail_link) &&
            (identical(other.adult, adult) || other.adult == adult) &&
            const DeepCollectionEquality().equals(
              other._created_by,
              _created_by,
            ) &&
            const DeepCollectionEquality().equals(
              other._episode_run_time,
              _episode_run_time,
            ) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.first_air_date, first_air_date) ||
                other.first_air_date == first_air_date) &&
            (identical(other.homepage, homepage) ||
                other.homepage == homepage) &&
            const DeepCollectionEquality().equals(
              other._languages,
              _languages,
            ) &&
            (identical(other.last_air_date, last_air_date) ||
                other.last_air_date == last_air_date) &&
            const DeepCollectionEquality().equals(other._networks, _networks) &&
            (identical(other.number_of_episodes, number_of_episodes) ||
                other.number_of_episodes == number_of_episodes) &&
            (identical(other.number_of_seasons, number_of_seasons) ||
                other.number_of_seasons == number_of_seasons) &&
            const DeepCollectionEquality().equals(
              other._origin_country,
              _origin_country,
            ) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            const DeepCollectionEquality().equals(
              other._production_companies,
              _production_companies,
            ) &&
            const DeepCollectionEquality().equals(
              other._production_countries,
              _production_countries,
            ) &&
            const DeepCollectionEquality().equals(
              other._spoken_languages,
              _spoken_languages,
            ) &&
            const DeepCollectionEquality().equals(
              other._release_dates,
              _release_dates,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            const DeepCollectionEquality().equals(
              other._genre_ids,
              _genre_ids,
            ) &&
            (identical(other.vote_count, vote_count) ||
                other.vote_count == vote_count) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.runtime, runtime) || other.runtime == runtime) &&
            (identical(other.next_episode_to_air, next_episode_to_air) ||
                other.next_episode_to_air == next_episode_to_air) &&
            const DeepCollectionEquality().equals(
              other._episode_groups,
              _episode_groups,
            ) &&
            (identical(other.episode_group, episode_group) ||
                other.episode_group == episode_group));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    source,
    type,
    title,
    en_title,
    year,
    title_year,
    season,
    tmdb_id,
    imdb_id,
    tvdb_id,
    douban_id,
    bangumi_id,
    collection_id,
    mediaid_prefix,
    media_id,
    original_language,
    original_title,
    release_date,
    backdrop_path,
    poster_path,
    vote_average,
    overview,
    category,
    const DeepCollectionEquality().hash(_seasons),
    const DeepCollectionEquality().hash(_season_info),
    const DeepCollectionEquality().hash(_names),
    const DeepCollectionEquality().hash(_actors),
    const DeepCollectionEquality().hash(_directors),
    detail_link,
    adult,
    const DeepCollectionEquality().hash(_created_by),
    const DeepCollectionEquality().hash(_episode_run_time),
    const DeepCollectionEquality().hash(_genres),
    first_air_date,
    homepage,
    const DeepCollectionEquality().hash(_languages),
    last_air_date,
    const DeepCollectionEquality().hash(_networks),
    number_of_episodes,
    number_of_seasons,
    const DeepCollectionEquality().hash(_origin_country),
    original_name,
    const DeepCollectionEquality().hash(_production_companies),
    const DeepCollectionEquality().hash(_production_countries),
    const DeepCollectionEquality().hash(_spoken_languages),
    const DeepCollectionEquality().hash(_release_dates),
    status,
    tagline,
    const DeepCollectionEquality().hash(_genre_ids),
    vote_count,
    popularity,
    runtime,
    next_episode_to_air,
    const DeepCollectionEquality().hash(_episode_groups),
    episode_group,
  ]);

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaInfoImplCopyWith<_$MediaInfoImpl> get copyWith =>
      __$$MediaInfoImplCopyWithImpl<_$MediaInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaInfoImplToJson(this);
  }
}

abstract class _MediaInfo implements MediaInfo {
  const factory _MediaInfo({
    @JsonKey(fromJson: _stringFromJson) final String? source,
    @JsonKey(fromJson: _stringFromJson) final String? type,
    @JsonKey(fromJson: _stringFromJson) final String? title,
    @JsonKey(fromJson: _stringFromJson) final String? en_title,
    @JsonKey(fromJson: _stringFromJson) final String? year,
    @JsonKey(fromJson: _stringFromJson) final String? title_year,
    @JsonKey(fromJson: _intFromJson) final int? season,
    @JsonKey(fromJson: _intFromJson) final int? tmdb_id,
    @JsonKey(fromJson: _stringFromJson) final String? imdb_id,
    @JsonKey(fromJson: _intFromJson) final int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) final int? douban_id,
    @JsonKey(fromJson: _intFromJson) final int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) final int? collection_id,
    @JsonKey(fromJson: _stringFromJson) final String? mediaid_prefix,
    @JsonKey(fromJson: _stringFromJson) final String? media_id,
    @JsonKey(fromJson: _stringFromJson) final String? original_language,
    @JsonKey(fromJson: _stringFromJson) final String? original_title,
    @JsonKey(fromJson: _stringFromJson) final String? release_date,
    @JsonKey(fromJson: _stringFromJson) final String? backdrop_path,
    @JsonKey(fromJson: _stringFromJson) final String? poster_path,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
    @JsonKey(fromJson: _stringFromJson) final String? overview,
    @JsonKey(fromJson: _stringFromJson) final String? category,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    final List<SeasonEpisodes>? seasons,
    final List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? names,
    final List<Actor>? actors,
    final List<Director>? directors,
    @JsonKey(fromJson: _stringFromJson) final String? detail_link,
    @JsonKey(fromJson: _boolFromJson) final bool? adult,
    final List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_run_time,
    final List<Genre>? genres,
    @JsonKey(fromJson: _stringFromJson) final String? first_air_date,
    @JsonKey(fromJson: _stringFromJson) final String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? languages,
    @JsonKey(fromJson: _stringFromJson) final String? last_air_date,
    final List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) final int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) final int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? origin_country,
    @JsonKey(fromJson: _stringFromJson) final String? original_name,
    final List<ProductionCompany>? production_companies,
    final List<ProductionCountry>? production_countries,
    final List<SpokenLanguage>? spoken_languages,
    final List<ReleaseDate>? release_dates,
    @JsonKey(fromJson: _stringFromJson) final String? status,
    @JsonKey(fromJson: _stringFromJson) final String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) final int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    @JsonKey(fromJson: _intFromJson) final int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    final NextEpisodeToAir? next_episode_to_air,
    @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
    final List<EpisodeGroup>? episode_groups,
    @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
    final EpisodeGroup? episode_group,
  }) = _$MediaInfoImpl;

  factory _MediaInfo.fromJson(Map<String, dynamic> json) =
      _$MediaInfoImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get source;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get type;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get en_title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get year;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get title_year;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get tmdb_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get imdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get tvdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get douban_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get bangumi_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get collection_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get mediaid_prefix;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get media_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_language;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_title;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get backdrop_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get poster_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get category;
  @override
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons;
  @override
  List<SeasonInfo>? get season_info;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names;
  @override
  List<Actor>? get actors;
  @override
  List<Director>? get directors;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get detail_link;
  @override
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult;
  @override
  List<CreatedBy>? get created_by;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time;
  @override
  List<Genre>? get genres;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get first_air_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get homepage;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get last_air_date;
  @override
  List<Network>? get networks;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_episodes;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_seasons;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name;
  @override
  List<ProductionCompany>? get production_companies;
  @override
  List<ProductionCountry>? get production_countries;
  @override
  List<SpokenLanguage>? get spoken_languages;
  @override
  List<ReleaseDate>? get release_dates;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get status;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get tagline;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get runtime;
  @override
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  NextEpisodeToAir? get next_episode_to_air;
  @override
  @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
  List<EpisodeGroup>? get episode_groups;
  @override
  @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
  EpisodeGroup? get episode_group;

  /// Create a copy of MediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaInfoImplCopyWith<_$MediaInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonEpisodes _$SeasonEpisodesFromJson(Map<String, dynamic> json) {
  return _SeasonEpisodes.fromJson(json);
}

/// @nodoc
mixin _$SeasonEpisodes {
  int get season => throw _privateConstructorUsedError;
  List<int> get episodes => throw _privateConstructorUsedError;

  /// Serializes this SeasonEpisodes to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonEpisodesCopyWith<SeasonEpisodes> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonEpisodesCopyWith<$Res> {
  factory $SeasonEpisodesCopyWith(
    SeasonEpisodes value,
    $Res Function(SeasonEpisodes) then,
  ) = _$SeasonEpisodesCopyWithImpl<$Res, SeasonEpisodes>;
  @useResult
  $Res call({int season, List<int> episodes});
}

/// @nodoc
class _$SeasonEpisodesCopyWithImpl<$Res, $Val extends SeasonEpisodes>
    implements $SeasonEpisodesCopyWith<$Res> {
  _$SeasonEpisodesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? season = null, Object? episodes = null}) {
    return _then(
      _value.copyWith(
            season: null == season
                ? _value.season
                : season // ignore: cast_nullable_to_non_nullable
                      as int,
            episodes: null == episodes
                ? _value.episodes
                : episodes // ignore: cast_nullable_to_non_nullable
                      as List<int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonEpisodesImplCopyWith<$Res>
    implements $SeasonEpisodesCopyWith<$Res> {
  factory _$$SeasonEpisodesImplCopyWith(
    _$SeasonEpisodesImpl value,
    $Res Function(_$SeasonEpisodesImpl) then,
  ) = __$$SeasonEpisodesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int season, List<int> episodes});
}

/// @nodoc
class __$$SeasonEpisodesImplCopyWithImpl<$Res>
    extends _$SeasonEpisodesCopyWithImpl<$Res, _$SeasonEpisodesImpl>
    implements _$$SeasonEpisodesImplCopyWith<$Res> {
  __$$SeasonEpisodesImplCopyWithImpl(
    _$SeasonEpisodesImpl _value,
    $Res Function(_$SeasonEpisodesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? season = null, Object? episodes = null}) {
    return _then(
      _$SeasonEpisodesImpl(
        season: null == season
            ? _value.season
            : season // ignore: cast_nullable_to_non_nullable
                  as int,
        episodes: null == episodes
            ? _value._episodes
            : episodes // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonEpisodesImpl implements _SeasonEpisodes {
  const _$SeasonEpisodesImpl({
    required this.season,
    required final List<int> episodes,
  }) : _episodes = episodes;

  factory _$SeasonEpisodesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonEpisodesImplFromJson(json);

  @override
  final int season;
  final List<int> _episodes;
  @override
  List<int> get episodes {
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_episodes);
  }

  @override
  String toString() {
    return 'SeasonEpisodes(season: $season, episodes: $episodes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonEpisodesImpl &&
            (identical(other.season, season) || other.season == season) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    season,
    const DeepCollectionEquality().hash(_episodes),
  );

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonEpisodesImplCopyWith<_$SeasonEpisodesImpl> get copyWith =>
      __$$SeasonEpisodesImplCopyWithImpl<_$SeasonEpisodesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonEpisodesImplToJson(this);
  }
}

abstract class _SeasonEpisodes implements SeasonEpisodes {
  const factory _SeasonEpisodes({
    required final int season,
    required final List<int> episodes,
  }) = _$SeasonEpisodesImpl;

  factory _SeasonEpisodes.fromJson(Map<String, dynamic> json) =
      _$SeasonEpisodesImpl.fromJson;

  @override
  int get season;
  @override
  List<int> get episodes;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonEpisodesImplCopyWith<_$SeasonEpisodesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonInfo _$SeasonInfoFromJson(Map<String, dynamic> json) {
  return _SeasonInfo.fromJson(json);
}

/// @nodoc
mixin _$SeasonInfo {
  @JsonKey(fromJson: _stringFromJson)
  String? get air_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get poster_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season_number => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;

  /// Serializes this SeasonInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonInfoCopyWith<SeasonInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonInfoCopyWith<$Res> {
  factory $SeasonInfoCopyWith(
    SeasonInfo value,
    $Res Function(SeasonInfo) then,
  ) = _$SeasonInfoCopyWithImpl<$Res, SeasonInfo>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  });
}

/// @nodoc
class _$SeasonInfoCopyWithImpl<$Res, $Val extends SeasonInfo>
    implements $SeasonInfoCopyWith<$Res> {
  _$SeasonInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? poster_path = freezed,
    Object? season_number = freezed,
    Object? vote_average = freezed,
  }) {
    return _then(
      _value.copyWith(
            air_date: freezed == air_date
                ? _value.air_date
                : air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_count: freezed == episode_count
                ? _value.episode_count
                : episode_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            poster_path: freezed == poster_path
                ? _value.poster_path
                : poster_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            season_number: freezed == season_number
                ? _value.season_number
                : season_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonInfoImplCopyWith<$Res>
    implements $SeasonInfoCopyWith<$Res> {
  factory _$$SeasonInfoImplCopyWith(
    _$SeasonInfoImpl value,
    $Res Function(_$SeasonInfoImpl) then,
  ) = __$$SeasonInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  });
}

/// @nodoc
class __$$SeasonInfoImplCopyWithImpl<$Res>
    extends _$SeasonInfoCopyWithImpl<$Res, _$SeasonInfoImpl>
    implements _$$SeasonInfoImplCopyWith<$Res> {
  __$$SeasonInfoImplCopyWithImpl(
    _$SeasonInfoImpl _value,
    $Res Function(_$SeasonInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? poster_path = freezed,
    Object? season_number = freezed,
    Object? vote_average = freezed,
  }) {
    return _then(
      _$SeasonInfoImpl(
        air_date: freezed == air_date
            ? _value.air_date
            : air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_count: freezed == episode_count
            ? _value.episode_count
            : episode_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        poster_path: freezed == poster_path
            ? _value.poster_path
            : poster_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        season_number: freezed == season_number
            ? _value.season_number
            : season_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonInfoImpl implements _SeasonInfo {
  const _$SeasonInfoImpl({
    @JsonKey(fromJson: _stringFromJson) this.air_date,
    @JsonKey(fromJson: _intFromJson) this.episode_count,
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.overview,
    @JsonKey(fromJson: _stringFromJson) this.poster_path,
    @JsonKey(fromJson: _intFromJson) this.season_number,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
  });

  factory _$SeasonInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonInfoImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? poster_path;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season_number;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;

  @override
  String toString() {
    return 'SeasonInfo(air_date: $air_date, episode_count: $episode_count, id: $id, name: $name, overview: $overview, poster_path: $poster_path, season_number: $season_number, vote_average: $vote_average)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonInfoImpl &&
            (identical(other.air_date, air_date) ||
                other.air_date == air_date) &&
            (identical(other.episode_count, episode_count) ||
                other.episode_count == episode_count) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.poster_path, poster_path) ||
                other.poster_path == poster_path) &&
            (identical(other.season_number, season_number) ||
                other.season_number == season_number) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    air_date,
    episode_count,
    id,
    name,
    overview,
    poster_path,
    season_number,
    vote_average,
  );

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonInfoImplCopyWith<_$SeasonInfoImpl> get copyWith =>
      __$$SeasonInfoImplCopyWithImpl<_$SeasonInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonInfoImplToJson(this);
  }
}

abstract class _SeasonInfo implements SeasonInfo {
  const factory _SeasonInfo({
    @JsonKey(fromJson: _stringFromJson) final String? air_date,
    @JsonKey(fromJson: _intFromJson) final int? episode_count,
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? overview,
    @JsonKey(fromJson: _stringFromJson) final String? poster_path,
    @JsonKey(fromJson: _intFromJson) final int? season_number,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
  }) = _$SeasonInfoImpl;

  factory _SeasonInfo.fromJson(Map<String, dynamic> json) =
      _$SeasonInfoImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get poster_path;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season_number;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonInfoImplCopyWith<_$SeasonInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Actor _$ActorFromJson(Map<String, dynamic> json) {
  return _Actor.fromJson(json);
}

/// @nodoc
mixin _$Actor {
  @JsonKey(fromJson: _stringFromJson)
  String? get source => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get known_for_department => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get character => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get order => throw _privateConstructorUsedError;

  /// Serializes this Actor to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActorCopyWith<Actor> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorCopyWith<$Res> {
  factory $ActorCopyWith(Actor value, $Res Function(Actor) then) =
      _$ActorCopyWithImpl<$Res, Actor>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? source,
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
    @JsonKey(fromJson: _stringFromJson) String? character,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _intFromJson) int? order,
  });
}

/// @nodoc
class _$ActorCopyWithImpl<$Res, $Val extends Actor>
    implements $ActorCopyWith<$Res> {
  _$ActorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? known_for_department = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
    Object? character = freezed,
    Object? credit_id = freezed,
    Object? order = freezed,
  }) {
    return _then(
      _value.copyWith(
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            known_for_department: freezed == known_for_department
                ? _value.known_for_department
                : known_for_department // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            character: freezed == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            order: freezed == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActorImplCopyWith<$Res> implements $ActorCopyWith<$Res> {
  factory _$$ActorImplCopyWith(
    _$ActorImpl value,
    $Res Function(_$ActorImpl) then,
  ) = __$$ActorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? source,
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
    @JsonKey(fromJson: _stringFromJson) String? character,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _intFromJson) int? order,
  });
}

/// @nodoc
class __$$ActorImplCopyWithImpl<$Res>
    extends _$ActorCopyWithImpl<$Res, _$ActorImpl>
    implements _$$ActorImplCopyWith<$Res> {
  __$$ActorImplCopyWithImpl(
    _$ActorImpl _value,
    $Res Function(_$ActorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? known_for_department = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
    Object? character = freezed,
    Object? credit_id = freezed,
    Object? order = freezed,
  }) {
    return _then(
      _$ActorImpl(
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        known_for_department: freezed == known_for_department
            ? _value.known_for_department
            : known_for_department // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        character: freezed == character
            ? _value.character
            : character // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        order: freezed == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorImpl implements _Actor {
  const _$ActorImpl({
    @JsonKey(fromJson: _stringFromJson) this.source,
    @JsonKey(fromJson: _boolFromJson) this.adult,
    @JsonKey(fromJson: _intFromJson) this.gender,
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.known_for_department,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.original_name,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    @JsonKey(fromJson: _stringFromJson) this.profile_path,
    @JsonKey(fromJson: _stringFromJson) this.character,
    @JsonKey(fromJson: _stringFromJson) this.credit_id,
    @JsonKey(fromJson: _intFromJson) this.order,
  });

  factory _$ActorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? source;
  @override
  @JsonKey(fromJson: _boolFromJson)
  final bool? adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? known_for_department;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_name;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? profile_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? character;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? credit_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? order;

  @override
  String toString() {
    return 'Actor(source: $source, adult: $adult, gender: $gender, id: $id, known_for_department: $known_for_department, name: $name, original_name: $original_name, popularity: $popularity, profile_path: $profile_path, character: $character, credit_id: $credit_id, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.adult, adult) || other.adult == adult) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.known_for_department, known_for_department) ||
                other.known_for_department == known_for_department) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    source,
    adult,
    gender,
    id,
    known_for_department,
    name,
    original_name,
    popularity,
    profile_path,
    character,
    credit_id,
    order,
  );

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorImplCopyWith<_$ActorImpl> get copyWith =>
      __$$ActorImplCopyWithImpl<_$ActorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorImplToJson(this);
  }
}

abstract class _Actor implements Actor {
  const factory _Actor({
    @JsonKey(fromJson: _stringFromJson) final String? source,
    @JsonKey(fromJson: _boolFromJson) final bool? adult,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? original_name,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    @JsonKey(fromJson: _stringFromJson) final String? profile_path,
    @JsonKey(fromJson: _stringFromJson) final String? character,
    @JsonKey(fromJson: _stringFromJson) final String? credit_id,
    @JsonKey(fromJson: _intFromJson) final int? order,
  }) = _$ActorImpl;

  factory _Actor.fromJson(Map<String, dynamic> json) = _$ActorImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get source;
  @override
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get known_for_department;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get character;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get order;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActorImplCopyWith<_$ActorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Director _$DirectorFromJson(Map<String, dynamic> json) {
  return _Director.fromJson(json);
}

/// @nodoc
mixin _$Director {
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get known_for_department => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get job => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path => throw _privateConstructorUsedError;

  /// Serializes this Director to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DirectorCopyWith<Director> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DirectorCopyWith<$Res> {
  factory $DirectorCopyWith(Director value, $Res Function(Director) then) =
      _$DirectorCopyWithImpl<$Res, Director>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _stringFromJson) String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) String? job,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
  });
}

/// @nodoc
class _$DirectorCopyWithImpl<$Res, $Val extends Director>
    implements $DirectorCopyWith<$Res> {
  _$DirectorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? credit_id = freezed,
    Object? known_for_department = freezed,
    Object? job = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _value.copyWith(
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            known_for_department: freezed == known_for_department
                ? _value.known_for_department
                : known_for_department // ignore: cast_nullable_to_non_nullable
                      as String?,
            job: freezed == job
                ? _value.job
                : job // ignore: cast_nullable_to_non_nullable
                      as String?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DirectorImplCopyWith<$Res>
    implements $DirectorCopyWith<$Res> {
  factory _$$DirectorImplCopyWith(
    _$DirectorImpl value,
    $Res Function(_$DirectorImpl) then,
  ) = __$$DirectorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _boolFromJson) bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _stringFromJson) String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) String? job,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
  });
}

/// @nodoc
class __$$DirectorImplCopyWithImpl<$Res>
    extends _$DirectorCopyWithImpl<$Res, _$DirectorImpl>
    implements _$$DirectorImplCopyWith<$Res> {
  __$$DirectorImplCopyWithImpl(
    _$DirectorImpl _value,
    $Res Function(_$DirectorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? credit_id = freezed,
    Object? known_for_department = freezed,
    Object? job = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _$DirectorImpl(
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        known_for_department: freezed == known_for_department
            ? _value.known_for_department
            : known_for_department // ignore: cast_nullable_to_non_nullable
                  as String?,
        job: freezed == job
            ? _value.job
            : job // ignore: cast_nullable_to_non_nullable
                  as String?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DirectorImpl implements _Director {
  const _$DirectorImpl({
    @JsonKey(fromJson: _boolFromJson) this.adult,
    @JsonKey(fromJson: _intFromJson) this.gender,
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.original_name,
    @JsonKey(fromJson: _stringFromJson) this.credit_id,
    @JsonKey(fromJson: _stringFromJson) this.known_for_department,
    @JsonKey(fromJson: _stringFromJson) this.job,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    @JsonKey(fromJson: _stringFromJson) this.profile_path,
  });

  factory _$DirectorImpl.fromJson(Map<String, dynamic> json) =>
      _$$DirectorImplFromJson(json);

  @override
  @JsonKey(fromJson: _boolFromJson)
  final bool? adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? credit_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? known_for_department;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? job;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? profile_path;

  @override
  String toString() {
    return 'Director(adult: $adult, gender: $gender, id: $id, name: $name, original_name: $original_name, credit_id: $credit_id, known_for_department: $known_for_department, job: $job, popularity: $popularity, profile_path: $profile_path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DirectorImpl &&
            (identical(other.adult, adult) || other.adult == adult) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.known_for_department, known_for_department) ||
                other.known_for_department == known_for_department) &&
            (identical(other.job, job) || other.job == job) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    adult,
    gender,
    id,
    name,
    original_name,
    credit_id,
    known_for_department,
    job,
    popularity,
    profile_path,
  );

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DirectorImplCopyWith<_$DirectorImpl> get copyWith =>
      __$$DirectorImplCopyWithImpl<_$DirectorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DirectorImplToJson(this);
  }
}

abstract class _Director implements Director {
  const factory _Director({
    @JsonKey(fromJson: _boolFromJson) final bool? adult,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? original_name,
    @JsonKey(fromJson: _stringFromJson) final String? credit_id,
    @JsonKey(fromJson: _stringFromJson) final String? known_for_department,
    @JsonKey(fromJson: _stringFromJson) final String? job,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    @JsonKey(fromJson: _stringFromJson) final String? profile_path,
  }) = _$DirectorImpl;

  factory _Director.fromJson(Map<String, dynamic> json) =
      _$DirectorImpl.fromJson;

  @override
  @JsonKey(fromJson: _boolFromJson)
  bool? get adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get known_for_department;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get job;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DirectorImplCopyWith<_$DirectorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatedBy _$CreatedByFromJson(Map<String, dynamic> json) {
  return _CreatedBy.fromJson(json);
}

/// @nodoc
mixin _$CreatedBy {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path => throw _privateConstructorUsedError;

  /// Serializes this CreatedBy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatedByCopyWith<CreatedBy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatedByCopyWith<$Res> {
  factory $CreatedByCopyWith(CreatedBy value, $Res Function(CreatedBy) then) =
      _$CreatedByCopyWithImpl<$Res, CreatedBy>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
  });
}

/// @nodoc
class _$CreatedByCopyWithImpl<$Res, $Val extends CreatedBy>
    implements $CreatedByCopyWith<$Res> {
  _$CreatedByCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? credit_id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? gender = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatedByImplCopyWith<$Res>
    implements $CreatedByCopyWith<$Res> {
  factory _$$CreatedByImplCopyWith(
    _$CreatedByImpl value,
    $Res Function(_$CreatedByImpl) then,
  ) = __$$CreatedByImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? credit_id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _stringFromJson) String? profile_path,
  });
}

/// @nodoc
class __$$CreatedByImplCopyWithImpl<$Res>
    extends _$CreatedByCopyWithImpl<$Res, _$CreatedByImpl>
    implements _$$CreatedByImplCopyWith<$Res> {
  __$$CreatedByImplCopyWithImpl(
    _$CreatedByImpl _value,
    $Res Function(_$CreatedByImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? credit_id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? gender = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _$CreatedByImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatedByImpl implements _CreatedBy {
  const _$CreatedByImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.credit_id,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.original_name,
    @JsonKey(fromJson: _intFromJson) this.gender,
    @JsonKey(fromJson: _stringFromJson) this.profile_path,
  });

  factory _$CreatedByImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatedByImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? credit_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? original_name;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? profile_path;

  @override
  String toString() {
    return 'CreatedBy(id: $id, credit_id: $credit_id, name: $name, original_name: $original_name, gender: $gender, profile_path: $profile_path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatedByImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    credit_id,
    name,
    original_name,
    gender,
    profile_path,
  );

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatedByImplCopyWith<_$CreatedByImpl> get copyWith =>
      __$$CreatedByImplCopyWithImpl<_$CreatedByImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatedByImplToJson(this);
  }
}

abstract class _CreatedBy implements CreatedBy {
  const factory _CreatedBy({
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? credit_id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? original_name,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    @JsonKey(fromJson: _stringFromJson) final String? profile_path,
  }) = _$CreatedByImpl;

  factory _CreatedBy.fromJson(Map<String, dynamic> json) =
      _$CreatedByImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get credit_id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get original_name;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get profile_path;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatedByImplCopyWith<_$CreatedByImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Genre _$GenreFromJson(Map<String, dynamic> json) {
  return _Genre.fromJson(json);
}

/// @nodoc
mixin _$Genre {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this Genre to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenreCopyWith<Genre> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenreCopyWith<$Res> {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) then) =
      _$GenreCopyWithImpl<$Res, Genre>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class _$GenreCopyWithImpl<$Res, $Val extends Genre>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GenreImplCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$$GenreImplCopyWith(
    _$GenreImpl value,
    $Res Function(_$GenreImpl) then,
  ) = __$$GenreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class __$$GenreImplCopyWithImpl<$Res>
    extends _$GenreCopyWithImpl<$Res, _$GenreImpl>
    implements _$$GenreImplCopyWith<$Res> {
  __$$GenreImplCopyWithImpl(
    _$GenreImpl _value,
    $Res Function(_$GenreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _$GenreImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GenreImpl implements _Genre {
  const _$GenreImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.name,
  });

  factory _$GenreImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenreImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;

  @override
  String toString() {
    return 'Genre(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenreImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenreImplCopyWith<_$GenreImpl> get copyWith =>
      __$$GenreImplCopyWithImpl<_$GenreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenreImplToJson(this);
  }
}

abstract class _Genre implements Genre {
  const factory _Genre({
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
  }) = _$GenreImpl;

  factory _Genre.fromJson(Map<String, dynamic> json) = _$GenreImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenreImplCopyWith<_$GenreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Network _$NetworkFromJson(Map<String, dynamic> json) {
  return _Network.fromJson(json);
}

/// @nodoc
mixin _$Network {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get logo_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get origin_country => throw _privateConstructorUsedError;

  /// Serializes this Network to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkCopyWith<Network> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkCopyWith<$Res> {
  factory $NetworkCopyWith(Network value, $Res Function(Network) then) =
      _$NetworkCopyWithImpl<$Res, Network>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? logo_path,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? origin_country,
  });
}

/// @nodoc
class _$NetworkCopyWithImpl<$Res, $Val extends Network>
    implements $NetworkCopyWith<$Res> {
  _$NetworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            logo_path: freezed == logo_path
                ? _value.logo_path
                : logo_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NetworkImplCopyWith<$Res> implements $NetworkCopyWith<$Res> {
  factory _$$NetworkImplCopyWith(
    _$NetworkImpl value,
    $Res Function(_$NetworkImpl) then,
  ) = __$$NetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? logo_path,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? origin_country,
  });
}

/// @nodoc
class __$$NetworkImplCopyWithImpl<$Res>
    extends _$NetworkCopyWithImpl<$Res, _$NetworkImpl>
    implements _$$NetworkImplCopyWith<$Res> {
  __$$NetworkImplCopyWithImpl(
    _$NetworkImpl _value,
    $Res Function(_$NetworkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _$NetworkImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        logo_path: freezed == logo_path
            ? _value.logo_path
            : logo_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        origin_country: freezed == origin_country
            ? _value.origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkImpl implements _Network {
  const _$NetworkImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.logo_path,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.origin_country,
  });

  factory _$NetworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? logo_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? origin_country;

  @override
  String toString() {
    return 'Network(id: $id, logo_path: $logo_path, name: $name, origin_country: $origin_country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logo_path, logo_path) ||
                other.logo_path == logo_path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.origin_country, origin_country) ||
                other.origin_country == origin_country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, logo_path, name, origin_country);

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkImplCopyWith<_$NetworkImpl> get copyWith =>
      __$$NetworkImplCopyWithImpl<_$NetworkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkImplToJson(this);
  }
}

abstract class _Network implements Network {
  const factory _Network({
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? logo_path,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? origin_country,
  }) = _$NetworkImpl;

  factory _Network.fromJson(Map<String, dynamic> json) = _$NetworkImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get logo_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get origin_country;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkImplCopyWith<_$NetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionCompany _$ProductionCompanyFromJson(Map<String, dynamic> json) {
  return _ProductionCompany.fromJson(json);
}

/// @nodoc
mixin _$ProductionCompany {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get logo_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get origin_country => throw _privateConstructorUsedError;

  /// Serializes this ProductionCompany to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductionCompanyCopyWith<ProductionCompany> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionCompanyCopyWith<$Res> {
  factory $ProductionCompanyCopyWith(
    ProductionCompany value,
    $Res Function(ProductionCompany) then,
  ) = _$ProductionCompanyCopyWithImpl<$Res, ProductionCompany>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? logo_path,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? origin_country,
  });
}

/// @nodoc
class _$ProductionCompanyCopyWithImpl<$Res, $Val extends ProductionCompany>
    implements $ProductionCompanyCopyWith<$Res> {
  _$ProductionCompanyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            logo_path: freezed == logo_path
                ? _value.logo_path
                : logo_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductionCompanyImplCopyWith<$Res>
    implements $ProductionCompanyCopyWith<$Res> {
  factory _$$ProductionCompanyImplCopyWith(
    _$ProductionCompanyImpl value,
    $Res Function(_$ProductionCompanyImpl) then,
  ) = __$$ProductionCompanyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? logo_path,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? origin_country,
  });
}

/// @nodoc
class __$$ProductionCompanyImplCopyWithImpl<$Res>
    extends _$ProductionCompanyCopyWithImpl<$Res, _$ProductionCompanyImpl>
    implements _$$ProductionCompanyImplCopyWith<$Res> {
  __$$ProductionCompanyImplCopyWithImpl(
    _$ProductionCompanyImpl _value,
    $Res Function(_$ProductionCompanyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _$ProductionCompanyImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        logo_path: freezed == logo_path
            ? _value.logo_path
            : logo_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        origin_country: freezed == origin_country
            ? _value.origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionCompanyImpl implements _ProductionCompany {
  const _$ProductionCompanyImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.logo_path,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.origin_country,
  });

  factory _$ProductionCompanyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionCompanyImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? logo_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? origin_country;

  @override
  String toString() {
    return 'ProductionCompany(id: $id, logo_path: $logo_path, name: $name, origin_country: $origin_country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionCompanyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logo_path, logo_path) ||
                other.logo_path == logo_path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.origin_country, origin_country) ||
                other.origin_country == origin_country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, logo_path, name, origin_country);

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionCompanyImplCopyWith<_$ProductionCompanyImpl> get copyWith =>
      __$$ProductionCompanyImplCopyWithImpl<_$ProductionCompanyImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionCompanyImplToJson(this);
  }
}

abstract class _ProductionCompany implements ProductionCompany {
  const factory _ProductionCompany({
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? logo_path,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? origin_country,
  }) = _$ProductionCompanyImpl;

  factory _ProductionCompany.fromJson(Map<String, dynamic> json) =
      _$ProductionCompanyImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get logo_path;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get origin_country;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductionCompanyImplCopyWith<_$ProductionCompanyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionCountry _$ProductionCountryFromJson(Map<String, dynamic> json) {
  return _ProductionCountry.fromJson(json);
}

/// @nodoc
mixin _$ProductionCountry {
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_3166_1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this ProductionCountry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductionCountryCopyWith<ProductionCountry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionCountryCopyWith<$Res> {
  factory $ProductionCountryCopyWith(
    ProductionCountry value,
    $Res Function(ProductionCountry) then,
  ) = _$ProductionCountryCopyWithImpl<$Res, ProductionCountry>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class _$ProductionCountryCopyWithImpl<$Res, $Val extends ProductionCountry>
    implements $ProductionCountryCopyWith<$Res> {
  _$ProductionCountryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iso_3166_1 = freezed, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            iso_3166_1: freezed == iso_3166_1
                ? _value.iso_3166_1
                : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductionCountryImplCopyWith<$Res>
    implements $ProductionCountryCopyWith<$Res> {
  factory _$$ProductionCountryImplCopyWith(
    _$ProductionCountryImpl value,
    $Res Function(_$ProductionCountryImpl) then,
  ) = __$$ProductionCountryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class __$$ProductionCountryImplCopyWithImpl<$Res>
    extends _$ProductionCountryCopyWithImpl<$Res, _$ProductionCountryImpl>
    implements _$$ProductionCountryImplCopyWith<$Res> {
  __$$ProductionCountryImplCopyWithImpl(
    _$ProductionCountryImpl _value,
    $Res Function(_$ProductionCountryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iso_3166_1 = freezed, Object? name = freezed}) {
    return _then(
      _$ProductionCountryImpl(
        iso_3166_1: freezed == iso_3166_1
            ? _value.iso_3166_1
            : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionCountryImpl implements _ProductionCountry {
  const _$ProductionCountryImpl({
    @JsonKey(fromJson: _stringFromJson) this.iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) this.name,
  });

  factory _$ProductionCountryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionCountryImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;

  @override
  String toString() {
    return 'ProductionCountry(iso_3166_1: $iso_3166_1, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionCountryImpl &&
            (identical(other.iso_3166_1, iso_3166_1) ||
                other.iso_3166_1 == iso_3166_1) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, iso_3166_1, name);

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionCountryImplCopyWith<_$ProductionCountryImpl> get copyWith =>
      __$$ProductionCountryImplCopyWithImpl<_$ProductionCountryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionCountryImplToJson(this);
  }
}

abstract class _ProductionCountry implements ProductionCountry {
  const factory _ProductionCountry({
    @JsonKey(fromJson: _stringFromJson) final String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) final String? name,
  }) = _$ProductionCountryImpl;

  factory _ProductionCountry.fromJson(Map<String, dynamic> json) =
      _$ProductionCountryImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductionCountryImplCopyWith<_$ProductionCountryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpokenLanguage _$SpokenLanguageFromJson(Map<String, dynamic> json) {
  return _SpokenLanguage.fromJson(json);
}

/// @nodoc
mixin _$SpokenLanguage {
  @JsonKey(fromJson: _stringFromJson)
  String? get english_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_639_1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this SpokenLanguage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpokenLanguageCopyWith<SpokenLanguage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpokenLanguageCopyWith<$Res> {
  factory $SpokenLanguageCopyWith(
    SpokenLanguage value,
    $Res Function(SpokenLanguage) then,
  ) = _$SpokenLanguageCopyWithImpl<$Res, SpokenLanguage>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? english_name,
    @JsonKey(fromJson: _stringFromJson) String? iso_639_1,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class _$SpokenLanguageCopyWithImpl<$Res, $Val extends SpokenLanguage>
    implements $SpokenLanguageCopyWith<$Res> {
  _$SpokenLanguageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english_name = freezed,
    Object? iso_639_1 = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _value.copyWith(
            english_name: freezed == english_name
                ? _value.english_name
                : english_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            iso_639_1: freezed == iso_639_1
                ? _value.iso_639_1
                : iso_639_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpokenLanguageImplCopyWith<$Res>
    implements $SpokenLanguageCopyWith<$Res> {
  factory _$$SpokenLanguageImplCopyWith(
    _$SpokenLanguageImpl value,
    $Res Function(_$SpokenLanguageImpl) then,
  ) = __$$SpokenLanguageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? english_name,
    @JsonKey(fromJson: _stringFromJson) String? iso_639_1,
    @JsonKey(fromJson: _stringFromJson) String? name,
  });
}

/// @nodoc
class __$$SpokenLanguageImplCopyWithImpl<$Res>
    extends _$SpokenLanguageCopyWithImpl<$Res, _$SpokenLanguageImpl>
    implements _$$SpokenLanguageImplCopyWith<$Res> {
  __$$SpokenLanguageImplCopyWithImpl(
    _$SpokenLanguageImpl _value,
    $Res Function(_$SpokenLanguageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english_name = freezed,
    Object? iso_639_1 = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _$SpokenLanguageImpl(
        english_name: freezed == english_name
            ? _value.english_name
            : english_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        iso_639_1: freezed == iso_639_1
            ? _value.iso_639_1
            : iso_639_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpokenLanguageImpl implements _SpokenLanguage {
  const _$SpokenLanguageImpl({
    @JsonKey(fromJson: _stringFromJson) this.english_name,
    @JsonKey(fromJson: _stringFromJson) this.iso_639_1,
    @JsonKey(fromJson: _stringFromJson) this.name,
  });

  factory _$SpokenLanguageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpokenLanguageImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? english_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? iso_639_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;

  @override
  String toString() {
    return 'SpokenLanguage(english_name: $english_name, iso_639_1: $iso_639_1, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpokenLanguageImpl &&
            (identical(other.english_name, english_name) ||
                other.english_name == english_name) &&
            (identical(other.iso_639_1, iso_639_1) ||
                other.iso_639_1 == iso_639_1) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, english_name, iso_639_1, name);

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpokenLanguageImplCopyWith<_$SpokenLanguageImpl> get copyWith =>
      __$$SpokenLanguageImplCopyWithImpl<_$SpokenLanguageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpokenLanguageImplToJson(this);
  }
}

abstract class _SpokenLanguage implements SpokenLanguage {
  const factory _SpokenLanguage({
    @JsonKey(fromJson: _stringFromJson) final String? english_name,
    @JsonKey(fromJson: _stringFromJson) final String? iso_639_1,
    @JsonKey(fromJson: _stringFromJson) final String? name,
  }) = _$SpokenLanguageImpl;

  factory _SpokenLanguage.fromJson(Map<String, dynamic> json) =
      _$SpokenLanguageImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get english_name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_639_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpokenLanguageImplCopyWith<_$SpokenLanguageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReleaseDate _$ReleaseDateFromJson(Map<String, dynamic> json) {
  return _ReleaseDate.fromJson(json);
}

/// @nodoc
mixin _$ReleaseDate {
  @JsonKey(fromJson: _stringFromJson)
  String? get certification => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_3166_1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get type => throw _privateConstructorUsedError;

  /// Serializes this ReleaseDate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReleaseDateCopyWith<ReleaseDate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReleaseDateCopyWith<$Res> {
  factory $ReleaseDateCopyWith(
    ReleaseDate value,
    $Res Function(ReleaseDate) then,
  ) = _$ReleaseDateCopyWithImpl<$Res, ReleaseDate>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? certification,
    @JsonKey(fromJson: _stringFromJson) String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _stringFromJson) String? note,
    @JsonKey(fromJson: _intFromJson) int? type,
  });
}

/// @nodoc
class _$ReleaseDateCopyWithImpl<$Res, $Val extends ReleaseDate>
    implements $ReleaseDateCopyWith<$Res> {
  _$ReleaseDateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? certification = freezed,
    Object? iso_3166_1 = freezed,
    Object? release_date = freezed,
    Object? note = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _value.copyWith(
            certification: freezed == certification
                ? _value.certification
                : certification // ignore: cast_nullable_to_non_nullable
                      as String?,
            iso_3166_1: freezed == iso_3166_1
                ? _value.iso_3166_1
                : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            release_date: freezed == release_date
                ? _value.release_date
                : release_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReleaseDateImplCopyWith<$Res>
    implements $ReleaseDateCopyWith<$Res> {
  factory _$$ReleaseDateImplCopyWith(
    _$ReleaseDateImpl value,
    $Res Function(_$ReleaseDateImpl) then,
  ) = __$$ReleaseDateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? certification,
    @JsonKey(fromJson: _stringFromJson) String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _stringFromJson) String? note,
    @JsonKey(fromJson: _intFromJson) int? type,
  });
}

/// @nodoc
class __$$ReleaseDateImplCopyWithImpl<$Res>
    extends _$ReleaseDateCopyWithImpl<$Res, _$ReleaseDateImpl>
    implements _$$ReleaseDateImplCopyWith<$Res> {
  __$$ReleaseDateImplCopyWithImpl(
    _$ReleaseDateImpl _value,
    $Res Function(_$ReleaseDateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? certification = freezed,
    Object? iso_3166_1 = freezed,
    Object? release_date = freezed,
    Object? note = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _$ReleaseDateImpl(
        certification: freezed == certification
            ? _value.certification
            : certification // ignore: cast_nullable_to_non_nullable
                  as String?,
        iso_3166_1: freezed == iso_3166_1
            ? _value.iso_3166_1
            : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        release_date: freezed == release_date
            ? _value.release_date
            : release_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReleaseDateImpl implements _ReleaseDate {
  const _$ReleaseDateImpl({
    @JsonKey(fromJson: _stringFromJson) this.certification,
    @JsonKey(fromJson: _stringFromJson) this.iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) this.release_date,
    @JsonKey(fromJson: _stringFromJson) this.note,
    @JsonKey(fromJson: _intFromJson) this.type,
  });

  factory _$ReleaseDateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReleaseDateImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? certification;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? release_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? note;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? type;

  @override
  String toString() {
    return 'ReleaseDate(certification: $certification, iso_3166_1: $iso_3166_1, release_date: $release_date, note: $note, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReleaseDateImpl &&
            (identical(other.certification, certification) ||
                other.certification == certification) &&
            (identical(other.iso_3166_1, iso_3166_1) ||
                other.iso_3166_1 == iso_3166_1) &&
            (identical(other.release_date, release_date) ||
                other.release_date == release_date) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    certification,
    iso_3166_1,
    release_date,
    note,
    type,
  );

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReleaseDateImplCopyWith<_$ReleaseDateImpl> get copyWith =>
      __$$ReleaseDateImplCopyWithImpl<_$ReleaseDateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReleaseDateImplToJson(this);
  }
}

abstract class _ReleaseDate implements ReleaseDate {
  const factory _ReleaseDate({
    @JsonKey(fromJson: _stringFromJson) final String? certification,
    @JsonKey(fromJson: _stringFromJson) final String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) final String? release_date,
    @JsonKey(fromJson: _stringFromJson) final String? note,
    @JsonKey(fromJson: _intFromJson) final int? type,
  }) = _$ReleaseDateImpl;

  factory _ReleaseDate.fromJson(Map<String, dynamic> json) =
      _$ReleaseDateImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get certification;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get note;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get type;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReleaseDateImplCopyWith<_$ReleaseDateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EpisodeGroup _$EpisodeGroupFromJson(Map<String, dynamic> json) {
  return _EpisodeGroup.fromJson(json);
}

/// @nodoc
mixin _$EpisodeGroup {
  @JsonKey(fromJson: _stringFromJson)
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get group_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
  Network? get network => throw _privateConstructorUsedError;

  /// Serializes this EpisodeGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeGroupCopyWith<EpisodeGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeGroupCopyWith<$Res> {
  factory $EpisodeGroupCopyWith(
    EpisodeGroup value,
    $Res Function(EpisodeGroup) then,
  ) = _$EpisodeGroupCopyWithImpl<$Res, EpisodeGroup>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
    Network? network,
  });

  $NetworkCopyWith<$Res>? get network;
}

/// @nodoc
class _$EpisodeGroupCopyWithImpl<$Res, $Val extends EpisodeGroup>
    implements $EpisodeGroupCopyWith<$Res> {
  _$EpisodeGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? description = freezed,
    Object? episode_count = freezed,
    Object? group_count = freezed,
    Object? type = freezed,
    Object? network = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_count: freezed == episode_count
                ? _value.episode_count
                : episode_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            group_count: freezed == group_count
                ? _value.group_count
                : group_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            network: freezed == network
                ? _value.network
                : network // ignore: cast_nullable_to_non_nullable
                      as Network?,
          )
          as $Val,
    );
  }

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkCopyWith<$Res>? get network {
    if (_value.network == null) {
      return null;
    }

    return $NetworkCopyWith<$Res>(_value.network!, (value) {
      return _then(_value.copyWith(network: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EpisodeGroupImplCopyWith<$Res>
    implements $EpisodeGroupCopyWith<$Res> {
  factory _$$EpisodeGroupImplCopyWith(
    _$EpisodeGroupImpl value,
    $Res Function(_$EpisodeGroupImpl) then,
  ) = __$$EpisodeGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    @JsonKey(fromJson: _stringFromJson) String? type,
    @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
    Network? network,
  });

  @override
  $NetworkCopyWith<$Res>? get network;
}

/// @nodoc
class __$$EpisodeGroupImplCopyWithImpl<$Res>
    extends _$EpisodeGroupCopyWithImpl<$Res, _$EpisodeGroupImpl>
    implements _$$EpisodeGroupImplCopyWith<$Res> {
  __$$EpisodeGroupImplCopyWithImpl(
    _$EpisodeGroupImpl _value,
    $Res Function(_$EpisodeGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? description = freezed,
    Object? episode_count = freezed,
    Object? group_count = freezed,
    Object? type = freezed,
    Object? network = freezed,
  }) {
    return _then(
      _$EpisodeGroupImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_count: freezed == episode_count
            ? _value.episode_count
            : episode_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        group_count: freezed == group_count
            ? _value.group_count
            : group_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        network: freezed == network
            ? _value.network
            : network // ignore: cast_nullable_to_non_nullable
                  as Network?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeGroupImpl implements _EpisodeGroup {
  const _$EpisodeGroupImpl({
    @JsonKey(fromJson: _stringFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.description,
    @JsonKey(fromJson: _intFromJson) this.episode_count,
    @JsonKey(fromJson: _intFromJson) this.group_count,
    @JsonKey(fromJson: _stringFromJson) this.type,
    @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson) this.network,
  });

  factory _$EpisodeGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeGroupImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? description;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? group_count;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? type;
  @override
  @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
  final Network? network;

  @override
  String toString() {
    return 'EpisodeGroup(id: $id, name: $name, description: $description, episode_count: $episode_count, group_count: $group_count, type: $type, network: $network)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.episode_count, episode_count) ||
                other.episode_count == episode_count) &&
            (identical(other.group_count, group_count) ||
                other.group_count == group_count) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.network, network) || other.network == network));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    episode_count,
    group_count,
    type,
    network,
  );

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeGroupImplCopyWith<_$EpisodeGroupImpl> get copyWith =>
      __$$EpisodeGroupImplCopyWithImpl<_$EpisodeGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeGroupImplToJson(this);
  }
}

abstract class _EpisodeGroup implements EpisodeGroup {
  const factory _EpisodeGroup({
    @JsonKey(fromJson: _stringFromJson) final String? id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? description,
    @JsonKey(fromJson: _intFromJson) final int? episode_count,
    @JsonKey(fromJson: _intFromJson) final int? group_count,
    @JsonKey(fromJson: _stringFromJson) final String? type,
    @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
    final Network? network,
  }) = _$EpisodeGroupImpl;

  factory _EpisodeGroup.fromJson(Map<String, dynamic> json) =
      _$EpisodeGroupImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get description;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get group_count;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get type;
  @override
  @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
  Network? get network;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeGroupImplCopyWith<_$EpisodeGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NextEpisodeToAir _$NextEpisodeToAirFromJson(Map<String, dynamic> json) {
  return _NextEpisodeToAir.fromJson(json);
}

/// @nodoc
mixin _$NextEpisodeToAir {
  @JsonKey(fromJson: _stringFromJson)
  String? get air_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_number => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get production_code => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season_number => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get still_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get runtime => throw _privateConstructorUsedError;

  /// Serializes this NextEpisodeToAir to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NextEpisodeToAirCopyWith<NextEpisodeToAir> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NextEpisodeToAirCopyWith<$Res> {
  factory $NextEpisodeToAirCopyWith(
    NextEpisodeToAir value,
    $Res Function(NextEpisodeToAir) then,
  ) = _$NextEpisodeToAirCopyWithImpl<$Res, NextEpisodeToAir>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_number,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? production_code,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _stringFromJson) String? still_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _intFromJson) int? runtime,
  });
}

/// @nodoc
class _$NextEpisodeToAirCopyWithImpl<$Res, $Val extends NextEpisodeToAir>
    implements $NextEpisodeToAirCopyWith<$Res> {
  _$NextEpisodeToAirCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_number = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? production_code = freezed,
    Object? season_number = freezed,
    Object? still_path = freezed,
    Object? vote_average = freezed,
    Object? vote_count = freezed,
    Object? runtime = freezed,
  }) {
    return _then(
      _value.copyWith(
            air_date: freezed == air_date
                ? _value.air_date
                : air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_number: freezed == episode_number
                ? _value.episode_number
                : episode_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            production_code: freezed == production_code
                ? _value.production_code
                : production_code // ignore: cast_nullable_to_non_nullable
                      as String?,
            season_number: freezed == season_number
                ? _value.season_number
                : season_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            still_path: freezed == still_path
                ? _value.still_path
                : still_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
            vote_count: freezed == vote_count
                ? _value.vote_count
                : vote_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            runtime: freezed == runtime
                ? _value.runtime
                : runtime // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NextEpisodeToAirImplCopyWith<$Res>
    implements $NextEpisodeToAirCopyWith<$Res> {
  factory _$$NextEpisodeToAirImplCopyWith(
    _$NextEpisodeToAirImpl value,
    $Res Function(_$NextEpisodeToAirImpl) then,
  ) = __$$NextEpisodeToAirImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _stringFromJson) String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_number,
    @JsonKey(fromJson: _intFromJson) int? id,
    @JsonKey(fromJson: _stringFromJson) String? name,
    @JsonKey(fromJson: _stringFromJson) String? overview,
    @JsonKey(fromJson: _stringFromJson) String? production_code,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _stringFromJson) String? still_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _intFromJson) int? runtime,
  });
}

/// @nodoc
class __$$NextEpisodeToAirImplCopyWithImpl<$Res>
    extends _$NextEpisodeToAirCopyWithImpl<$Res, _$NextEpisodeToAirImpl>
    implements _$$NextEpisodeToAirImplCopyWith<$Res> {
  __$$NextEpisodeToAirImplCopyWithImpl(
    _$NextEpisodeToAirImpl _value,
    $Res Function(_$NextEpisodeToAirImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_number = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? production_code = freezed,
    Object? season_number = freezed,
    Object? still_path = freezed,
    Object? vote_average = freezed,
    Object? vote_count = freezed,
    Object? runtime = freezed,
  }) {
    return _then(
      _$NextEpisodeToAirImpl(
        air_date: freezed == air_date
            ? _value.air_date
            : air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_number: freezed == episode_number
            ? _value.episode_number
            : episode_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        production_code: freezed == production_code
            ? _value.production_code
            : production_code // ignore: cast_nullable_to_non_nullable
                  as String?,
        season_number: freezed == season_number
            ? _value.season_number
            : season_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        still_path: freezed == still_path
            ? _value.still_path
            : still_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
        vote_count: freezed == vote_count
            ? _value.vote_count
            : vote_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        runtime: freezed == runtime
            ? _value.runtime
            : runtime // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NextEpisodeToAirImpl implements _NextEpisodeToAir {
  const _$NextEpisodeToAirImpl({
    @JsonKey(fromJson: _stringFromJson) this.air_date,
    @JsonKey(fromJson: _intFromJson) this.episode_number,
    @JsonKey(fromJson: _intFromJson) this.id,
    @JsonKey(fromJson: _stringFromJson) this.name,
    @JsonKey(fromJson: _stringFromJson) this.overview,
    @JsonKey(fromJson: _stringFromJson) this.production_code,
    @JsonKey(fromJson: _intFromJson) this.season_number,
    @JsonKey(fromJson: _stringFromJson) this.still_path,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
    @JsonKey(fromJson: _intFromJson) this.vote_count,
    @JsonKey(fromJson: _intFromJson) this.runtime,
  });

  factory _$NextEpisodeToAirImpl.fromJson(Map<String, dynamic> json) =>
      _$$NextEpisodeToAirImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_number;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? production_code;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season_number;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? still_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? vote_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? runtime;

  @override
  String toString() {
    return 'NextEpisodeToAir(air_date: $air_date, episode_number: $episode_number, id: $id, name: $name, overview: $overview, production_code: $production_code, season_number: $season_number, still_path: $still_path, vote_average: $vote_average, vote_count: $vote_count, runtime: $runtime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NextEpisodeToAirImpl &&
            (identical(other.air_date, air_date) ||
                other.air_date == air_date) &&
            (identical(other.episode_number, episode_number) ||
                other.episode_number == episode_number) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.production_code, production_code) ||
                other.production_code == production_code) &&
            (identical(other.season_number, season_number) ||
                other.season_number == season_number) &&
            (identical(other.still_path, still_path) ||
                other.still_path == still_path) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average) &&
            (identical(other.vote_count, vote_count) ||
                other.vote_count == vote_count) &&
            (identical(other.runtime, runtime) || other.runtime == runtime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    air_date,
    episode_number,
    id,
    name,
    overview,
    production_code,
    season_number,
    still_path,
    vote_average,
    vote_count,
    runtime,
  );

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NextEpisodeToAirImplCopyWith<_$NextEpisodeToAirImpl> get copyWith =>
      __$$NextEpisodeToAirImplCopyWithImpl<_$NextEpisodeToAirImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NextEpisodeToAirImplToJson(this);
  }
}

abstract class _NextEpisodeToAir implements NextEpisodeToAir {
  const factory _NextEpisodeToAir({
    @JsonKey(fromJson: _stringFromJson) final String? air_date,
    @JsonKey(fromJson: _intFromJson) final int? episode_number,
    @JsonKey(fromJson: _intFromJson) final int? id,
    @JsonKey(fromJson: _stringFromJson) final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? overview,
    @JsonKey(fromJson: _stringFromJson) final String? production_code,
    @JsonKey(fromJson: _intFromJson) final int? season_number,
    @JsonKey(fromJson: _stringFromJson) final String? still_path,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
    @JsonKey(fromJson: _intFromJson) final int? vote_count,
    @JsonKey(fromJson: _intFromJson) final int? runtime,
  }) = _$NextEpisodeToAirImpl;

  factory _NextEpisodeToAir.fromJson(Map<String, dynamic> json) =
      _$NextEpisodeToAirImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_number;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get overview;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get production_code;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season_number;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get still_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get runtime;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NextEpisodeToAirImplCopyWith<_$NextEpisodeToAirImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TorrentInfo _$TorrentInfoFromJson(Map<String, dynamic> json) {
  return _TorrentInfo.fromJson(json);
}

/// @nodoc
mixin _$TorrentInfo {
  /// Serializes this TorrentInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TorrentInfoCopyWith<$Res> {
  factory $TorrentInfoCopyWith(
    TorrentInfo value,
    $Res Function(TorrentInfo) then,
  ) = _$TorrentInfoCopyWithImpl<$Res, TorrentInfo>;
}

/// @nodoc
class _$TorrentInfoCopyWithImpl<$Res, $Val extends TorrentInfo>
    implements $TorrentInfoCopyWith<$Res> {
  _$TorrentInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TorrentInfo
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TorrentInfoImplCopyWith<$Res> {
  factory _$$TorrentInfoImplCopyWith(
    _$TorrentInfoImpl value,
    $Res Function(_$TorrentInfoImpl) then,
  ) = __$$TorrentInfoImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TorrentInfoImplCopyWithImpl<$Res>
    extends _$TorrentInfoCopyWithImpl<$Res, _$TorrentInfoImpl>
    implements _$$TorrentInfoImplCopyWith<$Res> {
  __$$TorrentInfoImplCopyWithImpl(
    _$TorrentInfoImpl _value,
    $Res Function(_$TorrentInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TorrentInfo
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$TorrentInfoImpl implements _TorrentInfo {
  const _$TorrentInfoImpl();

  factory _$TorrentInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TorrentInfoImplFromJson(json);

  @override
  String toString() {
    return 'TorrentInfo()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TorrentInfoImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return _$$TorrentInfoImplToJson(this);
  }
}

abstract class _TorrentInfo implements TorrentInfo {
  const factory _TorrentInfo() = _$TorrentInfoImpl;

  factory _TorrentInfo.fromJson(Map<String, dynamic> json) =
      _$TorrentInfoImpl.fromJson;
}

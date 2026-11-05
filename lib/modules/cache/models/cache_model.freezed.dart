// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cache_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CacheResponse _$CacheResponseFromJson(Map<String, dynamic> json) {
  return _CacheResponse.fromJson(json);
}

/// @nodoc
mixin _$CacheResponse {
  bool get success => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  CachePayload? get data => throw _privateConstructorUsedError;

  /// Serializes this CacheResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CacheResponseCopyWith<CacheResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CacheResponseCopyWith<$Res> {
  factory $CacheResponseCopyWith(
    CacheResponse value,
    $Res Function(CacheResponse) then,
  ) = _$CacheResponseCopyWithImpl<$Res, CacheResponse>;
  @useResult
  $Res call({bool success, String? message, CachePayload? data});

  $CachePayloadCopyWith<$Res>? get data;
}

/// @nodoc
class _$CacheResponseCopyWithImpl<$Res, $Val extends CacheResponse>
    implements $CacheResponseCopyWith<$Res> {
  _$CacheResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as CachePayload?,
          )
          as $Val,
    );
  }

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CachePayloadCopyWith<$Res>? get data {
    if (_value.data == null) {
      return null;
    }

    return $CachePayloadCopyWith<$Res>(_value.data!, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CacheResponseImplCopyWith<$Res>
    implements $CacheResponseCopyWith<$Res> {
  factory _$$CacheResponseImplCopyWith(
    _$CacheResponseImpl value,
    $Res Function(_$CacheResponseImpl) then,
  ) = __$$CacheResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, String? message, CachePayload? data});

  @override
  $CachePayloadCopyWith<$Res>? get data;
}

/// @nodoc
class __$$CacheResponseImplCopyWithImpl<$Res>
    extends _$CacheResponseCopyWithImpl<$Res, _$CacheResponseImpl>
    implements _$$CacheResponseImplCopyWith<$Res> {
  __$$CacheResponseImplCopyWithImpl(
    _$CacheResponseImpl _value,
    $Res Function(_$CacheResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _$CacheResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as CachePayload?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CacheResponseImpl implements _CacheResponse {
  const _$CacheResponseImpl({required this.success, this.message, this.data});

  factory _$CacheResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CacheResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final String? message;
  @override
  final CachePayload? data;

  @override
  String toString() {
    return 'CacheResponse(success: $success, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CacheResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, message, data);

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CacheResponseImplCopyWith<_$CacheResponseImpl> get copyWith =>
      __$$CacheResponseImplCopyWithImpl<_$CacheResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CacheResponseImplToJson(this);
  }
}

abstract class _CacheResponse implements CacheResponse {
  const factory _CacheResponse({
    required final bool success,
    final String? message,
    final CachePayload? data,
  }) = _$CacheResponseImpl;

  factory _CacheResponse.fromJson(Map<String, dynamic> json) =
      _$CacheResponseImpl.fromJson;

  @override
  bool get success;
  @override
  String? get message;
  @override
  CachePayload? get data;

  /// Create a copy of CacheResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CacheResponseImplCopyWith<_$CacheResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CachePayload _$CachePayloadFromJson(Map<String, dynamic> json) {
  return _CachePayload.fromJson(json);
}

/// @nodoc
mixin _$CachePayload {
  @JsonKey(fromJson: _intFromJson)
  int? get count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get sites => throw _privateConstructorUsedError;
  @JsonKey(name: 'data')
  List<CacheItem>? get items => throw _privateConstructorUsedError;

  /// Serializes this CachePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CachePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CachePayloadCopyWith<CachePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CachePayloadCopyWith<$Res> {
  factory $CachePayloadCopyWith(
    CachePayload value,
    $Res Function(CachePayload) then,
  ) = _$CachePayloadCopyWithImpl<$Res, CachePayload>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? count,
    @JsonKey(fromJson: _intFromJson) int? sites,
    @JsonKey(name: 'data') List<CacheItem>? items,
  });
}

/// @nodoc
class _$CachePayloadCopyWithImpl<$Res, $Val extends CachePayload>
    implements $CachePayloadCopyWith<$Res> {
  _$CachePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CachePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = freezed,
    Object? sites = freezed,
    Object? items = freezed,
  }) {
    return _then(
      _value.copyWith(
            count: freezed == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int?,
            sites: freezed == sites
                ? _value.sites
                : sites // ignore: cast_nullable_to_non_nullable
                      as int?,
            items: freezed == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CacheItem>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CachePayloadImplCopyWith<$Res>
    implements $CachePayloadCopyWith<$Res> {
  factory _$$CachePayloadImplCopyWith(
    _$CachePayloadImpl value,
    $Res Function(_$CachePayloadImpl) then,
  ) = __$$CachePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? count,
    @JsonKey(fromJson: _intFromJson) int? sites,
    @JsonKey(name: 'data') List<CacheItem>? items,
  });
}

/// @nodoc
class __$$CachePayloadImplCopyWithImpl<$Res>
    extends _$CachePayloadCopyWithImpl<$Res, _$CachePayloadImpl>
    implements _$$CachePayloadImplCopyWith<$Res> {
  __$$CachePayloadImplCopyWithImpl(
    _$CachePayloadImpl _value,
    $Res Function(_$CachePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CachePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = freezed,
    Object? sites = freezed,
    Object? items = freezed,
  }) {
    return _then(
      _$CachePayloadImpl(
        count: freezed == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int?,
        sites: freezed == sites
            ? _value.sites
            : sites // ignore: cast_nullable_to_non_nullable
                  as int?,
        items: freezed == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CacheItem>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CachePayloadImpl implements _CachePayload {
  const _$CachePayloadImpl({
    @JsonKey(fromJson: _intFromJson) this.count,
    @JsonKey(fromJson: _intFromJson) this.sites,
    @JsonKey(name: 'data') final List<CacheItem>? items,
  }) : _items = items;

  factory _$CachePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$CachePayloadImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? sites;
  final List<CacheItem>? _items;
  @override
  @JsonKey(name: 'data')
  List<CacheItem>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CachePayload(count: $count, sites: $sites, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CachePayloadImpl &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.sites, sites) || other.sites == sites) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    count,
    sites,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of CachePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CachePayloadImplCopyWith<_$CachePayloadImpl> get copyWith =>
      __$$CachePayloadImplCopyWithImpl<_$CachePayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CachePayloadImplToJson(this);
  }
}

abstract class _CachePayload implements CachePayload {
  const factory _CachePayload({
    @JsonKey(fromJson: _intFromJson) final int? count,
    @JsonKey(fromJson: _intFromJson) final int? sites,
    @JsonKey(name: 'data') final List<CacheItem>? items,
  }) = _$CachePayloadImpl;

  factory _CachePayload.fromJson(Map<String, dynamic> json) =
      _$CachePayloadImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get sites;
  @override
  @JsonKey(name: 'data')
  List<CacheItem>? get items;

  /// Create a copy of CachePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CachePayloadImplCopyWith<_$CachePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CacheItem _$CacheItemFromJson(Map<String, dynamic> json) {
  return _CacheItem.fromJson(json);
}

/// @nodoc
mixin _$CacheItem {
  String? get hash => throw _privateConstructorUsedError;
  String? get domain => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get size => throw _privateConstructorUsedError;
  String? get pubdate => throw _privateConstructorUsedError;
  @JsonKey(name: 'site_name')
  String? get siteName => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_name')
  String? get mediaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_year', fromJson: _strFromJson)
  String? get mediaYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_type')
  String? get mediaType => throw _privateConstructorUsedError;
  @JsonKey(name: 'season_episode')
  String? get seasonEpisode => throw _privateConstructorUsedError;
  @JsonKey(name: 'resource_term')
  String? get resourceTerm => throw _privateConstructorUsedError;
  String? get enclosure => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_url')
  String? get pageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'poster_path')
  String? get posterPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'backdrop_path')
  String? get backdropPath => throw _privateConstructorUsedError;

  /// Serializes this CacheItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CacheItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CacheItemCopyWith<CacheItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CacheItemCopyWith<$Res> {
  factory $CacheItemCopyWith(CacheItem value, $Res Function(CacheItem) then) =
      _$CacheItemCopyWithImpl<$Res, CacheItem>;
  @useResult
  $Res call({
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
  });
}

/// @nodoc
class _$CacheItemCopyWithImpl<$Res, $Val extends CacheItem>
    implements $CacheItemCopyWith<$Res> {
  _$CacheItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CacheItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hash = freezed,
    Object? domain = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? size = freezed,
    Object? pubdate = freezed,
    Object? siteName = freezed,
    Object? mediaName = freezed,
    Object? mediaYear = freezed,
    Object? mediaType = freezed,
    Object? seasonEpisode = freezed,
    Object? resourceTerm = freezed,
    Object? enclosure = freezed,
    Object? pageUrl = freezed,
    Object? posterPath = freezed,
    Object? backdropPath = freezed,
  }) {
    return _then(
      _value.copyWith(
            hash: freezed == hash
                ? _value.hash
                : hash // ignore: cast_nullable_to_non_nullable
                      as String?,
            domain: freezed == domain
                ? _value.domain
                : domain // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            size: freezed == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int?,
            pubdate: freezed == pubdate
                ? _value.pubdate
                : pubdate // ignore: cast_nullable_to_non_nullable
                      as String?,
            siteName: freezed == siteName
                ? _value.siteName
                : siteName // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaName: freezed == mediaName
                ? _value.mediaName
                : mediaName // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaYear: freezed == mediaYear
                ? _value.mediaYear
                : mediaYear // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaType: freezed == mediaType
                ? _value.mediaType
                : mediaType // ignore: cast_nullable_to_non_nullable
                      as String?,
            seasonEpisode: freezed == seasonEpisode
                ? _value.seasonEpisode
                : seasonEpisode // ignore: cast_nullable_to_non_nullable
                      as String?,
            resourceTerm: freezed == resourceTerm
                ? _value.resourceTerm
                : resourceTerm // ignore: cast_nullable_to_non_nullable
                      as String?,
            enclosure: freezed == enclosure
                ? _value.enclosure
                : enclosure // ignore: cast_nullable_to_non_nullable
                      as String?,
            pageUrl: freezed == pageUrl
                ? _value.pageUrl
                : pageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            posterPath: freezed == posterPath
                ? _value.posterPath
                : posterPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            backdropPath: freezed == backdropPath
                ? _value.backdropPath
                : backdropPath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CacheItemImplCopyWith<$Res>
    implements $CacheItemCopyWith<$Res> {
  factory _$$CacheItemImplCopyWith(
    _$CacheItemImpl value,
    $Res Function(_$CacheItemImpl) then,
  ) = __$$CacheItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
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
  });
}

/// @nodoc
class __$$CacheItemImplCopyWithImpl<$Res>
    extends _$CacheItemCopyWithImpl<$Res, _$CacheItemImpl>
    implements _$$CacheItemImplCopyWith<$Res> {
  __$$CacheItemImplCopyWithImpl(
    _$CacheItemImpl _value,
    $Res Function(_$CacheItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CacheItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hash = freezed,
    Object? domain = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? size = freezed,
    Object? pubdate = freezed,
    Object? siteName = freezed,
    Object? mediaName = freezed,
    Object? mediaYear = freezed,
    Object? mediaType = freezed,
    Object? seasonEpisode = freezed,
    Object? resourceTerm = freezed,
    Object? enclosure = freezed,
    Object? pageUrl = freezed,
    Object? posterPath = freezed,
    Object? backdropPath = freezed,
  }) {
    return _then(
      _$CacheItemImpl(
        hash: freezed == hash
            ? _value.hash
            : hash // ignore: cast_nullable_to_non_nullable
                  as String?,
        domain: freezed == domain
            ? _value.domain
            : domain // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        size: freezed == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
        pubdate: freezed == pubdate
            ? _value.pubdate
            : pubdate // ignore: cast_nullable_to_non_nullable
                  as String?,
        siteName: freezed == siteName
            ? _value.siteName
            : siteName // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaName: freezed == mediaName
            ? _value.mediaName
            : mediaName // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaYear: freezed == mediaYear
            ? _value.mediaYear
            : mediaYear // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaType: freezed == mediaType
            ? _value.mediaType
            : mediaType // ignore: cast_nullable_to_non_nullable
                  as String?,
        seasonEpisode: freezed == seasonEpisode
            ? _value.seasonEpisode
            : seasonEpisode // ignore: cast_nullable_to_non_nullable
                  as String?,
        resourceTerm: freezed == resourceTerm
            ? _value.resourceTerm
            : resourceTerm // ignore: cast_nullable_to_non_nullable
                  as String?,
        enclosure: freezed == enclosure
            ? _value.enclosure
            : enclosure // ignore: cast_nullable_to_non_nullable
                  as String?,
        pageUrl: freezed == pageUrl
            ? _value.pageUrl
            : pageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        posterPath: freezed == posterPath
            ? _value.posterPath
            : posterPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        backdropPath: freezed == backdropPath
            ? _value.backdropPath
            : backdropPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CacheItemImpl implements _CacheItem {
  const _$CacheItemImpl({
    this.hash,
    this.domain,
    this.title,
    this.description,
    @JsonKey(fromJson: _intFromJson) this.size,
    this.pubdate,
    @JsonKey(name: 'site_name') this.siteName,
    @JsonKey(name: 'media_name') this.mediaName,
    @JsonKey(name: 'media_year', fromJson: _strFromJson) this.mediaYear,
    @JsonKey(name: 'media_type') this.mediaType,
    @JsonKey(name: 'season_episode') this.seasonEpisode,
    @JsonKey(name: 'resource_term') this.resourceTerm,
    this.enclosure,
    @JsonKey(name: 'page_url') this.pageUrl,
    @JsonKey(name: 'poster_path') this.posterPath,
    @JsonKey(name: 'backdrop_path') this.backdropPath,
  });

  factory _$CacheItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CacheItemImplFromJson(json);

  @override
  final String? hash;
  @override
  final String? domain;
  @override
  final String? title;
  @override
  final String? description;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? size;
  @override
  final String? pubdate;
  @override
  @JsonKey(name: 'site_name')
  final String? siteName;
  @override
  @JsonKey(name: 'media_name')
  final String? mediaName;
  @override
  @JsonKey(name: 'media_year', fromJson: _strFromJson)
  final String? mediaYear;
  @override
  @JsonKey(name: 'media_type')
  final String? mediaType;
  @override
  @JsonKey(name: 'season_episode')
  final String? seasonEpisode;
  @override
  @JsonKey(name: 'resource_term')
  final String? resourceTerm;
  @override
  final String? enclosure;
  @override
  @JsonKey(name: 'page_url')
  final String? pageUrl;
  @override
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @override
  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;

  @override
  String toString() {
    return 'CacheItem(hash: $hash, domain: $domain, title: $title, description: $description, size: $size, pubdate: $pubdate, siteName: $siteName, mediaName: $mediaName, mediaYear: $mediaYear, mediaType: $mediaType, seasonEpisode: $seasonEpisode, resourceTerm: $resourceTerm, enclosure: $enclosure, pageUrl: $pageUrl, posterPath: $posterPath, backdropPath: $backdropPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CacheItemImpl &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.domain, domain) || other.domain == domain) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.pubdate, pubdate) || other.pubdate == pubdate) &&
            (identical(other.siteName, siteName) ||
                other.siteName == siteName) &&
            (identical(other.mediaName, mediaName) ||
                other.mediaName == mediaName) &&
            (identical(other.mediaYear, mediaYear) ||
                other.mediaYear == mediaYear) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.seasonEpisode, seasonEpisode) ||
                other.seasonEpisode == seasonEpisode) &&
            (identical(other.resourceTerm, resourceTerm) ||
                other.resourceTerm == resourceTerm) &&
            (identical(other.enclosure, enclosure) ||
                other.enclosure == enclosure) &&
            (identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl) &&
            (identical(other.posterPath, posterPath) ||
                other.posterPath == posterPath) &&
            (identical(other.backdropPath, backdropPath) ||
                other.backdropPath == backdropPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    hash,
    domain,
    title,
    description,
    size,
    pubdate,
    siteName,
    mediaName,
    mediaYear,
    mediaType,
    seasonEpisode,
    resourceTerm,
    enclosure,
    pageUrl,
    posterPath,
    backdropPath,
  );

  /// Create a copy of CacheItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CacheItemImplCopyWith<_$CacheItemImpl> get copyWith =>
      __$$CacheItemImplCopyWithImpl<_$CacheItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CacheItemImplToJson(this);
  }
}

abstract class _CacheItem implements CacheItem {
  const factory _CacheItem({
    final String? hash,
    final String? domain,
    final String? title,
    final String? description,
    @JsonKey(fromJson: _intFromJson) final int? size,
    final String? pubdate,
    @JsonKey(name: 'site_name') final String? siteName,
    @JsonKey(name: 'media_name') final String? mediaName,
    @JsonKey(name: 'media_year', fromJson: _strFromJson)
    final String? mediaYear,
    @JsonKey(name: 'media_type') final String? mediaType,
    @JsonKey(name: 'season_episode') final String? seasonEpisode,
    @JsonKey(name: 'resource_term') final String? resourceTerm,
    final String? enclosure,
    @JsonKey(name: 'page_url') final String? pageUrl,
    @JsonKey(name: 'poster_path') final String? posterPath,
    @JsonKey(name: 'backdrop_path') final String? backdropPath,
  }) = _$CacheItemImpl;

  factory _CacheItem.fromJson(Map<String, dynamic> json) =
      _$CacheItemImpl.fromJson;

  @override
  String? get hash;
  @override
  String? get domain;
  @override
  String? get title;
  @override
  String? get description;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get size;
  @override
  String? get pubdate;
  @override
  @JsonKey(name: 'site_name')
  String? get siteName;
  @override
  @JsonKey(name: 'media_name')
  String? get mediaName;
  @override
  @JsonKey(name: 'media_year', fromJson: _strFromJson)
  String? get mediaYear;
  @override
  @JsonKey(name: 'media_type')
  String? get mediaType;
  @override
  @JsonKey(name: 'season_episode')
  String? get seasonEpisode;
  @override
  @JsonKey(name: 'resource_term')
  String? get resourceTerm;
  @override
  String? get enclosure;
  @override
  @JsonKey(name: 'page_url')
  String? get pageUrl;
  @override
  @JsonKey(name: 'poster_path')
  String? get posterPath;
  @override
  @JsonKey(name: 'backdrop_path')
  String? get backdropPath;

  /// Create a copy of CacheItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CacheItemImplCopyWith<_$CacheItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

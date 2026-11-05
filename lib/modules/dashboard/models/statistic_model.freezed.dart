// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistic_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StatisticModel _$StatisticModelFromJson(Map<String, dynamic> json) {
  return _StatisticModel.fromJson(json);
}

/// @nodoc
mixin _$StatisticModel {
  /// 电影数量
  int get movie_count => throw _privateConstructorUsedError;

  /// 剧集数量
  int get tv_count => throw _privateConstructorUsedError;

  /// 集数
  int get episode_count => throw _privateConstructorUsedError;

  /// 用户数量
  int get user_count => throw _privateConstructorUsedError;

  /// 音乐数量（旧版服务端不返回，为 null 时隐藏音乐统计）
  int? get music_count => throw _privateConstructorUsedError;

  /// 本月新增电影
  int get movie_count_month => throw _privateConstructorUsedError;

  /// 本月新增剧集
  int get tv_count_month => throw _privateConstructorUsedError;

  /// 本月新增集数
  int get episode_count_month => throw _privateConstructorUsedError;

  /// 本月新增音乐
  int get music_count_month => throw _privateConstructorUsedError;

  /// Serializes this StatisticModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StatisticModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatisticModelCopyWith<StatisticModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatisticModelCopyWith<$Res> {
  factory $StatisticModelCopyWith(
    StatisticModel value,
    $Res Function(StatisticModel) then,
  ) = _$StatisticModelCopyWithImpl<$Res, StatisticModel>;
  @useResult
  $Res call({
    int movie_count,
    int tv_count,
    int episode_count,
    int user_count,
    int? music_count,
    int movie_count_month,
    int tv_count_month,
    int episode_count_month,
    int music_count_month,
  });
}

/// @nodoc
class _$StatisticModelCopyWithImpl<$Res, $Val extends StatisticModel>
    implements $StatisticModelCopyWith<$Res> {
  _$StatisticModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StatisticModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? movie_count = null,
    Object? tv_count = null,
    Object? episode_count = null,
    Object? user_count = null,
    Object? music_count = freezed,
    Object? movie_count_month = null,
    Object? tv_count_month = null,
    Object? episode_count_month = null,
    Object? music_count_month = null,
  }) {
    return _then(
      _value.copyWith(
            movie_count: null == movie_count
                ? _value.movie_count
                : movie_count // ignore: cast_nullable_to_non_nullable
                      as int,
            tv_count: null == tv_count
                ? _value.tv_count
                : tv_count // ignore: cast_nullable_to_non_nullable
                      as int,
            episode_count: null == episode_count
                ? _value.episode_count
                : episode_count // ignore: cast_nullable_to_non_nullable
                      as int,
            user_count: null == user_count
                ? _value.user_count
                : user_count // ignore: cast_nullable_to_non_nullable
                      as int,
            music_count: freezed == music_count
                ? _value.music_count
                : music_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            movie_count_month: null == movie_count_month
                ? _value.movie_count_month
                : movie_count_month // ignore: cast_nullable_to_non_nullable
                      as int,
            tv_count_month: null == tv_count_month
                ? _value.tv_count_month
                : tv_count_month // ignore: cast_nullable_to_non_nullable
                      as int,
            episode_count_month: null == episode_count_month
                ? _value.episode_count_month
                : episode_count_month // ignore: cast_nullable_to_non_nullable
                      as int,
            music_count_month: null == music_count_month
                ? _value.music_count_month
                : music_count_month // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StatisticModelImplCopyWith<$Res>
    implements $StatisticModelCopyWith<$Res> {
  factory _$$StatisticModelImplCopyWith(
    _$StatisticModelImpl value,
    $Res Function(_$StatisticModelImpl) then,
  ) = __$$StatisticModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int movie_count,
    int tv_count,
    int episode_count,
    int user_count,
    int? music_count,
    int movie_count_month,
    int tv_count_month,
    int episode_count_month,
    int music_count_month,
  });
}

/// @nodoc
class __$$StatisticModelImplCopyWithImpl<$Res>
    extends _$StatisticModelCopyWithImpl<$Res, _$StatisticModelImpl>
    implements _$$StatisticModelImplCopyWith<$Res> {
  __$$StatisticModelImplCopyWithImpl(
    _$StatisticModelImpl _value,
    $Res Function(_$StatisticModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StatisticModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? movie_count = null,
    Object? tv_count = null,
    Object? episode_count = null,
    Object? user_count = null,
    Object? music_count = freezed,
    Object? movie_count_month = null,
    Object? tv_count_month = null,
    Object? episode_count_month = null,
    Object? music_count_month = null,
  }) {
    return _then(
      _$StatisticModelImpl(
        movie_count: null == movie_count
            ? _value.movie_count
            : movie_count // ignore: cast_nullable_to_non_nullable
                  as int,
        tv_count: null == tv_count
            ? _value.tv_count
            : tv_count // ignore: cast_nullable_to_non_nullable
                  as int,
        episode_count: null == episode_count
            ? _value.episode_count
            : episode_count // ignore: cast_nullable_to_non_nullable
                  as int,
        user_count: null == user_count
            ? _value.user_count
            : user_count // ignore: cast_nullable_to_non_nullable
                  as int,
        music_count: freezed == music_count
            ? _value.music_count
            : music_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        movie_count_month: null == movie_count_month
            ? _value.movie_count_month
            : movie_count_month // ignore: cast_nullable_to_non_nullable
                  as int,
        tv_count_month: null == tv_count_month
            ? _value.tv_count_month
            : tv_count_month // ignore: cast_nullable_to_non_nullable
                  as int,
        episode_count_month: null == episode_count_month
            ? _value.episode_count_month
            : episode_count_month // ignore: cast_nullable_to_non_nullable
                  as int,
        music_count_month: null == music_count_month
            ? _value.music_count_month
            : music_count_month // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StatisticModelImpl implements _StatisticModel {
  const _$StatisticModelImpl({
    this.movie_count = 0,
    this.tv_count = 0,
    this.episode_count = 0,
    this.user_count = 0,
    this.music_count,
    this.movie_count_month = 0,
    this.tv_count_month = 0,
    this.episode_count_month = 0,
    this.music_count_month = 0,
  });

  factory _$StatisticModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatisticModelImplFromJson(json);

  /// 电影数量
  @override
  @JsonKey()
  final int movie_count;

  /// 剧集数量
  @override
  @JsonKey()
  final int tv_count;

  /// 集数
  @override
  @JsonKey()
  final int episode_count;

  /// 用户数量
  @override
  @JsonKey()
  final int user_count;

  /// 音乐数量（旧版服务端不返回，为 null 时隐藏音乐统计）
  @override
  final int? music_count;

  /// 本月新增电影
  @override
  @JsonKey()
  final int movie_count_month;

  /// 本月新增剧集
  @override
  @JsonKey()
  final int tv_count_month;

  /// 本月新增集数
  @override
  @JsonKey()
  final int episode_count_month;

  /// 本月新增音乐
  @override
  @JsonKey()
  final int music_count_month;

  @override
  String toString() {
    return 'StatisticModel(movie_count: $movie_count, tv_count: $tv_count, episode_count: $episode_count, user_count: $user_count, music_count: $music_count, movie_count_month: $movie_count_month, tv_count_month: $tv_count_month, episode_count_month: $episode_count_month, music_count_month: $music_count_month)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatisticModelImpl &&
            (identical(other.movie_count, movie_count) ||
                other.movie_count == movie_count) &&
            (identical(other.tv_count, tv_count) ||
                other.tv_count == tv_count) &&
            (identical(other.episode_count, episode_count) ||
                other.episode_count == episode_count) &&
            (identical(other.user_count, user_count) ||
                other.user_count == user_count) &&
            (identical(other.music_count, music_count) ||
                other.music_count == music_count) &&
            (identical(other.movie_count_month, movie_count_month) ||
                other.movie_count_month == movie_count_month) &&
            (identical(other.tv_count_month, tv_count_month) ||
                other.tv_count_month == tv_count_month) &&
            (identical(other.episode_count_month, episode_count_month) ||
                other.episode_count_month == episode_count_month) &&
            (identical(other.music_count_month, music_count_month) ||
                other.music_count_month == music_count_month));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    movie_count,
    tv_count,
    episode_count,
    user_count,
    music_count,
    movie_count_month,
    tv_count_month,
    episode_count_month,
    music_count_month,
  );

  /// Create a copy of StatisticModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatisticModelImplCopyWith<_$StatisticModelImpl> get copyWith =>
      __$$StatisticModelImplCopyWithImpl<_$StatisticModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StatisticModelImplToJson(this);
  }
}

abstract class _StatisticModel implements StatisticModel {
  const factory _StatisticModel({
    final int movie_count,
    final int tv_count,
    final int episode_count,
    final int user_count,
    final int? music_count,
    final int movie_count_month,
    final int tv_count_month,
    final int episode_count_month,
    final int music_count_month,
  }) = _$StatisticModelImpl;

  factory _StatisticModel.fromJson(Map<String, dynamic> json) =
      _$StatisticModelImpl.fromJson;

  /// 电影数量
  @override
  int get movie_count;

  /// 剧集数量
  @override
  int get tv_count;

  /// 集数
  @override
  int get episode_count;

  /// 用户数量
  @override
  int get user_count;

  /// 音乐数量（旧版服务端不返回，为 null 时隐藏音乐统计）
  @override
  int? get music_count;

  /// 本月新增电影
  @override
  int get movie_count_month;

  /// 本月新增剧集
  @override
  int get tv_count_month;

  /// 本月新增集数
  @override
  int get episode_count_month;

  /// 本月新增音乐
  @override
  int get music_count_month;

  /// Create a copy of StatisticModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatisticModelImplCopyWith<_$StatisticModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

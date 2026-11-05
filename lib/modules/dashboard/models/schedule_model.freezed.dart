// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) {
  return _ScheduleModel.fromJson(json);
}

/// @nodoc
mixin _$ScheduleModel {
  /// 任务ID
  String get id => throw _privateConstructorUsedError;

  /// 任务名称
  String get name => throw _privateConstructorUsedError;

  /// 任务提供者
  String get provider => throw _privateConstructorUsedError;

  /// 任务状态
  String get status => throw _privateConstructorUsedError;

  /// 下次运行时间
  String get next_run => throw _privateConstructorUsedError;

  /// 服务端按当前语言生成的名称
  String? get name_i18n => throw _privateConstructorUsedError;

  /// 服务端按当前语言生成的提供者
  String? get provider_i18n => throw _privateConstructorUsedError;

  /// 服务端按当前语言生成的状态
  String? get status_i18n => throw _privateConstructorUsedError;

  /// 服务端按当前语言生成的下次运行时间
  String? get next_run_i18n => throw _privateConstructorUsedError;

  /// 运行进度百分比（0-100）
  double get progress => throw _privateConstructorUsedError;

  /// 运行进度说明
  String? get progress_text => throw _privateConstructorUsedError;

  /// 服务端按当前语言生成的进度说明
  String? get progress_text_i18n => throw _privateConstructorUsedError;

  /// 是否启用进度上报（启用即视为运行中）
  bool get progress_enable => throw _privateConstructorUsedError;

  /// 进度详情（ScheduleProgress）
  Map<String, dynamic>? get progress_detail =>
      throw _privateConstructorUsedError;

  /// Serializes this ScheduleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleModelCopyWith<ScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleModelCopyWith<$Res> {
  factory $ScheduleModelCopyWith(
    ScheduleModel value,
    $Res Function(ScheduleModel) then,
  ) = _$ScheduleModelCopyWithImpl<$Res, ScheduleModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String provider,
    String status,
    String next_run,
    String? name_i18n,
    String? provider_i18n,
    String? status_i18n,
    String? next_run_i18n,
    double progress,
    String? progress_text,
    String? progress_text_i18n,
    bool progress_enable,
    Map<String, dynamic>? progress_detail,
  });
}

/// @nodoc
class _$ScheduleModelCopyWithImpl<$Res, $Val extends ScheduleModel>
    implements $ScheduleModelCopyWith<$Res> {
  _$ScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? provider = null,
    Object? status = null,
    Object? next_run = null,
    Object? name_i18n = freezed,
    Object? provider_i18n = freezed,
    Object? status_i18n = freezed,
    Object? next_run_i18n = freezed,
    Object? progress = null,
    Object? progress_text = freezed,
    Object? progress_text_i18n = freezed,
    Object? progress_enable = null,
    Object? progress_detail = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            provider: null == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            next_run: null == next_run
                ? _value.next_run
                : next_run // ignore: cast_nullable_to_non_nullable
                      as String,
            name_i18n: freezed == name_i18n
                ? _value.name_i18n
                : name_i18n // ignore: cast_nullable_to_non_nullable
                      as String?,
            provider_i18n: freezed == provider_i18n
                ? _value.provider_i18n
                : provider_i18n // ignore: cast_nullable_to_non_nullable
                      as String?,
            status_i18n: freezed == status_i18n
                ? _value.status_i18n
                : status_i18n // ignore: cast_nullable_to_non_nullable
                      as String?,
            next_run_i18n: freezed == next_run_i18n
                ? _value.next_run_i18n
                : next_run_i18n // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            progress_text: freezed == progress_text
                ? _value.progress_text
                : progress_text // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress_text_i18n: freezed == progress_text_i18n
                ? _value.progress_text_i18n
                : progress_text_i18n // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress_enable: null == progress_enable
                ? _value.progress_enable
                : progress_enable // ignore: cast_nullable_to_non_nullable
                      as bool,
            progress_detail: freezed == progress_detail
                ? _value.progress_detail
                : progress_detail // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScheduleModelImplCopyWith<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  factory _$$ScheduleModelImplCopyWith(
    _$ScheduleModelImpl value,
    $Res Function(_$ScheduleModelImpl) then,
  ) = __$$ScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String provider,
    String status,
    String next_run,
    String? name_i18n,
    String? provider_i18n,
    String? status_i18n,
    String? next_run_i18n,
    double progress,
    String? progress_text,
    String? progress_text_i18n,
    bool progress_enable,
    Map<String, dynamic>? progress_detail,
  });
}

/// @nodoc
class __$$ScheduleModelImplCopyWithImpl<$Res>
    extends _$ScheduleModelCopyWithImpl<$Res, _$ScheduleModelImpl>
    implements _$$ScheduleModelImplCopyWith<$Res> {
  __$$ScheduleModelImplCopyWithImpl(
    _$ScheduleModelImpl _value,
    $Res Function(_$ScheduleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? provider = null,
    Object? status = null,
    Object? next_run = null,
    Object? name_i18n = freezed,
    Object? provider_i18n = freezed,
    Object? status_i18n = freezed,
    Object? next_run_i18n = freezed,
    Object? progress = null,
    Object? progress_text = freezed,
    Object? progress_text_i18n = freezed,
    Object? progress_enable = null,
    Object? progress_detail = freezed,
  }) {
    return _then(
      _$ScheduleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        next_run: null == next_run
            ? _value.next_run
            : next_run // ignore: cast_nullable_to_non_nullable
                  as String,
        name_i18n: freezed == name_i18n
            ? _value.name_i18n
            : name_i18n // ignore: cast_nullable_to_non_nullable
                  as String?,
        provider_i18n: freezed == provider_i18n
            ? _value.provider_i18n
            : provider_i18n // ignore: cast_nullable_to_non_nullable
                  as String?,
        status_i18n: freezed == status_i18n
            ? _value.status_i18n
            : status_i18n // ignore: cast_nullable_to_non_nullable
                  as String?,
        next_run_i18n: freezed == next_run_i18n
            ? _value.next_run_i18n
            : next_run_i18n // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        progress_text: freezed == progress_text
            ? _value.progress_text
            : progress_text // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress_text_i18n: freezed == progress_text_i18n
            ? _value.progress_text_i18n
            : progress_text_i18n // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress_enable: null == progress_enable
            ? _value.progress_enable
            : progress_enable // ignore: cast_nullable_to_non_nullable
                  as bool,
        progress_detail: freezed == progress_detail
            ? _value._progress_detail
            : progress_detail // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduleModelImpl implements _ScheduleModel {
  const _$ScheduleModelImpl({
    this.id = '',
    this.name = '',
    this.provider = '',
    this.status = '',
    this.next_run = '',
    this.name_i18n,
    this.provider_i18n,
    this.status_i18n,
    this.next_run_i18n,
    this.progress = 0.0,
    this.progress_text,
    this.progress_text_i18n,
    this.progress_enable = false,
    final Map<String, dynamic>? progress_detail,
  }) : _progress_detail = progress_detail;

  factory _$ScheduleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleModelImplFromJson(json);

  /// 任务ID
  @override
  @JsonKey()
  final String id;

  /// 任务名称
  @override
  @JsonKey()
  final String name;

  /// 任务提供者
  @override
  @JsonKey()
  final String provider;

  /// 任务状态
  @override
  @JsonKey()
  final String status;

  /// 下次运行时间
  @override
  @JsonKey()
  final String next_run;

  /// 服务端按当前语言生成的名称
  @override
  final String? name_i18n;

  /// 服务端按当前语言生成的提供者
  @override
  final String? provider_i18n;

  /// 服务端按当前语言生成的状态
  @override
  final String? status_i18n;

  /// 服务端按当前语言生成的下次运行时间
  @override
  final String? next_run_i18n;

  /// 运行进度百分比（0-100）
  @override
  @JsonKey()
  final double progress;

  /// 运行进度说明
  @override
  final String? progress_text;

  /// 服务端按当前语言生成的进度说明
  @override
  final String? progress_text_i18n;

  /// 是否启用进度上报（启用即视为运行中）
  @override
  @JsonKey()
  final bool progress_enable;

  /// 进度详情（ScheduleProgress）
  final Map<String, dynamic>? _progress_detail;

  /// 进度详情（ScheduleProgress）
  @override
  Map<String, dynamic>? get progress_detail {
    final value = _progress_detail;
    if (value == null) return null;
    if (_progress_detail is EqualUnmodifiableMapView) return _progress_detail;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $id, name: $name, provider: $provider, status: $status, next_run: $next_run, name_i18n: $name_i18n, provider_i18n: $provider_i18n, status_i18n: $status_i18n, next_run_i18n: $next_run_i18n, progress: $progress, progress_text: $progress_text, progress_text_i18n: $progress_text_i18n, progress_enable: $progress_enable, progress_detail: $progress_detail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.next_run, next_run) ||
                other.next_run == next_run) &&
            (identical(other.name_i18n, name_i18n) ||
                other.name_i18n == name_i18n) &&
            (identical(other.provider_i18n, provider_i18n) ||
                other.provider_i18n == provider_i18n) &&
            (identical(other.status_i18n, status_i18n) ||
                other.status_i18n == status_i18n) &&
            (identical(other.next_run_i18n, next_run_i18n) ||
                other.next_run_i18n == next_run_i18n) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.progress_text, progress_text) ||
                other.progress_text == progress_text) &&
            (identical(other.progress_text_i18n, progress_text_i18n) ||
                other.progress_text_i18n == progress_text_i18n) &&
            (identical(other.progress_enable, progress_enable) ||
                other.progress_enable == progress_enable) &&
            const DeepCollectionEquality().equals(
              other._progress_detail,
              _progress_detail,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    provider,
    status,
    next_run,
    name_i18n,
    provider_i18n,
    status_i18n,
    next_run_i18n,
    progress,
    progress_text,
    progress_text_i18n,
    progress_enable,
    const DeepCollectionEquality().hash(_progress_detail),
  );

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      __$$ScheduleModelImplCopyWithImpl<_$ScheduleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleModelImplToJson(this);
  }
}

abstract class _ScheduleModel implements ScheduleModel {
  const factory _ScheduleModel({
    final String id,
    final String name,
    final String provider,
    final String status,
    final String next_run,
    final String? name_i18n,
    final String? provider_i18n,
    final String? status_i18n,
    final String? next_run_i18n,
    final double progress,
    final String? progress_text,
    final String? progress_text_i18n,
    final bool progress_enable,
    final Map<String, dynamic>? progress_detail,
  }) = _$ScheduleModelImpl;

  factory _ScheduleModel.fromJson(Map<String, dynamic> json) =
      _$ScheduleModelImpl.fromJson;

  /// 任务ID
  @override
  String get id;

  /// 任务名称
  @override
  String get name;

  /// 任务提供者
  @override
  String get provider;

  /// 任务状态
  @override
  String get status;

  /// 下次运行时间
  @override
  String get next_run;

  /// 服务端按当前语言生成的名称
  @override
  String? get name_i18n;

  /// 服务端按当前语言生成的提供者
  @override
  String? get provider_i18n;

  /// 服务端按当前语言生成的状态
  @override
  String? get status_i18n;

  /// 服务端按当前语言生成的下次运行时间
  @override
  String? get next_run_i18n;

  /// 运行进度百分比（0-100）
  @override
  double get progress;

  /// 运行进度说明
  @override
  String? get progress_text;

  /// 服务端按当前语言生成的进度说明
  @override
  String? get progress_text_i18n;

  /// 是否启用进度上报（启用即视为运行中）
  @override
  bool get progress_enable;

  /// 进度详情（ScheduleProgress）
  @override
  Map<String, dynamic>? get progress_detail;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

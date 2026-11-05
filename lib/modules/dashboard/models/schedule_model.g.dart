// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleModelImpl _$$ScheduleModelImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleModelImpl(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      status: json['status'] as String? ?? '',
      next_run: json['next_run'] as String? ?? '',
      name_i18n: json['name_i18n'] as String?,
      provider_i18n: json['provider_i18n'] as String?,
      status_i18n: json['status_i18n'] as String?,
      next_run_i18n: json['next_run_i18n'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      progress_text: json['progress_text'] as String?,
      progress_text_i18n: json['progress_text_i18n'] as String?,
      progress_enable: json['progress_enable'] as bool? ?? false,
      progress_detail: json['progress_detail'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ScheduleModelImplToJson(_$ScheduleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provider': instance.provider,
      'status': instance.status,
      'next_run': instance.next_run,
      'name_i18n': instance.name_i18n,
      'provider_i18n': instance.provider_i18n,
      'status_i18n': instance.status_i18n,
      'next_run_i18n': instance.next_run_i18n,
      'progress': instance.progress,
      'progress_text': instance.progress_text,
      'progress_text_i18n': instance.progress_text_i18n,
      'progress_enable': instance.progress_enable,
      'progress_detail': instance.progress_detail,
    };

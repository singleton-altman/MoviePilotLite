// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StatisticModelImpl _$$StatisticModelImplFromJson(Map<String, dynamic> json) =>
    _$StatisticModelImpl(
      movie_count: (json['movie_count'] as num?)?.toInt() ?? 0,
      tv_count: (json['tv_count'] as num?)?.toInt() ?? 0,
      episode_count: (json['episode_count'] as num?)?.toInt() ?? 0,
      user_count: (json['user_count'] as num?)?.toInt() ?? 0,
      music_count: (json['music_count'] as num?)?.toInt(),
      movie_count_month: (json['movie_count_month'] as num?)?.toInt() ?? 0,
      tv_count_month: (json['tv_count_month'] as num?)?.toInt() ?? 0,
      episode_count_month: (json['episode_count_month'] as num?)?.toInt() ?? 0,
      music_count_month: (json['music_count_month'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StatisticModelImplToJson(
  _$StatisticModelImpl instance,
) => <String, dynamic>{
  'movie_count': instance.movie_count,
  'tv_count': instance.tv_count,
  'episode_count': instance.episode_count,
  'user_count': instance.user_count,
  'music_count': instance.music_count,
  'movie_count_month': instance.movie_count_month,
  'tv_count_month': instance.tv_count_month,
  'episode_count_month': instance.episode_count_month,
  'music_count_month': instance.music_count_month,
};

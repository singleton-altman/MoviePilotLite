import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistic_model.freezed.dart';
part 'statistic_model.g.dart';

/// 媒体统计数据模型
@freezed
class StatisticModel with _$StatisticModel {
  /// 媒体统计数据模型构造函数
  const factory StatisticModel({
    /// 电影数量
    @Default(0) int movie_count,

    /// 剧集数量
    @Default(0) int tv_count,

    /// 集数
    @Default(0) int episode_count,

    /// 用户数量
    @Default(0) int user_count,

    /// 音乐数量（旧版服务端不返回，为 null 时隐藏音乐统计）
    int? music_count,

    /// 本月新增电影
    @Default(0) int movie_count_month,

    /// 本月新增剧集
    @Default(0) int tv_count_month,

    /// 本月新增集数
    @Default(0) int episode_count_month,

    /// 本月新增音乐
    @Default(0) int music_count_month,
  }) = _StatisticModel;

  /// 从JSON创建媒体统计数据模型
  factory StatisticModel.fromJson(Map<String, dynamic> json) =>
      _$StatisticModelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_model.freezed.dart';
part 'schedule_model.g.dart';

/// 后台任务模型
@freezed
class ScheduleModel with _$ScheduleModel {
  /// 后台任务模型构造函数
  const factory ScheduleModel({
    /// 任务ID
    @Default('') String id,

    /// 任务名称
    @Default('') String name,

    /// 任务提供者
    @Default('') String provider,

    /// 任务状态
    @Default('') String status,

    /// 下次运行时间
    @Default('') String next_run,

    /// 服务端按当前语言生成的名称
    String? name_i18n,

    /// 服务端按当前语言生成的提供者
    String? provider_i18n,

    /// 服务端按当前语言生成的状态
    String? status_i18n,

    /// 服务端按当前语言生成的下次运行时间
    String? next_run_i18n,

    /// 运行进度百分比（0-100）
    @Default(0.0) double progress,

    /// 运行进度说明
    String? progress_text,

    /// 服务端按当前语言生成的进度说明
    String? progress_text_i18n,

    /// 是否启用进度上报（启用即视为运行中）
    @Default(false) bool progress_enable,

    /// 进度详情（ScheduleProgress）
    Map<String, dynamic>? progress_detail,
  }) = _ScheduleModel;

  /// 从JSON创建后台任务模型
  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);
}

/// 后台服务运行进度（API: GET /api/v1/dashboard/schedule/{job_id}/progress）
///
/// 服务端以 Response 包裹，`data` 字段对应 ScheduleProgress。
class ScheduleProgressModel {
  const ScheduleProgressModel({
    required this.id,
    required this.enable,
    required this.value,
    required this.text,
    required this.status,
    required this.success,
  });

  final String id;

  /// 是否启用进度（启用即视为运行中）
  final bool enable;

  /// 进度百分比（0-100）
  final double value;

  /// 进度说明（优先取服务端按当前语言生成的文本）
  final String text;

  /// 运行状态，例如 running / finished
  final String status;

  /// 任务是否成功结束；运行中为 null
  final bool? success;

  bool get isRunning => enable || status == 'running';

  factory ScheduleProgressModel.fromJson(Map<String, dynamic> json) {
    final textI18n = json['text_i18n'];
    final text = json['text'];
    final successRaw = json['success'];
    return ScheduleProgressModel(
      id: json['id']?.toString() ?? '',
      enable: json['enable'] == true,
      value: _asDouble(json['value']).clamp(0.0, 100.0),
      text: (textI18n is String && textI18n.isNotEmpty)
          ? textI18n
          : (text is String ? text : ''),
      status: json['status']?.toString() ?? '',
      success: successRaw is bool ? successRaw : null,
    );
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

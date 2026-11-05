import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_config_model.freezed.dart';
part 'dashboard_config_model.g.dart';

@freezed
class DashboardConfigModel with _$DashboardConfigModel {
  const factory DashboardConfigModel({
    required bool success,
    String? message,
    required DashboardConfigData data,
  }) = _DashboardConfigModel;

  factory DashboardConfigModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardConfigModelFromJson(json);
}

@freezed
class DashboardConfigData with _$DashboardConfigData {
  const factory DashboardConfigData({
    required DashboardConfigValue value,
  }) = _DashboardConfigData;

  factory DashboardConfigData.fromJson(Map<String, dynamic> json) =>
      _$DashboardConfigDataFromJson(json);
}

@freezed
class DashboardConfigValue with _$DashboardConfigValue {
  const factory DashboardConfigValue({
    required bool mediaStatistic,
    required bool scheduler,
    required bool speed,
    required bool storage,
    required bool weeklyOverview,
    required bool cpu,
    required bool memory,
    required bool network,
    required bool library,
    required bool playing,
    required bool latest,
    @Default(true) bool mediaRecommend,
    @Default(true) bool recentImports,
    @Default(true) bool quickActions,
    @Default(true) bool systemInfo,
  }) = _DashboardConfigValue;

  factory DashboardConfigValue.fromJson(Map<String, dynamic> json) =>
      _$DashboardConfigValueFromJson(json);
}

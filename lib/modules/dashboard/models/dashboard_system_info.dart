/// 系统摘要信息（API: GET /api/v1/dashboard/system → DashboardSystemInfo）
class DashboardSystemInfo {
  const DashboardSystemInfo({
    required this.hostname,
    required this.operatingSystem,
    required this.runtime,
    required this.version,
  });

  /// 主机名称
  final String hostname;

  /// 操作系统
  final String operatingSystem;

  /// 已运行秒数
  final int runtime;

  /// 服务端版本
  final String version;

  factory DashboardSystemInfo.fromJson(Map<String, dynamic> json) {
    return DashboardSystemInfo(
      hostname: _asString(json['hostname']),
      operatingSystem: _asString(json['operating_system']),
      runtime: _asInt(json['runtime']),
      version: _asString(json['version']),
    );
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

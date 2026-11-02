/// RandomPic（随机图床API）插件状态模型
///
/// 对应 GET /api/v1/plugin/RandomPic/status 的返回结构（v2.3.1）。
class RandomPicStatus {
  const RandomPicStatus({
    required this.enable,
    required this.apiStatus,
    required this.endpointAvailability,
    required this.pcPath,
    required this.mobilePath,
    required this.pcPathCustom,
    required this.mobilePathCustom,
    required this.networkImageUrlPc,
    required this.networkImageUrlMobile,
    required this.networkImageUrl,
    required this.pcCount,
    required this.mobileCount,
    required this.totalCount,
    required this.todayVisits,
    required this.localPcCount,
    required this.localMobileCount,
    required this.networkPcCount,
    required this.networkMobileCount,
  });

  factory RandomPicStatus.fromJson(Map<String, dynamic> json) {
    final endpoints = json['api_endpoints'];
    final endpointMap = <String, bool>{};
    if (endpoints is Map) {
      for (final entry in endpoints.entries) {
        endpointMap[entry.key.toString()] = entry.value == true;
      }
    }
    final detail = json['detail'];
    Map<String, dynamic> detailMap = const {};
    if (detail is Map) detailMap = Map<String, dynamic>.from(detail);
    final local = detailMap['local'];
    final network = detailMap['network'];
    final localMap = local is Map ? Map<String, dynamic>.from(local) : const {};
    final networkMap = network is Map
        ? Map<String, dynamic>.from(network)
        : const {};

    return RandomPicStatus(
      enable: json['enable'] == true,
      apiStatus: _stringOf(json['api_status']),
      endpointAvailability: endpointMap,
      pcPath: _stringOf(json['pc_path']),
      mobilePath: _stringOf(json['mobile_path']),
      pcPathCustom: json['pc_path_custom'] == true,
      mobilePathCustom: json['mobile_path_custom'] == true,
      networkImageUrlPc: _stringOf(json['network_image_url_pc']),
      networkImageUrlMobile: _stringOf(json['network_image_url_mobile']),
      networkImageUrl: _stringOf(json['network_image_url']),
      pcCount: _intOf(json['pc_count']),
      mobileCount: _intOf(json['mobile_count']),
      totalCount: _intOf(json['total_count']),
      todayVisits: _intOf(json['today_visits']),
      localPcCount: _intOf(localMap['pc']),
      localMobileCount: _intOf(localMap['mobile']),
      networkPcCount: _intOf(networkMap['pc']),
      networkMobileCount: _intOf(networkMap['mobile']),
    );
  }

  final bool enable;
  final String apiStatus;

  /// auto / pc / mobile / stats 四个接口的可用性
  final Map<String, bool> endpointAvailability;

  final String pcPath;
  final String mobilePath;
  final bool pcPathCustom;
  final bool mobilePathCustom;
  final String networkImageUrlPc;
  final String networkImageUrlMobile;
  final String networkImageUrl;
  final int pcCount;
  final int mobileCount;
  final int totalCount;
  final int todayVisits;
  final int localPcCount;
  final int localMobileCount;
  final int networkPcCount;
  final int networkMobileCount;

  bool get pcAvailable => endpointAvailability['pc'] == true;
  bool get mobileAvailable => endpointAvailability['mobile'] == true;
  bool get autoAvailable => endpointAvailability['auto'] == true;

  /// 横屏、竖屏来源是否都已配置，决定插件能否真正提供图片
  bool get configComplete =>
      (pcPath.isNotEmpty || networkImageUrlPc.isNotEmpty ||
          networkImageUrl.isNotEmpty) &&
      (mobilePath.isNotEmpty || networkImageUrlMobile.isNotEmpty ||
          networkImageUrl.isNotEmpty);

  String get pcSourceLabel {
    if (pcPath.isNotEmpty) return pcPath;
    if (networkImageUrlPc.isNotEmpty) return networkImageUrlPc;
    return '未配置';
  }

  String get mobileSourceLabel {
    if (mobilePath.isNotEmpty) return mobilePath;
    if (networkImageUrlMobile.isNotEmpty) return networkImageUrlMobile;
    return '未配置';
  }
}

/// RandomPic 配置模型：对应 GET /POST /api/v1/plugin/RandomPic/config
class RandomPicConfig {
  const RandomPicConfig({
    required this.enable,
    required this.pcPath,
    required this.mobilePath,
    required this.networkImageUrlPc,
    required this.networkImageUrlMobile,
    required this.networkImageUrl,
    required this.downloadCount,
    this.defaultPcPath = '',
    this.defaultMobilePath = '',
  });

  factory RandomPicConfig.fromJson(Map<String, dynamic> json) {
    return RandomPicConfig(
      enable: json['enable'] == true,
      pcPath: _stringOf(json['pc_path']),
      mobilePath: _stringOf(json['mobile_path']),
      networkImageUrlPc: _stringOf(json['network_image_url_pc']),
      networkImageUrlMobile: _stringOf(json['network_image_url_mobile']),
      networkImageUrl: _stringOf(json['network_image_url']),
      downloadCount: _intOf(json['download_count']) == 0
          ? 20
          : _intOf(json['download_count']),
      defaultPcPath: _stringOf(json['default_pc_path']),
      defaultMobilePath: _stringOf(json['default_mobile_path']),
    );
  }

  final bool enable;
  final String pcPath;
  final String mobilePath;
  final String networkImageUrlPc;
  final String networkImageUrlMobile;
  final String networkImageUrl;
  final int downloadCount;
  final String defaultPcPath;
  final String defaultMobilePath;

  RandomPicConfig copyWith({bool? enable}) {
    return RandomPicConfig(
      enable: enable ?? this.enable,
      pcPath: pcPath,
      mobilePath: mobilePath,
      networkImageUrlPc: networkImageUrlPc,
      networkImageUrlMobile: networkImageUrlMobile,
      networkImageUrl: networkImageUrl,
      downloadCount: downloadCount,
      defaultPcPath: defaultPcPath,
      defaultMobilePath: defaultMobilePath,
    );
  }

  Map<String, dynamic> toRequestBody() {
    return {
      'enable': enable,
      'pc_path': pcPath,
      'mobile_path': mobilePath,
      'network_image_url_pc': networkImageUrlPc,
      'network_image_url_mobile': networkImageUrlMobile,
      'network_image_url': networkImageUrl,
      'download_count': downloadCount,
    };
  }

  static RandomPicConfig fromFormModel(Map<String, dynamic> model) {
    return RandomPicConfig(
      enable: model['enable'] == true,
      pcPath: _stringOf(model['pc_path']),
      mobilePath: _stringOf(model['mobile_path']),
      networkImageUrlPc: _stringOf(model['network_image_url_pc']),
      networkImageUrlMobile: _stringOf(model['network_image_url_mobile']),
      networkImageUrl: _stringOf(model['network_image_url']),
      downloadCount: _intOf(model['download_count']) == 0
          ? 20
          : _intOf(model['download_count']),
    );
  }

  Map<String, dynamic> toFormModel() {
    return {
      'enable': enable,
      'pc_path': pcPath,
      'mobile_path': mobilePath,
      'network_image_url_pc': networkImageUrlPc,
      'network_image_url_mobile': networkImageUrlMobile,
      'network_image_url': networkImageUrl,
      'download_count': downloadCount.toString(),
    };
  }
}

String _stringOf(Object? value) {
  if (value == null) return '';
  return value.toString();
}

int _intOf(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

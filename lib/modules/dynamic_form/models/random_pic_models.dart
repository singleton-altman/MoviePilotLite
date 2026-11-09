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
    // v3.x 新增字段：不随请求回传会被服务端重置为默认值
    this.networkFirst = false,
    this.dashboardEnable = true,
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
      networkFirst: json['network_first'] == true,
      dashboardEnable: json['dashboard_enable'] != false,
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

  /// 网络图源优先（RandomPic v3.x 新增，保存时必须回传否则会被重置）
  final bool networkFirst;

  /// 是否在首页仪表盘展示统计卡片（RandomPic v3.x 新增）
  final bool dashboardEnable;

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
      networkFirst: networkFirst,
      dashboardEnable: dashboardEnable,
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
      'network_first': networkFirst,
      'dashboard_enable': dashboardEnable,
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
      networkFirst: model['network_first'] == true,
      dashboardEnable: model['dashboard_enable'] != false,
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
      'network_first': networkFirst,
      'dashboard_enable': dashboardEnable,
    };
  }
}

String _stringOf(Object? value) {
  if (value == null) return '';
  return value.toString();
}

/// 访问记录（GET /visits → recent）
class RandomPicVisit {
  const RandomPicVisit({
    required this.time,
    required this.endpoint,
    required this.type,
    required this.source,
    required this.domain,
    required this.imageSource,
    required this.ok,
    required this.elapsedMs,
  });

  factory RandomPicVisit.fromJson(Map<String, dynamic> json) {
    return RandomPicVisit(
      time: _stringOf(json['time']),
      endpoint: _stringOf(json['endpoint']),
      type: _stringOf(json['type']),
      source: _stringOf(json['source']),
      domain: _stringOf(json['domain']),
      imageSource: _stringOf(json['img']),
      ok: json['ok'] != false,
      elapsedMs: _intOf(json['elapsed_ms']),
    );
  }

  final String time;
  final String endpoint;
  final String type;
  final String source;
  final String domain;
  final String imageSource;
  final bool ok;
  final int elapsedMs;
}

/// 每日访问量（GET /visits → daily）
class RandomPicDailyVisit {
  const RandomPicDailyVisit({
    required this.date,
    required this.label,
    required this.count,
  });

  factory RandomPicDailyVisit.fromJson(Map<String, dynamic> json) {
    return RandomPicDailyVisit(
      date: _stringOf(json['date']),
      label: _stringOf(json['label']),
      count: _intOf(json['count']),
    );
  }

  final String date;
  final String label;
  final int count;
}

/// 访问统计（GET /visits）
class RandomPicVisits {
  const RandomPicVisits({this.recent = const [], this.daily = const []});

  factory RandomPicVisits.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent'];
    final dailyRaw = json['daily'];
    return RandomPicVisits(
      recent: recentRaw is List
          ? recentRaw
                .whereType<Map>()
                .map((e) => RandomPicVisit.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      daily: dailyRaw is List
          ? dailyRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      RandomPicDailyVisit.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }

  final List<RandomPicVisit> recent;
  final List<RandomPicDailyVisit> daily;
}

/// 图源测速结果（GET /ping → data 下的各图源字段）
class RandomPicPing {
  const RandomPicPing({
    required this.label,
    required this.configured,
    required this.ok,
    this.ms,
  });

  factory RandomPicPing.fromJson(Map<String, dynamic> json) {
    return RandomPicPing(
      label: _stringOf(json['label']),
      configured: json['configured'] == true,
      ok: json['ok'] == true,
      ms: json['ms'] == null ? null : _intOf(json['ms']),
    );
  }

  final String label;
  final bool configured;
  final bool ok;
  final int? ms;
}

/// 网络图片下载任务状态（GET /download/status）
class RandomPicDownloadStatus {
  const RandomPicDownloadStatus({
    this.running = false,
    this.total = 0,
    this.done = 0,
    this.success = 0,
    this.failed = 0,
    this.skipped = 0,
    this.pcSaved = 0,
    this.mobileSaved = 0,
    this.message = '',
  });

  factory RandomPicDownloadStatus.fromJson(Map<String, dynamic> json) {
    return RandomPicDownloadStatus(
      running: json['running'] == true,
      total: _intOf(json['total']),
      done: _intOf(json['done']),
      success: _intOf(json['success']),
      failed: _intOf(json['failed']),
      skipped: _intOf(json['skipped']),
      pcSaved: _intOf(json['pc_saved']),
      mobileSaved: _intOf(json['mobile_saved']),
      message: _stringOf(json['message']),
    );
  }

  final bool running;
  final int total;
  final int done;
  final int success;
  final int failed;
  final int skipped;
  final int pcSaved;
  final int mobileSaved;
  final String message;

  double get progress => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

int _intOf(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

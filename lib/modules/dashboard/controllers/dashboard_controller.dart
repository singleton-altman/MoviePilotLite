import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/statistic_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_progress_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/dashboard_config_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/dashboard_order_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/dashboard_system_info.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/transfer_queue_job.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_source.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 仪表板「推荐媒体」可选来源
class DashboardRecommendSource {
  const DashboardRecommendSource({required this.name, required this.key});

  /// 展示名称
  final String name;

  /// 推荐接口键，交由 RecommendSource.resolveApiPath 解析为完整路径
  final String key;
}

/// Dashboard 控制器
class DashboardController extends GetxController {
  static const String _localConfigFileName = 'dashboard_config.json';
  static const int _localConfigVersion = 1;

  /// 可用的组件类型（顺序与 Web 端默认顺序一致）
  static const List<String> availableWidgets = [
    '存储空间',
    '媒体统计',
    '推荐媒体',
    '最近入库',
    '实时速率',
    '后台任务',
    'CPU',
    '内存',
    '网络流量',
    '我的媒体库',
    '继续观看',
    '最近添加',
    '近期整理',
    '快捷操作',
    '系统信息',
  ];

  /// 组件名称 → 本地/服务端配置 id
  static const Map<String, String> widgetIdByName = {
    '存储空间': 'storage',
    '媒体统计': 'mediaStatistic',
    '推荐媒体': 'mediaRecommend',
    '最近入库': 'weeklyOverview',
    '实时速率': 'speed',
    '后台任务': 'scheduler',
    'CPU': 'cpu',
    '内存': 'memory',
    '网络流量': 'network',
    '我的媒体库': 'library',
    '继续观看': 'playing',
    '最近添加': 'latest',
    '近期整理': 'recentImports',
    '快捷操作': 'quickActions',
    '系统信息': 'systemInfo',
  };

  /// 配置 id → 组件名称
  static final Map<String, String> widgetNameById = {
    for (final entry in widgetIdByName.entries) entry.value: entry.key,
  };

  /// 组件在编辑页/标题上的展示名称（与 Web 端文案对齐，内部键保持不变）
  static const Map<String, String> widgetDisplayNames = {
    '最近入库': '入库统计',
    '最近添加': '最新入库',
  };

  static String displayNameOf(String widget) =>
      widgetDisplayNames[widget] ?? widget;

  /// 「推荐媒体」内置来源
  static const List<DashboardRecommendSource> recommendSources = [
    DashboardRecommendSource(name: '流行趋势', key: 'tmdb_trending'),
    DashboardRecommendSource(name: 'TMDB 热门电影', key: 'tmdb_movies'),
    DashboardRecommendSource(
      name: 'TMDB 热门电视剧',
      key: 'tmdb_tvs?with_original_language=zh|en|ja|ko',
    ),
    DashboardRecommendSource(name: '正在热映', key: 'douban_showing'),
    DashboardRecommendSource(name: '豆瓣热门电影', key: 'douban_movie_hot'),
    DashboardRecommendSource(name: '豆瓣热门电视剧', key: 'douban_tv_hot'),
  ];

  /// 推荐媒体轮播条数
  static const int recommendSlideCount = 5;

  /// 近期整理最多展示条数
  static const int recentImportLimit = 10;

  /// 当前显示的组件列表
  final displayedWidgets = <String>[].obs;

  /// CPU使用率
  final cpuUsage = 0.0.obs;

  /// 网络流量 [上行, 下行]
  final networkTraffic = <int>[0, 0].obs;

  /// 内存数据（API: /api/v1/dashboard/memory → DashboardMemoryInfo）
  final memoryInfo = Rxn<DashboardMemoryInfo>();

  /// 下载器数据
  final downloaderData = <String, dynamic>{}.obs;

  /// 存储空间数据
  final storageData = <String, dynamic>{}.obs;

  /// 媒体统计数据
  final statisticData = Rx<StatisticModel?>(null);

  /// 后台任务列表数据
  final scheduleData = Rx<List<ScheduleModel>>([]);

  /// 后台任务列表加载失败原因；为 null 表示正常。
  /// 服务端 dashboard 接口仅超级管理员可访问，非管理员会收到 400「用户权限不足」，
  /// 需要与「任务列表确实为空」区分开展示。
  final scheduleError = RxnString();

  /// 后台任务接口无权访问时的提示文案
  static const String schedulePermissionMessage = '需要管理员权限';

  /// 媒体服务器最新入库数据
  final latestMediaData = Rx<Map<String, dynamic>?>(null);

  /// 最近入库数据（一周内每天的入库量）
  final transferData = <int>[].obs;

  /// 系统摘要信息（API: /api/v1/dashboard/system）
  final systemInfo = Rxn<DashboardSystemInfo>();

  /// 每分钟自增一次，驱动运行时间文案在无网络请求时也持续走动
  final runtimeTick = 0.obs;

  /// 近期整理成功记录（API: /api/v1/history/transfer?status=true）
  final recentImports = <MediaOrganizeTransferItem>[].obs;

  /// 整理队列（API: /api/v1/transfer/queue）
  final transferQueue = <TransferQueueJob>[].obs;

  /// 运行中后台任务的实时进度，key 为任务 id
  final scheduleProgress = <String, ScheduleProgressModel>{}.obs;

  /// 推荐媒体轮播条目
  final recommendItems = <RecommendApiItem>[].obs;

  /// 当前推荐来源键（见 [recommendSources]）
  final recommendSourceKey = recommendSources.first.key.obs;

  /// 推荐媒体是否加载中
  final isRecommendLoading = false.obs;

  /// 推荐媒体加载失败原因；为 null 表示正常
  final recommendError = RxnString();

  /// 系统更新检查是否进行中
  final isCheckingUpdate = false.obs;

  /// CPU 图表滚动数据（用于波浪图）
  static const int _chartDataLength = 20;
  final cpuChartData = <ChartDataPoint>[].obs;

  /// 内存图表滚动数据（用于波浪图）
  final memoryChartData = <ChartDataPoint>[].obs;

  /// API客户端
  late final ApiClient apiClient;

  /// 媒体服务器控制器
  late final MediaServerController mediaServerController;

  /// 日志实例
  late final AppLog talker;

  /// Dashboard配置
  final dashboardConfig = Rx<DashboardConfigModel?>(null);

  /// Dashboard元素排序
  final dashboardOrder = Rx<DashboardOrderModel?>(null);

  final appService = Get.find<AppService>();

  Timer? _refreshTimer;
  Timer? _cookieTimer;
  Timer? _progressTimer;
  Timer? _runtimeTimer;
  DateTime? _systemInfoSyncedAt;
  DateTime? _recommendAttemptedAt;
  bool _hasLocalDashboardConfig = false;
  bool _isLoadingDashboardData = false;
  bool _isRefreshingProgress = false;

  /// 推荐媒体的自动刷新间隔；推荐榜单变化慢，不跟随 15 秒主循环
  static const Duration _recommendRefreshInterval = Duration(minutes: 30);

  /// 推荐媒体加载失败后的重试冷却
  static const Duration _recommendRetryInterval = Duration(minutes: 2);

  /// 运行中任务的进度轮询间隔
  static const Duration _progressPollInterval = Duration(seconds: 2);

  @override
  Future<void> onInit() async {
    super.onInit();
    // 初始化依赖
    apiClient = Get.find<ApiClient>();
    talker = Get.find<AppLog>();

    // 1. 根据传入数据创建 mediaServerController
    await _initializeMediaServerController();

    await _loadLocalDashboardConfig();
    if (!_hasLocalDashboardConfig) {
      _useDefaultConfig();
    }
    await _loadRecommendSourcePreference();
    // 5. 根据开关获取对应数据
    _setupDataLoading();

    // 启动定时刷新
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _cookieTimer?.cancel();
    _progressTimer?.cancel();
    _runtimeTimer?.cancel();
    super.onClose();
  }

  /// 初始化媒体服务器控制器
  Future<void> _initializeMediaServerController() async {
    if (Get.isRegistered<MediaServerController>()) {
      mediaServerController = Get.find<MediaServerController>();
      return;
    }
    mediaServerController = Get.put(MediaServerController());

    // 媒体库数据由 _loadDataBasedOnConfig 在显示「我的媒体库」组件时加载
  }

  /// 设置数据加载
  void _setupDataLoading() {
    _loadDataBasedOnConfig();
  }

  /// 启动周期性刷新
  void _startPeriodicRefresh() {
    // release 由 5 秒放宽到 15 秒：全量组件刷新会并发 10+ 个请求，
    // 过密会在弱网下与启动初始化争抢带宽；debug 保持不自动刷。
    final duration = const Duration(seconds: kDebugMode ? 1000000 : 15);
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(duration, (_) {
      _loadDataBasedOnConfig();
    });

    _cookieTimer?.cancel();
    _cookieTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _ensureUserCookieRefreshed();
    });

    _runtimeTimer?.cancel();
    _runtimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      runtimeTick.value++;
    });
  }

  /// 系统运行秒数：以最近一次同步值为基准，叠加本地流逝时间
  int get displayedRuntimeSeconds {
    final info = systemInfo.value;
    final syncedAt = _systemInfoSyncedAt;
    if (info == null || syncedAt == null) return 0;
    final elapsed = DateTime.now().difference(syncedAt).inSeconds;
    return info.runtime + (elapsed < 0 ? 0 : elapsed);
  }

  /// 判断后台任务是否运行中：兼容列表状态与进度详情两种服务端信号
  static bool isScheduleRunning(ScheduleModel schedule) {
    if (schedule.status == '正在运行' || schedule.status == '运行中') {
      return true;
    }
    if (schedule.progress_enable) return true;
    final detail = schedule.progress_detail;
    if (detail != null) {
      if (detail['enable'] == true) return true;
      if (detail['status']?.toString() == 'running') return true;
    }
    return false;
  }

  /// 任务当前进度百分比：优先使用轮询到的实时值
  double scheduleProgressValue(ScheduleModel schedule) {
    final live = scheduleProgress[schedule.id];
    final value = live?.value ?? schedule.progress;
    return value.clamp(0.0, 100.0);
  }

  /// 任务当前进度说明：优先使用轮询到的实时文本
  String scheduleProgressText(ScheduleModel schedule) {
    final live = scheduleProgress[schedule.id];
    if (live != null && live.text.isNotEmpty) return live.text;
    final i18n = schedule.progress_text_i18n;
    if (i18n != null && i18n.isNotEmpty) return i18n;
    return schedule.progress_text ?? '';
  }

  void _ensureUserCookieRefreshed() {
    final server = appService.baseUrl ?? apiClient.baseUrl;
    final token = appService.loginResponse?.accessToken ?? apiClient.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    apiClient.getCookieHeader(url: server);
  }

  /// 添加组件
  void addWidget(String widget) {
    if (!displayedWidgets.contains(widget)) {
      displayedWidgets.add(widget);
    }
  }

  /// 移除组件
  void removeWidget(String widget) {
    displayedWidgets.remove(widget);
  }

  /// 重新排序组件
  void reorderWidgets(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = displayedWidgets.removeAt(oldIndex);
    displayedWidgets.insert(newIndex, item);
  }

  /// 加载CPU数据
  Future<void> loadCpuData() async {
    try {
      talker.info('开始加载CPU数据');
      final response = await apiClient.get<double>('/api/v1/dashboard/cpu');
      if (response.statusCode == 200) {
        // 模拟CPU使用率的波动，使动画效果更明显
        final newUsage = response.data!;
        // 添加适当的随机波动，使数据变化更自然明显
        final fluctuation = (Random().nextDouble() * 2 - 1) * 2.0;
        final finalUsage = (newUsage + fluctuation).clamp(0.0, 100.0);
        cpuUsage.value = finalUsage;
        _appendCpuChartData(finalUsage);
        talker.info('CPU数据加载成功: ${cpuUsage.value.toStringAsFixed(1)}%');
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('CPU数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
      } else {
        talker.warning('CPU数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载CPU数据失败');
    }
  }

  /// 加载网络流量数据
  Future<void> loadNetworkData() async {
    try {
      talker.info('开始加载网络流量数据');
      final response = await apiClient.get<List<dynamic>>(
        '/api/v1/dashboard/network',
      );
      if (response.statusCode == 200) {
        final traffic = response.data!;
        if (traffic.length >= 2) {
          // 转换为int类型
          final uploadKbps = traffic.first as int? ?? 0;
          final downloadKbps = traffic.last as int? ?? 0;
          networkTraffic.value = [uploadKbps, downloadKbps];
          talker.info(
            '网络流量数据加载成功: 上行 ${uploadKbps}Kbps, 下行 ${downloadKbps}Kbps',
          );
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('网络流量数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
      } else {
        talker.warning('网络流量数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载网络流量数据失败');
    }
  }

  /// 加载下载器数据
  Future<void> loadDownloaderData() async {
    try {
      talker.info('开始加载下载器数据');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/dashboard/downloader',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        downloaderData.value = data;
        talker.info(
          '下载器数据加载成功: 下载速度 ${data['download_speed']}MB/s, 上传速度 ${data['upload_speed']}MB/s',
        );
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('下载器数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
      } else {
        talker.warning('下载器数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载下载器数据失败');
    }
  }

  /// 加载存储空间数据
  Future<void> loadStorageData() async {
    try {
      talker.info('开始加载存储空间数据');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/dashboard/storage',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        storageData.value = data;
        talker.info(
          '存储空间数据加载成功: 总存储 ${_formatStorageSize(data['total_storage'] ?? 0.0)}, 已用存储 ${_formatStorageSize(data['used_storage'] ?? 0.0)}',
        );
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('存储空间数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
      } else {
        talker.warning('存储空间数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载存储空间数据失败');
    }
  }

  /// 格式化存储大小
  String _formatStorageSize(double bytes) {
    return SizeFormatter.formatSize(bytes, 2);
  }

  /// 加载媒体统计数据
  Future<void> loadStatisticData() async {
    try {
      talker.info('开始加载媒体统计数据');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/dashboard/statistic',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        final statisticModel = StatisticModel.fromJson(data);
        statisticData.value = statisticModel;
        talker.info('媒体统计数据加载成功: $statisticModel');
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('媒体统计数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
      } else {
        talker.warning('媒体统计数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载媒体统计数据失败');
    }
  }

  /// 加载后台任务列表数据
  Future<void> loadScheduleData() async {
    if (!appService.isSuperuser) {
      // 服务端只对超级管理员开放该接口，非管理员直接给出原因，不再发请求
      scheduleError.value = schedulePermissionMessage;
      if (scheduleData.value.isNotEmpty) scheduleData.value = const [];
      _syncProgressPolling();
      return;
    }
    try {
      talker.info('开始加载后台任务列表数据');
      final response = await apiClient.get<dynamic>(
        '/api/v1/dashboard/schedule',
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        scheduleError.value = _describeScheduleFailure(
          statusCode,
          response.data,
        );
        talker.warning(
          '后台任务列表数据加载失败，状态码: $statusCode，原因: ${scheduleError.value}',
        );
        return;
      }
      final scheduleList = <ScheduleModel>[];
      for (final raw in _extractList(response.data)) {
        if (raw is! Map) continue;
        scheduleList.add(
          ScheduleModel.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      scheduleData.value = scheduleList;
      scheduleError.value = null;
      _syncProgressPolling();
      talker.info('后台任务列表数据加载成功: ${scheduleList.length} 个任务');
    } catch (e, st) {
      scheduleError.value = '后台任务加载失败';
      talker.handle(e, stackTrace: st, message: '加载后台任务列表数据失败');
    }
  }

  /// 把后台任务接口的失败响应翻译成可展示的原因
  String _describeScheduleFailure(int statusCode, dynamic data) {
    final authFailure = ApiAuthFailure.from(statusCode, data);
    if (authFailure.isPermissionDenied) return schedulePermissionMessage;
    if (authFailure.isAuthFailure) return authFailure.message;
    final reason = ApiAuthFailure.extractReason(data);
    return reason ?? '请求失败 (HTTP $statusCode)';
  }

  /// 加载媒体服务器最新入库数据
  Future<void> loadLatestMediaData() async {
    await mediaServerController.loadMediaServers();
    final servers = mediaServerController.mediaServers.value;
    if (servers.isEmpty) return;
    final server = servers.first;
    try {
      talker.info('开始加载媒体服务器最新入库数据');
      // 获取第一个媒体服务器的最新入库数据
      final data = await mediaServerController.loadLatestMediaData(server.name);
      latestMediaData.value = data;
      talker.info('媒体服务器最新入库数据加载成功');
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载媒体服务器最新入库数据失败');
    }
  }

  /// 加载最近入库数据（一周内每天的入库量）
  Future<void> loadTransferData() async {
    try {
      talker.info('开始加载最近入库数据');
      final response = await apiClient.get<List<dynamic>>(
        '/api/v1/dashboard/transfer',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        // 将数据转换为整数列表
        final transferList = data
            .map((item) => item is int ? item : 0)
            .toList();
        transferData.value = transferList;
        talker.info('最近入库数据加载成功: $transferList');
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('最近入库数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
} else {
        talker.warning('最近入库数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载最近入库数据失败');
    }
  }

  /// 加载系统摘要信息
  Future<void> loadSystemInfo() async {
    try {
      final response = await apiClient.get<dynamic>('/api/v1/dashboard/system');
      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        systemInfo.value = DashboardSystemInfo.fromJson(map);
        _systemInfoSyncedAt = DateTime.now();
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('系统摘要加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
} else {
        talker.warning('系统摘要加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载系统摘要失败');
    }
  }

  /// 检查更新：对比 GitHub 最新 Release 与当前运行版本
  Future<void> checkSystemUpdate() async {
    if (isCheckingUpdate.value) return;
    isCheckingUpdate.value = true;
    try {
      final response = await apiClient.get<dynamic>('/api/v1/system/versions');
      final data = response.data;
      String? latestTag;
      if (data is Map) {
        final releases = data['data'];
        if (releases is List && releases.isNotEmpty) {
          final first = releases.first;
          if (first is Map) latestTag = first['tag_name']?.toString();
        }
      }
      if (latestTag == null || latestTag.isEmpty) {
        ToastUtil.info('暂时无法获取版本信息');
        return;
      }
      final current = systemInfo.value?.version ?? '';
      if (_compareVersions(latestTag, current) > 0) {
        ToastUtil.info('发现新版本 $latestTag');
      } else {
        ToastUtil.success('当前已是最新版本');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '检查更新失败');
      ToastUtil.error('检查更新失败，请稍后重试');
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  /// 比较版本号：返回正数表示 a 更新，0 相同，负数表示 a 更旧
  static int _compareVersions(String a, String b) {
    List<int> parts(String value) => RegExp(
      r'\d+',
    ).allMatches(value).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    final pa = parts(a);
    final pb = parts(b);
    final length = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  /// 加载近期整理成功记录
  Future<void> loadRecentImports() async {
    try {
      final response = await apiClient.get<dynamic>(
        '/api/v1/history/transfer',
        queryParameters: {
          'page': 1,
          'count': recentImportLimit,
          'status': true,
        },
      );
      if ((response.statusCode ?? 0) >= 400) {
        talker.warning('近期整理记录加载失败，状态码: ${response.statusCode}');
        return;
      }
      final parsed = <MediaOrganizeTransferItem>[];
      for (final raw in _extractList(response.data)) {
        if (raw is! Map) continue;
        try {
          parsed.add(
            MediaOrganizeTransferItem.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (e, st) {
          talker.handle(e, stackTrace: st, message: '解析近期整理记录失败');
        }
        if (parsed.length >= recentImportLimit) break;
      }
      recentImports.assignAll(parsed);
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载近期整理记录失败');
    }
  }

  /// 加载整理队列
  Future<void> loadTransferQueue() async {
    try {
      final response = await apiClient.get<dynamic>('/api/v1/transfer/queue');
      if ((response.statusCode ?? 0) >= 400) {
        talker.warning('整理队列加载失败，状态码: ${response.statusCode}');
        return;
      }
      final list = _extractList(response.data);
      final jobs = <TransferQueueJob>[];
      for (var i = 0; i < list.length; i++) {
        final raw = list[i];
        if (raw is! Map) continue;
        jobs.add(TransferQueueJob.fromJson(Map<String, dynamic>.from(raw), i));
      }
      transferQueue.assignAll(jobs);
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载整理队列失败');
    }
  }

  /// 根据是否存在运行中任务启停进度轮询
  void _syncProgressPolling() {
    final hasRunning = scheduleData.value.any(isScheduleRunning);
    if (!hasRunning) {
      _progressTimer?.cancel();
      _progressTimer = null;
      if (scheduleProgress.isNotEmpty) scheduleProgress.clear();
      return;
    }
    if (_progressTimer != null) return;
    refreshScheduleProgress();
    _progressTimer = Timer.periodic(_progressPollInterval, (_) {
      refreshScheduleProgress();
    });
  }

  /// 刷新运行中任务的实时进度；发现任务结束时顺带刷新任务列表
  Future<void> refreshScheduleProgress() async {
    if (_isRefreshingProgress) return;
    final running = scheduleData.value
        .where((item) => item.id.isNotEmpty && isScheduleRunning(item))
        .toList();
    if (running.isEmpty) {
      _syncProgressPolling();
      return;
    }
    _isRefreshingProgress = true;
    var shouldReloadSchedule = false;
    try {
      final results = await Future.wait(
        running.map((schedule) async {
          try {
            final response = await apiClient.get<dynamic>(
              '/api/v1/dashboard/schedule/${Uri.encodeComponent(schedule.id)}/progress',
            );
            final data = response.data;
            if (response.statusCode != 200 || data is! Map) return null;
            final payload = data['data'];
            if (payload is! Map) return null;
            final progress = ScheduleProgressModel.fromJson(
              Map<String, dynamic>.from(payload),
            );
            return MapEntry(schedule.id, progress);
          } catch (_) {
            return null;
          }
        }),
      );
      final next = <String, ScheduleProgressModel>{};
      for (final entry in results) {
        if (entry == null) continue;
        next[entry.key] = entry.value;
        if (!entry.value.isRunning) shouldReloadSchedule = true;
      }
      scheduleProgress.assignAll(next);
    } finally {
      _isRefreshingProgress = false;
    }
    if (shouldReloadSchedule) {
      await loadScheduleData();
    }
  }

  /// 加载推荐媒体；成功后 30 分钟内不重复请求，失败后 2 分钟内不重试，[force] 为 true 时立即刷新
  Future<void> loadRecommendMedia({bool force = false}) async {
    if (!appService.canDiscovery) return;
    final attemptedAt = _recommendAttemptedAt;
    if (!force && attemptedAt != null) {
      final cooldown = recommendItems.isNotEmpty
          ? _recommendRefreshInterval
          : _recommendRetryInterval;
      if (DateTime.now().difference(attemptedAt) < cooldown) return;
    }
    _recommendAttemptedAt = DateTime.now();
    isRecommendLoading.value = recommendItems.isEmpty;
    recommendError.value = null;
    try {
      final url = RecommendSource.resolveApiPath(recommendSourceKey.value);
      final response = await apiClient.get<dynamic>(url);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        recommendError.value = '请求失败 (HTTP $statusCode)';
        return;
      }
      var payload = response.data;
      if (payload is String) {
        try {
          payload = jsonDecode(payload);
        } catch (_) {}
      }
      final items = <RecommendApiItem>[];
      for (final raw in _extractList(payload)) {
        if (raw is! Map) continue;
        final map = <String, dynamic>{
          for (final entry in raw.entries)
            if (entry.key is String) entry.key as String: entry.value,
        };
        try {
          final item = RecommendApiItem.fromJson(normalizeMediaJson(map));
          if (_isUsableRecommendItem(item)) items.add(item);
        } catch (e, st) {
          talker.handle(e, stackTrace: st, message: '解析推荐媒体失败');
        }
        if (items.length >= recommendSlideCount) break;
      }
      recommendItems.assignAll(items);
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载推荐媒体失败');
      recommendError.value = '推荐媒体加载失败';
    } finally {
      isRecommendLoading.value = false;
    }
  }

  /// 可进入详情且有图可展示的条目才进入轮播
  bool _isUsableRecommendItem(RecommendApiItem item) {
    final hasIdentity =
        (item.source?.isNotEmpty == true &&
            item.media_id?.isNotEmpty == true) ||
        item.collection_id?.isNotEmpty == true ||
        item.tmdb_id?.isNotEmpty == true ||
        item.douban_id?.isNotEmpty == true ||
        item.bangumi_id?.isNotEmpty == true;
    final hasImage =
        item.backdrop_path?.isNotEmpty == true ||
        item.poster_path?.isNotEmpty == true;
    return hasIdentity && hasImage;
  }

  /// 切换推荐来源并持久化
  Future<void> selectRecommendSource(String key) async {
    if (key == recommendSourceKey.value) return;
    recommendSourceKey.value = key;
    recommendItems.clear();
    _recommendAttemptedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kDashboardRecommendSourceKey, key);
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '保存推荐来源失败');
    }
    await loadRecommendMedia(force: true);
  }

  Future<void> _loadRecommendSourcePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(kDashboardRecommendSourceKey);
      if (stored == null) return;
      if (recommendSources.any((source) => source.key == stored)) {
        recommendSourceKey.value = stored;
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '读取推荐来源失败');
    }
  }

  /// 兼容裸数组、Response.data 为数组、Response.data.list 三种返回形态
  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final data = payload['data'];
      if (data is List) return data;
      if (data is Map && data['list'] is List) return data['list'] as List;
      if (payload['list'] is List) return payload['list'] as List;
    }
    return const [];
  }

  /// 刷新所有数据
  Future<void> refreshData() async {
    try {
      talker.info('开始刷新所有数据');
      await _loadDataBasedOnConfig();
      if (displayedWidgets.contains('我的媒体库')) {
        await mediaServerController.loadMediaLibraries();
      }
      if (displayedWidgets.contains('最近添加')) {
        await mediaServerController.refreshLatestMediaList();
      }
      final enabledMediaServers = mediaServerController.mediaServers.value
          .where((server) => server.enabled)
          .toList();
      if (displayedWidgets.contains('继续观看') && enabledMediaServers.isNotEmpty) {
        await mediaServerController.loadPlayingMedia(
          enabledMediaServers.first.name,
        );
      }
      if (displayedWidgets.contains('推荐媒体')) {
        await loadRecommendMedia(force: true);
      }
      talker.info('所有数据刷新完成');
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '刷新所有数据失败');
    }
  }

  /// 执行后台任务；不关注返回值，提交后即提示任务已提交
  Future<void> runScheduler(String jobId) async {
    try {
      talker.info('提交后台任务: $jobId');
      await apiClient.get<dynamic>('/api/v1/system/runscheduler?jobid=$jobId');
      ToastUtil.success('任务已提交');
      await loadScheduleData();
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '提交后台任务失败');
      ToastUtil.error('提交失败，请检查网络');
    }
  }

  /// 加载内存数据
  Future<void> loadMemoryData() async {
    try {
      talker.info('开始加载内存数据');
      final response = await apiClient.get<dynamic>('/api/v1/dashboard/memory');
      if (response.statusCode == 200) {
        final payload = _unwrapMemoryPayload(response.data);
        if (payload == null) {
          talker.warning('内存数据格式异常');
          return;
        }
        final info = DashboardMemoryInfo.fromJson(payload);
        memoryInfo.value = info;
        _appendMemoryChartData(info.usage.clamp(0.0, 100.0));
        talker.info(
          '内存数据加载成功: used=${info.used}, available=${info.available}, '
          'usage=${info.usage.toStringAsFixed(1)}%',
        );
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        talker.error('内存数据加载失败: '
            '${ApiAuthFailure.from(response.statusCode, response.data).message}');
} else {
        talker.warning('内存数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载内存数据失败');
    }
  }

  Map<String, dynamic>? _unwrapMemoryPayload(dynamic data) {
    if (data is! Map) return null;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = nested is Map<String, dynamic>
          ? nested
          : Map<String, dynamic>.from(nested);
      if (nestedMap.containsKey('used') || nestedMap.containsKey('total')) {
        return nestedMap;
      }
    }
    if (map.containsKey('used') || map.containsKey('total')) {
      return map;
    }
    return null;
  }

  /// 根据开关配置更新displayedWidgets列表
  void _updateDisplayedWidgets(DashboardConfigValue config) {
    final widgets = <String>[];

    // 根据配置添加显示的组件
    if (config.storage) widgets.add('存储空间');
    if (config.mediaStatistic) widgets.add('媒体统计');
    if (config.mediaRecommend) widgets.add('推荐媒体');
    if (config.weeklyOverview) widgets.add('最近入库');
    if (config.speed) widgets.add('实时速率');
    if (config.scheduler) widgets.add('后台任务');
    if (config.cpu) widgets.add('CPU');
    if (config.memory) widgets.add('内存');
    if (config.network) widgets.add('网络流量');
    if (config.library) widgets.add('我的媒体库');
    if (config.latest) widgets.add('最近添加');
    if (config.playing) widgets.add('继续观看');
    if (config.recentImports) widgets.add('近期整理');
    if (config.quickActions) widgets.add('快捷操作');
    if (config.systemInfo) widgets.add('系统信息');

    displayedWidgets.assignAll(widgets);
    talker.info('根据配置更新displayedWidgets: $widgets');
  }

  /// 使用默认配置
  void _useDefaultConfig() {
    // 默认显示所有组件
    displayedWidgets.assignAll(availableWidgets);
    talker.info('使用默认配置，显示所有组件');
  }

  /// 已经挂载过的组件名。数据只为这些组件加载：首屏之外的区块滚到视口时
  /// 才由页面调用 [activateWidgets] 补齐，启动阶段不再把全部组件的请求一起打出去。
  final Set<String> _activatedWidgets = {};

  /// 已完成过至少一次加载（无论成败）的组件名。
  ///
  /// 未完成的组件在无数据时画骨架，这样既覆盖「刚渲染、请求还没发出」的几帧，
  /// 也覆盖「请求已发但未回」；以加载尝试结束（而不是拿到数据）为界，
  /// 没有数据源的组件才不会永远停在骨架上。
  final _settledWidgets = <String>{}.obs;

  bool isWidgetLoading(String name) => !_settledWidgets.contains(name);

  /// 区块首次挂载时调用，立即为其中尚未激活的组件加载数据
  void activateWidgets(Iterable<String> names) {
    final added = <String>{};
    for (final name in names) {
      if (_activatedWidgets.add(name)) added.add(name);
    }
    if (added.isEmpty) return;
    unawaited(_loadDataForWidgets(added));
  }

  /// 根据开关配置刷新数据，只覆盖已挂载过的组件
  Future<void> _loadDataBasedOnConfig() async {
    if (_isLoadingDashboardData) {
      return;
    }
    _isLoadingDashboardData = true;
    try {
      await _loadDataForWidgets(
        displayedWidgets.where(_activatedWidgets.contains).toSet(),
      );
    } finally {
      _isLoadingDashboardData = false;
    }
  }

  Future<void> _loadDataForWidgets(Set<String> names) async {
    if (names.isEmpty) return;
    try {
      final futures = <Future<void>>[];
      if (names.contains('CPU')) futures.add(loadCpuData());
      if (names.contains('网络流量')) futures.add(loadNetworkData());
      if (names.contains('内存')) futures.add(loadMemoryData());
      if (names.contains('实时速率')) futures.add(loadDownloaderData());
      if (names.contains('存储空间')) futures.add(loadStorageData());
      if (names.contains('媒体统计')) futures.add(loadStatisticData());
      if (names.contains('后台任务')) {
        futures.add(loadScheduleData());
        futures.add(loadTransferQueue());
      }
      if (names.contains('最近添加')) futures.add(loadLatestMediaData());
      if (names.contains('最近入库')) futures.add(loadTransferData());
      if (names.contains('近期整理')) futures.add(loadRecentImports());
      if (names.contains('系统信息')) futures.add(loadSystemInfo());
      if (names.contains('推荐媒体')) futures.add(loadRecommendMedia());
      if (names.contains('我的媒体库')) {
        futures.add(mediaServerController.loadMediaLibraries());
      }
      if (names.contains('继续观看')) futures.add(_loadPlayingMedia());
      await Future.wait(futures);
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载数据失败');
    } finally {
      _settledWidgets.addAll(names);
      _settledWidgets.refresh();
    }
  }

  /// 「继续观看」依赖媒体服务器列表；区块首次挂载时列表可能还没拉到，先补齐再加载
  Future<void> _loadPlayingMedia() async {
    if (mediaServerController.mediaServers.value.isEmpty) {
      await mediaServerController.loadMediaServers();
    }
    final enabledServers = mediaServerController.mediaServers.value
        .where((server) => server.enabled)
        .toList();
    if (enabledServers.isEmpty) return;
    await mediaServerController.loadPlayingMedia(enabledServers.first.name);
  }

  void _appendCpuChartData(double value) {
    var list = List<ChartDataPoint>.from(cpuChartData);
    if (list.isEmpty) {
      list = List.generate(_chartDataLength, (i) => ChartDataPoint(i, value));
    } else {
      if (list.length >= _chartDataLength) list.removeAt(0);
      for (var i = 0; i < list.length; i++) {
        list[i] = ChartDataPoint(i, list[i].value);
      }
      list.add(ChartDataPoint(list.length, value));
    }
    cpuChartData.assignAll(list);
  }

  void _appendMemoryChartData(double value) {
    var list = List<ChartDataPoint>.from(memoryChartData);
    if (list.isEmpty) {
      list = List.generate(_chartDataLength, (i) => ChartDataPoint(i, value));
    } else {
      if (list.length >= _chartDataLength) list.removeAt(0);
      for (var i = 0; i < list.length; i++) {
        list[i] = ChartDataPoint(i, list[i].value);
      }
      list.add(ChartDataPoint(list.length, value));
    }
    memoryChartData.assignAll(list);
  }

  Future<void> applyLocalDashboardLayout(List<String> orderedVisible) async {
    final value = DashboardConfigValue(
      mediaStatistic: orderedVisible.contains('媒体统计'),
      scheduler: orderedVisible.contains('后台任务'),
      speed: orderedVisible.contains('实时速率'),
      storage: orderedVisible.contains('存储空间'),
      weeklyOverview: orderedVisible.contains('最近入库'),
      cpu: orderedVisible.contains('CPU'),
      memory: orderedVisible.contains('内存'),
      network: orderedVisible.contains('网络流量'),
      library: orderedVisible.contains('我的媒体库'),
      playing: orderedVisible.contains('继续观看'),
      latest: orderedVisible.contains('最近添加'),
      mediaRecommend: orderedVisible.contains('推荐媒体'),
      recentImports: orderedVisible.contains('近期整理'),
      quickActions: orderedVisible.contains('快捷操作'),
      systemInfo: orderedVisible.contains('系统信息'),
    );

    final orderItems = orderedVisible
        .map(
          (name) => DashboardOrderItem(id: widgetIdByName[name] ?? '', key: ''),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();

    dashboardConfig.value = DashboardConfigModel(
      success: true,
      message: 'local',
      data: DashboardConfigData(value: value),
    );

    dashboardOrder.value = DashboardOrderModel(
      success: true,
      message: 'local',
      data: DashboardOrderData(value: orderItems),
    );

    _updateDisplayedWidgets(value);
    _updateWidgetsOrder(orderItems);
    await _saveLocalDashboardConfig(configValue: value, orderItems: orderItems);
  }

  /// 根据排序结果更新displayedWidgets列表的顺序
  void _updateWidgetsOrder(List<DashboardOrderItem> orderItems) {
    if (orderItems.isEmpty) return;

    // 根据排序结果创建新的displayedWidgets列表
    final newWidgets = <String>[];

    // 首先添加排序中的组件
    for (final item in orderItems) {
      final widgetName = widgetNameById[item.id];
      if (widgetName != null && displayedWidgets.contains(widgetName)) {
        newWidgets.add(widgetName);
      }
    }

    // 然后添加不在排序中的组件（如果有的话）
    for (final widget in displayedWidgets) {
      if (!newWidgets.contains(widget)) {
        newWidgets.add(widget);
      }
    }

    // 更新displayedWidgets列表
    displayedWidgets.assignAll(newWidgets);
    talker.info('根据排序结果更新displayedWidgets顺序: $newWidgets');
  }

  Future<void> _loadLocalDashboardConfig() async {
    if (kIsWeb) return;
    try {
      final file = await _resolveLocalConfigFile();
      if (file == null || !await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final profiles = decoded['profiles'];
      if (profiles is! Map) return;
      final profile = profiles[_profileKey()];
      if (profile is! Map) return;

      final configRaw = profile['config'];
      DashboardConfigValue? loadedConfigValue;
      if (configRaw is Map) {
        loadedConfigValue = DashboardConfigValue.fromJson(
          Map<String, dynamic>.from(configRaw),
        );
        dashboardConfig.value = DashboardConfigModel(
          success: true,
          message: 'local',
          data: DashboardConfigData(value: loadedConfigValue),
        );
        _updateDisplayedWidgets(loadedConfigValue);
        _hasLocalDashboardConfig = true;
      }

      final orderRaw = profile['order'];
      if (orderRaw is List) {
        final items = orderRaw
            .whereType<Map>()
            .map(
              (item) =>
                  DashboardOrderItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        if (items.isNotEmpty) {
          dashboardOrder.value = DashboardOrderModel(
            success: true,
            message: 'local',
            data: DashboardOrderData(value: items),
          );
          if (loadedConfigValue != null) {
            _updateWidgetsOrder(items);
          }
        }
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '读取本地dashboard配置失败');
    }
  }

  Future<void> _saveLocalDashboardConfig({
    DashboardConfigValue? configValue,
    List<DashboardOrderItem>? orderItems,
  }) async {
    if (kIsWeb) return;
    try {
      final file = await _resolveLocalConfigFile();
      if (file == null) return;
      final data = await _readLocalConfigRaw(file);
      final profiles = <String, dynamic>{};
      final existingProfiles = data['profiles'];
      if (existingProfiles is Map) {
        profiles.addAll(existingProfiles.cast<String, dynamic>());
      }
      final profile = <String, dynamic>{};
      final existingProfile = profiles[_profileKey()];
      if (existingProfile is Map) {
        profile.addAll(existingProfile.cast<String, dynamic>());
      }
      if (configValue != null) {
        profile['config'] = configValue.toJson();
        _hasLocalDashboardConfig = true;
      }
      if (orderItems != null) {
        profile['order'] = orderItems.map((item) => item.toJson()).toList();
      }
      profiles[_profileKey()] = profile;
      data['version'] = _localConfigVersion;
      data['profiles'] = profiles;
      await file.writeAsString(jsonEncode(data));
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '保存本地dashboard配置失败');
    }
  }

  Future<File?> _resolveLocalConfigFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_localConfigFileName');
  }

  Future<Map<String, dynamic>> _readLocalConfigRaw(File file) async {
    if (!await file.exists()) return <String, dynamic>{};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  String _profileKey() {
    final baseUrl = appService.baseUrl ?? 'default-server';
    final userId = appService.loginResponse?.userId ?? appService.userInfo?.id;
    return '$baseUrl::${userId ?? 0}';
  }
}

/// 图表数据点（供 CPU/内存波浪图使用）
class ChartDataPoint {
  const ChartDataPoint(this.index, this.value);
  final int index;
  final double value;
}

/// 仪表板内存信息（API: /api/v1/dashboard/memory）
class DashboardMemoryInfo {
  const DashboardMemoryInfo({
    required this.total,
    required this.used,
    required this.cached,
    required this.available,
    required this.usage,
  });

  final int total;
  final int used;
  final int cached;
  final int available;
  final double usage;

  factory DashboardMemoryInfo.fromJson(Map<String, dynamic> json) {
    return DashboardMemoryInfo(
      total: _asInt(json['total']),
      used: _asInt(json['used']),
      cached: _asInt(json['cached']),
      available: _asInt(json['available']),
      usage: _asDouble(json['usage']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

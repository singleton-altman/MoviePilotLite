import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/statistic_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/dashboard_config_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/dashboard_order_model.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:talker/talker.dart';
import 'package:path_provider/path_provider.dart';

/// Dashboard 控制器
class DashboardController extends GetxController {
  static const String _localConfigFileName = 'dashboard_config.json';
  static const int _localConfigVersion = 1;

  /// 可用的组件类型
  static const List<String> availableWidgets = [
    '存储空间',
    '媒体统计',
    '最近入库',
    '实时速率',
    '后台任务',
    'CPU',
    '内存',
    '网络流量',
    '我的媒体库',
    '继续观看',
    '最近添加',
  ];

  /// 当前显示的组件列表
  final displayedWidgets = <String>[].obs;

  /// CPU使用率
  final cpuUsage = 0.0.obs;

  /// 网络流量 [上行, 下行]
  final networkTraffic = <int>[0, 0].obs;

  /// 内存数据 [内存占用(字节), 使用率(%)]
  final memoryData = <int>[].obs;

  /// 下载器数据
  final downloaderData = <String, dynamic>{}.obs;

  /// 存储空间数据
  final storageData = <String, dynamic>{}.obs;

  /// 媒体统计数据
  final statisticData = Rx<StatisticModel?>(null);

  /// 后台任务列表数据
  final scheduleData = Rx<List<ScheduleModel>>([]);

  /// 媒体服务器最新入库数据
  final latestMediaData = Rx<Map<String, dynamic>?>(null);

  /// 最近入库数据（一周内每天的入库量）
  final transferData = <int>[].obs;

  /// CPU 图表滚动数据（用于波浪图）
  static const int _chartDataLength = 20;
  final cpuChartData = <ChartDataPoint>[].obs;

  /// 内存图表滚动数据（用于波浪图）
  final memoryChartData = <ChartDataPoint>[].obs;

  /// API客户端
  late final ApiClient apiClient;

  /// 媒体服务器控制器
  late final MediaServerController mediaServerController;

  /// Talker日志实例
  late final Talker talker;

  /// Dashboard配置
  final dashboardConfig = Rx<DashboardConfigModel?>(null);

  /// Dashboard元素排序
  final dashboardOrder = Rx<DashboardOrderModel?>(null);

  final appService = Get.find<AppService>();

  late Timer _cpuTimer;
  late Timer _networkTimer;
  late Timer _downloaderTimer;
  late Timer _memoryTimer;
  late Timer _cookieTimer;
  bool _hasLocalDashboardConfig = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    // 初始化依赖
    apiClient = Get.find<ApiClient>();
    talker = Talker();

    // 1. 根据传入数据创建 mediaServerController
    await _initializeMediaServerController();

    // 2. 读取本地配置并预先展示
    await _loadLocalDashboardConfig();

    // 3. 获取 dashboard 开关配置
    await _fetchDashboardConfig();

    // 4. 获取 dashboard 顺序配置
    await _fetchDashboardOrder();

    // 5. 根据开关获取对应数据
    _setupDataLoading();

    // 启动定时刷新
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _cpuTimer.cancel();
    _networkTimer.cancel();
    _downloaderTimer.cancel();
    _memoryTimer.cancel();
    _cookieTimer.cancel();
    super.onClose();
  }

  /// 初始化媒体服务器控制器
  Future<void> _initializeMediaServerController() async {
    // 无论当前是否已经有登录信息，都先初始化 MediaServerController，
    // 避免在后续定时任务中访问到未初始化的字段。
    mediaServerController = Get.put(MediaServerController());

    // 媒体库数据由 _loadDataBasedOnConfig 在显示「我的媒体库」组件时加载
  }

  /// 设置数据加载
  void _setupDataLoading() {
    _loadDataBasedOnConfig();
  }

  /// 启动周期性刷新
  void _startPeriodicRefresh() {
    final duration = const Duration(seconds: 5);
    // 初始化定时任务队列，每5秒获取一次数据，根据开关配置获取对应的数据
    _cpuTimer = Timer.periodic(duration, (_) {
      _loadDataBasedOnConfig();
    });

    _networkTimer = Timer.periodic(duration, (_) {
      _loadDataBasedOnConfig();
    });

    _downloaderTimer = Timer.periodic(duration, (_) {
      _loadDataBasedOnConfig();
    });

    _memoryTimer = Timer.periodic(duration, (_) {
      _loadDataBasedOnConfig();
    });

    _cookieTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _ensureUserCookieRefreshed();
    });
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
      } else if (response.statusCode == 401) {
        talker.error('CPU数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('CPU数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载CPU数据失败');
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
      } else if (response.statusCode == 401) {
        talker.error('网络流量数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('网络流量数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载网络流量数据失败');
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
      } else if (response.statusCode == 401) {
        talker.error('下载器数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('下载器数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载下载器数据失败');
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
      } else if (response.statusCode == 401) {
        talker.error('存储空间数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('存储空间数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载存储空间数据失败');
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
      } else if (response.statusCode == 401) {
        talker.error('媒体统计数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('媒体统计数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载媒体统计数据失败');
    }
  }

  /// 加载后台任务列表数据
  Future<void> loadScheduleData() async {
    try {
      talker.info('开始加载后台任务列表数据');
      final response = await apiClient.get<List<dynamic>>(
        '/api/v1/dashboard/schedule',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        final scheduleList = data
            .map((item) => ScheduleModel.fromJson(item))
            .toList();
        scheduleData.value = scheduleList;
        talker.info('后台任务列表数据加载成功: ${scheduleList.length} 个任务');
      } else if (response.statusCode == 401) {
        talker.error('后台任务列表数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('后台任务列表数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载后台任务列表数据失败');
    }
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
      talker.handle(e, st, '加载媒体服务器最新入库数据失败');
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
      } else if (response.statusCode == 401) {
        talker.error('最近入库数据加载失败: 未授权，请重新登录');
      } else {
        talker.warning('最近入库数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载最近入库数据失败');
    }
  }

  /// 刷新所有数据
  Future<void> refreshData() async {
    talker.info('开始刷新所有数据');
    await _loadDataBasedOnConfig();
    if (displayedWidgets.contains('我的媒体库')) {
      await mediaServerController.loadMediaLibraries();
    }
    await mediaServerController.refreshLatestMediaList();
    if (mediaServerController.mediaServers.value.isNotEmpty) {
      await mediaServerController.loadPlayingMedia(
        mediaServerController.mediaServers.value.first.name,
      );
    }
    talker.info('所有数据刷新完成');
  }

  /// 执行后台任务；不关注返回值，提交后即提示任务已提交
  Future<void> runScheduler(String jobId) async {
    try {
      talker.info('提交后台任务: $jobId');
      await apiClient.get<dynamic>('/api/v1/system/runscheduler?jobid=$jobId');
      ToastUtil.success('任务已提交');
      await loadScheduleData();
    } catch (e, st) {
      talker.handle(e, st, '提交后台任务失败');
      ToastUtil.error('提交失败，请检查网络');
    }
  }

  /// 加载内存数据
  Future<void> loadMemoryData() async {
    try {
      talker.info('开始加载内存数据');
      final response = await apiClient.get<List<dynamic>>(
        '/api/v1/dashboard/memory',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        if (data.length >= 2) {
          final memoryUsed = data[0] as int;
          final memoryUsage = data[1] as int;
          memoryData.value = [memoryUsed, memoryUsage];
          _appendMemoryChartData(memoryUsage.toDouble());
          talker.info('内存数据加载成功: 使用 $memoryUsed 字节, 使用率 $memoryUsage%');
        }
      } else if (response.statusCode == 401) {
        talker.error('内存数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('内存数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, st, '加载内存数据失败');
    }
  }

  /// 获取dashboard开关配置
  Future<void> _fetchDashboardConfig() async {
    try {
      talker.info('开始获取dashboard配置');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/user/config/Dashboard',
      );

      if (response.statusCode == 200 && response.data != null) {
        final config = DashboardConfigModel.fromJson(response.data!);
        dashboardConfig.value = config;
        talker.info('获取dashboard配置成功: ${config.data.value}');

        // 根据配置更新displayedWidgets列表
        _updateDisplayedWidgets(config.data.value);
        await _saveLocalDashboardConfig(
          configValue: config.data.value,
          orderItems: dashboardOrder.value?.data.value,
        );
      } else {
        talker.warning('获取dashboard配置失败: 响应数据为空或状态码错误');
        // 如果获取失败，使用默认配置
        if (!_hasLocalDashboardConfig) {
          _useDefaultConfig();
        }
      }
    } catch (e, st) {
      talker.handle(e, st, '获取dashboard配置失败');
      // 如果获取失败，使用默认配置
      if (!_hasLocalDashboardConfig) {
        _useDefaultConfig();
      }
    }
  }

  /// 根据开关配置更新displayedWidgets列表
  void _updateDisplayedWidgets(DashboardConfigValue config) {
    final widgets = <String>[];

    // 根据配置添加显示的组件
    if (config.storage) widgets.add('存储空间');
    if (config.mediaStatistic) widgets.add('媒体统计');
    if (config.weeklyOverview) widgets.add('最近入库');
    if (config.speed) widgets.add('实时速率');
    if (config.scheduler) widgets.add('后台任务');
    if (config.cpu) widgets.add('CPU');
    if (config.memory) widgets.add('内存');
    if (config.network) widgets.add('网络流量');
    if (config.library) widgets.add('我的媒体库');
    if (config.latest) widgets.add('最近添加');
    if (config.playing) widgets.add('继续观看');

    displayedWidgets.assignAll(widgets);
    talker.info('根据配置更新displayedWidgets: $widgets');
  }

  /// 使用默认配置
  void _useDefaultConfig() {
    // 默认显示所有组件
    displayedWidgets.assignAll(availableWidgets);
    talker.info('使用默认配置，显示所有组件');
  }

  /// 根据开关配置获取对应的数据
  Future<void> _loadDataBasedOnConfig() async {
    // 加载数据，只有当对应的组件在displayedWidgets列表中时才加载
    if (displayedWidgets.contains('CPU')) loadCpuData();
    if (displayedWidgets.contains('网络流量')) loadNetworkData();
    if (displayedWidgets.contains('内存')) loadMemoryData();
    if (displayedWidgets.contains('实时速率')) loadDownloaderData();
    if (displayedWidgets.contains('存储空间')) loadStorageData();
    if (displayedWidgets.contains('媒体统计')) loadStatisticData();
    if (displayedWidgets.contains('后台任务')) loadScheduleData();
    if (displayedWidgets.contains('最近添加')) loadLatestMediaData();
    if (displayedWidgets.contains('最近入库')) loadTransferData();
    if (displayedWidgets.contains('我的媒体库')) {
      mediaServerController.loadMediaLibraries();
    }
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

  /// 更新dashboard配置
  Future<bool> updateDashboardConfig(Map<String, dynamic> config) async {
    try {
      talker.info('开始更新dashboard配置: $config');
      final response = await apiClient.postForm<Map<String, dynamic>>(
        '/api/v1/user/config/Dashboard',
        config,
      );

      if (response.statusCode == 200) {
        talker.info('更新dashboard配置成功');
        // 重新获取配置
        await _fetchDashboardConfig();
        // 刷新dashboardUI
        update();
        // 重启所需的计时器和http请求任务
        _restartTimersAndTasks();
        return true;
      } else {
        talker.warning('更新dashboard配置失败: 状态码错误');
        return false;
      }
    } catch (e, st) {
      talker.handle(e, st, '更新dashboard配置失败');
      return false;
    }
  }

  /// 更新dashboard排序
  Future<bool> updateDashboardOrder(List<dynamic> order) async {
    try {
      talker.info('开始更新dashboard排序: $order');
      final response = await apiClient.postForm<Map<String, dynamic>>(
        '/api/v1/user/config/DashboardOrder',
        {'value': order},
        timeout: 30,
      );

      if (response.statusCode == 200) {
        talker.info('更新dashboard排序成功');
        // 重新获取排序
        await _fetchDashboardOrder();
        // 刷新dashboardUI
        update();
        return true;
      } else {
        talker.warning('更新dashboard排序失败: 状态码错误');
        return false;
      }
    } catch (e, st) {
      talker.handle(e, st, '更新dashboard排序失败');
      return false;
    }
  }

  /// 重新获取dashboard配置和排序
  Future<void> refreshDashboard() async {
    await _fetchDashboardConfig();
    await _fetchDashboardOrder();
    update();
  }

  /// 重启所需的计时器和http请求任务
  void _restartTimersAndTasks() {
    // 取消现有的计时器
    _cpuTimer.cancel();
    _networkTimer.cancel();
    _downloaderTimer.cancel();
    _memoryTimer.cancel();

    // 重新加载数据
    _loadDataBasedOnConfig();

    // 重新启动计时器
    _cpuTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDataBasedOnConfig();
    });

    _networkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDataBasedOnConfig();
    });

    _downloaderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDataBasedOnConfig();
    });

    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDataBasedOnConfig();
    });
  }

  /// 获取dashboard顺序配置
  Future<void> _fetchDashboardOrder() async {
    try {
      talker.info('开始获取dashboard元素排序');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/user/config/DashboardOrder',
      );

      if (response.statusCode == 200 && response.data != null) {
        final order = DashboardOrderModel.fromJson(response.data!);
        dashboardOrder.value = order;
        talker.info('获取dashboard元素排序成功: ${order.data.value}');

        // 根据排序结果更新displayedWidgets列表的顺序
        _updateWidgetsOrder(order.data.value);
        await _saveLocalDashboardConfig(
          configValue: dashboardConfig.value?.data.value,
          orderItems: order.data.value,
        );
      } else {
        talker.warning('获取dashboard元素排序失败: 响应数据为空或状态码错误');
      }
    } catch (e, st) {
      talker.handle(e, st, '获取dashboard元素排序失败');
    }
  }

  /// 根据排序结果更新displayedWidgets列表的顺序
  void _updateWidgetsOrder(List<DashboardOrderItem> orderItems) {
    if (orderItems.isEmpty) return;

    // 创建id到中文名称的映射
    final idToNameMap = {
      'storage': '存储空间',
      'mediaStatistic': '媒体统计',
      'weeklyOverview': '最近入库',
      'speed': '实时速率',
      'scheduler': '后台任务',
      'cpu': 'CPU',
      'memory': '内存',
      'network': '网络流量',
      'library': '我的媒体库',
      'playing': '继续观看',
      'latest': '最近添加',
    };

    // 根据排序结果创建新的displayedWidgets列表
    final newWidgets = <String>[];

    // 首先添加排序中的组件
    for (final item in orderItems) {
      final widgetName = idToNameMap[item.id];
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
      if (configRaw is Map) {
        final value = DashboardConfigValue.fromJson(
          Map<String, dynamic>.from(configRaw),
        );
        dashboardConfig.value = DashboardConfigModel(
          success: true,
          message: 'local',
          data: DashboardConfigData(value: value),
        );
        // _updateDisplayedWidgets(value);
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
          _updateWidgetsOrder(items);
        }
      }
    } catch (e, st) {
      talker.handle(e, st, '读取本地dashboard配置失败');
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
      talker.handle(e, st, '保存本地dashboard配置失败');
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
    final baseUrl = appService.baseUrl ?? apiClient.baseUrl ?? 'default-server';
    final userId = appService.loginResponse?.userId ?? appService.userInfo?.id;
    return '${baseUrl}::${userId ?? 0}';
  }
}

/// 图表数据点（供 CPU/内存波浪图使用）
class ChartDataPoint {
  const ChartDataPoint(this.index, this.value);
  final int index;
  final double value;
}

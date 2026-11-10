import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/ikuai_router_backup_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// IkuaiRouterBackup（爱快路由时光机）插件适配器。
///
/// 插件在 Web 端通过 Vue 联邦组件渲染（`render_mode = vue`），
/// App 侧按插件对外暴露的真实接口重建原生界面（注意：本插件无统一响应包装，
/// 备份类返回 {success, message|msg}，监控类返回 {ok, error, ...}）：
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/config`            完整配置
/// - POST `/api/v1/plugin/IkuaiRouterBackup/config`            保存配置（空密码=保留旧值）
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/status`            实时监控状态（服务端 30s 缓存）
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/histories`         备份/恢复历史与任务活动状态
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/available_backups` 可恢复备份列表
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/alert_history`     负载告警记录
/// - POST `/api/v1/plugin/IkuaiRouterBackup/backup`            立即备份（异步任务）
/// - POST `/api/v1/plugin/IkuaiRouterBackup/restore`           执行恢复（异步任务）
/// - POST `/api/v1/plugin/IkuaiRouterBackup/delete_backup`     删除备份文件
/// - GET  `/api/v1/plugin/IkuaiRouterBackup/download_backup`   下载备份（base64 JSON）
/// - POST `/api/v1/plugin/IkuaiRouterBackup/alert_history`     清空告警记录
/// - POST `/api/v1/plugin/IkuaiRouterBackup/test`              测试爱快连接
class IkuaiRouterBackupFormController extends GetxController
    implements PluginFormAdapter {
  IkuaiRouterBackupFormController({required this.formMode});

  @override
  final String pluginId = 'IkuaiRouterBackup';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  static const _basePath = '/api/v1/plugin/IkuaiRouterBackup';

  @override
  final blocks = <FormBlock>[].obs;

  @override
  final pageNodes = <FormNode>[].obs;

  @override
  final formModel = Rx<Map<String, dynamic>>({});

  @override
  final isLoading = false.obs;

  @override
  final RxBool actionLoading = false.obs;

  @override
  final errorText = RxnString();

  /// 实时监控状态（GET /status）
  final statusData = Rxn<IkuaiRouterStatus>();

  /// 备份/恢复历史与任务活动（GET /histories）
  final histories = Rxn<IkuaiRouterHistories>();

  /// 可恢复备份列表（GET /available_backups）
  final backups = <IkuaiRouterBackupFile>[].obs;

  /// 告警记录（GET /alert_history）
  final alerts = Rxn<IkuaiRouterAlerts>();

  /// 测试连接结果
  final testResult = RxnString();

  /// 下载/恢复等单文件操作的目标，用于行内 loading
  final operatingKey = RxnString();

  // ============ 实时监控（对齐 Web 端 AppPage.vue 多视图卡） ============

  /// 当前监控视图：proto / topflow / apptop / perf / network / flowsplit /
  /// devices4 / devices6 / camera / dhcp / blacklist / dns / routes / upnp
  final monitorView = 'proto'.obs;

  final monitorLoading = false.obs;
  final monitorError = RxnString();

  /// 当前视图原始数据（结构随视图不同）
  final monitorViewData = Rxn<Map<String, dynamic>>();

  /// 已拉取过的视图（切回时不再重复请求，除非 force）
  final _monitorViewLoaded = <String>{};

  /// 状态自动轮询定时器（30s，页面模式）
  Timer? _statusTimer;

  @override
  bool get supportsSave => formMode;

  @override
  bool get supportsFormEntry => true;

  @override
  List<AppBarActionItem>? get actionList => const [
    AppBarActionItem(
      type: 'refresh',
      label: '刷新状态',
      iconName: 'mdi-refresh',
    ),
    AppBarActionItem(
      type: 'backup',
      label: '立即备份',
      iconName: 'mdi-backup-restore',
    ),
  ];

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'refresh') {
      await load();
    } else if (type == 'backup') {
      final ok = await startBackup();
      if (ok) await refreshHistories();
    }
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        blocks.clear();
        formModel.value = {};
        return;
      }

      final configMap = await _getMap('$_basePath/config', token);
      if (configMap != null) {
        formModel.value = Map<String, dynamic>.from(configMap);
        blocks.assignAll(
          IkuaiRouterBackupConverter.convertForm(config: formModel.value),
        );
      }

      // 页面模式拉取监控/备份/告警数据；form 模式也顺带刷新备份任务状态
      final statusMap = await _getMap('$_basePath/status', token);
      if (statusMap != null) {
        statusData.value = IkuaiRouterStatus.fromJson(statusMap);
      }
      await refreshHistories();
      if (!formMode) {
        final alertMap = await _getMap('$_basePath/alert_history', token);
        if (alertMap != null) {
          alerts.value = IkuaiRouterAlerts.fromJson(alertMap);
        }
        unawaited(loadMonitorView(force: true));
        _startStatusTimer();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 IkuaiRouterBackup 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新备份历史与可恢复列表（备份/恢复任务启动后轮询用）
  Future<void> refreshHistories() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    try {
      final historiesMap = await _getMap('$_basePath/histories', token);
      if (historiesMap != null) {
        histories.value = IkuaiRouterHistories.fromJson(historiesMap);
      }
      final availableMap =
          await _getMap('$_basePath/available_backups', token);
      if (availableMap != null) {
        final list = availableMap['backups'];
        backups.assignAll(
          list is List
              ? list
                  .whereType<Map>()
                  .map((entry) => IkuaiRouterBackupFile.fromJson(
                        Map<String, dynamic>.from(entry),
                      ))
                  .toList()
              : <IkuaiRouterBackupFile>[],
        );
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新爱快备份历史失败');
    }
  }

  @override
  Future<bool> save() async {
    if (formModel.value.isEmpty) return false;
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      // 与 Web 端一致：提交整个配置对象；密码留空由服务端保留旧值
      final body = IkuaiRouterBackupConverter.toConfigBody(formModel.value);
      final response = await _apiClient.postJson<dynamic>(
        '$_basePath/config',
        body,
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) {
        errorText.value = '保存失败 (HTTP ${response.statusCode})';
        return false;
      }
      final map = _extractMap(response.data);
      final success = map?['success'] != false;
      if (!success) {
        errorText.value =
            map?['msg']?.toString() ?? map?['message']?.toString() ?? '保存失败';
        return false;
      }
      await load();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 IkuaiRouterBackup 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 立即备份（异步任务，进度通过 histories 轮询）
  Future<bool> startBackup() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    actionLoading.value = true;
    try {
      final map = await _postMap('$_basePath/backup', const {}, token);
      final ok = map?['success'] != false;
      if (!ok) {
        errorText.value =
            map?['message']?.toString() ?? map?['msg']?.toString() ?? '启动备份失败';
      }
      return ok;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '爱快立即备份失败');
      errorText.value = '启动备份失败，请稍后重试';
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  /// 恢复备份（异步任务）
  Future<bool> restoreBackup(IkuaiRouterBackupFile file) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return false;
    operatingKey.value = 'restore:${file.filename}';
    actionLoading.value = true;
    try {
      final body = <String, dynamic>{
        'filename': file.filename,
        'source': file.source,
        if (file.storage != null) 'storage': file.storage,
        if (file.remoteDir != null) 'remote_dir': file.remoteDir,
      };
      final map = await _postMap('$_basePath/restore', body, token);
      final ok = map?['success'] != false;
      if (!ok) {
        errorText.value =
            map?['message']?.toString() ?? '恢复失败';
      }
      return ok;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '爱快恢复备份失败');
      errorText.value = '恢复失败，请稍后重试';
      return false;
    } finally {
      operatingKey.value = null;
      actionLoading.value = false;
    }
  }

  /// 删除备份文件
  Future<bool> deleteBackup(IkuaiRouterBackupFile file) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return false;
    operatingKey.value = 'delete:${file.filename}';
    try {
      final body = <String, dynamic>{
        'filename': file.filename,
        'source': file.source,
        if (file.storage != null) 'storage': file.storage,
        if (file.remoteDir != null) 'remote_dir': file.remoteDir,
      };
      final map = await _postMap('$_basePath/delete_backup', body, token);
      final ok = map?['ok'] != false && map?['success'] != false;
      if (!ok) {
        errorText.value =
            map?['msg']?.toString() ?? map?['error']?.toString() ?? '删除失败';
      }
      return ok;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除爱快备份文件失败');
      errorText.value = '删除失败，请稍后重试';
      return false;
    } finally {
      operatingKey.value = null;
    }
  }

  /// 下载备份文件到临时目录并返回本地路径（base64 JSON，≤20MB）
  Future<String?> downloadBackup(IkuaiRouterBackupFile file) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    operatingKey.value = 'download:${file.filename}';
    try {
      final response = await _apiClient.get<dynamic>(
        '$_basePath/download_backup',
        queryParameters: {
          'filename': file.filename,
          'source': file.source,
          if (file.storage != null) 'storage': file.storage,
          if (file.remoteDir != null) 'remote_dir': file.remoteDir,
        },
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) return null;
      final map = _extractMap(response.data);
      if (map == null || map['ok'] != true) return null;
      final content = map['content']?.toString() ?? '';
      if (content.isEmpty) return null;
      final bytes = base64Decode(content);
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/ikuai_backups');
      if (!backupDir.existsSync()) {
        await backupDir.create(recursive: true);
      }
      final file0 = File('${backupDir.path}/${file.filename}');
      await file0.writeAsBytes(bytes);
      return file0.path;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '下载爱快备份文件失败');
      return null;
    } finally {
      operatingKey.value = null;
    }
  }

  /// 清空告警记录
  Future<bool> clearAlerts() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final map = await _postMap('$_basePath/alert_history', const {}, token);
      return map?['ok'] != false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '清空爱快告警记录失败');
      return false;
    }
  }

  // ============ 实时监控实现 ============

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final token = _getToken();
      if (token == null || token.isEmpty) return;
      try {
        final statusMap = await _getMap('$_basePath/status', token);
        if (statusMap != null) {
          statusData.value = IkuaiRouterStatus.fromJson(statusMap);
        }
      } catch (_) {
        // 静默失败，保留上一次状态
      }
    });
  }

  /// 切换监控视图（会触发按需加载）
  Future<void> switchMonitorView(String view) async {
    if (monitorView.value == view) return;
    monitorView.value = view;
    await loadMonitorView();
  }

  /// 按需加载当前监控视图数据。
  ///
  /// - `proto`      → GET /protocol_flow（{ok, protocols}）
  /// - `devices4`   → GET /devices（{ok, devices}）
  /// - 其余视图     → GET /monitor_view?view=<view>&datetype=hour
  Future<void> loadMonitorView({bool force = false}) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    final view = monitorView.value;
    if (!force && _monitorViewLoaded.contains(view) && monitorViewData.value != null) {
      return;
    }
    if (monitorLoading.value) return;
    monitorLoading.value = true;
    monitorError.value = null;
    try {
      final String path;
      if (view == 'proto') {
        path = '$_basePath/protocol_flow';
      } else if (view == 'devices4') {
        path = '$_basePath/devices';
      } else {
        path = '$_basePath/monitor_view'
            '?view=${Uri.encodeComponent(view)}&datetype=hour';
      }
      final response = await _apiClient.get<dynamic>(
        path,
        token: token,
        timeout: 60,
      );
      if ((response.statusCode ?? 0) >= 400) {
        monitorError.value = '获取监控数据失败 (HTTP ${response.statusCode})';
        monitorViewData.value = null;
        return;
      }
      final map = _extractMap(response.data);
      if (map == null) {
        monitorError.value = '监控数据格式异常';
        monitorViewData.value = null;
        return;
      }
      if (map['ok'] == false) {
        monitorError.value =
            map['error']?.toString().isEmpty == true
                ? '获取监控数据失败'
                : map['error']?.toString();
        monitorViewData.value = null;
        return;
      }
      _monitorViewLoaded.add(view);
      monitorViewData.value = map;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取爱快实时监控数据失败');
      monitorError.value = '获取监控数据失败，请稍后重试';
    } finally {
      monitorLoading.value = false;
    }
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    super.onClose();
  }

  /// 测试爱快连接（用当前表单值）
  Future<bool> testConnection() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    actionLoading.value = true;
    testResult.value = null;
    try {
      final config = formModel.value;
      final body = <String, dynamic>{
        'ikuai_url': config['ikuai_url']?.toString() ?? '',
        'ikuai_username': config['ikuai_username']?.toString() ?? '',
        'ikuai_password': config['ikuai_password']?.toString() ?? '',
        'ikuai_auth_mode': config['ikuai_auth_mode']?.toString() ?? 'auto',
        'ikuai_api_token': config['ikuai_api_token']?.toString() ?? '',
      };
      final map = await _postMap('$_basePath/test', body, token);
      if (map == null || map['ok'] != true) {
        testResult.value =
            '连接失败：${map?['error']?.toString() ?? '未知错误'}';
        return false;
      }
      final hostname = map['hostname']?.toString() ?? '';
      final version = map['version']?.toString() ?? '';
      testResult.value = '连接成功：$hostname ($version)';
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '爱快连接测试失败');
      testResult.value = '连接失败，请稍后重试';
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _getMap(String path, String token) async {
    final response = await _apiClient.get<dynamic>(path, token: token);
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>?> _postMap(
    String path,
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _apiClient.postJson<dynamic>(path, body,
        token: token);
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// 实时监控状态（GET /status）
class IkuaiRouterStatus {
  const IkuaiRouterStatus({
    required this.ok,
    required this.error,
    required this.cpuUsage,
    required this.memUsage,
    required this.hostname,
    required this.version,
    required this.uptime,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.wanIp,
    required this.onlineDevices,
    required this.cpuTemp,
    required this.memoryTotal,
    required this.memoryUsed,
    required this.connectNum,
    required this.interfaces,
  });

  factory IkuaiRouterStatus.fromJson(Map<String, dynamic> json) {
    final list = json['interfaces'];
    return IkuaiRouterStatus(
      ok: json['ok'] == true,
      error: json['error']?.toString() ?? '',
      cpuUsage: _doubleOf(json['cpu_usage']),
      memUsage: _doubleOf(json['mem_usage']),
      hostname: json['hostname']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      uptime: _doubleOf(json['uptime']),
      uploadSpeed: _doubleOf(json['upload_speed']),
      downloadSpeed: _doubleOf(json['download_speed']),
      wanIp: json['wan_ip']?.toString() ?? '',
      onlineDevices: json['online_devices'] is int
          ? json['online_devices'] as int
          : null,
      cpuTemp: json['cpu_temp'] == null
          ? null
          : _doubleOf(json['cpu_temp']),
      memoryTotal: _doubleOf(json['memory_total']),
      memoryUsed: _doubleOf(json['memory_used']),
      connectNum: _doubleOf(json['connect_num']).toInt(),
      interfaces: list is List
          ? list
              .whereType<Map>()
              .map((entry) =>
                  IkuaiRouterInterface.fromJson(
                      Map<String, dynamic>.from(entry)))
              .toList()
          : <IkuaiRouterInterface>[],
    );
  }

  final bool ok;
  final String error;
  final double cpuUsage;
  final double memUsage;
  final String hostname;
  final String version;
  final double uptime;
  final double uploadSpeed;
  final double downloadSpeed;
  final String wanIp;
  final int? onlineDevices;
  final double? cpuTemp;
  final double memoryTotal;
  final double memoryUsed;
  final int connectNum;
  final List<IkuaiRouterInterface> interfaces;

  String get uptimeLabel {
    final seconds = uptime.toInt();
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '$days 天 $hours 小时';
    if (hours > 0) return '$hours 小时 $minutes 分钟';
    return '$minutes 分钟';
  }

  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var value = bytesPerSecond;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
  }
}

/// WAN/LAN 线路（GET /status 的 interfaces）
class IkuaiRouterInterface {
  const IkuaiRouterInterface({
    required this.name,
    required this.type,
    required this.ip,
    required this.connected,
    required this.upload,
    required this.download,
  });

  factory IkuaiRouterInterface.fromJson(Map<String, dynamic> json) {
    return IkuaiRouterInterface(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      ip: json['ip']?.toString() ?? '--',
      connected: json['connected'] == true,
      upload: _doubleOf(json['upload']),
      download: _doubleOf(json['download']),
    );
  }

  final String name;
  final String type;
  final String ip;
  final bool connected;
  final double upload;
  final double download;
}

/// 备份/恢复历史与任务活动（GET /histories）
class IkuaiRouterHistories {
  const IkuaiRouterHistories({
    required this.ok,
    required this.backupHistory,
    required this.restoreHistory,
    required this.backupActivity,
    required this.restoreActivity,
  });

  factory IkuaiRouterHistories.fromJson(Map<String, dynamic> json) {
    final backupList = json['backup_history'];
    final restoreList = json['restore_history'];
    return IkuaiRouterHistories(
      ok: json['ok'] != false,
      backupHistory: backupList is List
          ? backupList
              .whereType<Map>()
              .map((entry) => IkuaiRouterHistoryEntry.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList()
          : <IkuaiRouterHistoryEntry>[],
      restoreHistory: restoreList is List
          ? restoreList
              .whereType<Map>()
              .map((entry) => IkuaiRouterHistoryEntry.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList()
          : <IkuaiRouterHistoryEntry>[],
      backupActivity: json['backup_activity']?.toString() ?? '空闲',
      restoreActivity: json['restore_activity']?.toString() ?? '空闲',
    );
  }

  final bool ok;
  final List<IkuaiRouterHistoryEntry> backupHistory;
  final List<IkuaiRouterHistoryEntry> restoreHistory;
  final String backupActivity;
  final String restoreActivity;

  bool get backupRunning => backupActivity != '空闲';
  bool get restoreRunning => restoreActivity != '空闲';
}

/// 历史/告警通用时间格式化
String formatUnixTime(num? seconds) {
  if (seconds == null || seconds <= 0) return '--';
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    (seconds * 1000).round(),
  );
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}-${twoDigits(dateTime.month)}-${twoDigits(dateTime.day)} '
      '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}

/// 备份历史条目
class IkuaiRouterHistoryEntry {
  const IkuaiRouterHistoryEntry({
    required this.timestamp,
    required this.success,
    required this.filename,
    required this.message,
  });

  factory IkuaiRouterHistoryEntry.fromJson(Map<String, dynamic> json) {
    return IkuaiRouterHistoryEntry(
      timestamp: json['timestamp'] is num
          ? (json['timestamp'] as num).toDouble()
          : null,
      success: json['success'] == true,
      filename: json['filename']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  final double? timestamp;
  final bool success;
  final String? filename;
  final String message;

  String get timeLabel => formatUnixTime(timestamp);
}

/// 可恢复备份文件（GET /available_backups）
class IkuaiRouterBackupFile {
  const IkuaiRouterBackupFile({
    required this.filename,
    required this.source,
    required this.time,
    this.storage,
    this.remoteDir,
  });

  factory IkuaiRouterBackupFile.fromJson(Map<String, dynamic> json) {
    return IkuaiRouterBackupFile(
      filename: json['filename']?.toString() ?? '',
      source: json['source']?.toString() ?? '本地备份',
      time: json['time'] is num ? (json['time'] as num).toDouble() : null,
      storage: json['storage']?.toString(),
      remoteDir: json['remote_dir']?.toString(),
    );
  }

  final String filename;
  final String source;
  final double? time;
  final String? storage;
  final String? remoteDir;

  String get timeLabel => formatUnixTime(time);
}

/// 负载告警记录（GET /alert_history）
class IkuaiRouterAlerts {
  const IkuaiRouterAlerts({
    required this.ok,
    required this.items,
    required this.enabled,
    required this.cpuThreshold,
    required this.memThreshold,
  });

  factory IkuaiRouterAlerts.fromJson(Map<String, dynamic> json) {
    final list = json['items'];
    return IkuaiRouterAlerts(
      ok: json['ok'] != false,
      items: list is List
          ? list
              .whereType<Map>()
              .map((entry) => IkuaiRouterAlert.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList()
          : <IkuaiRouterAlert>[],
      enabled: json['enabled'] == true,
      cpuThreshold: _doubleOf(json['cpu_threshold']),
      memThreshold: _doubleOf(json['mem_threshold']),
    );
  }

  final bool ok;
  final List<IkuaiRouterAlert> items;
  final bool enabled;
  final double cpuThreshold;
  final double memThreshold;
}

/// 单条告警
class IkuaiRouterAlert {
  const IkuaiRouterAlert({
    required this.kind,
    required this.start,
    required this.end,
    required this.duration,
    required this.peakCpu,
    required this.peakMem,
  });

  factory IkuaiRouterAlert.fromJson(Map<String, dynamic> json) {
    return IkuaiRouterAlert(
      kind: json['kind']?.toString() ?? '',
      start: json['start'] is num ? (json['start'] as num).toDouble() : null,
      end: json['end'] is num ? (json['end'] as num).toDouble() : null,
      duration: _doubleOf(json['duration']).toInt(),
      peakCpu: _doubleOf(json['peak_cpu']),
      peakMem: _doubleOf(json['peak_mem']),
    );
  }

  final String kind;
  final double? start;
  final double? end;
  final int duration;
  final double peakCpu;
  final double peakMem;

  String get timeLabel => formatUnixTime(start);

  String get durationLabel {
    if (end == null) return '进行中';
    final minutes = duration ~/ 60;
    if (minutes <= 0) return '${duration}s';
    return '$minutes 分钟';
  }
}

double _doubleOf(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

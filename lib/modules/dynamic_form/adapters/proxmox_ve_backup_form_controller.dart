import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/proxmox_ve_converter/proxmox_ve_backup_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// ProxmoxVEBackup 插件适配器：PVE 状态、虚机/容器、备份管理、监控与运维
class ProxmoxVEBackupFormController extends GetxController
    implements PluginFormAdapter {
  ProxmoxVEBackupFormController({required this.formMode});

  @override
  final String pluginId = 'ProxmoxVEBackup';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  @override
  final blocks = <FormBlock>[].obs;

  @override
  final pageNodes = <FormNode>[].obs;

  @override
  final formModel = Rx<Map<String, dynamic>>({});

  @override
  final isLoading = false.obs;

  @override
  final errorText = RxnString();

  /// Page 模式下的 PVE 主机状态，供 ProxmoxVeBackupHeader 渲染
  final pveStatus = Rx<Map<String, dynamic>?>(null);

  /// 插件自身状态（enabled / 备份活动 / 下次执行 / 轮询间隔）
  final pluginStatus = Rx<Map<String, dynamic>?>(null);

  /// 可用备份文件列表（本地 / WebDAV / 网盘）
  final availableBackups = <Map<String, dynamic>>[].obs;

  /// 备份历史与恢复历史
  final backupHistoryList = <Map<String, dynamic>>[].obs;
  final restoreHistoryList = <Map<String, dynamic>>[].obs;

  /// 仪表盘统计
  final dashboard = Rx<Map<String, dynamic>?>(null);

  /// 节点监控（存储 / 任务 / 负载）
  final monitor = Rx<Map<String, dynamic>?>(null);
  final monitorLoading = false.obs;

  /// 镜像模板
  final templates = <Map<String, dynamic>>[].obs;
  final templatesLoading = false.obs;

  /// SSH 控制台输出
  final terminalOutput = RxnString();
  final terminalRunning = false.obs;

  /// 运维操作（备份/清理/主机操作）loading
  final opsLoading = false.obs;

  /// 虚机实时画面
  final screenBytes = Rxn<Uint8List>();
  final screenLoading = false.obs;

  /// 备份行操作请求（restore / delete），由页面渲染层弹出确认对话框
  final pendingBackupAction =
      Rxn<({String type, Map<String, dynamic> item})>();

  @override
  RxBool? get actionLoading => containerActionLoading;

  /// 容器操作（启动/停止/重启/快照）的 loading 状态
  final containerActionLoading = false.obs;

  static const _basePath = '/api/v1/plugin/ProxmoxVEBackup';

  /// 默认轮询间隔（毫秒），可由插件配置 status_poll_interval 覆盖
  static const int _defaultPollIntervalMs = 30000;

  Timer? _pollTimer;

  /// 虚机/容器列表（页面渲染直接观察此列表）
  final containersList = <Map<String, dynamic>>[].obs;

  /// container_status 拉取失败（区别于「确实没有虚机」），供卡片显示重试入口
  final containerLoadFailed = false.obs;

  /// 容器检索中（单独重试时）
  final containerRetrying = false.obs;

  List<Map<String, dynamic>> _lastContainers = const [];

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  String get _baseUrl => (_apiClient.baseUrl ?? '').replaceAll(
    RegExp(r'/+$'),
    '',
  );

  @override
  Future<void> load() async {
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        blocks.clear();
        formModel.value = {};
        return;
      }

      if (formMode) {
        isLoading.value = true;
        errorText.value = null;
        await _loadForm(token);
      } else {
        // 先恢复上次的快照：有缓存时页面秒开，网络刷新放后台
        final restored = await _restorePageCache();
        isLoading.value = !restored;
        errorText.value = null;
        unawaited(
          _loadPage(token).then((_) => _savePageCache()),
        );
        _startPollTimer();
        // 监控与模板依赖 PVE API/SSH，单独异步加载，避免拖慢首屏
        unawaited(loadMonitor());
        unawaited(loadTemplates());
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 数据失败');
      // 带上异常摘要，真机上能直接看出根因
      errorText.value = '请求失败：$e';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  int get _pollIntervalMs {
    final raw = pluginStatus.value?['status_poll_interval'];
    final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (value == null || value <= 0) return _defaultPollIntervalMs;
    // 服务端 pve_status / container_status 有 30s 短缓存，过快轮询无意义
    return value < 5000 ? 5000 : value;
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(milliseconds: _pollIntervalMs),
      (_) => _pollLoad(),
    );
  }

  Future<void> _pollLoad() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    if (opsLoading.value || containerActionLoading.value) return;
    await _loadPage(token);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.onClose();
  }

  Future<void> _loadForm(String token) async {
    final resp = await _apiClient.get<dynamic>(
      '$_basePath/config',
      token: token,
    );
    final configMap = _extractMap(resp.data);
    if (configMap == null) {
      errorText.value = '数据格式错误';
      blocks.clear();
      formModel.value = {};
      return;
    }
    final (blocksList, model) = ProxmoxVEBackupConverter.convertForm(
      config: configMap,
    );
    // 轮询间隔下拉按数值匹配，插件历史配置可能存成字符串，这里归一化
    for (final key in const ['status_poll_interval', 'container_poll_interval']) {
      final raw = model[key];
      if (raw is String) {
        final parsed = int.tryParse(raw.trim());
        if (parsed != null) model[key] = parsed;
      }
    }
    formModel.value = model;
    blocks.assignAll(blocksList);
  }

  /// 容错 GET：失败返回 null，不抛出，避免单个接口异常导致整页空白
  Future<dynamic> _getData(String path, {int timeout = 60}) async {
    try {
      final resp = await _apiClient.get<dynamic>(
        path,
        token: _getToken(),
        timeout: timeout,
      );
      final status = resp.statusCode ?? 0;
      if (status >= 400) {
        _log.info('ProxmoxVEBackup GET $path -> HTTP $status');
        return null;
      }
      return resp.data;
    } catch (e) {
      _log.info('ProxmoxVEBackup GET $path 异常: $e');
      return null;
    }
  }

  /// 拉取页面数据。各接口相互独立，部分失败时保留其余内容。
  Future<void> _loadPage(String token) async {
    final results = await Future.wait([
      _getData('$_basePath/status', timeout: 30),
      _getData('$_basePath/pve_status', timeout: 90),
      _getData('$_basePath/container_status', timeout: 90),
      _getData('$_basePath/available_backups', timeout: 60),
    ]);

    final statusMap = _extractMap(results[0]);
    final pveMap = _extractMap(results[1]);
    final containerList = _extractList(results[2]);
    final backupList = _extractList(results[3]);
    final containerRequestFailed = results[2] == null;

    // 主数据全部拿不到才算失败；已有缓存内容时保留页面，只提示刷新失败
    if (statusMap == null && pveMap == null && containerList.isEmpty) {
      if (blocks.isEmpty) {
        errorText.value = '获取插件数据失败，请检查 MoviePilot 服务与 PVE 连接';
      }
      return;
    }

    if (statusMap != null) pluginStatus.value = statusMap;
    // PVE 状态取不到时保留上一次结果，避免轮询抖动导致整块消失
    if (pveMap != null) pveStatus.value = pveMap;
    _lastContainers = containerList;
    containersList.assignAll(containerList);
    containerLoadFailed.value = containerRequestFailed && containerList.isEmpty;

    // 历史与统计：失败时保留旧数据
    final extras = await Future.wait([
      _getData('$_basePath/backup_history'),
      _getData('$_basePath/restore_history'),
      _getData('$_basePath/dashboard_data'),
    ]);
    final historyList = _extractList(extras[0]);
    final restoreList = _extractList(extras[1]);
    if (extras[0] != null) backupHistoryList.assignAll(historyList);
    if (extras[1] != null) restoreHistoryList.assignAll(restoreList);
    final dashboardMap = _extractMap(extras[2]);
    if (dashboardMap != null) dashboard.value = dashboardMap;

    availableBackups.assignAll(backupList);

    _rebuildPage();
    errorText.value = null;
  }

  // ---------------------------------------------------------------- 页面快照缓存
  // 首次进入用上一次的数据秒开，网络刷新在后台进行（stale-while-revalidate）。

  File? _pageCacheFile;

  Future<File?> _resolveCacheFile() async {
    if (_pageCacheFile != null) return _pageCacheFile;
    try {
      final dir = await getApplicationSupportDirectory();
      _pageCacheFile = File('${dir.path}${Platform.pathSeparator}pve_page_cache.json');
      return _pageCacheFile;
    } catch (e) {
      _log.info('ProxmoxVEBackup 缓存目录获取失败: $e');
      return null;
    }
  }

  /// 恢复上一次的页面快照，命中返回 true
  Future<bool> _restorePageCache() async {
    try {
      final file = await _resolveCacheFile();
      if (file == null || !file.existsSync()) return false;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return false;
      final snap = Map<String, dynamic>.from(raw);

      final pve = snap['pve'];
      final status = snap['status'];
      final containerList = (snap['containers'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const <Map<String, dynamic>>[];
      final backupList = (snap['backups'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const <Map<String, dynamic>>[];
      if (pve is! Map && status is! Map && containerList.isEmpty) {
        return false;
      }

      if (pve is Map) pveStatus.value = Map<String, dynamic>.from(pve);
      if (status is Map) pluginStatus.value = Map<String, dynamic>.from(status);
      _lastContainers = containerList;
      containersList.assignAll(containerList);
      containerLoadFailed.value = false;
      availableBackups.assignAll(backupList);
      final bh = snap['backup_history'];
      if (bh is List) {
        backupHistoryList.assignAll(
          bh.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      final rh = snap['restore_history'];
      if (rh is List) {
        restoreHistoryList.assignAll(
          rh.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      final db = snap['dashboard'];
      if (db is Map) dashboard.value = Map<String, dynamic>.from(db);
      final mon = snap['monitor'];
      if (mon is Map) monitor.value = Map<String, dynamic>.from(mon);
      final tpl = snap['templates'];
      if (tpl is List) {
        templates.assignAll(
          tpl.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }

      _rebuildPage();
      return true;
    } catch (e) {
      _log.info('ProxmoxVEBackup 恢复页面缓存失败: $e');
      return false;
    }
  }

  /// 保存当前数据为页面快照（只在有内容时写入，避免把空结果缓存住）
  Future<void> _savePageCache() async {
    try {
      if (blocks.isEmpty) return;
      final snap = {
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'pve': pveStatus.value,
        'status': pluginStatus.value,
        'containers': _lastContainers,
        'backups': availableBackups.toList(),
        'backup_history': backupHistoryList.toList(),
        'restore_history': restoreHistoryList.toList(),
        'dashboard': dashboard.value,
        'monitor': monitor.value,
        'templates': templates.toList(),
      };
      final file = await _resolveCacheFile();
      if (file == null) return;
      await file.writeAsString(jsonEncode(snap), flush: true);
    } catch (e) {
      _log.info('ProxmoxVEBackup 保存页面缓存失败: $e');
    }
  }

  /// 单独重试拉取虚机/容器列表
  Future<void> retryContainers() async {
    if (containerRetrying.value) return;
    containerRetrying.value = true;
    try {
      final raw = await _getData('$_basePath/container_status', timeout: 120);
      final list = _extractList(raw);
      if (list.isNotEmpty || raw != null) {
        _lastContainers = list;
        containersList.assignAll(list);
        containerLoadFailed.value = false;
      }
    } finally {
      containerRetrying.value = false;
    }
  }

  /// 刷新页面（运维操作后调用）
  Future<void> reloadPage() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    await _loadPage(token);
    unawaited(loadMonitor());
  }

  /// 加载节点监控
  Future<void> loadMonitor() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    if (monitorLoading.value) return;
    monitorLoading.value = true;
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/monitor',
        timeout: 60,
      );
      monitor.value = _extractMap(resp.data);
      _rebuildPage();
      unawaited(_savePageCache());
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 监控数据失败');
    } finally {
      monitorLoading.value = false;
    }
  }

  /// 加载镜像模板列表
  Future<void> loadTemplates() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    if (templatesLoading.value) return;
    templatesLoading.value = true;
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/template_images',
        timeout: 120,
      );
      final list = resp.data is List
          ? _extractList(resp.data)
          : _extractList(_extractMap(resp.data)?['data']);
      templates.assignAll(list);
      _rebuildPage();
      unawaited(_savePageCache());
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 模板列表失败');
    } finally {
      templatesLoading.value = false;
    }
  }

  void _rebuildPage() {
    if (formMode) return;
    final blocksList = ProxmoxVEBackupConverter.convertPage(
      pveStatus: pveStatus.value ?? <String, dynamic>{},
      containerStatusList: _lastContainers,
      backups: availableBackups.toList(),
      backupHistory: backupHistoryList.toList(),
      restoreHistory: restoreHistoryList.toList(),
      dashboard: dashboard.value,
      monitor: monitor.value,
      templates: templates.toList(),
      useHeaderBlock: true,
      onContainerAction: (type, vmid, action) =>
          _handleAction(action: action, vmid: vmid, type: type),
      onBackupAction: _handleBackupAction,
    );
    blocks.assignAll(blocksList);
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
      final body = ProxmoxVEBackupConverter.toConfigBody(formModel.value);
      _log.info('保存 ProxmoxVEBackup 配置');
      // 使用插件自身的 /config 接口：服务端与现有配置合并，避免丢字段
      final response = await _apiClient.post<dynamic>(
        '$_basePath/config',
        data: body,
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '保存失败 (HTTP $status)';
        return false;
      }
      final respMap = _extractMap(response.data);
      if (respMap != null && respMap['success'] == false) {
        errorText.value = respMap['message']?.toString() ?? '保存失败';
        return false;
      }
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 ProxmoxVEBackup 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 单独保存存储目标（多目标备份），走 /config 合并接口
  Future<bool> saveStorageTargets(
    List<Map<String, dynamic>> targets, {
    bool? enabled,
  }) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return false;
    opsLoading.value = true;
    try {
      final resp = await _apiClient.post<dynamic>(
        '$_basePath/config',
        data: {
          'storage_targets': targets,
          if (enabled != null) 'storage_backup_enable': enabled,
        },
        token: token,
      );
      final map = _extractMap(resp.data);
      final ok = (resp.statusCode ?? 0) < 400 && map?['success'] != false;
      if (ok) {
        formModel.value = {
          ...formModel.value,
          'storage_targets': targets,
          if (enabled != null) 'storage_backup_enable': enabled,
        };
        ToastUtil.success('存储目标已保存');
      } else {
        ToastUtil.error(map?['message']?.toString() ?? '保存失败');
      }
      return ok;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 ProxmoxVEBackup 存储目标失败');
      ToastUtil.error('保存失败，请稍后重试');
      return false;
    } finally {
      opsLoading.value = false;
    }
  }

  /// 从 API 错误响应中提取 msg/message 等字段
  String _extractErrorMessage(dynamic data, int status, String fallback) {
    final map = _extractMap(data);
    if (map != null) {
      final msg =
          map['msg']?.toString().trim() ??
          map['message']?.toString().trim() ??
          map['detail']?.toString().trim() ??
          map['error']?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return '$fallback (HTTP $status)';
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

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map<Map<String, dynamic>>(
          (e) => e is Map<String, dynamic>
              ? e
              : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
        )
        .where((m) => m.isNotEmpty)
        .toList();
  }

  Future<bool> _handleAction({
    required String action,
    required String vmid,
    required String type,
  }) async {
    containerActionLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        ToastUtil.error('请先登录');
        return false;
      }
      final path = action == 'snapshot'
          ? 'container_snapshot'
          : 'container_action';
      final data = action == 'snapshot'
          ? {'vmid': vmid, 'type': type}
          : {'action': action, 'vmid': vmid, 'type': type};
      final response = await _apiClient.post<dynamic>(
        '$_basePath/$path',
        data: data,
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        final msg = _extractErrorMessage(response.data, status, '操作失败');
        errorText.value = msg;
        ToastUtil.error(msg);
        return false;
      }
      // 插件失败时可能返回 HTTP 200 + {"success": false, "message": ...}，
      // 必须显式检查 success 字段，避免误报成功。
      final respMap = _extractMap(response.data);
      if (respMap != null && respMap['success'] == false) {
        final msg = _extractErrorMessage(respMap, status, '操作失败');
        errorText.value = msg;
        ToastUtil.error(msg);
        return false;
      }
      final actionLabels = {
        'start': '启动',
        'stop': '停止',
        'reboot': '重启',
        'snapshot': '快照',
      };
      ToastUtil.success('${actionLabels[action] ?? action} VMID $vmid 操作成功');
      // 操作成功后刷新页面
      final t = _getToken();
      if (t != null && t.isNotEmpty && !formMode) {
        await _loadPage(t);
      }
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '处理 ProxmoxVEBackup 操作失败');
      final msg = e.toString();
      errorText.value = msg;
      ToastUtil.error(msg);
      return false;
    } finally {
      containerActionLoading.value = false;
    }
  }

  /// 虚机/容器行内操作（页面按钮直接调用）
  Future<bool> runVmAction({
    required String vmid,
    required String type,
    required String action,
  }) {
    return _handleAction(action: action, vmid: vmid, type: type);
  }

  /// 备份文件行操作：恢复/删除交给页面确认弹窗，下载直接执行
  Future<void> _handleBackupAction(
    String type,
    Map<String, dynamic> item,
  ) async {
    switch (type) {
      case 'download':
        await downloadBackup(item);
        break;
      case 'restore':
      case 'delete':
        pendingBackupAction.value = (type: type, item: item);
        break;
      default:
        break;
    }
  }

  /// 通用 POST，返回 (成功, 消息)
  Future<(bool, String)> _postAction(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return (false, '请先登录');
    opsLoading.value = true;
    try {
      final resp = await _apiClient.post<dynamic>(
        '$_basePath/$path',
        data: body ?? const <String, dynamic>{},
        token: token,
      );
      final status = resp.statusCode ?? 0;
      final map = _extractMap(resp.data);
      final msg =
          map?['message']?.toString() ??
          map?['msg']?.toString() ??
          (status >= 400 ? 'HTTP $status' : '');
      if (status >= 400 || map?['success'] == false) {
        return (false, msg.isEmpty ? '操作失败' : msg);
      }
      return (true, msg.isEmpty ? '操作成功' : msg);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'ProxmoxVEBackup 操作失败: $path');
      return (false, '请求失败，请稍后重试');
    } finally {
      opsLoading.value = false;
    }
  }

  /// 立即备份
  Future<bool> runBackup() async {
    final (ok, msg) = await _postAction('run_backup');
    if (ok) {
      ToastUtil.success(msg);
      unawaited(reloadPage());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 停止所有任务
  Future<bool> stopAllTasks() async {
    final (ok, msg) = await _postAction('stop_all_tasks');
    if (ok) {
      ToastUtil.success(msg.isEmpty ? '已停止任务' : msg);
      unawaited(reloadPage());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 清理备份/恢复历史
  Future<bool> clearHistory() async {
    final (ok, msg) = await _postAction('clear_history');
    if (ok) {
      ToastUtil.success(msg);
      unawaited(reloadPage());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 清理 PVE 系统日志
  Future<bool> cleanupLogs() async {
    final (ok, msg) = await _postAction('cleanup_logs');
    if (ok) {
      ToastUtil.success(msg);
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 清理 PVE 临时空间
  Future<bool> cleanupTmp() async {
    final (ok, msg) = await _postAction('cleanup_tmp');
    if (ok) {
      ToastUtil.success(msg);
      unawaited(loadMonitor());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 主机重启 / 关机，[action] 取 reboot / shutdown
  Future<bool> hostAction(String action) async {
    final (ok, msg) = await _postAction('host_action', body: {'action': action});
    if (ok) {
      ToastUtil.success(msg.isEmpty ? '命令已发送' : msg);
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 删除备份文件
  Future<bool> deleteBackup(Map<String, dynamic> item) async {
    final filename = item['filename']?.toString() ?? '';
    if (filename.isEmpty) return false;
    final (ok, msg) = await _postAction(
      'delete_backup',
      body: {
        'filename': filename,
        'source': item['source']?.toString() ?? '本地备份',
        if (item['storage'] != null) 'storage': item['storage'],
        if (item['remote_dir'] != null) 'remote_dir': item['remote_dir'],
      },
    );
    if (ok) {
      ToastUtil.success(msg);
      unawaited(reloadPage());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 恢复备份
  Future<bool> restoreBackup(
    Map<String, dynamic> item, {
    bool force = false,
    bool skipExisting = true,
    String vmid = '',
  }) async {
    final filename = item['filename']?.toString() ?? '';
    if (filename.isEmpty) return false;
    final (ok, msg) = await _postAction(
      'restore',
      body: {
        'filename': filename,
        'source': item['source']?.toString() ?? '本地备份',
        'restore_vmid': vmid,
        'restore_force': force,
        'restore_skip_existing': skipExisting,
      },
    );
    if (ok) {
      ToastUtil.success(msg);
      unawaited(reloadPage());
    } else {
      ToastUtil.error(msg);
    }
    return ok;
  }

  /// 下载备份文件到本地缓存并返回文件路径（供分享）
  Future<String?> downloadBackup(Map<String, dynamic> item) async {
    final filename = item['filename']?.toString() ?? '';
    if (filename.isEmpty) return null;
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    opsLoading.value = true;
    ToastUtil.info('开始下载 $filename…');
    try {
      final url =
          '$_baseUrl$_basePath/download_backup'
          '?filename=${Uri.encodeComponent(filename)}'
          '&source=${Uri.encodeComponent(item['source']?.toString() ?? '本地备份')}';
      final tempDir = await getTemporaryDirectory();
      final safeName = filename.replaceAll('/', '_');
      final target = File('${tempDir.path}/pve_backups/$safeName');
      await target.parent.create(recursive: true);
      final d = dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      await d.download(
        url,
        target.path,
        options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return target.path;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '下载 ProxmoxVEBackup 备份失败');
      ToastUtil.error('下载失败，请稍后重试');
      return null;
    } finally {
      opsLoading.value = false;
    }
  }

  /// SSH 控制台执行单条命令
  Future<String?> runTerminal(String command) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    terminalRunning.value = true;
    terminalOutput.value = null;
    try {
      final resp = await _apiClient.post<dynamic>(
        '$_basePath/terminal',
        data: {'command': command},
        token: token,
      );
      final map = _extractMap(resp.data);
      if (map == null) return null;
      final output = map['output']?.toString() ?? '';
      final message = map['message']?.toString() ?? '';
      final exitCode = map['exit_code'];
      final buffer = StringBuffer();
      if (output.isNotEmpty) buffer.writeln(output);
      if (message.isNotEmpty) buffer.writeln('[错误] $message');
      if (exitCode != null) buffer.writeln('[退出码] $exitCode');
      final text = buffer.toString().trim();
      terminalOutput.value = text.isEmpty ? '(无输出)' : text;
      return terminalOutput.value;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'ProxmoxVEBackup 控制台执行失败');
      terminalOutput.value = '执行失败：$e';
      return null;
    } finally {
      terminalRunning.value = false;
    }
  }

  /// 虚机实时画面（仅 qemu）
  Future<Uint8List?> fetchScreen(String vmid) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    screenLoading.value = true;
    try {
      final url =
          '$_baseUrl$_basePath/vm_screen?'
          'vmid=${Uri.encodeComponent(vmid)}&type=qemu';
      final bytes = await _apiClient.fetchResourceProxyImage(url);
      screenBytes.value = bytes;
      return bytes;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 画面失败');
      return null;
    } finally {
      screenLoading.value = false;
    }
  }

  /// 当前页面容器列表（供运维面板选择虚机）
  List<Map<String, dynamic>> get containers => containersList.toList();

  @override
  get supportsSave => true;

  @override
  bool get supportsFormEntry => true;

  @override
  List<AppBarActionItem>? get actionList => [
    AppBarActionItem(
      label: '关机',
      iconName: 'mdi-power',
      type: 'shutdown',
      iconColor: 'red',
    ),
    AppBarActionItem(
      label: '重启',
      iconName: 'mdi-restart',
      type: 'reboot',
      iconColor: 'blue',
    ),
  ];

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'reboot' || type == 'shutdown') {
      await hostAction(type);
      return;
    }
    ToastUtil.error('暂不支持该操作');
  }
}

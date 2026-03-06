import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/proxmox_ve_converter/proxmox_ve_backup_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// ProxmoxVEBackup 插件适配器：PVE 状态、容器、备份列表与配置
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

  @override
  RxBool? get actionLoading => containerActionLoading;

  /// 容器操作（启动/停止/重启/快照）的 loading 状态
  final containerActionLoading = false.obs;

  static const _basePath = '/api/v1/plugin/ProxmoxVEBackup';

  /// 轮询间隔（毫秒），默认 5 秒，与 status_poll_interval 一致
  static const int _defaultPollIntervalMs = 5000;

  Timer? _pollTimer;

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

      pveStatus.value = null;
      if (formMode) {
        await _loadForm(token);
      } else {
        await _loadPage(token);
        _startPollTimer();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    final interval = Duration(milliseconds: _defaultPollIntervalMs);
    _pollTimer = Timer.periodic(interval, (_) => _pollLoad());
  }

  Future<void> _pollLoad() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
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
    formModel.value = model;
    blocks.assignAll(blocksList);
  }

  Future<void> _loadPage(String token) async {
    try {
      final pveStatusResponse = await _apiClient.get<dynamic>(
        '$_basePath/pve_status',
        timeout: 120,
      );
      final containerStatusResponse = await _apiClient.get<dynamic>(
        '$_basePath/container_status',
        timeout: 120,
      );
      final availableBackupsResponse = await _apiClient.get<dynamic>(
        '$_basePath/backup_history',
        timeout: 120,
      );

      final containerList = containerStatusResponse.data is List
          ? (containerStatusResponse.data as List)
                .map<Map<String, dynamic>>(
                  (e) => e is Map<String, dynamic>
                      ? e
                      : (e is Map
                            ? Map<String, dynamic>.from(e)
                            : <String, dynamic>{}),
                )
                .where((Map<String, dynamic> m) => m.isNotEmpty)
                .toList()
          : <Map<String, dynamic>>[];
      final backupList = availableBackupsResponse.data is List
          ? (availableBackupsResponse.data as List)
                .map<Map<String, dynamic>>(
                  (e) => e is Map<String, dynamic>
                      ? e
                      : (e is Map
                            ? Map<String, dynamic>.from(e)
                            : <String, dynamic>{}),
                )
                .where((Map<String, dynamic> m) => m.isNotEmpty)
                .toList()
          : <Map<String, dynamic>>[];

      final pveMap = _extractMap(pveStatusResponse.data);
      pveStatus.value = pveMap ?? <String, dynamic>{};

      final blocksList = ProxmoxVEBackupConverter.convertPage(
        pveStatus: pveMap ?? <String, dynamic>{},
        containerStatusList: containerList,
        backups: backupList,
        useHeaderBlock: true,
        onContainerAction: (type, vmid, action) =>
            _handleAction(action: action, vmid: vmid, type: type),
      );
      formModel.value = {};
      blocks.assignAll(blocksList);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 数据失败');
      errorText.value = '请求失败，请稍后重试';
      pveStatus.value = null;
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
      final body = ProxmoxVEBackupConverter.toConfigBody(formModel.value);
      _log.info('保存 ProxmoxVEBackup 配置');
      final response = await _apiClient.put<dynamic>(
        _basePath,
        body,
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '保存失败 (HTTP $status)';
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
    ToastUtil.error('暂为实现, 有需要请提供接口参数');
  }
}

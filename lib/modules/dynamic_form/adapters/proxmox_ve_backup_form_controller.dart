import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
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

  static const _basePath = '/api/v1/plugin/ProxmoxVEBackup';

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
    _pollLoad();
  }

  Future<void> _pollLoad() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _loadPage(token);
    } catch (_) {}
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
      );
      formModel.value = {};
      blocks.assignAll(blocksList);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 ProxmoxVEBackup 数据失败');
      errorText.value = '请求失败，请稍后重试';
      pveStatus.value = null;
      blocks.clear();
      formModel.value = {};
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

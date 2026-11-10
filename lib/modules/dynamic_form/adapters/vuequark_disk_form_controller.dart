import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/vuequark_disk_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// VueQuarkDisk（夸克网盘存储）插件适配器。
///
/// 插件在 Web 端通过 Vue 联邦组件渲染（`render_mode = vue`），
/// App 侧按插件对外暴露的真实接口重建原生界面：
/// - GET  `/api/v1/plugin/VueQuarkDisk/config`       配置与登录状态（无 success 外壳）
/// - POST `/api/v1/plugin/VueQuarkDisk/config`       保存配置
/// - GET  `/api/v1/plugin/VueQuarkDisk/login/qrcode` 获取扫码登录二维码
/// - GET  `/api/v1/plugin/VueQuarkDisk/login/poll`   轮询扫码状态（约 3 秒一次）
/// - POST `/api/v1/plugin/VueQuarkDisk/login/logout` 退出登录
class VueQuarkDiskFormController extends GetxController
    implements PluginFormAdapter {
  VueQuarkDiskFormController({required this.formMode});

  @override
  final String pluginId = 'VueQuarkDisk';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  static const _basePath = '/api/v1/plugin/VueQuarkDisk';

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

  @override
  final RxBool actionLoading = false.obs;

  /// GET /config 返回的完整状态（配置 + 登录态 + 空间信息）
  final status = Rxn<VueQuarkDiskStatus>();

  /// 扫码登录状态
  final qrUrl = RxnString();
  final qrExpiresIn = 0.obs;
  final qrPolling = false.obs;
  final qrMessage = RxnString();

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
  ];

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'refresh') {
      await load();
      // 未登录时自动拉起新二维码
      final current = status.value;
      if (current != null && !current.loggedIn && !qrPolling.value) {
        await startQrLogin();
      }
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
      final configMap = await _fetchConfig(token);
      if (configMap == null) {
        errorText.value = '获取插件状态失败';
        blocks.clear();
        formModel.value = {};
        return;
      }
      final parsed = VueQuarkDiskStatus.fromJson(configMap);
      status.value = parsed;
      formModel.value = parsed.toFormModel();
      blocks.assignAll(VueQuarkDiskConverter.convertForm(status: parsed));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 VueQuarkDisk 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
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
      final body = VueQuarkDiskConverter.toConfigBody(formModel.value);
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
        errorText.value = map?['message']?.toString() ?? '保存失败';
        return false;
      }
      // 用响应 data 回填，保持登录态/空间信息同步
      final data = map?['data'];
      if (data is Map) {
        final parsed = VueQuarkDiskStatus.fromJson(
          Map<String, dynamic>.from(data),
        );
        status.value = parsed;
        formModel.value = parsed.toFormModel();
        blocks.assignAll(VueQuarkDiskConverter.convertForm(status: parsed));
      }
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 VueQuarkDisk 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取扫码登录二维码
  Future<bool> startQrLogin() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    stopQrPolling();
    try {
      final response = await _apiClient.get<dynamic>(
        '$_basePath/login/qrcode',
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) {
        qrMessage.value = '获取二维码失败 (HTTP ${response.statusCode})';
        return false;
      }
      final map = _extractMap(response.data);
      if (map == null || map['success'] != true) {
        qrMessage.value = map?['message']?.toString() ?? '获取二维码失败';
        return false;
      }
      qrUrl.value = map['qr_url']?.toString();
      qrExpiresIn.value = _intOf(map['expires_in']);
      qrMessage.value = null;
      _startPolling();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取夸克登录二维码失败');
      qrMessage.value = '获取二维码失败，请稍后重试';
      return false;
    }
  }

  /// 启动扫码状态轮询（3 秒一次），成功后自动启用插件并刷新
  void _startPolling() {
    stopQrPolling();
    qrPolling.value = true;
    _schedulePoll();
  }

  Timer? _pollTimer;

  void _schedulePoll() {
    _pollTimer = Timer(const Duration(seconds: 3), () async {
      if (!qrPolling.value) return;
      final token = _getToken();
      if (token == null || token.isEmpty) {
        stopQrPolling();
        return;
      }
      try {
        final response = await _apiClient.get<dynamic>(
          '$_basePath/login/poll',
          token: token,
        );
        final map = _extractMap(response.data);
        if (!qrPolling.value) return;
        final success = map?['success'] == true;
        final waiting = map?['waiting'] == true;
        final message = map?['message']?.toString();
        if (success) {
          qrMessage.value = message ?? '登录成功';
          stopQrPolling();
          // 登录成功后自动启用插件，再刷新状态（与 Web 端行为一致）
          await _autoEnable(token);
          await load();
          return;
        }
        if (waiting) {
          if (qrExpiresIn.value > 0) {
            qrExpiresIn.value =
                (qrExpiresIn.value - 3).clamp(0, qrExpiresIn.value);
          }
          if (qrExpiresIn.value <= 0) {
            qrMessage.value = '二维码已过期，正在重新获取…';
            stopQrPolling();
            await startQrLogin();
            return;
          }
          _schedulePoll();
          return;
        }
        // 明确失败（二维码过期/登录失败）
        qrMessage.value = message ?? '登录失败';
        stopQrPolling();
      } catch (e) {
        if (qrPolling.value) _schedulePoll();
      }
    });
  }

  Future<void> _autoEnable(String token) async {
    try {
      await _apiClient.postJson<dynamic>(
        '$_basePath/config',
        const {'enabled': true},
        token: token,
      );
    } catch (_) {
      // 忽略：仅影响自动启用
    }
  }

  void stopQrPolling() {
    qrPolling.value = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 退出登录
  Future<bool> logout() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    actionLoading.value = true;
    try {
      final response = await _apiClient.postJson<dynamic>(
        '$_basePath/login/logout',
        const <String, dynamic>{},
        token: token,
      );
      final map = _extractMap(response.data);
      final success = (response.statusCode ?? 0) < 400 &&
          map?['success'] != false;
      if (success) {
        qrUrl.value = null;
        stopQrPolling();
        await load();
      } else {
        errorText.value = map?['message']?.toString() ?? '退出登录失败';
      }
      return success;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '夸克网盘退出登录失败');
      errorText.value = '退出登录失败，请稍后重试';
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _fetchConfig(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$_basePath/config',
      token: token,
    );
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

  static int _intOf(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  @override
  void onClose() {
    stopQrPolling();
    super.onClose();
  }
}

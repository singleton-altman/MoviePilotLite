import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/random_pic_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/random_pic_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// RandomPic（随机图床API）插件适配器。
///
/// 插件在 Web 端通过 Vue 联邦组件渲染（`render_mode = vue`），
/// App 侧按插件对外暴露的真实接口重建原生界面：
/// - GET  `/api/v1/plugin/RandomPic/status`   运行状态与统计
/// - GET  `/api/v1/plugin/RandomPic/config`   配置（含默认目录）
/// - POST `/api/v1/plugin/RandomPic/config`   保存配置
/// - GET  `/api/v1/plugin/RandomPic/preview`  随机预览图（图片二进制）
/// - POST `/api/v1/plugin/RandomPic/preview/save` 将预览图保存到服务器本地
class RandomPicFormController extends GetxController
    implements PluginFormAdapter {
  RandomPicFormController({required this.formMode});

  @override
  final String pluginId = 'RandomPic';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  static const _basePath = '/api/v1/plugin/RandomPic';

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

  /// 展示页依赖的实时状态
  final status = Rxn<RandomPicStatus>();

  /// 当前配置（保存与启停都会以它为基准，避免漏字段被服务端清空）
  final config = Rxn<RandomPicConfig>();

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
    if (type == 'refresh') await load();
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

      if (formMode) {
        final statusMap = await _fetchStatus(token);
        if (statusMap != null) {
          status.value = RandomPicStatus.fromJson(statusMap);
        }
        final configMap = await _fetchConfig(token);
        if (configMap == null) {
          errorText.value = '获取插件配置失败';
          blocks.clear();
          formModel.value = {};
          return;
        }
        final parsed = RandomPicConfig.fromJson(configMap);
        config.value = parsed;
        formModel.value = parsed.toFormModel();
        blocks.assignAll(RandomPicConverter.convertForm(config: parsed));
        return;
      }

      final statusMap = await _fetchStatus(token);
      if (statusMap == null) {
        errorText.value = '获取插件状态失败';
        blocks.clear();
        return;
      }
      final parsed = RandomPicStatus.fromJson(statusMap);
      status.value = parsed;
      blocks.assignAll(RandomPicConverter.convertPage(status: parsed));
      formModel.value = {};
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RandomPic 数据失败');
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
      final body = RandomPicConverter.toConfigBody(formModel.value);
      final result = await _postConfig(body, token);
      if (result != null && result.success) {
        await load();
        return true;
      }
      errorText.value = result?.message ?? '保存失败';
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 RandomPic 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 启用/禁用：以完整配置为基准提交，避免服务端把未传字段写成空值。
  Future<bool> setEnabled(bool enabled) async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    actionLoading.value = true;
    errorText.value = null;
    try {
      final baseConfig =
          config.value ??
          RandomPicConfig.fromJson(await _fetchConfig(token) ?? const {});
      final result = await _postConfig(
        baseConfig.copyWith(enable: enabled).toRequestBody(),
        token,
      );
      if (result != null && result.success) {
        config.value = baseConfig.copyWith(enable: enabled);
        await load();
        return true;
      }
      errorText.value = result?.message ?? (enabled ? '启用失败' : '禁用失败');
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '切换 RandomPic 状态失败');
      errorText.value = '操作失败，请稍后重试';
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  /// 随机预览图地址。[type] 取 auto / pc / mobile
  String previewUrl(String type) {
    final base = (_apiClient.baseUrl ?? '').replaceAll(RegExp(r'/+$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final typeQuery = type == 'auto' ? '' : '&type=$type';
    return '$base$_basePath/preview?t=$stamp$typeQuery';
  }

  Future<Uint8List?> fetchPreview(String type) async {
    return _apiClient.fetchResourceProxyImage(previewUrl(type));
  }

  /// 把当前预览图保存到服务器本地目录（插件会按横竖屏自动分类）。
  Future<RandomPicActionResult> savePreviewToLocal(Uint8List bytes) async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      return const RandomPicActionResult(false, '请先登录');
    }
    try {
      final formData = dio.FormData();
      formData.files.add(
        MapEntry(
          'file',
          dio.MultipartFile.fromBytes(bytes, filename: 'preview-image.jpg'),
        ),
      );
      final response = await _apiClient.postMultipart<dynamic>(
        '$_basePath/preview/save',
        formData,
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) {
        return RandomPicActionResult(false, '保存失败 (HTTP ${response.statusCode})');
      }
      final map = _extractMap(response.data);
      final success = map?['success'] != false;
      final message = map?['msg']?.toString() ?? '已保存到本地目录';
      return RandomPicActionResult(success, message);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存预览图到本地失败');
      return const RandomPicActionResult(false, '保存到本地目录失败');
    }
  }

  Future<Map<String, dynamic>?> _fetchStatus(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$_basePath/status',
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>?> _fetchConfig(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$_basePath/config',
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Future<RandomPicActionResult?> _postConfig(
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _apiClient.postJson<dynamic>(
      '$_basePath/config',
      body,
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) {
      final map = _extractMap(response.data);
      return RandomPicActionResult(
        false,
        map?['detail']?.toString() ??
            map?['message']?.toString() ??
            map?['msg']?.toString() ??
            'HTTP ${response.statusCode}',
      );
    }
    final map = _extractMap(response.data);
    if (map == null) return const RandomPicActionResult(true, '保存成功');
    return RandomPicActionResult(
      map['success'] != false,
      map['msg']?.toString() ??
          map['message']?.toString() ??
          '保存成功',
    );
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

/// 插件接口的轻量结果：success + 提示文案
class RandomPicActionResult {
  const RandomPicActionResult(this.success, this.message);

  final bool success;
  final String message;
}

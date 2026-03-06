import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/trash_converter/trash_clean_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// TrashClean 插件适配器：自定义多接口请求与 FormBlock 转换
class TrashCleanFormController extends GetxController
    implements PluginFormAdapterWithClean {
  TrashCleanFormController({required this.formMode});

  @override
  final String pluginId = 'TrashClean';

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

  @override
  RxBool? get actionLoading => null;

  static const _basePath = '/api/v1/plugin/TrashClean';

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
        await _loadForm(token);
      } else {
        await _loadPage(token);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 TrashClean 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadForm(String token) async {
    final resp = await _apiClient.get<dynamic>(
      '$_basePath/status',
      token: token,
    );
    final statusMap = _extractMap(resp.data);
    if (statusMap == null) {
      errorText.value = '数据格式错误';
      blocks.clear();
      formModel.value = {};
      return;
    }
    final (blocksList, model) = TrashCleanConverter.convertForm(
      status: statusMap,
    );
    formModel.value = model;
    blocks.assignAll(blocksList);
  }

  Future<void> _loadPage(String token) async {
    final results = await Future.wait([
      _apiClient.get<dynamic>('$_basePath/status', token: token),
      _apiClient.get<dynamic>('$_basePath/latest_clean_result', token: token),
      _apiClient.get<dynamic>('$_basePath/clean_progress', token: token),
      _apiClient.get<dynamic>('$_basePath/stats', token: token),
      _apiClient.get<dynamic>('$_basePath/downloaders', token: token),
    ]);

    final statusMap = _extractMap(results[0].data) ?? {};
    final cleanResultMap = _extractMap(results[1].data) ?? {};
    final progressMap = _extractMap(results[2].data) ?? {};
    final statsData = results[3].data;
    final statsList = statsData is List
        ? statsData.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final downloadersData = results[4].data;
    final downloadersList = downloadersData is List
        ? downloadersData.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final blocksList = TrashCleanConverter.convertPage(
      status: statusMap,
      latestCleanResult: cleanResultMap,
      cleanProgress: progressMap,
      stats: statsList,
      downloaders: downloadersList,
    );
    formModel.value = {};
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
      final body = TrashCleanConverter.toConfigBody(formModel.value);
      _log.info('保存 TrashClean 配置: $body');
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
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 TrashClean 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<Map<String, dynamic>?> triggerClean() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _apiClient.post<dynamic>(
        '$_basePath/clean',
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) return null;
      return _extractMap(response.data);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'TrashClean 清理失败');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCleanProgress() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _apiClient.get<dynamic>(
        '$_basePath/clean_progress',
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) return null;
      return _extractMap(response.data);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 TrashClean 清理进度失败');
      return null;
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

  @override
  bool get supportsSave => true;

  @override
  bool get supportsFormEntry => true;

  @override
  List<AppBarActionItem>? get actionList => null;

  @override
  Future<void> onAppBarAction(String type) async {
    // TODO: implement onAppBarAction
  }
}

import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/random_pic_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// RandomPic 插件适配器：随机图床状态与配置
class RandomPicFormController extends GetxController
    implements PluginFormAdapter {
  RandomPicFormController({required this.formMode});

  @override
  final String pluginId = 'RandomPic';

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

  static const _basePath = '/api/v1/plugin/RandomPic';

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

      if (formMode) {
        final (blocksList, model) = RandomPicConverter.convertForm(
          status: statusMap,
        );
        formModel.value = model;
        blocks.assignAll(blocksList);
      } else {
        final blocksList = RandomPicConverter.convertPage(status: statusMap);
        formModel.value = {};
        blocks.assignAll(blocksList);
      }
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
      _log.info('保存 RandomPic 配置: $body');
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
      _log.handle(e, stackTrace: st, message: '保存 RandomPic 配置失败');
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

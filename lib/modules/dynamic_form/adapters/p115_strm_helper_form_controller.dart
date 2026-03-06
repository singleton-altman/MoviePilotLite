import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/p115_strm_helper_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// P115StrmHelper 插件适配器：115 转流助手状态与配置
class P115StrmHelperFormController extends GetxController
    implements PluginFormAdapter {
  P115StrmHelperFormController({required this.formMode});

  @override
  final String pluginId = 'P115StrmHelper';

  final bool formMode;

  @override
  bool get supportsSave => false;

  @override
  bool get supportsFormEntry => false;

  @override
  List<AppBarActionItem> get actionList => [
    AppBarActionItem(type: 'full_sync', label: '全量同步', iconName: 'mdi-sync'),
    AppBarActionItem(
      type: 'full_sync_db',
      label: '数据库同步',
      iconName: 'mdi-database',
    ),
  ];

  @override
  Future<void> onAppBarAction(String type) async {
    try {
      final resp = await _apiClient.post<dynamic>('$_basePath/full_sync');
      final status = resp.statusCode ?? 0;
      if (status >= 400) {
        ToastUtil.error('全量同步失败');
        return;
      }
      ToastUtil.success('全量同步成功');
    } catch (e) {
      ToastUtil.error('全量同步失败: $e');
    }
  }

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

  static const _basePath = '/api/v1/plugin/P115StrmHelper';

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

      final resp = await _apiClient.get<dynamic>('$_basePath/get_config');
      final configMap = _extractMap(resp.data);
      if (configMap == null) {
        errorText.value = '数据格式错误';
        blocks.clear();
        formModel.value = {};
        return;
      }

      final results = await Future.wait([
        _apiClient.get<dynamic>('$_basePath/get_status', token: token),
        _apiClient.get<dynamic>('$_basePath/user_storage_status', token: token),
      ]);
      final statusResp = _extractMap(results[0].data);
      final userStorageResp = _extractMap(results[1].data);

      if (statusResp == null) {
        errorText.value = '获取插件状态失败';
        blocks.clear();
        formModel.value = {};
        return;
      }

      final statusData = statusResp['data'];
      final status = statusData is Map<String, dynamic>
          ? statusData
          : (statusData is Map
                ? Map<String, dynamic>.from(statusData)
                : <String, dynamic>{});

      Map<String, dynamic>? userStorage;
      if (userStorageResp != null && userStorageResp['success'] == true) {
        userStorage = userStorageResp;
      }

      final blocksList = P115StrmHelperConverter.convertPage(
        status: status,
        userStorage: userStorage,
        config: configMap,
      );
      formModel.value = {};
      blocks.assignAll(blocksList);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 P115StrmHelper 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<bool> save() async {
    return false;
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

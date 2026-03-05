import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/form_block_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 动态表单控制器：可插件化入口，根据 render_mode 分流 vuetify/vue 渲染
class DynamicFormController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  /// 接口路径（GET 拉取），如 /api/v1/plugin/page/xxx
  late final String apiPath;

  /// 接口路径（PUT 保存），仅配置表单需要，如 /api/v1/plugin/xxx
  String? apiSavePath;

  /// 页面标题，可选，用于 AppBar
  String? pageTitle;

  final blocks = <FormBlock>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final saveSuccess = false.obs;
  final formMode = false.obs;
  String? pluginId;

  /// page 模式下的原始 FormNode 列表，供 VuetifyRenderer 直接渲染
  final pageNodes = <FormNode>[].obs;

  /// 配置表单当前数据（key 为 props.model），保存时 PUT 此 Map
  final _formModel = Rx<Map<String, dynamic>>({});

  /// vue 模式下注入的插件适配器
  PluginFormAdapter? _pluginAdapter;

  /// 当前使用的 formModel（vue 模式时指向 adapter 的 formModel）
  Rx<Map<String, dynamic>> get formModel =>
      _pluginAdapter?.formModel ?? _formModel;

  /// vue 模式下的插件适配器，供页面判断是否展示插件专属操作
  PluginFormAdapter? get pluginAdapter => _pluginAdapter;

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  /// 初始化：接口路径必填，标题可选
  void init(
    String path, {
    String? title,
    bool formMode = false,
    String? pluginId,
  }) {
    apiPath = path;
    pageTitle = title;
    this.formMode.value = formMode;
    this.pluginId = pluginId;
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  /// 根据字段名取当前值（配置表单用）
  dynamic getValue(String? name) {
    if (name == null || name.isEmpty) return null;
    return formModel.value[name];
  }

  static bool _boolFromDynamic(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return false;
  }

  /// 根据字段名取 bool（用于 Switch）
  bool getBoolValue(String? name) => _boolFromDynamic(getValue(name));

  /// 更新字段值（配置表单用）
  void updateField(String? name, dynamic value) {
    if (name == null || name.isEmpty) return;
    final target = _pluginAdapter?.formModel ?? _formModel;
    target.value = Map<String, dynamic>.from(target.value)..[name] = value;
  }

  /// 是否显示保存按钮（有 formModel 且有 key 时）
  bool get hasFormModel => formModel.value.isNotEmpty;

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    saveSuccess.value = false;
    _pluginAdapter = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        blocks.clear();
        pageNodes.clear();
        _formModel.value = {};
        return;
      }

      final response = await _apiClient.get<dynamic>(apiPath, token: token);
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        blocks.clear();
        pageNodes.clear();
        _formModel.value = {};
        return;
      }
      final data = response.data;
      final map = _extractMap(data);
      if (map == null) {
        errorText.value = '数据格式错误';
        blocks.clear();
        pageNodes.clear();
        _formModel.value = {};
        return;
      }
      final parsed = DynamicFormResponse.fromJson(
        Map<String, dynamic>.from(map),
      );
      final renderMode = parsed.render_mode?.toLowerCase().trim();

      if (renderMode == 'vue' &&
          pluginId != null &&
          PluginFormAdapterRegistry.hasAdapter(pluginId!)) {
        await _loadViaAdapter();
        return;
      }

      _loadVuetify(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取动态表单失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      pageNodes.clear();
      _formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadViaAdapter() async {
    final adapter = PluginFormAdapterRegistry.createAdapter(
      pluginId!,
      formMode: formMode.value,
    );
    if (adapter == null) {
      errorText.value = '插件适配器未注册';
      blocks.clear();
      pageNodes.clear();
      _formModel.value = {};
      return;
    }
    _pluginAdapter = adapter;
    await _pluginAdapter!.load();
    errorText.value = _pluginAdapter!.errorText.value;
    blocks.assignAll(_pluginAdapter!.blocks);
    pageNodes.assignAll(_pluginAdapter!.pageNodes);
    _formModel.value = {};
  }

  void _loadVuetify(DynamicFormResponse parsed) {
    if (parsed.model != null && parsed.model!.isNotEmpty) {
      _formModel.value = Map<String, dynamic>.from(parsed.model!);
    } else {
      _formModel.value = {};
    }
    if (!formMode.value && parsed.page.isNotEmpty) {
      pageNodes.assignAll(parsed.page);
      blocks.clear();
    } else {
      pageNodes.clear();
    }
    final blocksList = FormBlockConverter.convert(parsed);
    blocks.assignAll(blocksList);
  }

  /// 保存配置
  Future<bool> save() async {
    if (formModel.value.isEmpty) return false;
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }

    if (_pluginAdapter != null) {
      final ok = await _pluginAdapter!.save();
      if (ok) saveSuccess.value = true;
      return ok;
    }

    final savePath = apiSavePath;
    if (savePath == null || savePath.isEmpty) return false;
    isLoading.value = true;
    errorText.value = null;
    saveSuccess.value = false;
    try {
      _log.info('保存配置: $savePath ${formModel.value}');
      final response = await _apiClient.put(
        savePath,
        formModel.value,
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '保存失败 (HTTP $status)';
        return false;
      }
      saveSuccess.value = true;
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 立即清理（仅 PluginFormAdapterWithClean 支持）
  Future<Map<String, dynamic>?> triggerClean() async {
    final adapter = _pluginAdapter;
    if (adapter is PluginFormAdapterWithClean) {
      return adapter.triggerClean();
    }
    return null;
  }

  /// 获取清理进度（仅 PluginFormAdapterWithClean 支持）
  Future<Map<String, dynamic>?> fetchCleanProgress() async {
    final adapter = _pluginAdapter;
    if (adapter is PluginFormAdapterWithClean) {
      return adapter.fetchCleanProgress();
    }
    return null;
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

  final formModePlugins = [
    'AutoSignIn',
    'TrashClean',
    'ProxmoxVEBackup',
    'RandomPic',
    'MonitorPaths',
    'SiteStatistic',
    'MedalWall',
    'nexusinvitee',
  ];
  bool get isFormMode => formModePlugins.contains(pluginId);
}

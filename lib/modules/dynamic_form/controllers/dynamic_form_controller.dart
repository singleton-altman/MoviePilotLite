import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/form_block_converter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_component_subset.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/jpush_service.dart';

class ApplyPushAliasOutcome {
  const ApplyPushAliasOutcome._({this.appliedToken, this.errorMessage});

  final String? appliedToken;
  final String? errorMessage;

  bool get isSuccess => appliedToken != null;

  factory ApplyPushAliasOutcome.ok(String token) =>
      ApplyPushAliasOutcome._(appliedToken: token);

  factory ApplyPushAliasOutcome.err(String message) {
    final t = message.trim();
    return ApplyPushAliasOutcome._(errorMessage: t.isEmpty ? '未知错误' : t);
  }
}

/// 动态表单控制器：可插件化入口，根据 render_mode 分流 vuetify/vue 渲染
class DynamicFormController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _jpushService = Get.find<JPushService>();
  final _log = Get.find<AppLog>();
  static const _appLitePushFallbackPluginId = 'AppPushMsg';

  /// 插件可能以克隆实例的 id 安装，测试路径必须跟随当前表单的插件标识。
  String get _appLitePushRunPath {
    final key = pluginId?.trim();
    final resolved = key == null || key.isEmpty
        ? _appLitePushFallbackPluginId
        : key;
    return '/api/v1/plugin/$resolved/run';
  }

  static final _appLitePushApiKeyPattern = RegExp(
    r'''apikey\s*:\s*['"]([^'"]+)['"]''',
  );

  /// 接口路径（GET 拉取），如 /api/v1/plugin/page/xxx
  late final String apiPath;

  /// 接口路径（PUT 保存），仅配置表单需要，如 /api/v1/plugin/xxx
  String? apiSavePath;

  /// 页面标题，可选，用于 AppBar
  String? pageTitle;

  final blocks = <FormBlock>[].obs;
  final isLoading = false.obs;
  final isApplyingPushAlias = false.obs;
  final isTestingAppLitePush = false.obs;
  final errorText = RxnString();
  final appLitePushLastTestText = RxnString();
  final saveSuccess = false.obs;
  final formMode = false.obs;
  String? pluginId;

  /// 服务端声明的渲染模式(vue/vuetify)。
  /// 适配策略:注册了原生适配器的特殊插件 ID 优先走适配器;
  /// vuetify 模式走通用 Vuetify 渲染;其余 vue 插件留待逐插件适配,
  /// 在此之前引导用户到 Web 端配置。
  final serverRenderMode = RxnString();

  /// 配置表单(conf)中移动端通用渲染暂不支持、会被丢弃的组件名。
  /// 仅提示,不阻断:这些字段的值保存在 model 中不会被破坏。
  final unsupportedFormComponents = RxList<String>();

  /// page 模式下的原始 FormNode 列表，供 VuetifyRenderer 直接渲染
  final pageNodes = <FormNode>[].obs;

  /// 配置表单当前数据（key 为 props.model），保存时 PUT 此 Map
  final _formModel = Rx<Map<String, dynamic>>({});

  /// vue 模式下注入的插件适配器
  PluginFormAdapter? _pluginAdapter;
  String? _appLitePushMoviePilotApiKey;

  /// 当前使用的 formModel（vue 模式时指向 adapter 的 formModel）
  Rx<Map<String, dynamic>> get formModel =>
      _pluginAdapter?.formModel ?? _formModel;

  /// 当前使用的 blocks（vue 模式时使用 adapter 的 blocks，以便轮询更新能触发 UI 刷新）
  RxList<FormBlock> get effectiveBlocks => _pluginAdapter?.blocks ?? blocks;

  /// 当前使用的 pageNodes（vue 模式时使用 adapter 的 pageNodes）
  RxList<FormNode> get effectivePageNodes =>
      _pluginAdapter?.pageNodes ?? pageNodes;

  /// vue 模式下的插件适配器，供页面判断是否展示插件专属操作
  PluginFormAdapter? get pluginAdapter => _pluginAdapter;

  /// 服务端声明 vue 模式且没有注册原生适配器:App 当前无法渲染该插件界面。
  bool get isUnsupportedVuePlugin =>
      serverRenderMode.value == 'vue' && _pluginAdapter == null;

  /// 服务器 Web 端地址,用于 vue 插件引导用户到 Web 端配置。
  String? get serverWebUrl => _appService.baseUrl;

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

  List<String> get unsupportedRawPageComponents =>
      VuetifyComponentSubset.collectUnsupportedRawComponents(
        effectivePageNodes,
      );

  bool get canUseRawPageRenderer => unsupportedRawPageComponents.isEmpty;

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    saveSuccess.value = false;
    isTestingAppLitePush.value = false;
    appLitePushLastTestText.value = null;
    _appLitePushMoviePilotApiKey = null;
    _pluginAdapter = null;
    serverRenderMode.value = null;
    unsupportedFormComponents.clear();
    if (isAppLitePushPlugin) {
      formMode.value = true;
    }
    final pluginKey = pluginId?.trim();
    if (isAppLitePushPlugin && pluginKey != null && pluginKey.isNotEmpty) {
      apiSavePath ??= '/api/v1/plugin/$pluginKey';
    }
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        blocks.clear();
        pageNodes.clear();
        _formModel.value = {};
        return;
      }

      if (pluginKey != null &&
          pluginKey.isNotEmpty &&
          PluginFormAdapterRegistry.hasAdapter(pluginKey) &&
          !isAppLitePushPlugin) {
        await _loadViaAdapter();
        _syncSpecialPluginState();
        return;
      }

      final fetchPath =
          isAppLitePushPlugin && pluginKey != null && pluginKey.isNotEmpty
          ? '/api/v1/plugin/form/$pluginKey'
          : apiPath;
      final response = await _apiClient.get<dynamic>(fetchPath, token: token);
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
      final parsed = DynamicFormResponse.fromJson(_normalizeFormPayload(map));
      serverRenderMode.value = parsed.render_mode?.toLowerCase().trim();
      if (isAppLitePushPlugin) {
        _appLitePushMoviePilotApiKey = _extractAppLitePushMoviePilotApiKey(
          parsed,
        );
      }
      final renderMode = parsed.render_mode?.toLowerCase().trim();

      if (renderMode == 'vue' &&
          pluginId != null &&
          PluginFormAdapterRegistry.hasAdapter(pluginId!)) {
        await _loadViaAdapter();
        _syncSpecialPluginState();
        return;
      }

      _loadVuetify(parsed);
      _syncSpecialPluginState();
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
    // 表单块会静默丢弃子集外的输入组件,这里收集并提示用户到 Web 端配置;
    // 对应字段的值仍在 model 中,保存不会破坏已存配置。
    unsupportedFormComponents.assignAll(
      VuetifyComponentSubset.collectUnsupportedRawComponents(parsed.conf),
    );
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

  /// 宽容归一化 conf/page:个别插件不按 List[dict] 约定返回时,
  /// 单个 dict 包成列表,列表里的非 Map 条目丢弃,避免整个表单解析失败。
  /// (生成的反序列化对 conf/page 是强类型转换,这里必须先行归一。)
  Map<String, dynamic> _normalizeFormPayload(Map<String, dynamic> map) {
    Object? normalize(Object? raw) {
      if (raw is Map) return [Map<String, dynamic>.from(raw)];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      return raw;
    }

    return Map<String, dynamic>.from(map)
      ..['conf'] = normalize(map['conf'])
      ..['page'] = normalize(map['page']);
  }

  final formModePlugins = [
    'AutoSignIn',
    'TrashClean',
    'ProxmoxVEBackup',
    'P115StrmHelper',
    'SubtitleManualUpload',
    'RandomPic',
    'MonitorPaths',
    'SiteStatistic',
    'MedalWall',
    'nexusinvitee',
  ];
  bool get isFormMode => formModePlugins.contains(pluginId);

  String get normalizedPluginId => pluginId?.trim().toLowerCase() ?? '';

  bool get isAppLitePushPlugin =>
      normalizedPluginId == 'applitepush' ||
      normalizedPluginId == 'apppushmsg' ||
      normalizedPluginId == 'applitepushplugin';

  bool get showApplyPushAliasAction => isAppLitePushPlugin;

  String get appLitePushResultText =>
      appLitePushLastTestText.value?.trim().isNotEmpty == true
      ? appLitePushLastTestText.value!.trim()
      : '最近一次测试结果：暂无记录';

  void _syncSpecialPluginState() {
    if (!isAppLitePushPlugin) return;
    final lastTestText = formModel.value['last_test_text']?.toString().trim();
    if (lastTestText != null && lastTestText.isNotEmpty) {
      appLitePushLastTestText.value = lastTestText;
    }
  }

  String _formatAppLitePushTestResult(bool success, String message) {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final time =
        '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)} '
        '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
    final normalizedMessage = message.trim().isEmpty ? '无返回信息' : message;
    return '最近一次测试结果：${success ? '成功' : '失败'} | 时间：$time | 返回：$normalizedMessage';
  }

  String? _extractResponseMessage(dynamic data) {
    final map = _extractMap(data);
    if (map != null) {
      for (final key in const ['msg', 'message', 'detail']) {
        final value = map[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  String? _extractAppLitePushMoviePilotApiKey(DynamicFormResponse parsed) {
    for (final node in [...parsed.conf, ...parsed.page]) {
      final value = _extractAppLitePushMoviePilotApiKeyFromNode(node);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractAppLitePushMoviePilotApiKeyFromNode(FormNode node) {
    final value = _extractAppLitePushMoviePilotApiKeyFromValue(node.events);
    if (value != null && value.isNotEmpty) return value;

    final propsValue = _extractAppLitePushMoviePilotApiKeyFromValue(node.props);
    if (propsValue != null && propsValue.isNotEmpty) return propsValue;

    for (final child in node.content) {
      final childValue = _extractAppLitePushMoviePilotApiKeyFromNode(child);
      if (childValue != null && childValue.isNotEmpty) return childValue;
    }
    return null;
  }

  String? _extractAppLitePushMoviePilotApiKeyFromValue(dynamic value) {
    if (value is Map) {
      final direct = value['apikey']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      for (final entryValue in value.values) {
        final nested = _extractAppLitePushMoviePilotApiKeyFromValue(entryValue);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    } else if (value is Iterable) {
      for (final item in value) {
        final nested = _extractAppLitePushMoviePilotApiKeyFromValue(item);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    } else if (value is String) {
      final match = _appLitePushApiKeyPattern.firstMatch(value);
      final matched = match?.group(1)?.trim();
      if (matched != null && matched.isNotEmpty) return matched;
    }
    return null;
  }

  Future<String?> _getAppLitePushMoviePilotApiKey(String token) async {
    final cached = _appLitePushMoviePilotApiKey?.trim();
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/system/env',
        token: token,
        skipUnauthorizedHandling: true,
      );
      final status = response.statusCode ?? 0;
      final body = response.data;
      if (status < 200 || status >= 300 || body == null) return null;
      final parsed = SystemEnvResponse.fromJson(body);
      final apiKey = parsed.data?.apiToken?.trim();
      if (parsed.success && apiKey != null && apiKey.isNotEmpty) {
        _appLitePushMoviePilotApiKey = apiKey;
        return apiKey;
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 MoviePilot 接口令牌失败');
    }
    return null;
  }

  Future<bool> runAppLitePushTest() async {
    if (!isAppLitePushPlugin || isTestingAppLitePush.value) return false;

    final pushToken = _configuredPushToken();
    final pushKey = formModel.value['apikey']?.toString().trim();
    if (pushToken == null ||
        pushToken.isEmpty ||
        pushKey == null ||
        pushKey.isEmpty) {
      appLitePushLastTestText.value = _formatAppLitePushTestResult(
        false,
        '请先填写并保存 Push Key 和 App Push Token',
      );
      return false;
    }

    final token = _getToken();
    if (token == null || token.isEmpty) {
      appLitePushLastTestText.value = _formatAppLitePushTestResult(
        false,
        '请先登录',
      );
      return false;
    }

    isTestingAppLitePush.value = true;
    try {
      final moviePilotApiKey = await _getAppLitePushMoviePilotApiKey(token);
      if (moviePilotApiKey == null || moviePilotApiKey.isEmpty) {
        appLitePushLastTestText.value = _formatAppLitePushTestResult(
          false,
          '未获取到 MoviePilot 接口令牌',
        );
        return false;
      }

      final cookieHeader =
          await _apiClient.getCookieHeader() ?? _appService.cookie;
      final headers = cookieHeader != null && cookieHeader.isNotEmpty
          ? <String, dynamic>{'cookie': cookieHeader}
          : null;
      final response = await _apiClient.get<dynamic>(
        _appLitePushRunPath,
        queryParameters: <String, dynamic>{'apikey': moviePilotApiKey},
        token: token,
        headers: headers,
        skipUnauthorizedHandling: true,
      );
      final status = response.statusCode ?? 0;
      final responseMap = _extractMap(response.data);
      final responseCode = responseMap?['code'];
      final explicitSuccess = responseMap?['success'];
      final success =
          status < 400 &&
          (explicitSuccess is bool
              ? explicitSuccess
              : responseCode == null ||
                    (responseCode is num && responseCode.toInt() == 0) ||
                    responseCode.toString() == '0');
      final message =
          _extractResponseMessage(response.data) ??
          (success ? '消息发送成功' : '操作失败');
      appLitePushLastTestText.value = _formatAppLitePushTestResult(
        success,
        message,
      );
      return success;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '发送 AppLitePush 测试消息失败');
      final message = e.toString().trim().isEmpty ? '请求失败，请稍后重试' : '$e';
      appLitePushLastTestText.value = _formatAppLitePushTestResult(
        false,
        message,
      );
      return false;
    } finally {
      isTestingAppLitePush.value = false;
    }
  }

  String? _configuredPushToken() {
    final data = formModel.value;
    if (data.isEmpty) return null;

    const exactKeys = ['token', 'pushtoken', 'push_token', 'pushToken'];
    for (final key in exactKeys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    for (final entry in data.entries) {
      final normalizedKey = entry.key
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toLowerCase();
      if (normalizedKey == 'pushtoken') {
        final value = entry.value?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  Future<ApplyPushAliasOutcome> applyCurrentPushTokenAsAlias() async {
    if (!showApplyPushAliasAction) {
      return ApplyPushAliasOutcome.err('当前插件不支持此操作');
    }
    if (isApplyingPushAlias.value) {
      return ApplyPushAliasOutcome.err('正在应用中，请稍候');
    }

    isApplyingPushAlias.value = true;
    try {
      final pushToken = _configuredPushToken();
      if (pushToken == null || pushToken.isEmpty) {
        return ApplyPushAliasOutcome.err(
          '表单中未找到 Token，请填写 token、push_token、pushToken 等字段',
        );
      }

      final jResult = await _jpushService.setAlias(pushToken);
      if (!jResult.ok) {
        return ApplyPushAliasOutcome.err(
          jResult.errorMessage ?? '设置 JPush Alias 失败',
        );
      }
      return ApplyPushAliasOutcome.ok(pushToken);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '应用 App Push Token 失败');
      final msg = e.toString().trim();
      return ApplyPushAliasOutcome.err(msg.isEmpty ? '应用失败' : msg);
    } finally {
      isApplyingPushAlias.value = false;
    }
  }
}

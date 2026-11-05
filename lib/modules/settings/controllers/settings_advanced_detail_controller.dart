import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_advanced_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_field_state.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_manager.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/llm_api_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

/// 高级设置详情控制器：加载系统环境数据，支持编辑保存
class SettingsAdvancedDetailController extends GetxController {
  final _apiClient = Get.find<ApiClient>();

  final envData = Rxn<SystemEnvData>();
  final isLoading = false.obs;
  final errorText = RxnString();
  final isUpdating = false.obs;
  final isEditing = true.obs;

  final imageUtil = Get.find<ImageUtil>();

  late final SettingsFormManager form = SettingsFormManager(
    fields: [
      ...advancedSystemFields,
      ...advancedMediaFields,
      ...advancedNetworkFields,
      ...advancedLogFields,
      ...advancedLabFields,
    ],
  );

  final llmModelOptions = <SettingsEnumOption>[].obs;
  final _llmModelsLoaded = false.obs;
  late final _llmApi = LlmApiService(apiClient: _apiClient);

  /// 所有区块：(标题, 字段列表)
  List<(String, List<SettingsFieldConfig>)> get sections => [
    ('系统', advancedSystemFields),
    ('媒体', advancedMediaFields),
    ('网络', advancedNetworkFields),
    ('日志', advancedLogFields),
    ('实验室', advancedLabFields),
  ];

  dynamic valueFor(SettingsFieldConfig field) =>
      envData.value?.valueFor(field.envKey);

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final resp = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/system/env',
      );
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final body = resp.data;
        if (body != null) {
          final parsed = SystemEnvResponse.fromJson(body);
          if (parsed.success && parsed.data != null) {
            envData.value = parsed.data;
            imageUtil.saveGlobalCachedEnabled(
              envData.value?.globalImageCache ?? false,
            );
            form.hydrateAll((k) => envData.value?.valueFor(k));
            await _tryAutoloadLlmModels();
            return;
          }
        }
      }
      errorText.value = '加载失败';
    } catch (e) {
      errorText.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    form.dispose();
    super.onClose();
  }

  Future<bool> saveEdit() async {
    if (!form.hasPendingChanges) {
      isEditing.value = false;
      return true;
    }
    final ok = await updateEnv(form.toPatch());
    if (ok) {
      form.clearDirty();
      isEditing.value = false;
    }
    return ok;
  }

  Future<bool> updateEnv(Map<String, dynamic> changes) async {
    if (changes.isEmpty) return true;
    isUpdating.value = true;
    errorText.value = null;
    try {
      final resp = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/system/env',
        data: changes,
      );
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final body = resp.data;
        if (body != null) {
          final parsed = SystemEnvResponse.fromJson(body);
          if (parsed.success) {
            await load();
            return true;
          }
        }
      }
      errorText.value = '更新失败';
      return false;
    } catch (e) {
      errorText.value = e.toString();
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<String?> fetchLlmModels() async {
    final provider = _readString('LLM_PROVIDER');
    final apiKey = _readString('LLM_API_KEY');
    final baseUrl = _readString('LLM_BASE_URL');

    if (provider.isEmpty || apiKey.isEmpty || baseUrl.isEmpty) {
      return '请先填写 LLM 提供商 / LLM API 密钥 / LLM 基础 URL';
    }

    try {
      // v2 为 GET /llm/models,v3.1.5 为 POST /llm/manage
      // (target=provider, action=list_models),契约细节由 LlmApiService 处理,
      // 不再使用未经证实的 /system/llm-models 回退。
      final catalog = await _llmApi.listModels(
        provider: provider,
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      llmModelOptions.assignAll(
        catalog.models
            .map((m) => SettingsEnumOption(value: m.id, label: m.name))
            .toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _tryAutoloadLlmModels() async {
    if (_llmModelsLoaded.value) return;
    final provider = _readString('LLM_PROVIDER');
    final apiKey = _readString('LLM_API_KEY');
    final baseUrl = _readString('LLM_BASE_URL');
    if (provider.isEmpty || apiKey.isEmpty || baseUrl.isEmpty) return;
    final err = await fetchLlmModels();
    if (err == null || err.isEmpty) {
      _llmModelsLoaded.value = true;
    }
  }

  String _readString(String envKey) {
    final field = form.fields.firstWhereOrNull((e) => e.envKey == envKey) ??
        SettingsFieldConfig(
          label: envKey,
          envKey: envKey,
          type: SettingsFieldType.text,
        );
    final s = form.stateFor(field);
    if (s is SettingsTextFieldState) return s.controller.text.trim();
    if (s is SettingsSelectFieldState) return s.value.value.trim();
    if (s is SettingsNumberFieldState) return s.controller.text.trim();
    if (s is SettingsToggleFieldState) return s.value.value.toString();
    return '';
  }
}

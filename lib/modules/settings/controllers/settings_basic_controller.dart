import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_basic_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_manager.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_field_state.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/llm_api_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class SettingsBasicController extends GetxController {
  final _apiClient = Get.find<ApiClient>();

  final envData = Rxn<SystemEnvData>();
  final isLoading = false.obs;
  final errorText = RxnString();
  final isUpdating = false.obs;
  final isEditing = true.obs;

  final imageUtil = Get.find<ImageUtil>();

  late final SettingsFormManager form = SettingsFormManager(
    fields: [...basicFields, ...aiFields],
  );

  final llmModelOptions = <SettingsEnumOption>[].obs;
  final _llmModelsLoaded = false.obs;
  late final _llmApi = LlmApiService(apiClient: _apiClient);

  List<SettingsFieldConfig> get basicFields => basicConfigFields;
  List<SettingsFieldConfig> get aiFields => aiAssistantConfigFields;
  bool get aiAgentEnabled => envData.value?.aiAgentEnable ?? false;

  bool get hasPendingChanges => form.hasPendingChanges;

  @override
  void onInit() {
    super.onInit();
    onLoad();
  }

  onLoad() async {
    await load();
    isEditing.value = true;
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

  bool get aiSectionVisible {
    final d = envData.value;
    if (d == null) return false;
    if (!isEditing.value) return d.aiAgentEnable ?? false;
    final s = form.stateFor(
      const SettingsFieldConfig(
        label: '启用智能助手',
        envKey: 'AI_AGENT_ENABLE',
        type: SettingsFieldType.toggle,
      ),
    );
    if (s is SettingsToggleFieldState) return s.value.value;
    return d.aiAgentEnable ?? false;
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  @override
  void onClose() {
    form.dispose();
    super.onClose();
  }

  /// 仅更新指定参数，避免修改未改动的其他配置
  /// 保存成功后重新拉取完整数据，避免 POST 返回的 data 不完整导致页面空白
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
            _applyAiRecommendDefaults();
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

  dynamic valueFor(SettingsFieldConfig field) =>
      envData.value?.valueFor(field.envKey);

  bool shouldShowField(SettingsFieldConfig field) {
    final d = envData.value;
    if (d == null) return false;
    return form.shouldShow(field, (k) => d.valueFor(k));
  }

  List<SettingsFieldConfig> visibleBasicFields() =>
      basicFields.where(shouldShowField).toList();

  List<SettingsFieldConfig> visibleAiFields() =>
      aiFields.where(shouldShowField).toList();

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

  void _applyAiRecommendDefaults() {
    final maxField = aiFields.firstWhere(
      (f) => f.envKey == 'AI_RECOMMEND_MAX_ITEMS',
    );
    final v = envData.value?.valueFor(maxField.envKey);
    if (v != null) return;
    final s = form.stateFor(maxField);
    if (s is SettingsNumberFieldState) {
      s.hydrate(50);
    }
  }

  String _readString(String envKey) {
    final f = form.fields.where((e) => e.envKey == envKey).toList();
    final field = f.isNotEmpty
        ? f.first
        : SettingsFieldConfig(label: envKey, envKey: envKey, type: SettingsFieldType.text);
    final s = form.stateFor(field);
    if (s is SettingsTextFieldState) return s.controller.text.trim();
    if (s is SettingsSelectFieldState) return s.value.value.trim();
    if (s is SettingsNumberFieldState) return s.controller.text.trim();
    if (s is SettingsToggleFieldState) return s.value.value.toString();
    return '';
  }
}

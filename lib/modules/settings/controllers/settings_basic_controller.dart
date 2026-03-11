import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_basic_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class SettingsBasicController extends GetxController {
  final _apiClient = Get.find<ApiClient>();

  final envData = Rxn<SystemEnvData>();
  final isLoading = false.obs;
  final errorText = RxnString();
  final isUpdating = false.obs;
  final isEditing = false.obs;
  final pendingChanges = <String, dynamic>{}.obs;

  final imageUtil = Get.find<ImageUtil>();

  /// 编辑态下 AI 区域展开状态，切换开关时立即更新
  final aiSectionExpanded = false.obs;

  final Map<String, TextEditingController> _textControllers = {};

  List<SettingsFieldConfig> get basicFields => basicConfigFields;
  List<SettingsFieldConfig> get aiFields => aiAssistantConfigFields;
  bool get aiAgentEnabled => envData.value?.aiAgentEnable ?? false;

  bool get hasPendingChanges => pendingChanges.isNotEmpty;

  void enterEditMode() {
    pendingChanges.clear();
    aiSectionExpanded.value = aiAgentEnabled;
    _syncAllTextControllers();
    isEditing.value = true;
  }

  void cancelEdit() {
    _revertTextControllers();
    pendingChanges.clear();
    aiSectionExpanded.value = aiAgentEnabled;
    isEditing.value = false;
  }

  void exitEditMode() {
    pendingChanges.clear();
    aiSectionExpanded.value = aiAgentEnabled;
    isEditing.value = false;
  }

  Future<bool> saveEdit() async {
    if (pendingChanges.isEmpty) {
      isEditing.value = false;
      return true;
    }
    final ok = await updateEnv(Map.from(pendingChanges));
    if (ok) {
      pendingChanges.clear();
      _syncAllTextControllers();
      isEditing.value = false;
    }
    return ok;
  }

  void addPendingChange(String key, dynamic value) {
    pendingChanges[key] = value;
  }

  void setAiSectionExpanded(bool v) {
    aiSectionExpanded.value = v;
    addPendingChange('AI_AGENT_ENABLE', v);
  }

  void _syncAllTextControllers() {
    for (final f in [...basicFields, ...aiFields]) {
      if (f.type == SettingsFieldType.text ||
          f.type == SettingsFieldType.number) {
        final c = _textControllers[f.envKey];
        if (c != null) {
          final v = valueFor(f);
          c.text = v?.toString() ?? '';
        }
      }
    }
  }

  void _revertTextControllers() {
    for (final f in [...basicFields, ...aiFields]) {
      if (f.type == SettingsFieldType.text ||
          f.type == SettingsFieldType.number) {
        final c = _textControllers[f.envKey];
        if (c != null) {
          final v = valueFor(f);
          c.text = v?.toString() ?? '';
        }
      }
    }
  }

  TextEditingController textControllerFor(SettingsFieldConfig field) {
    final c = _textControllers.putIfAbsent(field.envKey, () {
      final controller = TextEditingController();
      final v = valueFor(field);
      controller.text = v?.toString() ?? '';
      return controller;
    });
    if (!isEditing.value) {
      final v = valueFor(field);
      final s = v?.toString() ?? '';
      if (c.text != s) c.text = s;
    } else if (!pendingChanges.containsKey(field.envKey)) {
      // 编辑态下若用户未修改该字段，则从 valueFor 同步（兜底）
      final v = valueFor(field);
      final s = v?.toString() ?? '';
      if (c.text != s) c.text = s;
    }
    return c;
  }

  void syncTextController(SettingsFieldConfig field) {
    final c = _textControllers[field.envKey];
    if (c != null) {
      final v = valueFor(field);
      final s = v?.toString() ?? '';
      if (c.text != s) c.text = s;
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  @override
  void onClose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _textControllers.clear();
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

  /// 编辑态下优先使用待保存值
  dynamic effectiveValueFor(SettingsFieldConfig field) {
    if (pendingChanges.containsKey(field.envKey)) {
      return pendingChanges[field.envKey];
    }
    return valueFor(field);
  }

  bool shouldShowField(SettingsFieldConfig field) {
    if (field.conditionKey == null || field.conditionValue == null) return true;
    final v = isEditing.value && pendingChanges.containsKey(field.conditionKey!)
        ? pendingChanges[field.conditionKey!]
        : envData.value?.valueFor(field.conditionKey!);
    return v?.toString().toLowerCase() == field.conditionValue?.toLowerCase();
  }

  List<SettingsFieldConfig> visibleBasicFields() =>
      basicFields.where(shouldShowField).toList();

  List<SettingsFieldConfig> visibleAiFields() =>
      aiFields.where(shouldShowField).toList();
}

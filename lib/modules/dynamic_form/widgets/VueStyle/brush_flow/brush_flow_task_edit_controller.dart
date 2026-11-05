import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/brush_flow_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/brush_flow_service.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_task_form_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_manager.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class BrushFlowTaskEditController extends GetxController {
  BrushFlowTaskEditController({
    this.taskId,
    List<BrushFlowOption> sites = const [],
    List<BrushFlowOption> downloaders = const [],
  }) : sites = List.unmodifiable(sites),
       downloaders = List.unmodifiable(downloaders);

  final String? taskId;
  final List<BrushFlowOption> sites;
  final List<BrushFlowOption> downloaders;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  late final BrushFlowService _service = BrushFlowService(_apiClient);

  late final SettingsFormManager form = SettingsFormManager(
    fields: BrushFlowTaskFormConfig.allFields,
  );

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditing = true.obs;
  final errorText = RxnString();
  final segment = BrushFlowTaskFormSegment.basic.obs;
  final config = Rxn<BrushFlowTaskConfig>();

  bool get isCreate => taskId == null || taskId!.isEmpty;

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    form.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      if (isCreate) {
        final defaults = BrushFlowTaskConfig(
          downloader: downloaders.isNotEmpty
              ? downloaders.first.value?.toString()
              : null,
          siteId: sites.isNotEmpty
              ? int.tryParse(sites.first.value?.toString() ?? '')
              : null,
        );
        config.value = defaults;
        form.hydrateAll(defaults.valueFor);
        form.clearDirty();
        return;
      }
      final detail = await _service.fetchTaskDetail(
        taskId: taskId!,
        token: _getToken(),
      );
      config.value = detail.task;
      form.hydrateAll(detail.task.valueFor);
      form.clearDirty();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载 BrushFlow 任务失败');
      errorText.value = e is BrushFlowApiException ? e.message : '加载失败';
    } finally {
      isLoading.value = false;
    }
  }

  List<SettingsEnumOption> optionsFor(String enumKey) {
    switch (enumKey) {
      case 'BRUSH_FLOW_SITE':
        return sites
            .map(
              (e) => SettingsEnumOption(
                value: e.value?.toString() ?? '',
                label: e.title,
              ),
            )
            .where((e) => e.value.isNotEmpty)
            .toList();
      case 'BRUSH_FLOW_DOWNLOADER':
        return downloaders
            .map(
              (e) => SettingsEnumOption(
                value: e.value?.toString() ?? '',
                label: e.title,
              ),
            )
            .where((e) => e.value.isNotEmpty)
            .toList();
      case 'BRUSH_FLOW_FREELEECH':
        return BrushFlowTaskFormConfig.freeleechOptions;
      case 'BRUSH_FLOW_HR':
        return BrushFlowTaskFormConfig.hrOptions;
      default:
        return const [];
    }
  }

  Future<bool> save() async {
    final name = form.effectiveValue('name')?.toString().trim() ?? '';
    if (name.isEmpty) {
      ToastUtil.error('请填写任务名称');
      return false;
    }
    final siteId = form.effectiveValue('site_id')?.toString().trim() ?? '';
    if (siteId.isEmpty) {
      ToastUtil.error('请选择站点');
      return false;
    }
    final downloader =
        form.effectiveValue('downloader')?.toString().trim() ?? '';
    if (downloader.isEmpty) {
      ToastUtil.error('请选择下载器');
      return false;
    }

    isSaving.value = true;
    errorText.value = null;
    try {
      final body = _buildBody();
      if (isCreate) {
        await _service.createTask(body: body, token: _getToken());
        ToastUtil.success('任务已创建');
      } else {
        await _service.updateTask(
          taskId: taskId!,
          body: body,
          token: _getToken(),
        );
        ToastUtil.success('任务已保存');
      }
      form.clearDirty();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 BrushFlow 任务失败');
      final msg = e is BrushFlowApiException ? e.message : '保存失败';
      errorText.value = msg;
      ToastUtil.error(msg);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildBody() {
    final out = <String, dynamic>{
      'id': isCreate ? '' : (taskId ?? ''),
    };
    for (final field in BrushFlowTaskFormConfig.allFields) {
      final key = field.envKey;
      final raw = form.effectiveValue(key);
      out[key] = _normalizeValue(key, raw);
    }
    return out;
  }

  dynamic _normalizeValue(String key, dynamic raw) {
    if (key == 'site_id') {
      final text = raw?.toString().trim() ?? '';
      return text.isEmpty ? null : int.tryParse(text);
    }
    if (BrushFlowTaskFormConfig.intKeys.contains(key)) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      final text = raw.toString().trim();
      if (text.isEmpty) return null;
      return int.tryParse(text) ?? num.tryParse(text)?.toInt();
    }
    if (BrushFlowTaskFormConfig.nullableNumberKeys.contains(key)) {
      if (raw == null) return null;
      if (raw is num) return raw;
      final text = raw.toString().trim();
      if (text.isEmpty) return null;
      return num.tryParse(text);
    }
    if (key == 'timezone_offset') {
      if (raw is num) return raw;
      final text = raw?.toString().trim() ?? '';
      if (text.isEmpty) return 0;
      return num.tryParse(text) ?? 0;
    }
    if (raw is bool) return raw;
    final text = raw?.toString().trim() ?? '';
    if (BrushFlowTaskFormConfig.nullableTextKeys.contains(key)) {
      return text.isEmpty ? null : text;
    }
    return text;
  }
}

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/brush_flow_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/brush_flow_service.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_task_edit_page.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class BrushFlowFormController extends GetxController
    implements PluginFormAdapter {
  BrushFlowFormController({required this.formMode});

  @override
  final String pluginId = BrushFlowService.pluginId;

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  late final BrushFlowService _service = BrushFlowService(_apiClient);

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
  RxBool? get actionLoading => settingsSaving;

  @override
  bool get supportsSave => false;

  @override
  bool get supportsFormEntry => false;

  @override
  List<AppBarActionItem>? get actionList => formMode
      ? null
      : const [
          AppBarActionItem(
            type: 'settings',
            label: '设置',
            iconName: 'mdi-cog',
          ),
        ];

  final statusData = Rxn<BrushFlowStatusData>();
  final detailSheetOpen = false.obs;
  final selectedTaskId = RxnString();
  final taskDetail = Rxn<BrushFlowTaskDetail>();
  final torrents = <BrushFlowTorrent>[].obs;
  final torrentState = 'active'.obs;
  final torrentPage = 1.obs;
  final torrentTotal = 0.obs;
  final torrentHasMore = false.obs;
  final detailLoading = false.obs;
  final loadingMoreTorrents = false.obs;
  final settingsSaving = false.obs;
  final taskStateUpdatingIds = <String>{}.obs;

  Future<void> Function()? openSettingsSheet;

  static const _pageSize = 50;

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'settings') {
      await openSettingsSheet?.call();
    }
  }

  @override
  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        statusData.value = null;
        _ensurePageBlock();
        return;
      }
      final data = await _service.fetchStatus(token: token);
      statusData.value = data;
      _ensurePageBlock();
      final selected = selectedTaskId.value;
      if (selected != null &&
          data.tasks.any((task) => task.id == selected) &&
          detailSheetOpen.value) {
        await openTaskDetail(selected, keepOpen: true);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 BrushFlow 状态失败');
      errorText.value = e is BrushFlowApiException ? e.message : '请求失败，请稍后重试';
      statusData.value = null;
      _ensurePageBlock();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<bool> save() async => false;

  Future<void> openCreateTask() async {
    final data = statusData.value;
    final saved = await openBrushFlowTaskEditPage(
      sites: data?.sites ?? const [],
      downloaders: data?.downloaders ?? const [],
    );
    if (saved == true) {
      await load();
    }
  }

  Future<void> openEditTask(String taskId) async {
    if (taskId.isEmpty) return;
    final data = statusData.value;
    final saved = await openBrushFlowTaskEditPage(
      taskId: taskId,
      sites: data?.sites ?? const [],
      downloaders: data?.downloaders ?? const [],
    );
    if (saved == true) {
      await load();
      if (detailSheetOpen.value && selectedTaskId.value == taskId) {
        await refreshTaskDetail();
      }
    }
  }

  bool isTaskStateUpdating(String taskId) =>
      taskStateUpdatingIds.contains(taskId);

  Future<void> setTaskEnabled(String taskId, bool enabled) async {
    if (taskId.isEmpty || taskStateUpdatingIds.contains(taskId)) return;
    final previous = statusData.value;
    if (previous == null) return;
    final index = previous.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;

    taskStateUpdatingIds.add(taskId);
    taskStateUpdatingIds.refresh();
    final updatedTasks = [...previous.tasks];
    updatedTasks[index] = updatedTasks[index].copyWith(enabled: enabled);
    statusData.value = previous.copyWith(tasks: updatedTasks);

    final detail = taskDetail.value;
    if (detail != null &&
        (detail.task.id == taskId || detail.summary?.id == taskId)) {
      taskDetail.value = BrushFlowTaskDetail(
        task: BrushFlowTaskConfig.fromJson({
          ...detail.task.toJson(),
          'enabled': enabled,
        }),
        summary: detail.summary?.copyWith(enabled: enabled),
        torrents: detail.torrents,
      );
    }

    try {
      await _service.updateTaskState(
        taskId: taskId,
        enabled: enabled,
        token: _getToken(),
      );
      ToastUtil.success(enabled ? '任务已重启' : '任务已暂停');
      await load();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '更新 BrushFlow 任务状态失败');
      statusData.value = previous;
      if (detail != null) {
        taskDetail.value = detail;
      }
      final msg = e is BrushFlowApiException ? e.message : '更新任务状态失败';
      errorText.value = msg;
      ToastUtil.error(msg);
    } finally {
      taskStateUpdatingIds.remove(taskId);
      taskStateUpdatingIds.refresh();
    }
  }

  Future<void> clearTask(String taskId) async {
    if (taskId.isEmpty || taskStateUpdatingIds.contains(taskId)) return;
    taskStateUpdatingIds.add(taskId);
    taskStateUpdatingIds.refresh();
    try {
      await _service.clearTask(taskId: taskId, token: _getToken());
      ToastUtil.success('任务已清理');
      await load();
      if (detailSheetOpen.value && selectedTaskId.value == taskId) {
        await refreshTaskDetail();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '清理 BrushFlow 任务失败');
      final msg = e is BrushFlowApiException ? e.message : '清理任务失败';
      errorText.value = msg;
      ToastUtil.error(msg);
    } finally {
      taskStateUpdatingIds.remove(taskId);
      taskStateUpdatingIds.refresh();
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty || taskStateUpdatingIds.contains(taskId)) return;
    taskStateUpdatingIds.add(taskId);
    taskStateUpdatingIds.refresh();
    try {
      await _service.deleteTask(taskId: taskId, token: _getToken());
      ToastUtil.success('任务已删除');
      if (selectedTaskId.value == taskId) {
        detailSheetOpen.value = false;
        selectedTaskId.value = null;
        taskDetail.value = null;
        torrents.clear();
      }
      await load();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除 BrushFlow 任务失败');
      final msg = e is BrushFlowApiException ? e.message : '删除任务失败';
      errorText.value = msg;
      ToastUtil.error(msg);
    } finally {
      taskStateUpdatingIds.remove(taskId);
      taskStateUpdatingIds.refresh();
    }
  }

  Future<void> setPluginEnabled(bool enabled) async {
    final previous = statusData.value;
    if (previous == null || settingsSaving.value) return;
    settingsSaving.value = true;
    statusData.value = previous.copyWith(enabled: enabled);
    try {
      await _service.updateSettings(
        enabled: enabled,
        showSidebarNav: previous.showSidebarNav,
        token: _getToken(),
      );
      ToastUtil.success(enabled ? '插件已启用' : '插件已停用');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '更新 BrushFlow 设置失败');
      statusData.value = previous;
      final msg = e is BrushFlowApiException ? e.message : '更新设置失败';
      errorText.value = msg;
      ToastUtil.error(msg);
    } finally {
      settingsSaving.value = false;
    }
  }

  Future<void> openTaskDetail(String taskId, {bool keepOpen = false}) async {
    if (taskId.isEmpty) return;
    selectedTaskId.value = taskId;
    detailSheetOpen.value = true;
    if (!keepOpen) {
      torrentState.value = 'active';
      torrentPage.value = 1;
      torrents.clear();
      taskDetail.value = null;
    }
    await _loadTaskDetail(reset: true);
  }

  void closeTaskDetail() {
    detailSheetOpen.value = false;
    selectedTaskId.value = null;
  }

  Future<void> setTorrentState(String state) async {
    if (torrentState.value == state) return;
    torrentState.value = state;
    torrentPage.value = 1;
    torrents.clear();
    await _loadTaskDetail(reset: true);
  }

  Future<void> loadMoreTorrents() async {
    if (!torrentHasMore.value || loadingMoreTorrents.value) return;
    final taskId = selectedTaskId.value;
    if (taskId == null || taskId.isEmpty) return;
    loadingMoreTorrents.value = true;
    try {
      final nextPage = torrentPage.value + 1;
      final detail = await _service.fetchTaskDetail(
        taskId: taskId,
        state: torrentState.value,
        page: nextPage,
        pageSize: _pageSize,
        token: _getToken(),
      );
      taskDetail.value = detail;
      torrents.addAll(detail.torrents.items);
      torrentPage.value = detail.torrents.page;
      torrentTotal.value = detail.torrents.total;
      torrentHasMore.value = torrents.length < detail.torrents.total;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多 BrushFlow 种子失败');
      errorText.value = e is BrushFlowApiException ? e.message : '加载更多失败';
    } finally {
      loadingMoreTorrents.value = false;
    }
  }

  Future<void> refreshTaskDetail() async {
    torrentPage.value = 1;
    await _loadTaskDetail(reset: true);
  }

  Future<void> _loadTaskDetail({required bool reset}) async {
    final taskId = selectedTaskId.value;
    if (taskId == null || taskId.isEmpty) return;
    detailLoading.value = true;
    try {
      final detail = await _service.fetchTaskDetail(
        taskId: taskId,
        state: torrentState.value,
        page: 1,
        pageSize: _pageSize,
        token: _getToken(),
      );
      taskDetail.value = detail;
      if (reset) {
        torrents.assignAll(detail.torrents.items);
      }
      torrentPage.value = detail.torrents.page;
      torrentTotal.value = detail.torrents.total;
      torrentHasMore.value = torrents.length < detail.torrents.total;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 BrushFlow 任务详情失败');
      errorText.value = e is BrushFlowApiException ? e.message : '获取任务详情失败';
    } finally {
      detailLoading.value = false;
    }
  }

  BrushFlowTask? taskById(String? id) {
    if (id == null) return null;
    final tasks = statusData.value?.tasks ?? const <BrushFlowTask>[];
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void _ensurePageBlock() {
    if (blocks.isEmpty) {
      blocks.assignAll([
        const FormBlock.alert(
          type: 'info',
          text: 'BrushFlow native renderer',
        ),
      ]);
    }
  }
}

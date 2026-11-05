import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/brush_flow_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/brush_flow_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_task_form_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';

Future<bool> _confirmBrushFlowAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确定',
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void registerBrushFlowRenderer() {
  PluginFormAdapterRegistry.registerRenderer('BrushFlow', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! BrushFlowFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return BrushFlowRenderer(controller: adapter);
  });
}

class BrushFlowRenderer extends StatefulWidget {
  const BrushFlowRenderer({super.key, required this.controller});

  final BrushFlowFormController controller;

  @override
  State<BrushFlowRenderer> createState() => _BrushFlowRendererState();
}

class _BrushFlowRendererState extends State<BrushFlowRenderer> {
  @override
  void initState() {
    super.initState();
    widget.controller.openSettingsSheet = _openSettingsSheet;
  }

  @override
  void didUpdateWidget(covariant BrushFlowRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.openSettingsSheet = null;
      widget.controller.openSettingsSheet = _openSettingsSheet;
    }
  }

  @override
  void dispose() {
    if (widget.controller.openSettingsSheet == _openSettingsSheet) {
      widget.controller.openSettingsSheet = null;
    }
    super.dispose();
  }

  Future<void> _openSettingsSheet() {
    return showBrushFlowSettingsSheet(context, widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return _BrushFlowHome(controller: widget.controller);
  }
}

Future<void> showBrushFlowSettingsSheet(
  BuildContext context,
  BrushFlowFormController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BrushFlowSettingsSheet(controller: controller),
  );
}

Future<void> showBrushFlowTaskDetailSheet(
  BuildContext context,
  BrushFlowFormController controller,
  String taskId,
) async {
  await controller.openTaskDetail(taskId);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BrushFlowTaskDetailSheet(controller: controller),
  );
  controller.closeTaskDetail();
}

class _BrushFlowHome extends StatelessWidget {
  const _BrushFlowHome({required this.controller});

  final BrushFlowFormController controller;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return RefreshIndicator(
      onRefresh: controller.load,
      color: palette.primary,
      backgroundColor: palette.surfaceAlt,
      child: Obx(() {
        final data = controller.statusData.value;
        final tasks = data?.tasks ?? const <BrushFlowTask>[];
        final summary = data?.summary ?? const BrushFlowSummary();
        controller.taskStateUpdatingIds.toList();
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _SummaryHeader(
                  enabled: data?.enabled == true,
                  summary: summary,
                  palette: palette,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '刷流任务',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.titleText,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: '添加刷流任务',
                        child: IconButton(
                          onPressed: controller.openCreateTask,
                          tooltip: '添加任务',
                          icon: Icon(
                            CupertinoIcons.add_circled,
                            color: palette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  title: '暂无刷流任务',
                  subtitle: '点击右上角加号创建任务',
                  palette: palette,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      palette: palette,
                      stateUpdating:
                          controller.isTaskStateUpdating(task.id),
                      onTap: () => showBrushFlowTaskDetailSheet(
                        context,
                        controller,
                        task.id,
                      ),
                      onEdit: () => controller.openEditTask(task.id),
                      onToggleState: () => controller.setTaskEnabled(
                        task.id,
                        !task.enabled,
                      ),
                      onClear: () async {
                        final ok = await _confirmBrushFlowAction(
                          context,
                          title: '清理任务',
                          message: '确定清理「${task.name}」的种子记录？',
                          confirmLabel: '清理',
                        );
                        if (ok) await controller.clearTask(task.id);
                      },
                      onDelete: () async {
                        final ok = await _confirmBrushFlowAction(
                          context,
                          title: '删除任务',
                          message: '确定删除「${task.name}」？此操作不可恢复。',
                          confirmLabel: '删除',
                        );
                        if (ok) await controller.deleteTask(task.id);
                      },
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.enabled,
    required this.summary,
    required this.palette,
  });

  final bool enabled;
  final BrushFlowSummary summary;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompactMetric(
              label: '活跃',
              value: '${summary.activeCount}',
              palette: palette,
            ),
          ),
          Expanded(
            child: _CompactMetric(
              label: '上传',
              value: SizeFormatter.formatSize(summary.uploaded, 1),
              palette: palette,
            ),
          ),
          Expanded(
            child: _CompactMetric(
              label: '做种',
              value: SizeFormatter.formatSize(summary.seedingSize, 1),
              palette: palette,
            ),
          ),
          _StatusChip(
            label: enabled ? '已启用' : '未启用',
            color: enabled ? palette.successAccent : palette.mutedText,
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: palette.mutedText),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.titleText,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrushFlowSettingsSheet extends StatelessWidget {
  const _BrushFlowSettingsSheet({required this.controller});

  final BrushFlowFormController controller;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Material(
        color: palette.pageBackgroundAlt,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Obx(() {
              final enabled = controller.statusData.value?.enabled == true;
              final saving = controller.settingsSaving.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'BrushFlow 设置',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.titleText,
                          ),
                        ),
                      ),
                      if (saving)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: CupertinoActivityIndicator(radius: 8),
                        ),
                      Semantics(
                        button: true,
                        label: '关闭设置',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            CupertinoIcons.xmark,
                            color: palette.titleText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSwitchRow(
                    title: '启用插件',
                    subtitle: enabled ? '刷流调度已开启' : '刷流调度已关闭',
                    value: enabled,
                    enabled: !saving,
                    palette: palette,
                    onChanged: controller.setPluginEnabled,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.palette,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final DashboardPaletteData palette;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: title,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.tileSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.titleText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: palette.mutedText),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              activeTrackColor: palette.primary,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.palette,
    required this.stateUpdating,
    required this.onTap,
    required this.onEdit,
    required this.onToggleState,
    required this.onClear,
    required this.onDelete,
  });

  final BrushFlowTask task;
  final DashboardPaletteData palette;
  final bool stateUpdating;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleState;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stats = task.statistic;
    final accent = task.enabled ? palette.successAccent : palette.mutedText;
    final meta = [
      if (task.siteName != null && task.siteName!.isNotEmpty) task.siteName!,
      if (task.downloader != null && task.downloader!.isNotEmpty)
        task.downloader!,
      if (task.state != null && task.state!.isNotEmpty) task.state!,
    ];
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.tileBorder),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: accent,
                    child: const SizedBox(width: 4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up_arrow_down_circle_fill,
                              size: 20,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: palette.titleText,
                                  ),
                                ),
                                if (meta.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    meta.join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: palette.mutedText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: task.enabled ? '运行中' : '已暂停',
                            color: accent,
                            palette: palette,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _MetricGrid(
                        palette: palette,
                        items: [
                          (
                            '活跃',
                            '${stats.active}',
                            CupertinoIcons.bolt_fill,
                            palette.warmAccent,
                          ),
                          (
                            '上传',
                            SizeFormatter.formatSize(stats.uploaded, 1),
                            CupertinoIcons.arrow_up_circle_fill,
                            palette.successAccent,
                          ),
                          (
                            '下载',
                            SizeFormatter.formatSize(stats.downloaded, 1),
                            CupertinoIcons.arrow_down_circle_fill,
                            palette.coolAccent,
                          ),
                          (
                            '做种',
                            SizeFormatter.formatSize(task.seedingSize, 1),
                            CupertinoIcons.device_phone_portrait,
                            palette.primary,
                          ),
                        ],
                      ),
                      if (task.nextRunAt != null &&
                          task.nextRunAt!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.clock,
                              size: 13,
                              color: palette.faintText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '下次运行 ${task.nextRunAt}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.faintText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (task.lastError != null &&
                          task.lastError!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: palette.warningAccent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            task.lastError!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: palette.warningAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: task.enabled
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.play_circle,
          onPressed: () {
            Navigator.of(context).pop();
            if (!stateUpdating) onToggleState();
          },
          child: Text(task.enabled ? '暂停任务' : '重启任务'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.pencil,
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          child: const Text('编辑任务'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.clear_circled,
          onPressed: () {
            Navigator.of(context).pop();
            if (!stateUpdating) onClear();
          },
          child: const Text('清理任务'),
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: CupertinoIcons.delete,
          onPressed: () {
            Navigator.of(context).pop();
            if (!stateUpdating) onDelete();
          },
          child: const Text('删除任务'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.info_circle,
          onPressed: () {
            Navigator.of(context).pop();
            onTap();
          },
          child: const Text('查看详情'),
        ),
      ],
      builder: (context, animation) => card,
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.palette,
    required this.items,
  });

  final DashboardPaletteData palette;
  final List<(String, String, IconData, Color)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _MetricCell(
                    label: item.$1,
                    value: item.$2,
                    icon: item.$3,
                    accent: item.$4,
                    palette: palette,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.palette,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: palette.mutedText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.titleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DetailAction { toggle, edit, refresh, clear, delete }

class _DetailMenuRow extends StatelessWidget {
  const _DetailMenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BrushFlowTaskDetailSheet extends StatelessWidget {
  const _BrushFlowTaskDetailSheet({required this.controller});

  final BrushFlowFormController controller;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.48,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: palette.pageBackgroundAlt,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Obx(() {
            final taskId = controller.selectedTaskId.value;
            final listTask = controller.taskById(taskId);
            final detail = controller.taskDetail.value;
            final config = detail?.task;
            final summary = detail?.summary ?? listTask;
            final title = config?.name.isNotEmpty == true
                ? config!.name
                : (listTask?.name ?? '任务详情');
            final loading = controller.detailLoading.value &&
                controller.torrents.isEmpty;
            controller.taskStateUpdatingIds.toList();
            final enabled = (summary?.enabled ?? config?.enabled) == true;
            final updating =
                taskId != null && controller.isTaskStateUpdating(taskId);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '任务详情',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: palette.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: palette.titleText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (taskId != null && taskId.isNotEmpty)
                            PopupMenuButton<_DetailAction>(
                              enabled: !updating,
                              tooltip: '更多操作',
                              padding: EdgeInsets.zero,
                              icon: updating
                                  ? const CupertinoActivityIndicator(radius: 8)
                                  : Icon(
                                      CupertinoIcons.ellipsis_circle,
                                      color: palette.primary,
                                    ),
                              onSelected: (action) async {
                                switch (action) {
                                  case _DetailAction.toggle:
                                    await controller.setTaskEnabled(
                                      taskId,
                                      !enabled,
                                    );
                                  case _DetailAction.edit:
                                    Navigator.of(context).maybePop();
                                    await controller.openEditTask(taskId);
                                  case _DetailAction.refresh:
                                    await controller.refreshTaskDetail();
                                  case _DetailAction.clear:
                                    final ok = await _confirmBrushFlowAction(
                                      context,
                                      title: '清理任务',
                                      message: '确定清理「$title」的种子记录？',
                                      confirmLabel: '清理',
                                    );
                                    if (ok) {
                                      await controller.clearTask(taskId);
                                    }
                                  case _DetailAction.delete:
                                    final ok = await _confirmBrushFlowAction(
                                      context,
                                      title: '删除任务',
                                      message: '确定删除「$title」？此操作不可恢复。',
                                      confirmLabel: '删除',
                                    );
                                    if (!ok || !context.mounted) return;
                                    Navigator.of(context).maybePop();
                                    await controller.deleteTask(taskId);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: _DetailAction.toggle,
                                  child: _DetailMenuRow(
                                    icon: enabled
                                        ? CupertinoIcons.pause_circle
                                        : CupertinoIcons.play_circle,
                                    label: enabled ? '暂停任务' : '重启任务',
                                    color: enabled
                                        ? palette.warningAccent
                                        : palette.successAccent,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _DetailAction.edit,
                                  child: _DetailMenuRow(
                                    icon: CupertinoIcons.pencil,
                                    label: '编辑任务',
                                    color: palette.primary,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _DetailAction.refresh,
                                  child: _DetailMenuRow(
                                    icon: CupertinoIcons.refresh,
                                    label: '刷新',
                                    color: palette.primary,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _DetailAction.clear,
                                  child: _DetailMenuRow(
                                    icon: CupertinoIcons.clear_circled,
                                    label: '清理任务',
                                    color: palette.warningAccent,
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: _DetailAction.delete,
                                  child: _DetailMenuRow(
                                    icon: CupertinoIcons.delete,
                                    label: '删除任务',
                                    color: CupertinoColors.destructiveRed,
                                  ),
                                ),
                              ],
                            ),
                          Semantics(
                            button: true,
                            label: '关闭详情',
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                CupertinoIcons.xmark,
                                color: palette.titleText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const Expanded(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (summary != null)
                          _TaskSummaryCard(
                            task: summary,
                            config: config,
                            palette: palette,
                          ),
                        const SizedBox(height: 16),
                        if (config != null)
                          _TaskConfigCard(
                            config: config,
                            palette: palette,
                          ),
                        const SizedBox(height: 20),
                        Text(
                          '种子列表',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: palette.titleText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TorrentStateSegment(
                          selected: controller.torrentState.value,
                          onSelected: controller.setTorrentState,
                          palette: palette,
                        ),
                        const SizedBox(height: 10),
                        if (controller.torrents.isEmpty)
                          _EmptyState(
                            title: '暂无种子',
                            subtitle: '当前筛选条件下没有种子',
                            palette: palette,
                            compact: true,
                          )
                        else
                          ...controller.torrents.map(
                            (torrent) => Padding(
                              key: ValueKey(
                                '${torrent.pageUrl ?? torrent.title}-${torrent.pubdate}',
                              ),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TorrentCard(
                                torrent: torrent,
                                palette: palette,
                              ),
                            ),
                          ),
                        LoadMoreFooter(
                          hasMore: controller.torrentHasMore.value,
                          isLoading: controller.loadingMoreTorrents.value,
                          hasItems: controller.torrents.isNotEmpty,
                          total: controller.torrentTotal.value,
                          onLoadMore: controller.loadMoreTorrents,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({
    required this.task,
    required this.config,
    required this.palette,
  });

  final BrushFlowTask task;
  final BrushFlowTaskConfig? config;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    final stats = task.statistic;
    final accent = task.enabled ? palette.successAccent : palette.mutedText;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.tileBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface,
            Color.alphaBlend(
              accent.withValues(alpha: palette.isDark ? 0.08 : 0.05),
              palette.pageBackgroundAlt,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up_arrow_down_circle_fill,
                    size: 22,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: palette.titleText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (task.siteName != null && task.siteName!.isNotEmpty)
                            task.siteName!,
                          if (task.downloader != null &&
                              task.downloader!.isNotEmpty)
                            task.downloader!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: task.enabled ? '运行中' : '已暂停',
                  color: accent,
                  palette: palette,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (task.state != null && task.state!.isNotEmpty)
                  _StatusChip(
                    label: task.state!,
                    color: palette.coolAccent,
                    palette: palette,
                  ),
                if (config != null)
                  _StatusChip(
                    label:
                        '刷流 ${config!.brushInterval ?? '-'}分 / 检查 ${config!.checkInterval ?? '-'}分',
                    color: palette.primary,
                    palette: palette,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _MetricGrid(
              palette: palette,
              items: [
                (
                  '活跃',
                  '${stats.active}',
                  CupertinoIcons.bolt_fill,
                  palette.warmAccent,
                ),
                (
                  '上传',
                  SizeFormatter.formatSize(stats.uploaded, 1),
                  CupertinoIcons.arrow_up_circle_fill,
                  palette.successAccent,
                ),
                (
                  '下载',
                  SizeFormatter.formatSize(stats.downloaded, 1),
                  CupertinoIcons.arrow_down_circle_fill,
                  palette.coolAccent,
                ),
                (
                  '做种',
                  SizeFormatter.formatSize(task.seedingSize, 1),
                  CupertinoIcons.device_phone_portrait,
                  palette.primary,
                ),
              ],
            ),
            if (task.nextRunAt != null && task.nextRunAt!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.tileSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.tileBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock_fill,
                      size: 14,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '下次运行 ${task.nextRunAt}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: palette.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskConfigCard extends StatefulWidget {
  const _TaskConfigCard({
    required this.config,
    required this.palette,
  });

  final BrushFlowTaskConfig config;
  final DashboardPaletteData palette;

  @override
  State<_TaskConfigCard> createState() => _TaskConfigCardState();
}

class _TaskConfigCardState extends State<_TaskConfigCard> {
  bool _expanded = false;

  static String _optionLabel(
    List<SettingsEnumOption> options,
    String? value,
  ) {
    final raw = value ?? '';
    for (final option in options) {
      if (option.value == raw) return option.label;
    }
    return raw.isEmpty ? '不限' : raw;
  }

  List<(String, String)> get _primaryChips {
    final c = widget.config;
    return [
      (
        '免费',
        _optionLabel(BrushFlowTaskFormConfig.freeleechOptions, c.freeleech),
      ),
      ('H&R', _optionLabel(BrushFlowTaskFormConfig.hrOptions, c.hr)),
      ('体积', (c.size ?? '').trim().isEmpty ? '不限' : c.size!.trim()),
      ('做种', (c.seeder ?? '').trim().isEmpty ? '不限' : c.seeder!.trim()),
      ('刷流', c.brushInterval == null ? '-' : '${c.brushInterval}分'),
      ('检查', c.checkInterval == null ? '-' : '${c.checkInterval}分'),
      ('下载数', '${c.maxdlcount ?? '-'}'),
      ('磁盘', c.disksize == null ? '-' : '${c.disksize}G'),
    ];
  }

  List<(String, String)> get _extraChips {
    final c = widget.config;
    final chips = <(String, String)>[];
    void addText(String label, String? value) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) chips.add((label, text));
    }

    void addNum(String label, Object? value, {String suffix = ''}) {
      if (value != null) chips.add((label, '$value$suffix'));
    }

    addText('Cron', c.cron);
    addText('时段', c.activeTimeRange);
    addText('包含', c.include);
    addText('排除', c.exclude);
    addText('发布时间', c.pubtime);
    addNum('上传限速', c.maxupspeed);
    addNum('下载限速', c.maxdlspeed);
    addNum('做种时间', c.seedTime);
    addNum('H&R做种', c.hrSeedTime);
    addNum('分享率', c.seedRatio);
    addNum('做种体积', c.seedSize);
    addNum('下载时间', c.downloadTime);
    addText('删种体积', c.deleteSizeRange);
    addText('保留标签', c.deleteExceptTags);
    addText('路径', c.savePath);
    addText('分类', c.qbCategory);
    addNum('归档', c.autoArchiveDays, suffix: '天');
    if (c.exceptSubscribe) chips.add(('排除订阅', '开'));
    if (c.rssSupport) chips.add(('RSS', '开'));
    if (c.notify) chips.add(('通知', '开'));
    if (c.proxyDelete) chips.add(('代理删除', '开'));
    if (c.delNoFree) chips.add(('删非免费', '开'));
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final extras = _extraChips;
    final chips = _expanded ? [..._primaryChips, ...extras] : _primaryChips;

    return Semantics(
      container: true,
      label: '任务规则',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '任务规则',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.titleText,
                  ),
                ),
                const Spacer(),
                if (extras.isNotEmpty)
                  Semantics(
                    button: true,
                    label: _expanded ? '收起规则' : '展开更多规则',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded ? '收起' : '更多',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.primary,
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? CupertinoIcons.chevron_up
                                  : CupertinoIcons.chevron_down,
                              size: 12,
                              color: palette.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips
                  .map(
                    (chip) => _RuleChip(
                      label: chip.$1,
                      value: chip.$2,
                      palette: palette,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: palette.mutedText,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TorrentStateSegment extends StatelessWidget {
  const _TorrentStateSegment({
    required this.selected,
    required this.onSelected,
    required this.palette,
  });

  final String selected;
  final Future<void> Function(String state) onSelected;
  final DashboardPaletteData palette;

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.titleText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: '种子状态筛选',
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: selected,
          backgroundColor: palette.surfaceAlt,
          thumbColor: palette.surface,
          children: {
            'active': _label('活跃'),
            'deleted': _label('已删除'),
            'all': _label('全部'),
          },
          onValueChanged: (next) {
            if (next != null) {
              onSelected(next);
            }
          },
        ),
      ),
    );
  }
}

class _TorrentCard extends StatelessWidget {
  const _TorrentCard({
    required this.torrent,
    required this.palette,
  });

  final BrushFlowTorrent torrent;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    final accent = torrent.deleted
        ? palette.mutedText
        : torrent.hitAndRun
            ? palette.warningAccent
            : palette.coolAccent;
    final meta = <String>[
      if ((torrent.siteName ?? '').trim().isNotEmpty) torrent.siteName!.trim(),
      SizeFormatter.formatSize(torrent.size, 1),
      if ((torrent.pubdate ?? '').trim().isNotEmpty) torrent.pubdate!.trim(),
    ];
    final stats = <(IconData, String, Color)>[
      (
        CupertinoIcons.arrow_up,
        SizeFormatter.formatSize(torrent.uploaded, 1),
        palette.successAccent,
      ),
      (
        CupertinoIcons.arrow_down,
        SizeFormatter.formatSize(torrent.downloaded, 1),
        palette.coolAccent,
      ),
      (
        CupertinoIcons.chart_bar_alt_fill,
        torrent.ratio.toStringAsFixed(2),
        palette.warmAccent,
      ),
      if (torrent.seedingTime > 0)
        (
          CupertinoIcons.clock,
          _formatDuration(torrent.seedingTime),
          palette.mutedText,
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: torrent.pageUrl == null || torrent.pageUrl!.isEmpty
            ? null
            : () => WebUtil.open(url: torrent.pageUrl),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.tileBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: accent,
                    child: const SizedBox(width: 3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              torrent.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.15,
                                color: palette.titleText,
                              ),
                            ),
                          ),
                          if ((torrent.volumeFactor ?? '').trim().isNotEmpty ||
                              torrent.hitAndRun ||
                              torrent.deleted) ...[
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                if ((torrent.volumeFactor ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  _TorrentBadge(
                                    label: torrent.volumeFactor!.trim(),
                                    color: palette.successAccent,
                                  ),
                                if (torrent.hitAndRun)
                                  _TorrentBadge(
                                    label: 'H&R',
                                    color: palette.warningAccent,
                                  ),
                                if (torrent.deleted)
                                  _TorrentBadge(
                                    label: '已删除',
                                    color: palette.mutedText,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          meta.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.mutedText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Icon(
                              stats[i].$1,
                              size: 12,
                              color: stats[i].$3,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              stats[i].$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.bodyText,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if ((torrent.freedateDiff ?? '').trim().isNotEmpty)
                            Text(
                              '免费 ${torrent.freedateDiff}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: palette.successAccent,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TorrentBadge extends StatelessWidget {
  const _TorrentBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.palette,
  });

  final String label;
  final Color color;
  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.palette,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final DashboardPaletteData palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.tray,
            size: compact ? 28 : 36,
            color: palette.faintText,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.titleText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0分';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '$hours时$minutes分';
  return '$minutes分';
}

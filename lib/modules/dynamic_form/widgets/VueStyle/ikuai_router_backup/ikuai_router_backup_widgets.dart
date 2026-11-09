import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/ikuai_router_backup_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/ikuai_router_backup/ikuai_monitor_views.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:share_plus/share_plus.dart';

/// 爱快路由时光机（IkuaiRouterBackup）自定义渲染器。
///
/// 页面模式 = 实时监控 + 线路 + 备份管理 + 告警记录
/// 配置模式 = 可编辑配置表单 + 连接测试（保存由页面右上角按钮触发）
void registerIkuaiRouterBackupRenderer() {
  PluginFormAdapterRegistry.registerRenderer('IkuaiRouterBackup', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! IkuaiRouterBackupFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return IkuaiRouterBackupPageView(
      controller: adapter,
      formMode: formMode,
      blocks: blocks,
      buildBlock: buildBlock,
    );
  });
}

class IkuaiRouterBackupPageView extends StatefulWidget {
  const IkuaiRouterBackupPageView({
    super.key,
    required this.controller,
    required this.formMode,
    required this.blocks,
    required this.buildBlock,
  });

  final IkuaiRouterBackupFormController controller;
  final bool formMode;
  final List<FormBlock> blocks;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  State<IkuaiRouterBackupPageView> createState() =>
      _IkuaiRouterBackupPageViewState();
}

class _IkuaiRouterBackupPageViewState extends State<IkuaiRouterBackupPageView> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;
      final status = controller.statusData.value;
      final loading = controller.isLoading.value;

      if (status == null && loading) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (status == null && widget.blocks.isEmpty) {
        return Center(
          child: Text(
            controller.errorText.value ?? '暂无数据',
            style: TextStyle(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        );
      }

      final sections = <Widget>[];
      if (status != null && status.ok) {
        sections.add(_MonitorSection(status: status));
        if (!widget.formMode) {
          // 实时监控多视图卡（流量分布 / 排行 / 性能 / 网络负载 / 终端等）
          sections.add(IkuaiRealtimeMonitorSection(controller: controller));
        }
        if (status.interfaces.isNotEmpty) {
          sections.add(_LinesSection(status: status));
        }
      } else if (status != null && !status.ok) {
        sections.add(
          Section(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFB8C00),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.error.isEmpty
                        ? '无法连接爱快路由，请检查插件配置'
                        : status.error,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      sections.add(_BackupSection(controller: controller));

      if (!widget.formMode) {
        final alerts = controller.alerts.value;
        if (alerts != null) {
          sections.add(_AlertsSection(controller: controller, alerts: alerts));
        }
      }

      if (widget.formMode) {
        sections.add(_TestConnectionSection(controller: controller));
        for (final block in widget.blocks) {
          sections.add(widget.buildBlock(context, block));
        }
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => sections[index],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.color, this.trailing});

  final String title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MonitorSection extends StatelessWidget {
  const _MonitorSection({required this.status});

  final IkuaiRouterStatus status;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Color)>[
      (
        'CPU',
        '${status.cpuUsage.toStringAsFixed(1)}%',
        Icons.memory_rounded,
        status.cpuUsage >= 80
            ? const Color(0xFFE53935)
            : status.cpuUsage >= 50
                ? const Color(0xFFFB8C00)
                : const Color(0xFF2E9E5B),
      ),
      (
        '内存',
        '${status.memUsage.toStringAsFixed(1)}%',
        Icons.dns_outlined,
        status.memUsage >= 80
            ? const Color(0xFFE53935)
            : status.memUsage >= 50
                ? const Color(0xFFFB8C00)
                : const Color(0xFF2E9E5B),
      ),
      (
        '上行',
        IkuaiRouterStatus.formatSpeed(status.uploadSpeed),
        Icons.north_rounded,
        const Color(0xFF1E88E5),
      ),
      (
        '下行',
        IkuaiRouterStatus.formatSpeed(status.downloadSpeed),
        Icons.south_rounded,
        const Color(0xFF00897B),
      ),
    ];
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: status.hostname.isEmpty ? '路由状态' : status.hostname,
            icon: Icons.router_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E9E5B).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '在线',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E9E5B),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Icon(items[i].$3, size: 20, color: items[i].$4),
                      const SizedBox(height: 6),
                      Text(
                        items[i].$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(items[i].$1, style: mutedStyle),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (status.version.isNotEmpty) _InfoChip(text: '固件 ${status.version}'),
            _InfoChip(text: '运行 ${status.uptimeLabel}'),
            if (status.onlineDevices != null)
              _InfoChip(text: '在线设备 ${status.onlineDevices}'),
            _InfoChip(text: '连接数 ${status.connectNum}'),
            if (status.cpuTemp != null)
              _InfoChip(text: 'CPU 温度 ${status.cpuTemp!.toStringAsFixed(0)}℃'),
            if (status.wanIp.isNotEmpty && status.wanIp != '--')
              _InfoChip(text: 'WAN ${status.wanIp}'),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LinesSection extends StatelessWidget {
  const _LinesSection({required this.status});

  final IkuaiRouterStatus status;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '线路监控',
            icon: Icons.lan_rounded,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemBlue,
              context,
            ),
          ),
          for (final line in status.interfaces)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    line.connected
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline,
                    size: 16,
                    color: line.connected
                        ? const Color(0xFF2E9E5B)
                        : CupertinoDynamicColor.resolve(
                            CupertinoColors.systemGrey3,
                            context,
                          ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(line.type, style: mutedStyle),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.ip,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '↑${IkuaiRouterStatus.formatSpeed(line.upload)}\n'
                      '↓${IkuaiRouterStatus.formatSpeed(line.download)}',
                      style: mutedStyle,
                      textAlign: TextAlign.end,
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

class _BackupSection extends StatelessWidget {
  const _BackupSection({required this.controller});

  final IkuaiRouterBackupFormController controller;

  Future<void> _confirmRestore(
    BuildContext context,
    IkuaiRouterBackupFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: Text('确定要使用「${file.filename}」恢复路由配置吗？恢复期间路由可能短暂离线。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.restoreBackup(file);
    if (ok) {
      ToastUtil.success('恢复任务已启动');
      await Future.delayed(const Duration(seconds: 3));
      await controller.refreshHistories();
    } else {
      ToastUtil.error(controller.errorText.value ?? '恢复失败');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    IkuaiRouterBackupFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定要删除「${file.filename}」吗？删除后不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onError,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteBackup(file);
    if (ok) {
      ToastUtil.success('已删除');
      await controller.refreshHistories();
    } else {
      ToastUtil.error(controller.errorText.value ?? '删除失败');
    }
  }

  Future<void> _download(IkuaiRouterBackupFile file) async {
    final path = await controller.downloadBackup(file);
    if (path == null) {
      ToastUtil.error('下载失败，请稍后重试');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: '爱快路由备份：${file.filename}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Obx(() {
      final controller = this.controller;
      final histories = controller.histories.value;
      final backups = controller.backups.toList();
      final busy = controller.actionLoading.value ||
          (histories?.backupRunning ?? false) ||
          (histories?.restoreRunning ?? false);

      final sections = <Widget>[
        _SectionHeader(
          title: '备份管理',
          icon: Icons.backup_rounded,
          trailing: FilledButton.icon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: busy
                ? null
                : () async {
                    final ok = await controller.startBackup();
                    if (ok) {
                      ToastUtil.success('备份任务已启动');
                      await Future.delayed(const Duration(seconds: 3));
                      await controller.refreshHistories();
                    } else {
                      ToastUtil.error(
                        controller.errorText.value ?? '启动备份失败',
                      );
                    }
                  },
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CupertinoActivityIndicator(radius: 6),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              busy
                  ? ((histories?.backupRunning ?? false)
                      ? '备份中'
                      : '恢复中')
                  : '立即备份',
            ),
          ),
        ),
      ];

      if (histories != null &&
          (histories.backupRunning || histories.restoreRunning)) {
        sections.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              histories.backupRunning
                  ? '备份任务进行中：${histories.backupActivity}'
                  : '恢复任务进行中：${histories.restoreActivity}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        );
      }

      if (backups.isEmpty) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('暂无可用备份文件', style: mutedStyle),
          ),
        );
      } else {
        sections.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              '可恢复备份',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        );
        for (final file in backups.take(20)) {
          final operating = controller.operatingKey.value != null;
          sections.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Color(0xFF1E88E5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.filename,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${file.source} · ${file.timeLabel}',
                          style: mutedStyle,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '恢复',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    onPressed: operating
                        ? null
                        : () => _confirmRestore(context, file),
                  ),
                  IconButton(
                    tooltip: '下载',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    onPressed: operating
                        ? null
                        : () => _download(file),
                  ),
                  IconButton(
                    tooltip: '删除',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: operating
                        ? null
                        : () => _confirmDelete(context, file),
                  ),
                ],
              ),
            ),
          );
        }
      }

      final history = histories?.backupHistory ?? <IkuaiRouterHistoryEntry>[];
      if (history.isNotEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              '最近历史',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        );
        for (final entry in history.take(6)) {
          sections.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    entry.success
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: entry.success
                        ? const Color(0xFF2E9E5B)
                        : const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.message,
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(entry.timeLabel, style: mutedStyle),
                ],
              ),
            ),
          );
        }
      }

      return Section(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      );
    });
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.controller, required this.alerts});

  final IkuaiRouterBackupFormController controller;
  final IkuaiRouterAlerts alerts;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '负载告警',
            icon: Icons.notification_important_rounded,
            color: const Color(0xFFFB8C00),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '刷新',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: controller.load,
                ),
                if (alerts.items.isNotEmpty)
                  IconButton(
                    tooltip: '清空',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    onPressed: () async {
                      final ok = await controller.clearAlerts();
                      if (ok) {
                        ToastUtil.success('告警记录已清空');
                        await controller.load();
                      } else {
                        ToastUtil.error('清空失败');
                      }
                    },
                  ),
              ],
            ),
          ),
          if (!alerts.enabled)
            Text('负载告警未启用，可在插件配置中开启', style: mutedStyle)
          else if (alerts.items.isEmpty)
            Text('暂无告警记录（阈值 CPU ${alerts.cpuThreshold.toStringAsFixed(0)}% / 内存 ${alerts.memThreshold.toStringAsFixed(0)}%）', style: mutedStyle)
          else
            for (final alert in alerts.items.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Color(0xFFFB8C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${alert.kind} 峰值 CPU ${alert.peakCpu.toStringAsFixed(0)}% / 内存 ${alert.peakMem.toStringAsFixed(0)}% · ${alert.durationLabel}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    Text(alert.timeLabel, style: mutedStyle),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TestConnectionSection extends StatelessWidget {
  const _TestConnectionSection({required this.controller});

  final IkuaiRouterBackupFormController controller;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Obx(() {
      final busy = controller.actionLoading.value;
      final result = controller.testResult.value;
      return Section(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '连接测试',
              icon: Icons.wifi_tethering_rounded,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGreen,
                context,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '使用当前表单中的地址与凭据测试爱快连接',
                    style: mutedStyle,
                  ),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: busy ? null : controller.testConnection,
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CupertinoActivityIndicator(radius: 6),
                        )
                      : const Text('测试连接'),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Text(result, style: mutedStyle),
            ],
          ],
        ),
      );
    });
  }
}

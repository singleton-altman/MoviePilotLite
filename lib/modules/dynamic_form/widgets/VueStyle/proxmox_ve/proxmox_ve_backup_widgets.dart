import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/proxmox_ve_converter/proxmox_ve_backup_converter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/proxmox_ve/proxmox_ve_backup_ops.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/proxmox_ve/proxmox_ve_storage_targets_editor.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// 向注册表注册 ProxmoxVEBackup 自定义渲染器
void registerProxmoxVeBackupRenderer() {
  PluginFormAdapterRegistry.registerRenderer('ProxmoxVEBackup', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    Widget proxmoxBuildBlock(BuildContext ctx, FormBlock b) {
      if (formMode && b is PageHeaderBlock) {
        return SectionHeader(title: b.title, subtitle: b.subtitle);
      }
      return buildBlock(ctx, b);
    }

    return formMode
        ? ProxmoxFormRenderer(
            blocks: blocks,
            controller: controller,
            buildBlock: proxmoxBuildBlock,
          )
        : ProxmoxPageView(
            controller: controller,
            blocks: blocks,
            buildBlock: buildBlock,
          );
  });
}

/// Proxmox 页面渲染器：按 Web 端 AppPage.vue 旧版排版重建
/// 主机概况 → 最近任务 → 性能监控 → 虚拟机/容器 → 备份文件 → 历史 → 镜像模板。
/// 运维按钮归属对应卡片，不再单独列出。
class ProxmoxPageView extends StatefulWidget {
  const ProxmoxPageView({
    super.key,
    required this.controller,
    required this.blocks,
    required this.buildBlock,
  });

  final DynamicFormController controller;
  final List<FormBlock> blocks;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  State<ProxmoxPageView> createState() => _ProxmoxPageViewState();
}

class _ProxmoxPageViewState extends State<ProxmoxPageView> {
  Worker? _pendingWorker;

  ProxmoxVEBackupFormController? get _adapter {
    final a = widget.controller.pluginAdapter;
    return a is ProxmoxVEBackupFormController ? a : null;
  }

  @override
  void initState() {
    super.initState();
    // 备份行操作（恢复/删除）统一在这里弹确认框
    final adapter = _adapter;
    if (adapter != null) {
      _pendingWorker = ever(adapter.pendingBackupAction, (action) async {
        if (action == null) return;
        adapter.pendingBackupAction.value = null;
        if (!mounted) return;
        if (action.type == 'restore') {
          await ProxmoxOps.showRestoreDialog(context, adapter, action.item);
        } else if (action.type == 'delete') {
          await ProxmoxOps.confirmDeleteBackup(context, adapter, action.item);
        }
      });
    }
  }

  @override
  void dispose() {
    _pendingWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adapter = _adapter;
    if (adapter == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: widget.blocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => Section(
          child: widget.buildBlock(context, widget.blocks[index]),
        ),
      );
    }

    return Obx(() {
      final loading = widget.controller.isLoading.value;
      final pveStatus = adapter.pveStatus.value;
      final monitor = adapter.monitor.value;
      final hasData = (pveStatus != null && pveStatus.isNotEmpty) ||
          adapter.availableBackups.isNotEmpty;

      if (!hasData && loading) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (!hasData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                adapter.errorText.value ?? '暂无数据',
                style: TextStyle(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.controller.load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重新获取'),
              ),
            ],
          ),
        );
      }

      final sections = <Widget>[
        _HostOverviewCard(controller: adapter, pveStatus: pveStatus ?? {}),
        _TasksCard(controller: adapter, monitor: monitor),
        _PerfCard(controller: adapter, monitor: monitor),
        _VmsCard(controller: adapter),
        _BackupsCard(controller: adapter),
        _HistoryCard(
          title: '备份历史',
          iconName: Icons.history_rounded,
          color: const Color(0xFF1E88E5),
          records: adapter.backupHistoryList.toList(),
        ),
        _HistoryCard(
          title: '恢复历史',
          iconName: Icons.restore_rounded,
          color: const Color(0xFFFB8C00),
          records: adapter.restoreHistoryList.toList(),
        ),
        if (adapter.templates.isNotEmpty)
          _TemplatesCard(controller: adapter),
      ];

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => sections[index],
      );
    });
  }
}

// ============ 通用小组件 ============

String _fmtUptime(int seconds) {
  if (seconds <= 0) return '-';
  final d = seconds ~/ 86400;
  final h = (seconds % 86400) ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (d > 0) return '$d天$h小时';
  if (h > 0) return '$h小时$m分';
  return '$m分钟';
}

Color _barColor(double percent) {
  if (percent >= 80) return const Color(0xFFE53935);
  if (percent >= 50) return const Color(0xFFFB8C00);
  return const Color(0xFF2E9E5B);
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({
    required this.values,
    required this.color,
    this.multiLine,
  });

  final List<double> values;
  final Color color;

  /// 第二条线（如网络流入/流出），与 values 同长度
  final List<double>? multiLine;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 56),
      painter: _MiniLineChartPainter(
        values: values,
        color: color,
        secondValues: multiLine,
      ),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  _MiniLineChartPainter({
    required this.values,
    required this.color,
    this.secondValues,
  });

  final List<double> values;
  final List<double>? secondValues;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    void paintSeries(List<double> data, Color c, {bool fill = true}) {
      if (data.isEmpty) return;
      final maxV = data.fold<double>(0, (m, v) => v > m ? v : m);
      final max = maxV <= 0 ? 1.0 : maxV;
      final stepX = data.length > 1 ? size.width / (data.length - 1) : 0.0;
      final points = <Offset>[
        for (var i = 0; i < data.length; i++)
          Offset(
            i * stepX,
            size.height - (data[i] / max).clamp(0.0, 1.0) * (size.height - 4) - 2,
          ),
      ];
      final linePaint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawPath(Path()..addPolygon(points, false), linePaint);
      if (fill) {
        final area = Path()..addPolygon(points, false);
        area.lineTo(size.width, size.height);
        area.lineTo(0, size.height);
        area.close();
        canvas.drawPath(area, Paint()..color = c.withValues(alpha: 0.12));
      }
    }

    paintSeries(values, color);
    final second = secondValues;
    if (second != null && second.any((v) => v > 0)) {
      paintSeries(second, const Color(0xFF43B581), fill: false);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.secondValues != secondValues;
}

Widget _labeledChart(
  BuildContext context, {
  required String title,
  required String last,
  Color? lastColor,
  required Widget chart,
}) {
  final mutedStyle = TextStyle(
    fontSize: 11,
    color: CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    ),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: mutedStyle),
          Text(
            last,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: lastColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      chart,
    ],
  );
}

String _fmtBytes(double bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes;
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[u]}';
}

// ============ 主机概况卡（含清理/重启/关机/终端按钮） ============

class _HostOverviewCard extends StatelessWidget {
  const _HostOverviewCard({required this.controller, required this.pveStatus});

  final ProxmoxVEBackupFormController controller;
  final Map<String, dynamic> pveStatus;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final online = pveStatus['online'] == true;
    final hostname = pveStatus['hostname']?.toString() ?? '';
    final cpuUsage = ProxmoxVEBackupConverter.numOf(pveStatus['cpu_usage']) ?? 0;
    final memUsage = ProxmoxVEBackupConverter.numOf(pveStatus['mem_usage']) ?? 0;
    final diskUsage = ProxmoxVEBackupConverter.numOf(pveStatus['disk_usage']) ?? 0;
    final swapUsage = ProxmoxVEBackupConverter.numOf(pveStatus['swap_usage']) ?? 0;
    final cpuTemp = ProxmoxVEBackupConverter.numOf(pveStatus['cpu_temp']);
    final cpuModel = pveStatus['cpu_model']?.toString() ?? '';
    final cpuCores = pveStatus['cpu_cores']?.toString() ?? '';
    final memTotal = ProxmoxVEBackupConverter.numOf(pveStatus['mem_total']) ?? 0;
    final memUsed = ProxmoxVEBackupConverter.numOf(pveStatus['mem_used']) ?? 0;
    final diskTotal = ProxmoxVEBackupConverter.numOf(pveStatus['disk_total']) ?? 0;
    final diskUsed = ProxmoxVEBackupConverter.numOf(pveStatus['disk_used']) ?? 0;
    final loadAvg = (pveStatus['load_avg'] as List?) ?? const [];
    final monitor = controller.monitor.value;
    final storages = (monitor?['storages'] as List?) ?? const [];

    Widget bar(String label, String valueText, double percent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5)),
              Text(valueText, style: mutedStyle),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(_barColor(percent)),
            ),
          ),
        ],
      );
    }

    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_rounded, size: 18, color: Color(0xFF1E88E5)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '主机概况',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (hostname.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _chip(hostname, const Color(0xFF1E88E5)),
                ),
              _chip(online ? '在线' : '离线',
                  online ? const Color(0xFF2E9E5B) : const Color(0xFFE53935)),
            ],
          ),
          const SizedBox(height: 4),
          // 卡片级运维按钮（对齐 Web 端主机概况卡头部按钮）
          Row(
            children: [
              _iconAction(
                context,
                icon: Icons.cleaning_services_rounded,
                tooltip: '清理系统日志',
                color: const Color(0xFF00897B),
                onTap: () => ProxmoxOps.cleanupLogs(context, controller),
              ),
              _iconAction(
                context,
                icon: Icons.delete_sweep_outlined,
                tooltip: '清理临时空间',
                color: const Color(0xFF00897B),
                onTap: () => ProxmoxOps.cleanupTmp(context, controller),
              ),
              _iconAction(
                context,
                icon: Icons.restart_alt_rounded,
                tooltip: '重启主机',
                color: const Color(0xFFFB8C00),
                onTap: () => ProxmoxOps.hostReboot(context, controller),
              ),
              _iconAction(
                context,
                icon: Icons.power_settings_new_rounded,
                tooltip: '关闭主机',
                color: const Color(0xFFE53935),
                onTap: () => ProxmoxOps.hostShutdown(context, controller),
              ),
              _iconAction(
                context,
                icon: Icons.terminal_rounded,
                tooltip: '宿主机终端',
                color: const Color(0xFF7C4DFF),
                onTap: () => ProxmoxOps.showTerminalDialog(context, controller),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.opsLoading.value ? null : controller.reloadPage,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('刷新'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (cpuModel.isNotEmpty || cpuCores.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [
                if (cpuModel.isNotEmpty) cpuModel,
                if (cpuCores.isNotEmpty) '$cpuCores 核',
                if ((pveStatus['ip']?.toString() ?? '').isNotEmpty)
                  pveStatus['ip'].toString(),
                if ((pveStatus['kernel']?.toString() ?? '').isNotEmpty)
                  pveStatus['kernel'].toString(),
              ].join(' · '),
              style: mutedStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          bar(
            'CPU 使用率${cpuTemp != null ? ' · ${cpuTemp.toStringAsFixed(0)}°C' : ''}',
            '${cpuUsage.toStringAsFixed(1)}%',
            cpuUsage,
          ),
          const SizedBox(height: 10),
          bar(
            '内存使用率',
            memTotal > 0
                ? '${SizeFormatter.formatSizeFromMb(memUsed / 1024 / 1024)}/${SizeFormatter.formatSizeFromMb(memTotal / 1024 / 1024)}'
                : '${memUsage.toStringAsFixed(1)}%',
            memUsage,
          ),
          const SizedBox(height: 10),
          bar(
            '磁盘使用率',
            diskTotal > 0
                ? '${SizeFormatter.formatSizeFromMb(diskUsed / 1024 / 1024)}/${SizeFormatter.formatSizeFromMb(diskTotal / 1024 / 1024)}'
                : '${diskUsage.toStringAsFixed(1)}%',
            diskUsage,
          ),
          if (swapUsage > 0) ...[
            const SizedBox(height: 10),
            bar('Swap 使用率', '${swapUsage.toStringAsFixed(1)}%', swapUsage),
          ],
          if (loadAvg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '负载 ${loadAvg.map((e) => e?.toString() ?? '').join(' / ')}',
              style: mutedStyle,
            ),
          ],
          // 存储空间（来自监控数据的 storage 列表）
          for (final s in storages)
            if (s is Map) ...[
              const SizedBox(height: 10),
              bar(
                '${s['storage'] ?? ''}${s['content'] != null ? ' · ${s['content']}' : ''}',
                '${SizeFormatter.formatSizeFromMb((ProxmoxVEBackupConverter.numOf(s['used']) ?? 0).toDouble() / 1024 / 1024)}/'
                '${SizeFormatter.formatSizeFromMb((ProxmoxVEBackupConverter.numOf(s['total']) ?? 0).toDouble() / 1024 / 1024)}',
                ((ProxmoxVEBackupConverter.numOf(s['used_fraction']) ?? 0).toDouble() * 100),
              ),
            ],
        ],
      ),
    );
  }

  Widget _iconAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 19, color: color),
      onPressed: controller.opsLoading.value ? null : onTap,
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============ 最近任务卡 ============

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.controller, required this.monitor});

  final ProxmoxVEBackupFormController controller;
  final Map<String, dynamic>? monitor;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final tasks = ((monitor?['tasks'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: '最近任务',
            icon: Icons.format_list_bulleted_rounded,
            color: Color(0xFF3949AB),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                controller.monitorLoading.value ? '加载中…' : '暂无任务记录',
                style: mutedStyle,
              ),
            )
          else
            for (final t in tasks.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _taskRunning(t)
                          ? Icons.schedule_rounded
                          : Icons.check_circle_rounded,
                      size: 15,
                      color: _taskRunning(t)
                          ? const Color(0xFFFB8C00)
                          : const Color(0xFF2E9E5B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t['desc'] ?? t['type'] ?? ''}'
                        '${t['vmid'] != null ? ' #${t['vmid']}' : ''}',
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (t['starttime'] != null)
                      Text(
                        ProxmoxVEBackupConverter.formatTime(t['starttime']),
                        style: mutedStyle,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _taskRunning(t) ? '进行中' : '完成',
                      style: mutedStyle,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static bool _taskRunning(Map<String, dynamic> t) {
    return t['endtime'] == null ||
        t['endtime'] == 0 ||
        (t['status']?.toString() ?? '').contains('running');
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
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

// ============ 性能监控卡（rrd 折线图） ============

class _PerfCard extends StatelessWidget {
  const _PerfCard({required this.controller, required this.monitor});

  final ProxmoxVEBackupFormController controller;
  final Map<String, dynamic>? monitor;

  List<double> _series(List rrd, String key) {
    return rrd
        .map<double>((e) =>
            e is Map
                ? (ProxmoxVEBackupConverter.numOf(e[key]) ?? 0)
                : 0.0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = this.monitor;
    final rrd = (monitor?['rrd'] as List?) ?? const [];
    final loading = controller.monitorLoading.value;
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );

    // rrd 值：cpu 0-1，mem/maxmem 字节，netin/netout 字节/s，rootfs/maxrootfs 字节
    final cpu = _series(rrd, 'cpu').map((v) => v * 100).toList();
    final mem = _series(rrd, 'mem');
    final maxMem = _series(rrd, 'maxmem');
    final memPct = <double>[
      for (var i = 0; i < mem.length; i++)
        maxMem[i] > 0 ? mem[i] / maxMem[i] * 100 : 0,
    ];
    final netin = _series(rrd, 'netin');
    final netout = _series(rrd, 'netout');
    final rootfs = _series(rrd, 'rootfs');
    final maxRoot = _series(rrd, 'maxrootfs');
    final rootPct = <double>[
      for (var i = 0; i < rootfs.length; i++)
        maxRoot[i] > 0 ? rootfs[i] / maxRoot[i] * 100 : 0,
    ];

    final hasCharts = cpu.isNotEmpty && cpu.any((v) => v > 0) ||
        memPct.any((v) => v > 0) ||
        netin.any((v) => v > 0);

    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: '性能监控',
            icon: Icons.area_chart_rounded,
            color: const Color(0xFF1E88E5),
            trailing: IconButton(
              tooltip: '刷新监控',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: controller.loadMonitor,
            ),
          ),
          if (!hasCharts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                loading ? '加载中…' : '暂无监控数据（请检查 PVE API 端口 8006 是否可达）',
                style: mutedStyle,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final half = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: half,
                      child: _labeledChart(
                        context,
                        title: 'CPU 使用率',
                        last:
                            '${(cpu.isEmpty ? 0 : cpu.last).toStringAsFixed(1)}%',
                        lastColor: _barColor(cpu.isEmpty ? 0 : cpu.last),
                        chart: _MiniLineChart(
                          values: cpu,
                          color: const Color(0xFF4F8CFF),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: _labeledChart(
                        context,
                        title: '内存使用率',
                        last:
                            '${(memPct.isEmpty ? 0 : memPct.last).toStringAsFixed(1)}%',
                        lastColor:
                            _barColor(memPct.isEmpty ? 0 : memPct.last),
                        chart: _MiniLineChart(
                          values: memPct,
                          color: const Color(0xFF43E97B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: _labeledChart(
                        context,
                        title: '网络流入 / 流出',
                        last:
                            '${_fmtBytes(netin.isEmpty ? 0 : netin.last)}/s',
                        chart: _MiniLineChart(
                          values: netin,
                          multiLine: netout,
                          color: const Color(0xFF4F8CFF),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: _labeledChart(
                        context,
                        title: '根分区使用率',
                        last:
                            '${(rootPct.isEmpty ? 0 : rootPct.last).toStringAsFixed(1)}%',
                        chart: _MiniLineChart(
                          values: rootPct,
                          color: const Color(0xFFAB47BC),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============ 虚拟机 / 容器卡 ============

class _VmsCard extends StatefulWidget {
  const _VmsCard({required this.controller});

  final ProxmoxVEBackupFormController controller;

  @override
  State<_VmsCard> createState() => _VmsCardState();
}

class _VmsCardState extends State<_VmsCard> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Obx(() {
        final containers = controller.containersList.toList();
        final keyword = _search.text.trim().toLowerCase();
        final filtered = keyword.isEmpty
            ? containers
            : containers.where((c) {
                final s =
                    '${c['displayName'] ?? ''} ${c['name'] ?? ''} ${c['vmid'] ?? ''} ${c['type'] ?? ''}'
                    ' ${c['status'] ?? ''}'
                    ' ${((c['tags'] as List?) ?? const []).join(' ')}'
                    .toLowerCase();
                return s.contains(keyword);
              }).toList();
        final running = containers
            .where((c) => c['status']?.toString() == 'running')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              title: '虚拟机 / 容器',
              icon: Icons.monitor_rounded,
              color: const Color(0xFF00897B),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _chip('运行 $running', const Color(0xFF2E9E5B)),
                  const SizedBox(width: 4),
                  _chip('停止 ${containers.length - running}', Colors.grey),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '搜索 ID / 名称 / 标签',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: controller.containerActionLoading.value
                      ? null
                      : () => ProxmoxOps.stopAllTasks(context, controller),
                  icon: const Icon(Icons.stop_circle_outlined,
                      size: 16, color: Color(0xFFE53935)),
                  label: const Text('全部停止'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.containerLoadFailed.value && containers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded,
                        size: 16, color: Color(0xFFE53935)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '获取虚机/容器列表失败（SSH 连接异常或超时）',
                        style: mutedStyle,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.containerRetrying.value
                          ? null
                          : controller.retryContainers,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            else if (containers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('暂无数据', style: mutedStyle),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('没有匹配的虚拟机 / 容器', style: mutedStyle),
                ),
              )
            else
              for (final vm in filtered)
                _VmRow(
                  controller: controller,
                  vm: vm,
                  mutedStyle: mutedStyle,
                ),
          ],
        );
      }),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _VmRow extends StatelessWidget {
  const _VmRow({
    required this.controller,
    required this.vm,
    required this.mutedStyle,
  });

  final ProxmoxVEBackupFormController controller;
  final Map<String, dynamic> vm;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final vmid = vm['vmid']?.toString() ?? '';
    final type = vm['type']?.toString() ?? '';
    final status = vm['status']?.toString() ?? '';
    final running = status == 'running';
    final uptime = ProxmoxVEBackupConverter.intOfNum(vm['uptime']);
    final name =
        (vm['displayName'] ?? vm['name'] ?? vmid).toString();
    final isLxc = type == 'lxc' || type == 'LXC';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isLxc ? Icons.inventory_2_outlined : Icons.dns_outlined,
            size: 18,
            color: running ? const Color(0xFF2E9E5B) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('#$vmid · ${type.toUpperCase()}', style: mutedStyle),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      running ? '运行中' : '已停止',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: running
                            ? const Color(0xFF2E9E5B)
                            : CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                      ),
                    ),
                    if (running && uptime > 0) ...[
                      const SizedBox(width: 6),
                      Text('已运行 ${_fmtUptime(uptime)}', style: mutedStyle),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 行内操作：画面（仅 qemu）+ 启动/停止/重启/快照
          if (type == 'qemu')
            IconButton(
              tooltip: '实时画面',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.monitor_rounded, size: 17),
              onPressed: () => ProxmoxOps.showScreenDialog(
                context,
                controller,
                initialVmid: vmid,
              ),
            ),
          for (final act in ProxmoxOps.vmActions(running))
            IconButton(
              tooltip: act.label,
              visualDensity: VisualDensity.compact,
              icon: Icon(act.icon, size: 17, color: act.color),
              onPressed: controller.containerActionLoading.value
                  ? null
                  : () => ProxmoxOps.vmAction(context, controller, vm, act.action),
            ),
        ],
      ),
    );
  }
}

// ============ 备份文件卡 ============

class _BackupsCard extends StatelessWidget {
  const _BackupsCard({required this.controller});

  final ProxmoxVEBackupFormController controller;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Obx(() {
        final backups = controller.availableBackups.toList();
        final status = controller.pluginStatus.value;
        final backupActivity = status?['backup_activity']?.toString() ?? '';
        final restoreActivity = status?['restore_activity']?.toString() ?? '';
        final busy = controller.opsLoading.value ||
            (backupActivity.isNotEmpty && backupActivity != '空闲') ||
            (restoreActivity.isNotEmpty && restoreActivity != '空闲');
        final local = backups
            .where((b) => b['source']?.toString() == '本地备份')
            .length;
        final webdav = backups
            .where((b) => b['source']?.toString() == 'WebDAV备份')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              title: '备份文件',
              icon: Icons.backup_outlined,
              color: const Color(0xFFFFB300),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _chip('本地 $local', const Color(0xFF1E88E5)),
                  const SizedBox(width: 4),
                  _chip('WebDAV $webdav', const Color(0xFF7C4DFF)),
                ],
              ),
            ),
            Row(
              children: [
                if (backupActivity.isNotEmpty && backupActivity != '空闲')
                  Expanded(
                    child: Text(
                      '备份中：$backupActivity',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFB8C00),
                      ),
                    ),
                  )
                else if (restoreActivity.isNotEmpty &&
                    restoreActivity != '空闲')
                  Expanded(
                    child: Text(
                      '恢复中：$restoreActivity',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFB8C00),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: busy
                      ? null
                      : () => ProxmoxOps.runBackup(context, controller),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('立即备份'),
                ),
                IconButton(
                  tooltip: '清空备份/恢复历史',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.history_toggle_off, size: 18),
                  onPressed: busy
                      ? null
                      : () => ProxmoxOps.clearHistory(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (backups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: Text('暂无备份文件', style: mutedStyle)),
              )
            else
              for (final f in backups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        f['source']?.toString() == 'WebDAV备份'
                            ? Icons.cloud_outlined
                            : Icons.save_outlined,
                        size: 17,
                        color: f['source']?.toString() == 'WebDAV备份'
                            ? const Color(0xFF7C4DFF)
                            : const Color(0xFF1E88E5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['filename']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(ProxmoxVEBackupConverter.numOf(f['size_mb']) ?? 0).toStringAsFixed(1)} MB'
                              ' · ${f['time_str']?.toString() ?? ProxmoxVEBackupConverter.formatTime(f['timestamp'])}',
                              style: mutedStyle,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '下载',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.download_rounded,
                            size: 18, color: Color(0xFF1E88E5)),
                        onPressed: controller.opsLoading.value
                            ? null
                            : () => ProxmoxOps.downloadBackup(controller, f),
                      ),
                      IconButton(
                        tooltip: '恢复',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.restore_rounded,
                            size: 18, color: Color(0xFF7C4DFF)),
                        onPressed: controller.opsLoading.value
                            ? null
                            : () => ProxmoxOps.showRestoreDialog(
                                  context,
                                  controller,
                                  f,
                                ),
                      ),
                      IconButton(
                        tooltip: '删除',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Color(0xFFE53935)),
                        onPressed: controller.opsLoading.value
                            ? null
                            : () => ProxmoxOps.confirmDeleteBackup(
                                  context,
                                  controller,
                                  f,
                                ),
                      ),
                    ],
                  ),
                ),
          ],
        );
      }),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============ 历史 / 镜像模板卡 ============

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.iconName,
    required this.color,
    required this.records,
  });

  final String title;
  final IconData iconName;
  final Color color;
  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final recent = records.reversed.take(10).toList();
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: title,
            icon: iconName,
            color: color,
            trailing: Text(
              '${records.length} 条',
              style: mutedStyle,
            ),
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('暂无记录', style: mutedStyle),
            )
          else
            for (final r in recent) ...[
              Row(
                children: [
                  Icon(
                    r['success'] == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: r['success'] == true
                        ? const Color(0xFF2E9E5B)
                        : const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['filename']?.toString() ?? '(无文件名)',
                          style: const TextStyle(fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((r['message']?.toString() ?? '').isNotEmpty)
                          Text(
                            r['message'].toString(),
                            style: mutedStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ProxmoxVEBackupConverter.formatTime(r['timestamp']),
                    style: mutedStyle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _TemplatesCard extends StatelessWidget {
  const _TemplatesCard({required this.controller});

  final ProxmoxVEBackupFormController controller;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              title: '镜像模板',
              icon: Icons.album_outlined,
              color: const Color(0xFF7C4DFF),
              trailing: Text(
                '${controller.templates.length} 个',
                style: mutedStyle,
              ),
            ),
            for (final t in controller.templates.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      t['type']?.toString() == 'iso'
                          ? Icons.album_outlined
                          : Icons.inventory_2_outlined,
                      size: 16,
                      color: t['type']?.toString() == 'iso'
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF7C4DFF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t['filename']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(ProxmoxVEBackupConverter.numOf(t['size_mb']) ?? 0).toStringAsFixed(1)} MB'
                      '${t['date'] != null ? ' · ${t['date']}' : ''}',
                      style: mutedStyle,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Proxmox 表单内容渲染器：对表单控件使用增强样式
class ProxmoxFormRenderer extends StatelessWidget {
  const ProxmoxFormRenderer({
    super.key,
    required this.blocks,
    required this.controller,
    required this.buildBlock,
  });

  final List<FormBlock> blocks;
  final DynamicFormController controller;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  Widget build(BuildContext context) {
    final proxmoxAdapter =
        controller.pluginAdapter is ProxmoxVEBackupFormController
        ? controller.pluginAdapter! as ProxmoxVEBackupFormController
        : null;
    final items = <Widget>[];
    for (final b in blocks) {
      items.add(buildBlock(context, b));
      // 「备份存储」标题后插入多目标编辑器（对齐 Web 端 Config.vue 顺序）
      if (proxmoxAdapter != null &&
          b is PageHeaderBlock &&
          b.title == '备份存储') {
        items.add(ProxmoxStorageTargetsEditor(controller: proxmoxAdapter));
      }
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

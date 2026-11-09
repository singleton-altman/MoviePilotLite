import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/ikuai_router_backup_form_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 爱快路由「实时监控」多视图卡（对齐 Web 端 AppPage.vue monitor 卡）。
///
/// 视图数据来源：
/// - 流量/连接数分布 → GET /protocol_flow
/// - IPv4 终端       → GET /devices
/// - 其余视图        → GET /monitor_view?view=<view>&datetype=hour
class IkuaiRealtimeMonitorSection extends StatelessWidget {
  const IkuaiRealtimeMonitorSection({super.key, required this.controller});

  final IkuaiRouterBackupFormController controller;

  static const _views = <(String, String)>[
    ('proto', '流量/连接数分布'),
    ('topflow', '终端排行'),
    ('apptop', '协议排行'),
    ('perf', '性能负载'),
    ('network', '网络负载'),
    ('flowsplit', '分流监控'),
    ('devices4', 'IPv4 终端'),
    ('devices6', 'IPv6 终端'),
    ('camera', '摄像头'),
    ('dhcp', 'DHCP 终端'),
    ('blacklist', '黑名单'),
    ('dns', 'DNS 设置'),
    ('routes', '路由表'),
    ('upnp', 'UPnP'),
  ];

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
          Obx(() {
            final current = controller.monitorView.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (final (value, label) in _views)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ViewChip(
                        label: label,
                        selected: current == value,
                        onTap: () => controller.switchMonitorView(value),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final loading = controller.monitorLoading.value;
            final error = controller.monitorError.value;
            final data = controller.monitorViewData.value;
            final view = controller.monitorView.value;

            if (loading && data == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            if (error != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFFB8C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error, style: mutedStyle)),
                    TextButton(
                      onPressed: () => controller.loadMonitorView(force: true),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }
            if (data == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('暂无数据', style: mutedStyle)),
              );
            }

            switch (view) {
              case 'proto':
                return _ProtoView(data: data, mutedStyle: mutedStyle);
              case 'topflow':
                return _TopflowView(data: data, mutedStyle: mutedStyle);
              case 'apptop':
                return _ApptopView(data: data, mutedStyle: mutedStyle);
              case 'perf':
                return _PerfView(data: data);
              case 'network':
                return _NetworkView(data: data, mutedStyle: mutedStyle);
              case 'flowsplit':
                return _FlowsplitView(data: data, mutedStyle: mutedStyle);
              case 'devices4':
              case 'devices6':
                return _DevicesView(
                  data: data,
                  mutedStyle: mutedStyle,
                  isV6: view == 'devices6',
                );
              case 'camera':
                return _CameraView(data: data, mutedStyle: mutedStyle);
              case 'dhcp':
                return _DhcpView(data: data, mutedStyle: mutedStyle);
              case 'blacklist':
                return _BlacklistView(data: data, mutedStyle: mutedStyle);
              case 'dns':
                return _DnsView(data: data, mutedStyle: mutedStyle);
              case 'routes':
                return _RoutesView(data: data, mutedStyle: mutedStyle);
              case 'upnp':
                return _UpnpView(data: data, mutedStyle: mutedStyle);
              default:
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('暂不支持该视图', style: mutedStyle)),
                );
            }
          }),
        ],
      ),
    );
  }
}

// ============ 视图组件 ============

/// 协议中文名（对齐爱快官方译名）
const _protoNames = {
  'HTTP': 'HTTP协议',
  'Video': '网络视频',
  'Game': '网络游戏',
  'Transport': '文件传输',
  'IM': '网络通讯',
  'Common': '常用协议',
  'Download': '网络下载',
  'Others': '其它应用',
  'Test': '测速软件',
  'Unknown': '未知应用',
  'Total': '所有协议',
};

const _protoColors = {
  'HTTP': Color(0xFF9A7FD1),
  'Video': Color(0xFFFFB980),
  'Game': Color(0xFFDC69AA),
  'Download': Color(0xFF5CADFF),
  'Transport': Color(0xFF2DB7F5),
  'IM': Color(0xFF19BE6B),
  'Common': Color(0xFFFF9900),
  'Others': Color(0xFF808695),
  'Test': Color(0xFFE062AE),
  'Unknown': Color(0xFFC5C8CE),
};

String _protoName(String name) => _protoNames[name] ?? name;

Color _protoColor(String name) => _protoColors[name] ?? const Color(0xFF4F8CFF);

String _fmtKB(dynamic kb) {
  final v = (kb as num?)?.toDouble() ?? 0;
  if (v >= 1024 * 1024) return '${(v / 1024 / 1024).toStringAsFixed(2)} GB';
  if (v >= 1024) return '${(v / 1024).toStringAsFixed(1)} MB';
  return '${v.toStringAsFixed(0)} KB';
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

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Map<String, dynamic> _mapOf(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const {};
}

Future<void> _copyText(String? value) async {
  final text = (value ?? '').trim();
  if (text.isEmpty || text == '-') return;
  await Clipboard.setData(ClipboardData(text: text));
  ToastUtil.success('已复制：$text');
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

/// 迷你折线图
class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.values, required this.color, this.secondValues});

  final List<double> values;
  final Color color;
  final List<double>? secondValues;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 56),
      painter: _MiniChartPainter(
        values: values,
        color: color,
        secondValues: secondValues,
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter({
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
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
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
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.secondValues != secondValues;
}

Widget _chartCell(
  BuildContext context, {
  required String title,
  required String last,
  Color? lastColor,
  required Widget chart,
  String? rangeStart,
  String? rangeEnd,
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
      if (rangeStart != null || rangeEnd != null)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rangeStart ?? '', style: mutedStyle),
              Text(rangeEnd ?? '', style: mutedStyle),
            ],
          ),
        ),
    ],
  );
}

// ============ 流量/连接数分布（proto） ============

class _ProtoView extends StatelessWidget {
  const _ProtoView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final protocols = _mapList(data['protocols']);
    if (protocols.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无协议流量数据', style: mutedStyle)),
      );
    }
    final connTop = [...protocols]..sort(
        (a, b) => ((b['connect_num'] as num?) ?? 0)
            .compareTo(((a['connect_num'] as num?) ?? 0)),
      );
    final connMax = ((connTop.first['connect_num'] as num?) ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 会话数 Top5
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('网络会话数 Top5', style: mutedStyle),
        ),
        for (final p in connTop.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    _protoName(p['app_name']?.toString() ?? ''),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: connMax > 0
                          ? (((p['connect_num'] as num?) ?? 0).toDouble() / connMax)
                              .clamp(0.04, 1.0)
                          : 0,
                      minHeight: 9,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(p['connect_num'] as num?) ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 20),
        // 协议明细表（前 10）
        _MonoTable(
          headers: const ['协议', '总流量', '上行', '下行', '会话数'],
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(0.8),
          },
          rows: [
            for (final p in protocols.take(10))
              [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _protoColor(p['app_name']?.toString() ?? ''),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _protoName(p['app_name']?.toString() ?? ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                _fmtKB(p['total']),
                _fmtKB(p['upload']),
                _fmtKB(p['download']),
                '${(p['connect_num'] as num?) ?? 0}',
              ],
          ],
        ),
      ],
    );
  }
}

// ============ 排行视图（终端排行 / 协议排行） ============

class _RankList extends StatelessWidget {
  const _RankList({
    required this.rows,
    required this.valueOf,
    required this.labelOf,
    required this.subLabelOf,
    required this.valueTextOf,
    this.leadingColorOf,
    this.mutedStyle,
  });

  final List<Map<String, dynamic>> rows;
  final double Function(Map<String, dynamic> row) valueOf;
  final String Function(Map<String, dynamic> row) labelOf;
  final String? Function(Map<String, dynamic> row) subLabelOf;
  final String Function(Map<String, dynamic> row) valueTextOf;
  final Color Function(Map<String, dynamic> row)? leadingColorOf;
  final TextStyle? mutedStyle;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('暂无排行数据', style: mutedStyle),
        ),
      );
    }
    final max = rows.fold<double>(1, (m, r) {
      final v = valueOf(r);
      return v > m ? v : m;
    });
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          InkWell(
            onTap: () => _copyText(subLabelOf(rows[i])),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i < 3
                            ? Theme.of(context).colorScheme.primary
                            : CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (leadingColorOf != null) ...[
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: leadingColorOf!(rows[i]),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                labelOf(rows[i]),
                                style: const TextStyle(fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (subLabelOf(rows[i])?.isNotEmpty == true)
                          Text(subLabelOf(rows[i])!, style: mutedStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (valueOf(rows[i]) / max).clamp(0.03, 1.0),
                        minHeight: 7,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: Text(
                      valueTextOf(rows[i]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TopflowView extends StatefulWidget {
  const _TopflowView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  State<_TopflowView> createState() => _TopflowViewState();
}

class _TopflowViewState extends State<_TopflowView> {
  bool byConnect = false;

  @override
  Widget build(BuildContext context) {
    final rows = _mapList(widget.data['rows']);
    final sorted = [...rows]..sort((a, b) {
        final key = byConnect ? 'connect_num' : 'total';
        return ((b[key] as num?) ?? 0).compareTo(((a[key] as num?) ?? 0));
      });
    final top = sorted.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ViewChip(
              label: '流量 Top20',
              selected: !byConnect,
              onTap: () => setState(() => byConnect = false),
            ),
            const SizedBox(width: 6),
            _ViewChip(
              label: '连接数 Top20',
              selected: byConnect,
              onTap: () => setState(() => byConnect = true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _RankList(
          rows: top,
          valueOf: (r) => byConnect
              ? ((r['connect_num'] as num?) ?? 0).toDouble()
              : ((r['total'] as num?) ?? 0).toDouble(),
          labelOf: (r) =>
              (r['hostname'] ?? r['comment'] ?? r['ip'] ?? '-').toString(),
          subLabelOf: (r) => r['ip']?.toString(),
          valueTextOf: (r) => byConnect
              ? '${(r['connect_num'] as num?) ?? 0} 个'
              : _fmtBytes(((r['total'] as num?) ?? 0).toDouble()),
          mutedStyle: widget.mutedStyle,
        ),
      ],
    );
  }
}

class _ApptopView extends StatelessWidget {
  const _ApptopView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final rows = _mapList(data['rows']);
    final sorted = [...rows]..sort((a, b) =>
        ((b['total'] as num?) ?? 0).compareTo(((a['total'] as num?) ?? 0)));
    return _RankList(
      rows: sorted.take(20).toList(),
      valueOf: (r) => ((r['total'] as num?) ?? 0).toDouble(),
      labelOf: (r) => _protoName(r['name']?.toString() ?? ''),
      subLabelOf: (_) => '',
      valueTextOf: (r) =>
          _fmtBytes(((r['total'] as num?) ?? 0).toDouble()),
      leadingColorOf: (r) => _protoColor(r['name']?.toString() ?? ''),
      mutedStyle: mutedStyle,
    );
  }
}

// ============ 性能负载（perf） ============

class _PerfView extends StatelessWidget {
  const _PerfView({required this.data});

  final Map<String, dynamic> data;

  List<double> _series(String containerKey, String fieldKey, {double scale = 1}) {
    final items = _mapList(data[containerKey]);
    return items
        .map<double>((e) => ((e[fieldKey] as num?) ?? 0).toDouble() * scale)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cpu = _series('cpu', 'cpu', scale: 100);
    final mem = _series('memory', 'memory_use');
    final terminals = _series('terminals', 'on_terminal');
    final conns = _series('conns', 'conn_num');
    final hasData = cpu.any((v) => v > 0) ||
        mem.any((v) => v > 0) ||
        terminals.any((v) => v > 0) ||
        conns.any((v) => v > 0);
    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            '暂无性能负载数据',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: 'CPU 使用率',
                last: '${(cpu.isEmpty ? 0 : cpu.last).toStringAsFixed(1)}%',
                chart: _MiniChart(
                  values: cpu,
                  color: const Color(0xFF4F8CFF),
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: '内存使用率',
                last: '${(mem.isEmpty ? 0 : mem.last).toStringAsFixed(1)}%',
                chart: _MiniChart(
                  values: mem,
                  color: const Color(0xFF43E97B),
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: '在线终端数',
                last: '${(terminals.isEmpty ? 0 : terminals.last).toStringAsFixed(0)} 台',
                chart: _MiniChart(
                  values: terminals,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: '网络连接数',
                last: '${(conns.isEmpty ? 0 : conns.last).toStringAsFixed(0)} 个',
                chart: _MiniChart(
                  values: conns,
                  color: const Color(0xFFDC69AA),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============ 网络负载（network） ============

class _NetworkView extends StatelessWidget {
  const _NetworkView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  String _tsText(dynamic ts) {
    final n = (ts as num?)?.toInt() ?? 0;
    if (n <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(n * 1000);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final series = _mapList(data['rate_stat']);
    if (series.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无网络负载数据', style: mutedStyle)),
      );
    }
    final upload = series
        .map<double>((e) => ((e['max_upload'] as num?) ?? 0).toDouble())
        .toList();
    final download = series
        .map<double>((e) => ((e['max_download'] as num?) ?? 0).toDouble())
        .toList();
    final rx = series
        .map<double>((e) => ((e['rx_packages'] as num?) ?? 0).toDouble())
        .toList();
    final tx = series
        .map<double>((e) => ((e['tx_packages'] as num?) ?? 0).toDouble())
        .toList();
    final last = series.last;
    final start = _tsText(series.first['timestamp']);
    final end = _tsText(last['timestamp']);

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: '上 / 下行速率',
                last: '↑${IkuaiRouterStatus.formatSpeed(((last['max_upload'] as num?) ?? 0).toDouble())}'
                    ' ↓${IkuaiRouterStatus.formatSpeed(((last['max_download'] as num?) ?? 0).toDouble())}',
                chart: _MiniChart(
                  values: upload,
                  secondValues: download,
                  color: const Color(0xFFEF6B6B),
                ),
                rangeStart: start,
                rangeEnd: end,
              ),
            ),
            SizedBox(
              width: half,
              child: _chartCell(
                context,
                title: '收 / 发包数',
                last: '收 ${(last['rx_packages'] as num?) ?? 0}'
                    ' · 发 ${(last['tx_packages'] as num?) ?? 0}',
                chart: _MiniChart(
                  values: rx,
                  secondValues: tx,
                  color: const Color(0xFF4F8CFF),
                ),
                rangeStart: start,
                rangeEnd: end,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============ 分流监控（flowsplit） ============

class _FlowsplitView extends StatelessWidget {
  const _FlowsplitView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  static const _rowDefs = <(String, String)>[
    ('port_cnt', '端口分流'),
    ('proto_cnt', '协议分流'),
    ('domain_cnt', '域名分流'),
    ('llb_cnt', '多线负载'),
    ('conn_cnt', '总连接数（含未分流）'),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = _mapOf(data['rows']);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无分流监控数据', style: mutedStyle)),
      );
    }
    final today = _mapOf(rows['today']);
    final yesterday = _mapOf(rows['yesterday']);
    final week = _mapOf(rows['week']);
    int numOf(Map m, String key) => (m[key] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonoTable(
          headers: const ['分流方式', '今天', '昨天', '最近 7 天'],
          columnWidths: const {
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          rows: [
            for (final (key, name) in _rowDefs)
              [
                name,
                '${numOf(today, key)}',
                '${numOf(yesterday, key)}',
                '${numOf(week, key)}',
              ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '总连接数包含未命中分流策略的连接；数据由路由器累计，可在爱快「分流监控」页清除',
          style: mutedStyle,
        ),
      ],
    );
  }
}

// ============ 终端列表（IPv4 / IPv6） ============

class _DevicesView extends StatelessWidget {
  const _DevicesView({
    required this.data,
    required this.mutedStyle,
    required this.isV6,
  });

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;
  final bool isV6;

  @override
  Widget build(BuildContext context) {
    final devices = _mapList(data['devices']);
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            isV6 ? '暂无 IPv6 在线终端' : '暂无在线设备数据',
            style: mutedStyle,
          ),
        ),
      );
    }
    final shown = devices.take(50).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '共 ${devices.length} 台${devices.length > 50 ? '（仅显示前 50 条）' : ''}',
            style: mutedStyle,
          ),
        ),
        _MonoTable(
          headers: ['主机名', isV6 ? 'IPv6 地址' : 'IP 地址', 'MAC 地址'],
          columnWidths: const {
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.4),
          },
          rows: [
            for (final d in shown)
              [
                (d['hostname'] ?? d['username'] ?? '未知设备').toString(),
                (d['ip'] ?? d['userip'] ?? '-').toString(),
                (d['mac'] ?? d['usermac'] ?? '-').toString(),
              ],
          ],
          onRowTap: (cells) => _copyText(cells[1]),
        ),
      ],
    );
  }
}

// ============ 摄像头（camera） ============

class _CameraView extends StatelessWidget {
  const _CameraView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final cameras = _mapList(data['cameras']);
    if (cameras.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无摄像头数据', style: mutedStyle)),
      );
    }
    return _MonoTable(
      headers: const ['设备', 'IP 地址', '状态'],
      columnWidths: const {
        0: FlexColumnWidth(1.6),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(0.8),
      },
      rows: [
        for (final c in cameras)
          [
            (c['name'] ?? c['hostname'] ?? c['ip'] ?? '摄像头').toString(),
            (c['ip'] ?? '-').toString(),
            '__chip__${((c['last_time'] as num?) ?? (c['online_time'] as num?) ?? (c['online'] as num?) ?? 0) > 0 ? '在线' : '离线'}',
          ],
      ],
      onRowTap: (cells) => _copyText(cells[1]),
    );
  }
}

// ============ DHCP 租约（dhcp） ============

class _DhcpView extends StatelessWidget {
  const _DhcpView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  String _fmtTs(dynamic ts) {
    final n = (ts as num?)?.toInt() ?? 0;
    if (n <= 0) return '-';
    return formatUnixTime(n.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final leases = _mapList(data['leases']);
    if (leases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无 DHCP 租约记录', style: mutedStyle)),
      );
    }
    final shown = leases.take(50).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '共 ${leases.length} 条${leases.length > 50 ? '（仅显示前 50 条）' : ''}',
            style: mutedStyle,
          ),
        ),
        _MonoTable(
          headers: const ['主机名', 'IP 地址', 'MAC 地址', '接口', '租约到期'],
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(0.8),
            4: FlexColumnWidth(1.3),
          },
          rows: [
            for (final d in shown)
              [
                (d['comment'] ?? d['hostname'] ?? '未知终端').toString(),
                (d['ip'] ?? d['ip_addr'] ?? '-').toString(),
                (d['mac'] ?? '-').toString(),
                (d['interface'] ?? '-').toString(),
                _fmtTs(d['end_time']),
              ],
          ],
          onRowTap: (cells) => _copyText(cells[1]),
        ),
      ],
    );
  }
}

// ============ 黑名单（blacklist） ============

class _BlacklistView extends StatelessWidget {
  const _BlacklistView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final items = _mapList(data['items']);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('黑名单列表为空', style: mutedStyle)),
      );
    }
    final shown = items.take(50).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '共 ${items.length} 条${items.length > 50 ? '（仅显示前 50 条）' : ''}',
            style: mutedStyle,
          ),
        ),
        _MonoTable(
          headers: const ['MAC 地址', '备注', '状态'],
          columnWidths: const {
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1.4),
            2: FlexColumnWidth(0.9),
          },
          rows: [
            for (final b in shown)
              [
                (b['mac'] ?? '-').toString(),
                (b['comment'] ?? '-').toString(),
                '__chip__${b['enabled']?.toString() == 'yes' ? '生效中' : '已停用'}',
              ],
          ],
          onRowTap: (cells) => _copyText(cells[0]),
        ),
      ],
    );
  }
}

// ============ DNS 设置（dns） ============

class _DnsView extends StatelessWidget {
  const _DnsView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final config = _mapOf(data['config']);
    final rules = _mapList(data['rules']);
    if (config.isEmpty && rules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无 DNS 设置数据', style: mutedStyle)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _kv('上游 DNS1', config['dns1']?.toString() ?? '-'),
            _kv('上游 DNS2', config['dns2']?.toString() ?? '-'),
            _kv('DoH 加密解析', config['query']?.toString() ?? '-'),
            _kv(
              'DNS 缓存',
              config['enabled']?.toString() == 'yes'
                  ? '已开启（TTL ${config['cache_ttl'] ?? '-'}s）'
                  : '关闭',
            ),
            _kv('DNS 强制代理',
                config['proxy_force'] == true ? '开启' : '关闭'),
          ],
        ),
        const Divider(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '自定义解析规则（共 ${data['rules_total'] ?? rules.length} 条）',
            style: mutedStyle,
          ),
        ),
        if (rules.isEmpty)
          Text('暂无自定义解析规则', style: mutedStyle)
        else
          _MonoTable(
            headers: const ['域名', '解析地址', '来源', '状态'],
            columnWidths: const {
              0: FlexColumnWidth(1.6),
              1: FlexColumnWidth(1.3),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(0.7),
            },
            rows: [
              for (final r in rules.take(30))
                [
                  (r['domain'] ?? '-').toString(),
                  (r['dns_addr'] ?? '-').toString(),
                  (r['comment'] ?? r['src_addr'] ?? '-').toString(),
                  '__chip__${r['enabled']?.toString() == 'yes' ? '启用' : '停用'}',
                ],
            ],
          ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: mutedStyle),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

// ============ 路由表（routes） ============

class _RoutesView extends StatefulWidget {
  const _RoutesView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  State<_RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<_RoutesView> {
  bool _v6 = false;

  @override
  Widget build(BuildContext context) {
    final v4 = _mapList(widget.data['v4']);
    final v6 = _mapList(widget.data['v6']);
    final rows = _v6 ? v6 : v4;
    if (v4.isEmpty && v6.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无路由表数据', style: widget.mutedStyle)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ViewChip(
              label: 'IPv4（${v4.length}）',
              selected: !_v6,
              onTap: () => setState(() => _v6 = false),
            ),
            const SizedBox(width: 6),
            _ViewChip(
              label: 'IPv6（${v6.length}）',
              selected: _v6,
              onTap: () => setState(() => _v6 = true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text('暂无路由', style: widget.mutedStyle)),
          )
        else
          _MonoTable(
            headers: _v6
                ? const ['目的网段', '网关', '接口', '优先级']
                : const ['目的网段', '子网掩码', '网关', '接口', '优先级'],
            rows: [
              for (final r in rows.take(50))
                [
                  (r['dst_addr'] ?? '-').toString(),
                  if (!_v6) (r['netmask'] ?? '-').toString(),
                  (r['gateway'] ?? '-').toString(),
                  (r['interface'] ?? '-').toString(),
                  '${r['prio'] ?? '-'}',
                ],
            ],
            onRowTap: (cells) => _copyText(cells[0]),
          ),
      ],
    );
  }
}

// ============ UPnP（upnp） ============

class _UpnpView extends StatelessWidget {
  const _UpnpView({required this.data, required this.mutedStyle});

  final Map<String, dynamic> data;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final config = _mapOf(data['config']);
    final leases = _mapList(data['leases']);
    if (config.isEmpty && leases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('暂无 UPnP 状态数据', style: mutedStyle)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _statusChip(
              'UPnP 服务：${config['enabled']?.toString() == 'yes' ? '已开启' : '未开启'}',
              config['enabled']?.toString() == 'yes'
                  ? const Color(0xFF2E9E5B)
                  : Colors.grey,
            ),
            if ((config['interface']?.toString() ?? '').isNotEmpty)
              _statusChip(
                '线路：${config['interface']}',
                const Color(0xFF1E88E5),
              ),
            if ((config['exclude_port']?.toString() ?? '').isNotEmpty)
              _statusChip(
                '排除端口：${config['exclude_port']}',
                const Color(0xFFFB8C00),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (leases.isEmpty)
          Text('暂无 UPnP 端口映射', style: mutedStyle)
        else
          _MonoTable(
            headers: const ['内网地址', '协议', '内网端口', '外网端口', '描述', '创建时间'],
            columnWidths: const {
              0: FlexColumnWidth(1.3),
              1: FlexColumnWidth(0.7),
              2: FlexColumnWidth(0.8),
              3: FlexColumnWidth(0.8),
              4: FlexColumnWidth(1.3),
              5: FlexColumnWidth(1.3),
            },
            rows: [
              for (final u in leases.take(50))
                [
                  (u['lan_ip'] ?? '-').toString(),
                  (u['protocol'] ?? u['proto'] ?? '-').toString(),
                  '${u['lan_port'] ?? '-'}',
                  '${u['wan_port'] ?? '-'}',
                  (u['comment'] ?? '-').toString(),
                  formatUnixTime((u['time'] as num?)?.toDouble()),
                ],
            ],
          ),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ============ 通用小表格 ============

class _MonoTable extends StatelessWidget {
  const _MonoTable({
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.onRowTap,
  });

  final List<String> headers;
  final List<List<dynamic>> rows;
  final Map<int, TableColumnWidth>? columnWidths;
  final void Function(List<dynamic> cells)? onRowTap;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final monoStyle = const TextStyle(
      fontSize: 11.5,
      fontFamily: 'monospace',
    );

    Widget cellWidget(dynamic cell, {required bool header, int column = 0}) {
      if (cell is Widget) return cell;
      final text = cell?.toString() ?? '';
      if (text.startsWith('__chip__')) {
        final value = text.substring(8);
        final bad = value == '离线' || value == '停用' || value == '已停用';
        final color = bad ? Colors.grey : const Color(0xFF2E9E5B);
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        );
      }
      final isMono = column > 0;
      return Text(
        text,
        style: header
            ? mutedStyle.copyWith(fontWeight: FontWeight.w600)
            : (isMono ? monoStyle : const TextStyle(fontSize: 11.5)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 76),
        child: Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              children: [
                for (var i = 0; i < headers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 5,
                    ),
                    child: cellWidget(headers[i], header: true),
                  ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  for (var i = 0; i < row.length; i++)
                    InkWell(
                      onTap: onRowTap == null ? null : () => onRowTap!(row),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        child: cellWidget(row[i], header: false, column: i),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

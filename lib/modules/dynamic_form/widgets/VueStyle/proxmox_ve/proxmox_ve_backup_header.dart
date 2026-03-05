import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

/// Proxmox VE 备份页顶部状态栏：PVE 在线状态、主机名、CPU/内存/磁盘使用率
class ProxmoxVeBackupHeader extends StatelessWidget {
  const ProxmoxVeBackupHeader({super.key, required this.pveStatus});

  final Map<String, dynamic> pveStatus;

  static const _proxmoxOrange = Color(0xFFE57000);

  @override
  Widget build(BuildContext context) {
    final online = pveStatus['online'] == true;
    final error = pveStatus['error']?.toString() ?? '';
    final hostname = pveStatus['hostname']?.toString() ?? '未知';
    final ip = pveStatus['ip']?.toString() ?? '';
    final cpuUsage = (pveStatus['cpu_usage'] as num?)?.toDouble() ?? 0.0;
    final memUsage = (pveStatus['mem_usage'] as num?)?.toDouble() ?? 0.0;
    final memUsed = (pveStatus['mem_used'] as num?)?.toDouble() ?? 0.0;
    final memTotal = (pveStatus['mem_total'] as num?)?.toDouble() ?? 0.0;
    final diskUsage = (pveStatus['disk_usage'] as num?)?.toDouble() ?? 0.0;
    final diskUsed = (pveStatus['disk_used'] as num?)?.toDouble() ?? 0.0;
    final diskTotal = (pveStatus['disk_total'] as num?)?.toDouble() ?? 0.0;
    final swapUsed = (pveStatus['swap_used'] as num?)?.toDouble() ?? 0.0;
    final swapTotal = (pveStatus['swap_total'] as num?)?.toDouble() ?? 0.0;
    final swapUsage = (pveStatus['swap_usage'] as num?)?.toDouble() ?? 0.0;
    final loadAvg = pveStatus['load_avg'] as List? ?? [];
    final loadStr = loadAvg.map((e) => e?.toString() ?? '').join(' / ');
    final version = pveStatus['pve_version']?.toString() ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D2D30), const Color(0xFF252528)]
              : [Colors.white, const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _proxmoxOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: _proxmoxOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (ip.isNotEmpty)
                      _buildListTile(
                        Icons.wifi,
                        Colors.blue,
                        'IP',
                        ip,
                        context,
                      ),
                  ],
                ),
              ),
              _StatusChip(online: online),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _MetricChip(
            icon: Icons.memory,
            label: 'CPU',
            subtitle: '${cpuUsage.toStringAsFixed(0)}%',
            value: cpuUsage / 100.0,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _MetricChip(
            icon: Icons.sd_storage,
            label: '内存',
            subtitle:
                '${SizeFormatter.formatSizeFromMb(memUsed)}/${SizeFormatter.formatSizeFromMb(memTotal)}',
            value: memUsage / 100.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          _MetricChip(
            icon: Icons.storage,
            label: '磁盘',
            subtitle:
                '${SizeFormatter.formatSizeFromMb(diskUsed)}/${SizeFormatter.formatSizeFromMb(diskTotal)}',
            value: diskUsage / 100.0,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          _MetricChip(
            icon: Icons.swap_calls,
            label: '交换空间',
            subtitle:
                '${SizeFormatter.formatSizeFromMb(swapUsed)}/${SizeFormatter.formatSizeFromMb(swapTotal)}',
            value: swapUsage / 100.0,
            color: Colors.grey,
          ),
          if (loadStr.isNotEmpty) ...[
            const SizedBox(height: 8),

            _buildListTile(Icons.memory, Colors.blue, '负载', loadStr, context),
          ],
          if (version.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildListTile(Icons.info, Colors.blue, '版本', version, context),
          ],
        ],
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    Color color,
    String label,
    String value,

    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: online
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: online ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? '在线' : '离线',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: online ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Spacer(),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

class DownloaderConfigItemCard extends StatelessWidget {
  const DownloaderConfigItemCard({
    super.key,
    required this.downloader,
    required this.stats,
    required this.onTap,
    this.obscureHost = false,
  });

  final DownloadClient downloader;
  final DownloaderStats? stats;
  final VoidCallback onTap;
  final bool obscureHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive =
        stats != null && (stats!.downloadSpeed > 0 || stats!.uploadSpeed > 0);
    final statusLabel = stats == null
        ? '连接中'
        : isActive
        ? '传输中'
        : '空闲';
    final statusColor = stats == null
        ? colorScheme.primary
        : isActive
        ? const Color(0xFF22C55E)
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '${downloader.name}，$statusLabel',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildLogo(context),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  downloader.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                context,
                                label: statusLabel,
                                color: statusColor,
                                loading: stats == null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                _typeLabel(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: _buildHostText(
                                  theme,
                                  colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                _buildMetrics(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final logo = switch (downloader.type) {
      'qbittorrent' => Assets.images.logos.qbittorrent,
      'transmission' => Assets.images.logos.transmission,
      _ => Assets.images.logos.downloader,
    };

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: logo.image(fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required bool loading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 7,
              height: 7,
              child: CircularProgressIndicator(strokeWidth: 1.4, color: color),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (stats == null) {
      return Row(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 17,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '正在获取运行状态',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _metric(
            context,
            icon: Icons.south_rounded,
            label: '下载',
            value: _formatSpeed(stats!.downloadSpeed),
            color: const Color(0xFF22C55E),
          ),
        ),
        _metricDivider(context),
        Expanded(
          child: _metric(
            context,
            icon: Icons.north_rounded,
            label: '上传',
            value: _formatSpeed(stats!.uploadSpeed),
            color: const Color(0xFF38BDF8),
          ),
        ),
        _metricDivider(context),
        Expanded(
          child: _metric(
            context,
            icon: Icons.storage_rounded,
            label: '可用',
            value: SizeFormatter.formatSize(stats!.freeSpace, 1),
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _metricDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.65),
    );
  }

  String _typeLabel() {
    return switch (downloader.type) {
      'qbittorrent' => 'qBittorrent',
      'transmission' => 'Transmission',
      _ => downloader.type.isEmpty ? '未知类型' : downloader.type,
    };
  }

  String _hostText() {
    final host = downloader.config?.host.trim() ?? '';
    return host.isEmpty ? '未配置地址' : host;
  }

  Widget _buildHostText(ThemeData theme, Color color) {
    final text = Text(
      _hostText(),
      style: theme.textTheme.bodySmall?.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (!obscureHost) return text;
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 3.2, sigmaY: 3.2),
        child: text,
      ),
    );
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${SizeFormatter.formatSize(bytesPerSecond, 1)}/s';
  }
}

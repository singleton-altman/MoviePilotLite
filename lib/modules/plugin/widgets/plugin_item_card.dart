import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

enum PluginHandleType { settings, reset, uninstall, log, web }

class PluginItemCard extends StatelessWidget {
  const PluginItemCard({
    super.key,
    required this.item,
    required this.iconUrl,
    required this.installCount,
    this.onHandleTap,
  });

  final PluginItem item;
  final String iconUrl;
  final int installCount;
  final Function(PluginHandleType type)? onHandleTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _resolveThemeColor();
    final installedView = onHandleTap != null;
    final status = _statusPresentation(colorScheme, installedView);

    return Semantics(
      button: true,
      label: '${item.pluginName}，${status.label}',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: accent.withValues(alpha: 0.18), width: 0.8),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.10),
                colorScheme.surfaceContainer,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(context, accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.pluginName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.pluginAuthor?.trim().isNotEmpty == true
                                      ? item.pluginAuthor!.trim()
                                      : '未知作者',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if ((item.pluginVersion ?? '').isNotEmpty) ...[
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
                                Text(
                                  'v${item.pluginVersion}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _statusBadge(
                      context,
                      label: status.label,
                      color: status.color,
                      icon: status.icon,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.pluginDesc?.trim().isNotEmpty == true
                      ? item.pluginDesc!.trim()
                      : '暂无插件说明',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.download_outlined,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatInstallCount(installCount),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_labelList.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 74),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _labelList.first,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (item.isLocal) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.computer_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '本地',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (onHandleTap != null)
                      _buildMenu(context)
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveThemeColor() {
    try {
      final cache = Get.find<PluginPaletteCache>();
      return cache.getCached(iconUrl) ?? PluginPaletteCache.defaultColor;
    } catch (_) {
      return PluginPaletteCache.defaultColor;
    }
  }

  Widget _buildIcon(BuildContext context, Color accent) {
    final fallback = Container(
      color: accent.withValues(alpha: 0.18),
      child: Icon(Icons.extension_rounded, size: 23, color: accent),
    );
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl.isEmpty
          ? fallback
          : CachedImage(
              imageUrl: iconUrl,
              fit: BoxFit.cover,
              memCacheWidth: 88,
              memCacheHeight: 88,
              placeholder: fallback,
              errorWidget: fallback,
            ),
    );
  }

  Widget _statusBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
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

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<PluginHandleType>(
      tooltip: '插件操作',
      padding: EdgeInsets.zero,
      onSelected: onHandleTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          Icons.more_horiz_rounded,
          size: 19,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      itemBuilder: (context) => PluginHandleType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _getHandleTypeIcon(type),
                    size: 18,
                    color: _getHandleTypeColor(context, type),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getHandleTypeLabel(type),
                    style: TextStyle(
                      color: _getHandleTypeColor(context, type),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  ({String label, IconData icon, Color color}) _statusPresentation(
    ColorScheme colorScheme,
    bool installedView,
  ) {
    if (item.hasUpdate) {
      return (
        label: '可更新',
        icon: Icons.system_update_alt_rounded,
        color: const Color(0xFFF59E0B),
      );
    }
    if (installedView) {
      return item.state
          ? (
              label: '运行中',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF22C55E),
            )
          : (
              label: '已停用',
              icon: Icons.pause_circle_outline_rounded,
              color: colorScheme.onSurfaceVariant,
            );
    }
    if (item.installed) {
      return (
        label: '已安装',
        icon: Icons.check_rounded,
        color: const Color(0xFF22C55E),
      );
    }
    return (label: '可安装', icon: Icons.add_rounded, color: colorScheme.primary);
  }

  List<String> get _labelList {
    final raw = item.pluginLabel;
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  String _formatInstallCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  String _getHandleTypeLabel(PluginHandleType type) {
    switch (type) {
      case PluginHandleType.settings:
        return '设置';
      case PluginHandleType.log:
        return '日志';
      case PluginHandleType.reset:
        return '重置';
      case PluginHandleType.uninstall:
        return '卸载';
      case PluginHandleType.web:
        return '作者主页';
    }
  }

  IconData _getHandleTypeIcon(PluginHandleType type) {
    switch (type) {
      case PluginHandleType.settings:
        return Icons.settings_outlined;
      case PluginHandleType.log:
        return Icons.receipt_long_outlined;
      case PluginHandleType.reset:
        return Icons.restart_alt_rounded;
      case PluginHandleType.uninstall:
        return Icons.delete_outline_rounded;
      case PluginHandleType.web:
        return Icons.open_in_new_rounded;
    }
  }

  Color _getHandleTypeColor(BuildContext context, PluginHandleType type) {
    if (type == PluginHandleType.uninstall) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurface;
  }
}

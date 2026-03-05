import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/theme/section.dart';

/// 信息卡片：基于 CupertinoListSection.insetGrouped 构建，
/// 参考 iOS 系统设置/通讯录风格：彩色圆角图标 + 行列式布局
class InfoCardWidget extends StatelessWidget {
  const InfoCardWidget({super.key, required this.block});

  final InfoCardBlock block;

  static const double _iconBgSize = 30;
  static const double _iconSize = 18;
  static const double _headerIconBgSize = 28;
  static const double _headerIconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Section(
      padding: EdgeInsets.zero,
      separatorBuilder: (context) => Divider(),
      margin: EdgeInsets.zero,
      header: _buildHeader(context),
      children: _buildChildren(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: 彩色圆角图标 + 标题 + 可选 Chip
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final iconData = VuetifyMappings.iconFromMdi(block.iconName);
    final color = _resolveColor(block.iconColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (iconData != null) ...[
            _buildIconBadge(
              iconData,
              color,
              size: _headerIconBgSize,
              iconSize: _headerIconSize,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              block.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.label,
                  context,
                ),
              ),
            ),
          ),
          if (block.headerChipText != null && block.headerChipText!.isNotEmpty)
            _buildBadgeChip(block.headerChipText!, block.headerChipColor),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Children: Alert + Rows + EmptyState
  // ---------------------------------------------------------------------------

  List<Widget> _buildChildren(BuildContext context) {
    final children = <Widget>[];

    if (block.alertText != null && block.alertText!.isNotEmpty) {
      children.add(_buildAlertBanner(context));
    }

    if (block.rows.isNotEmpty) {
      for (final row in block.rows) {
        children.add(_buildRowTile(context, row));
      }
    }

    if (block.rows.isEmpty &&
        block.emptyText != null &&
        block.emptyText!.isNotEmpty) {
      children.add(_buildEmptyState(context));
    }

    if (children.isEmpty) {
      children.add(const SizedBox(height: 8));
    }

    return children;
  }

  // ---------------------------------------------------------------------------
  // Row: iOS Settings 风格 — 彩色圆角图标 + 标签 + trailing 值/Chip
  // ---------------------------------------------------------------------------

  Widget _buildRowTile(BuildContext context, InfoCardRow row) {
    final iconData = VuetifyMappings.iconFromMdi(row.iconName);
    final iconColor = _resolveColor(row.iconColor);
    final hasSubtitle = row.subtitle != null && row.subtitle!.isNotEmpty;

    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: iconData != null
          ? _buildSubtleIconBadge(iconData, iconColor)
          : null,
      title: Text(
        row.label,
        style: TextStyle(
          fontSize: 15,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: hasSubtitle
          ? Text(
              row.subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _buildRowTrailing(context, row),
    );
  }

  Widget? _buildRowTrailing(BuildContext context, InfoCardRow row) {
    final hasChip = row.chipText != null && row.chipText!.isNotEmpty;
    final hasValue = row.value != null && row.value!.isNotEmpty;
    if (!hasChip && !hasValue) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasValue)
          Flexible(
            child: Text(
              row.value!,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (hasValue && hasChip) const SizedBox(width: 8),
        if (hasChip) _buildBadgeChip(row.chipText!, row.chipColor),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Alert Banner: 圆角色块 + 图标 + 文字
  // ---------------------------------------------------------------------------

  Widget _buildAlertBanner(BuildContext context) {
    final type = block.alertType ?? 'info';
    final (bgColor, fgColor, icon) = _alertStyle(type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                block.alertText!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State: 大号柔和图标 + 说明文字
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    final iconData = VuetifyMappings.iconFromMdi(block.emptyIconName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.tertiarySystemFill,
                  context,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                iconData ?? CupertinoIcons.doc_text,
                size: 26,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.tertiaryLabel,
                  context,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              block.emptyText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // iOS Settings 风格彩色圆角图标背景（Header 用，实心）
  // ---------------------------------------------------------------------------

  Widget _buildIconBadge(
    IconData icon,
    Color color, {
    double size = _iconBgSize,
    double iconSize = _iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }

  // ---------------------------------------------------------------------------
  // 行内柔和图标（淡色背景 + 彩色图标，视觉层级低于 Header）
  // ---------------------------------------------------------------------------

  Widget _buildSubtleIconBadge(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  // ---------------------------------------------------------------------------
  // Badge Chip: 实心圆角 + 白色文字（类似 iOS 通知角标风格）
  // ---------------------------------------------------------------------------

  Widget _buildBadgeChip(String text, String? colorName) {
    final color = _chipColor(colorName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 颜色工具
  // ---------------------------------------------------------------------------

  static Color _resolveColor(String? name) {
    if (name == null || name.isEmpty) return const Color(0xFF007AFF);
    return _namedColor(name) ??
        VuetifyMappings.colorFromHex(name) ??
        const Color(0xFF007AFF);
  }

  static Color _chipColor(String? name) {
    if (name == null || name.isEmpty) return const Color(0xFF34C759);
    return _namedColor(name) ??
        VuetifyMappings.colorFromHex(name) ??
        const Color(0xFF34C759);
  }

  static Color? _namedColor(String name) {
    switch (name.toLowerCase()) {
      case 'green':
      case 'success':
        return const Color(0xFF34C759);
      case 'red':
      case 'error':
        return const Color(0xFFFF3B30);
      case 'orange':
      case 'warning':
        return const Color(0xFFFF9500);
      case 'grey':
      case 'gray':
      case 'secondary':
        return const Color(0xFF8E8E93);
      case 'blue':
      case 'info':
      case 'primary':
        return const Color(0xFF007AFF);
      case 'purple':
        return const Color(0xFFAF52DE);
      case 'teal':
        return const Color(0xFF5AC8FA);
      case 'indigo':
        return const Color(0xFF5856D6);
      default:
        return null;
    }
  }

  static (Color bg, Color fg, IconData icon) _alertStyle(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return (
          const Color(0xFF34C759).withValues(alpha: 0.12),
          const Color(0xFF34C759),
          CupertinoIcons.checkmark_circle_fill,
        );
      case 'warning':
        return (
          const Color(0xFFFF9500).withValues(alpha: 0.12),
          const Color(0xFFFF9500),
          CupertinoIcons.exclamationmark_triangle_fill,
        );
      case 'error':
        return (
          const Color(0xFFFF3B30).withValues(alpha: 0.12),
          const Color(0xFFFF3B30),
          CupertinoIcons.exclamationmark_circle_fill,
        );
      default:
        return (
          const Color(0xFF007AFF).withValues(alpha: 0.12),
          const Color(0xFF007AFF),
          CupertinoIcons.info_circle_fill,
        );
    }
  }
}

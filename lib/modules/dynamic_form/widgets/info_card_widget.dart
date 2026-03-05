import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
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
    final clickEvent = _extractClickEvent(
      row.map(
        (data) => data.events,
        progress: (data) => data.events,
        menu: (data) => data.events,
      ),
    );

    return row.map(
      (data) => _buildBasicRow(context, data, iconData, iconColor, clickEvent),
      progress: (data) =>
          _buildProgressRow(context, data, iconData, iconColor, clickEvent),
      menu: (data) =>
          _buildMenuRow(context, data, iconData, iconColor, clickEvent),
    );
  }

  Widget _buildBasicRow(
    BuildContext context,
    InfoCardRowBase row,
    IconData? iconData,
    Color iconColor,
    _InfoCardClickEvent? clickEvent,
  ) {
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
      subtitle: _buildSubtitle(context, row.subtitle),
      trailing: _buildValueChipTrailing(
        context,
        value: row.value,
        chipText: row.chipText,
        chipColor: row.chipColor,
      ),
      onTap: clickEvent != null ? () => _handleClickEvent(clickEvent) : null,
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    InfoCardRowProgress row,
    IconData? iconData,
    Color iconColor,
    _InfoCardClickEvent? clickEvent,
  ) {
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
      subtitle: _buildSubtitle(context, row.subtitle),
      trailing: _buildProgressTrailing(context, row),
      onTap: clickEvent != null ? () => _handleClickEvent(clickEvent) : null,
    );
  }

  Widget _buildMenuRow(
    BuildContext context,
    InfoCardRowMenu row,
    IconData? iconData,
    Color iconColor,
    _InfoCardClickEvent? clickEvent,
  ) {
    final valueTrailing = _buildValueChipTrailing(
      context,
      value: row.value,
      chipText: row.chipText,
      chipColor: row.chipColor,
    );
    final trailingWidgets = <Widget>[];
    if (valueTrailing != null) {
      trailingWidgets.add(Flexible(child: valueTrailing));
      if (row.menuItems.isNotEmpty) {
        trailingWidgets.add(const SizedBox(width: 6));
      }
    }
    if (row.menuItems.isNotEmpty) {
      trailingWidgets.add(_buildPopupMenuButton(context, row.menuItems));
    }

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
      subtitle: _buildSubtitle(context, row.subtitle),
      trailing: trailingWidgets.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: trailingWidgets)
          : null,
      onTap: clickEvent != null ? () => _handleClickEvent(clickEvent) : null,
    );
  }

  Widget? _buildSubtitle(BuildContext context, String? subtitle) {
    if (subtitle == null || subtitle.isEmpty) return null;
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 13,
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondaryLabel,
          context,
        ),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildValueChipTrailing(
    BuildContext context, {
    String? value,
    String? chipText,
    String? chipColor,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final hasChip = chipText != null && chipText.isNotEmpty;
    if (!hasValue && !hasChip) return null;

    final children = <Widget>[];
    if (hasValue) {
      children.add(
        Flexible(
          child: Text(
            value!,
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
      );
    }
    if (hasValue && hasChip) {
      children.add(const SizedBox(width: 8));
    }
    if (hasChip) {
      children.add(_buildBadgeChip(chipText!, chipColor));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildProgressTrailing(BuildContext context, InfoCardRowProgress row) {
    final valueText = row.value?.isNotEmpty == true ? row.value : null;
    final chipText = row.chipText?.isNotEmpty == true ? row.chipText : null;
    final progress = row.progressValue.clamp(0.0, 1.0);
    final progressColor = _resolveColor(row.progressColor);
    final backgroundColor =
        (row.progressBackgroundColor?.isNotEmpty == true
                ? _resolveColor(row.progressBackgroundColor)
                : progressColor.withOpacity(0.2))
            .withOpacity(0.4);
    final labelText = row.progressLabel?.isNotEmpty == true
        ? row.progressLabel!
        : '${(progress * 100).round()}%';

    final children = <Widget>[];
    if (chipText != null) {
      children.add(const SizedBox(height: 4));
      children.add(_buildBadgeChip(chipText, row.chipColor));
      children.add(const SizedBox(height: 4));
    }
    if (valueText != null) {
      children.add(
        Text(
          valueText,
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
      );
      children.add(const SizedBox(height: 6));
    }
    children.add(
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress,
          color: progressColor,
          backgroundColor: backgroundColor,
          minHeight: 6,
        ),
      ),
    );
    children.add(const SizedBox(height: 4));
    children.add(
      Text(
        labelText,
        style: TextStyle(
          fontSize: 12,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel,
            context,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }

  Widget _buildPopupMenuButton(
    BuildContext context,
    List<InfoCardRowMenuItem> items,
  ) {
    final iconColor = CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );
    return PopupMenuButton<InfoCardRowMenuItem>(
      padding: EdgeInsets.zero,
      tooltip: '更多',
      icon: Icon(CupertinoIcons.ellipsis_vertical, color: iconColor, size: 20),
      onSelected: (item) async {
        final event = _extractClickEvent(item.events);
        if (event != null) await _handleClickEvent(event);
      },
      itemBuilder: (_) => items.map((item) {
        final iconData = VuetifyMappings.iconFromMdi(item.iconName);
        return PopupMenuItem(
          value: item,
          child: Row(
            children: [
              if (iconData != null) ...[
                Icon(iconData, size: 18, color: _resolveColor(item.iconColor)),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(item.label)),
            ],
          ),
        );
      }).toList(),
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

  _InfoCardClickEvent? _extractClickEvent(Map<String, dynamic>? events) {
    if (events == null) return null;
    final click = events['click'];
    if (click is! Map) return null;
    final api = click['api']?.toString();
    final method = click['method']?.toString().toLowerCase() ?? 'get';
    if (api == null || api.isEmpty) return null;
    return _InfoCardClickEvent(api: api, method: method);
  }

  static Future<void> _handleClickEvent(_InfoCardClickEvent event) async {
    try {
      final apiClient = Get.find<ApiClient>();
      final appService = Get.find<AppService>();
      final token =
          appService.loginResponse?.accessToken ??
          appService.latestLoginProfileAccessToken ??
          apiClient.token;
      if (token == null || token.isEmpty) return;
      if (event.method == 'post') {
        await apiClient.post<dynamic>(event.api, token: token);
      } else {
        await apiClient.get<dynamic>(event.api, token: token);
      }
    } catch (e, st) {
      Get.find<AppLog>().handle(e, stackTrace: st, message: 'API 调用失败');
    }
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

class _InfoCardClickEvent {
  const _InfoCardClickEvent({required this.api, required this.method});

  final String api;
  final String method;
}

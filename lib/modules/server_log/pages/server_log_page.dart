import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/server_log_controller.dart';

class ServerLogPage extends GetView<ServerLogController> {
  const ServerLogPage({super.key});

  static const double _floatingBarHeight = 52;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('${controller.title}日志'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [Obx(() => _buildStreamIndicator(context, controller))],
      ),
      body: SafeArea(
        child: Obx(() => _buildScrollableBody(context, controller)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() => _buildFloatingBar(context, controller)),
    );
  }

  Widget _buildStreamIndicator(
    BuildContext context,
    ServerLogController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isConnecting =
        controller.isLoading.value && !controller.isStreaming.value;
    final isIdle = controller.isIdle.value;
    final isStreaming = controller.isStreaming.value;

    if (isConnecting) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: CupertinoActivityIndicator(radius: 8),
      );
    }

    Color color;
    String label;
    if (isStreaming && isIdle) {
      color = CupertinoColors.systemOrange;
      label = '等待';
    } else if (isStreaming) {
      color = CupertinoColors.activeGreen;
      label = '在线';
    } else {
      color = CupertinoColors.systemGrey;
      label = '断开';
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (!isStreaming && !isConnecting)
            ? () => controller.reconnect()
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              if (!isStreaming && !isConnecting) ...[
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.refresh,
                  size: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableBody(
    BuildContext context,
    ServerLogController controller,
  ) {
    final logs = controller.filteredLogs;

    return CustomScrollView(
      slivers: [
        if (logs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context, controller),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLogItem(context, logs[index]),
                childCount: logs.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingBar(
    BuildContext context,
    ServerLogController controller,
  ) {
    final theme = Theme.of(context);
    final child = Row(
      children: [
        _buildLevelFilterButton(context, controller),
        const SizedBox(width: 8),
        Expanded(child: _buildKeywordTrigger(context, controller)),
        const SizedBox(width: 8),
        _buildReconnectButton(context, controller),
      ],
    );
    final pill = Container(
      height: _floatingBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: pill,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelFilterButton(
    BuildContext context,
    ServerLogController controller,
  ) {
    final level = controller.filterLevel.value.toUpperCase();
    final active = level != 'ALL';
    final color = active
        ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _showLevelSheet(context, controller),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
          if (active)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordTrigger(
    BuildContext context,
    ServerLogController controller,
  ) {
    final theme = Theme.of(context);
    final keyword = controller.keyword.value.trim();
    final active = keyword.isNotEmpty;
    final color = active
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showKeywordSheet(context, controller),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                active ? keyword : '搜索日志',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (active)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.keyword.value = '',
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectButton(
    BuildContext context,
    ServerLogController controller,
  ) {
    final isConnecting =
        controller.isLoading.value && !controller.isStreaming.value;
    final isStreaming = controller.isStreaming.value;
    final color = CupertinoDynamicColor.resolve(
      isStreaming
          ? CupertinoColors.activeGreen
          : CupertinoColors.secondaryLabel,
      context,
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: isConnecting ? null : () => controller.reconnect(),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: isConnecting
              ? const CupertinoActivityIndicator(radius: 8)
              : Icon(CupertinoIcons.refresh, size: 20, color: color),
        ),
      ),
    );
  }

  Future<void> _showKeywordSheet(
    BuildContext context,
    ServerLogController controller,
  ) async {
    final textController = TextEditingController(
      text: controller.keyword.value,
    );
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Material(
              color: colors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoSearchTextField(
                              controller: textController,
                              autofocus: true,
                              placeholder: '搜索日志、模块或关键字',
                              backgroundColor: colors.surfaceContainerHighest
                                  .withValues(
                                    alpha: _isDark(sheetContext) ? 0.36 : 0.72,
                                  ),
                              onSubmitted: (value) =>
                                  Navigator.of(sheetContext).pop(value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            onPressed: () => Navigator.of(
                              sheetContext,
                            ).pop(textController.text),
                            child: const Text('完成'),
                          ),
                        ],
                      ),
                      if (textController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(sheetContext).pop(''),
                          child: const Text('清空搜索'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    textController.dispose();

    if (result == null) return;
    controller.keyword.value = result;
  }

  Future<void> _showLevelSheet(
    BuildContext context,
    ServerLogController controller,
  ) {
    final levels = ['ALL', 'INFO', 'WARN', 'ERROR', 'DEBUG'];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final current = controller.filterLevel.value.toUpperCase();
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Material(
            color: colors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    for (final level in levels)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          controller.filterLevel.value = level;
                          Navigator.of(sheetContext).pop();
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: current == level
                                ? colors.primary.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                level == 'ALL'
                                    ? CupertinoIcons.line_horizontal_3_decrease
                                    : CupertinoIcons.doc_text_search,
                                size: 18,
                                color: current == level
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _levelLabel(level),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: current == level
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                                ),
                              ),
                              if (current == level)
                                Icon(
                                  CupertinoIcons.check_mark,
                                  size: 18,
                                  color: colors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _levelLabel(String level) {
    switch (level.toUpperCase()) {
      case 'INFO':
        return 'INFO';
      case 'WARN':
        return 'WARN';
      case 'ERROR':
        return 'ERROR';
      case 'DEBUG':
        return 'DEBUG';
      case 'ALL':
      default:
        return '全部';
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    ServerLogController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    if (controller.isLoading.value) {
      return Center(child: CupertinoActivityIndicator(color: colors.primary));
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              color: colors.onSurfaceVariant,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              '暂无日志数据',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry entry) {
    final colors = Theme.of(context).colorScheme;
    final levelColor = _levelColor(context, entry.level);
    final dayLabel = DateFormat('MM-dd').format(entry.timestamp);
    final timeLabel = DateFormat('HH:mm:ss').format(entry.timestamp);
    final timestampLabel = '$dayLabel $timeLabel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineMarker(context, levelColor),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(
                  alpha: _isDark(context) ? 0.18 : 0.34,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLevelChip(context, entry.level, levelColor),
                      const SizedBox(width: 6),
                      Flexible(child: _buildModuleChip(context, entry.module)),
                      const SizedBox(width: 8),
                      Text(
                        timestampLabel,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    entry.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.38,
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(BuildContext context, Color color) {
    return SizedBox(
      width: 10,
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: _isDark(context) ? 0.22 : 0.14,
                  ),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 54,
            margin: const EdgeInsets.only(top: 6),
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(BuildContext context, String level, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark(context) ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildModuleChip(BuildContext context, String module) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: _isDark(context) ? 0.30 : 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        module,
        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      ),
    );
  }

  Color _levelColor(BuildContext context, String level) {
    final dark = _isDark(context);
    switch (level.toUpperCase()) {
      case 'ERROR':
        return dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case 'WARN':
      case 'WARNING':
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'DEBUG':
        return dark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED);
      case 'INFO':
      default:
        return dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    }
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/system_health_controller.dart';

class SystemHealthPage extends GetView<SystemHealthController> {
  const SystemHealthPage({super.key});

  static const double _maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.gear_alt_fill,
                size: 17,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '健康检查',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.isLoading.value) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CupertinoActivityIndicator(
                  radius: 9,
                  color: colors.primary,
                ),
              );
            }
            return IconButton(
              tooltip: '刷新',
              icon: const Icon(CupertinoIcons.refresh),
              color: colors.onSurfaceVariant,
              onPressed: controller.fetchHealth,
            );
          }),
          IconButton(
            tooltip: '关闭',
            icon: const Icon(CupertinoIcons.xmark_circle_fill),
            color: colors.onSurfaceVariant,
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: Obx(() => _buildBody(context, controller))),
    );
  }

  Widget _buildBody(BuildContext context, SystemHealthController controller) {
    final items = controller.items.toList();
    final error = controller.errorMessage.value;
    final isLoading = controller.isLoading.value;
    final children = <Widget>[
      _buildSummary(context, controller),
      if (error != null) _buildErrorBanner(context, error),
      if (items.isEmpty && !isLoading) _buildEmptyState(context, error),
      if (items.isNotEmpty) _buildSectionHeader(context, items.length),
      if (items.isNotEmpty) ...items.map((item) => _buildItem(context, item)),
    ];

    return RefreshIndicator(
      onRefresh: controller.fetchHealth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth > _maxContentWidth ? 24 : 16,
              12,
              constraints.maxWidth > _maxContentWidth ? 24 : 16,
              28,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: children[index],
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: children.length,
          );
        },
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    SystemHealthController controller,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final items = controller.items;
    final total = items.length;
    final okCount = items
        .where((item) => item.status == SystemHealthStatus.ok)
        .length;
    final warningCount = items
        .where((item) => item.status == SystemHealthStatus.warning)
        .length;
    final errorCount = items
        .where((item) => item.status == SystemHealthStatus.error)
        .length;
    final finishedCount = items
        .where(
          (item) =>
              item.status != SystemHealthStatus.checking &&
              item.status != SystemHealthStatus.idle,
        )
        .length;
    final progress = total == 0 ? 0.0 : finishedCount / total;
    final percentLabel = '${(progress * 100).round()}%';
    final isChecking = controller.isLoading.value;
    final hasError = errorCount > 0;
    final hasWarning = warningCount > 0;
    final accent = isChecking
        ? _statusColor(context, SystemHealthStatus.checking)
        : hasError
        ? _statusColor(context, SystemHealthStatus.error)
        : hasWarning
        ? _statusColor(context, SystemHealthStatus.warning)
        : _statusColor(context, SystemHealthStatus.ok);
    final headline = isChecking
        ? '正在检测系统状态'
        : hasError
        ? '发现异常项目'
        : hasWarning
        ? '存在需要关注的项目'
        : total == 0
        ? '等待检查数据'
        : '系统状态良好';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainerHighest.withValues(alpha: 0.82),
            Color.alphaBlend(
              accent.withValues(alpha: _isDark(context) ? 0.16 : 0.08),
              colors.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroStatusIcon(context, accent, isChecking),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summarySubtitle(controller),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPercentPill(context, percentLabel, accent),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(context, progress, accent),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  label: '总模块',
                  value: total,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  context,
                  label: '正常',
                  value: okCount,
                  color: _statusColor(context, SystemHealthStatus.ok),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  context,
                  label: '异常',
                  value: errorCount,
                  color: _statusColor(context, SystemHealthStatus.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatusIcon(
    BuildContext context,
    Color accent,
    bool isChecking,
  ) {
    if (isChecking) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: CupertinoActivityIndicator(radius: 10, color: accent),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        CupertinoIcons.checkmark_shield_fill,
        color: accent,
        size: 24,
      ),
    );
  }

  Widget _buildPercentPill(
    BuildContext context,
    String percentLabel,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isDark(context) ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        percentLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double progress,
    Color accent,
  ) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: progress,
        backgroundColor: colors.outlineVariant.withValues(alpha: 0.42),
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: _isDark(context) ? 0.42 : 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '检查项目',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
          ),
          Text(
            '$count 项',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    final error = _statusColor(context, SystemHealthStatus.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: _isDark(context) ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 17,
            color: error,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String? message) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = message ?? '暂无健康检查数据';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.doc_text_search,
            color: colors.onSurfaceVariant,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, SystemHealthItem item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusText = _statusLabel(item.status);
    final statusColor = _statusColor(context, item.status);
    final detail = _detailText(item);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: _isDark(context) ? 0.34 : 0.62,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIcon(context, item.status, statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    height: 1.22,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusChip(context, statusText, statusColor),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
    BuildContext context,
    SystemHealthStatus status,
    Color color,
  ) {
    if (status == SystemHealthStatus.checking) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoActivityIndicator(radius: 8, color: color),
      );
    }
    IconData iconData = CupertinoIcons.question_circle_fill;
    switch (status) {
      case SystemHealthStatus.ok:
        iconData = CupertinoIcons.checkmark_circle_fill;
        break;
      case SystemHealthStatus.warning:
        iconData = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case SystemHealthStatus.error:
        iconData = CupertinoIcons.xmark_circle_fill;
        break;
      case SystemHealthStatus.disabled:
        iconData = CupertinoIcons.minus_circle_fill;
        break;
      case SystemHealthStatus.idle:
      case SystemHealthStatus.unknown:
      case SystemHealthStatus.checking:
        iconData = CupertinoIcons.question_circle_fill;
        break;
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark(context) ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark(context) ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, SystemHealthStatus status) {
    final dark = _isDark(context);
    switch (status) {
      case SystemHealthStatus.ok:
        return dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      case SystemHealthStatus.warning:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case SystemHealthStatus.error:
        return dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case SystemHealthStatus.disabled:
        return dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      case SystemHealthStatus.checking:
        return dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case SystemHealthStatus.idle:
      case SystemHealthStatus.unknown:
        return dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    }
  }

  String _statusLabel(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.ok:
        return '正常';
      case SystemHealthStatus.warning:
        return '警告';
      case SystemHealthStatus.error:
        return '错误';
      case SystemHealthStatus.disabled:
        return '未启用';
      case SystemHealthStatus.checking:
        return '检测中';
      case SystemHealthStatus.idle:
        return '未检测';
      case SystemHealthStatus.unknown:
        return '未知';
    }
  }

  String _detailText(SystemHealthItem item) {
    if (item.detail != null && item.detail!.trim().isNotEmpty) {
      return item.detail!.trim();
    }
    if (item.message != null && item.message!.trim().isNotEmpty) {
      return item.message!.trim();
    }
    return '';
  }

  String _summarySubtitle(SystemHealthController controller) {
    final lastRunAt = controller.lastRunAt.value;
    if (controller.isLoading.value) return '正在刷新模块检测结果';
    if (lastRunAt == null) return '下拉或点击刷新开始检测';
    final hour = lastRunAt.hour.toString().padLeft(2, '0');
    final minute = lastRunAt.minute.toString().padLeft(2, '0');
    return '上次检查 $hour:$minute';
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

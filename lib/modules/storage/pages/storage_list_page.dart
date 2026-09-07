import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/utils/file_storage_utils.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

class StorageListPage extends GetView<StorageListController> {
  const StorageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: const Text('存储'),
        centerTitle: false,
        backgroundColor: palette.appBarBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final error = controller.errorText.value;
        if (error != null) {
          return _StorageStatePane(
            icon: Icons.cloud_off_rounded,
            title: '加载失败',
            message: error,
            actionLabel: '重试',
            onAction: controller.loadStorages,
          );
        }
        if (controller.storages.isEmpty && !controller.isLoading.value) {
          return const _StorageStatePane(
            icon: Icons.storage_outlined,
            title: '暂无存储',
            message: '当前没有可用的存储配置',
          );
        }
        if (controller.storages.isEmpty && controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: palette.primary),
          );
        }

        return RefreshIndicator(
          color: palette.primary,
          onRefresh: controller.loadStorages,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: controller.storages.length,
            itemBuilder: (context, index) {
              final storage = controller.storages[index];
              return Obx(
                () => _StorageItemCard(
                  key: ValueKey(storage.type),
                  storage: storage,
                  usage: controller.getUsageFor(storage.type),
                  onTap: () {
                    Get.toNamed(
                      '/file-manager',
                      arguments: {
                        'initialStorage': storage.type,
                        'allowSelectStorage': false,
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _StorageItemCard extends StatelessWidget {
  const _StorageItemCard({
    super.key,
    required this.storage,
    required this.onTap,
    this.usage,
  });

  final StorageSetting storage;
  final StorageUsage? usage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardPalette.of(context);
    final configured = StorageListController.isConfigured(storage);
    final total = usage?.total ?? 0.0;
    final available = usage?.available ?? 0.0;
    final used = total > 0 ? total - available : 0.0;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final hasUsage = usage != null && total > 0;
    final status = _statusInfo(palette, configured, hasUsage, progress);
    final subtitle = _subtitle(configured);

    return Semantics(
      button: true,
      label: '${storage.name}，${status.label}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: palette.pageBackgroundAlt,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: palette.tileBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: palette.primary.withValues(alpha: 0.08),
            highlightColor: palette.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 12, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StorageLogo(type: storage.type),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    storage.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: palette.titleText,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(
                                  label: status.label,
                                  color: status.color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  storage.type,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  Container(
                                    width: 3,
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.faintText,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: palette.mutedText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.faintText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: palette.divider),
                  const SizedBox(height: 12),
                  if (hasUsage)
                    _UsageBlock(
                      total: total,
                      available: available,
                      used: used,
                      progress: progress,
                      progressColor: status.color,
                    )
                  else
                    _FooterHint(
                      configured: configured,
                      hint: subtitle ?? (configured ? '已配置' : '未配置'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _subtitle(bool configured) {
    final type = storage.type.toLowerCase();
    if (type == 'alist' || type == 'openlist') {
      final url = storage.config['url']?.toString().trim() ?? '';
      if (url.isNotEmpty) return url;
    }
    if (!configured) return '点击查看或配置';
    if (type == 'local') return '本机磁盘';
    return '可浏览文件';
  }

  ({String label, Color color}) _statusInfo(
    DashboardPaletteData palette,
    bool configured,
    bool hasUsage,
    double progress,
  ) {
    if (!configured) {
      return (label: '未配置', color: palette.faintText);
    }
    if (!hasUsage) {
      return (label: '已配置', color: palette.coolAccent);
    }
    if (progress >= 0.9) {
      return (label: '空间紧张', color: palette.warmAccent);
    }
    if (progress >= 0.75) {
      return (label: '占用较高', color: palette.warningAccent);
    }
    return (label: '运行正常', color: const Color(0xFF22C55E));
  }
}

class _StorageLogo extends StatelessWidget {
  const _StorageLogo({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: FileStorageUtils.storageIconWidget(type, size: 28),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
}

class _UsageBlock extends StatelessWidget {
  const _UsageBlock({
    required this.total,
    required this.available,
    required this.used,
    required this.progress,
    required this.progressColor,
  });

  final double total;
  final double available;
  final double used;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardPalette.of(context);
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: palette.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.south_west_rounded,
                label: '已用',
                value: SizeFormatter.formatSize(used, 1),
                color: palette.warningAccent,
              ),
            ),
            _MetricDivider(),
            Expanded(
              child: _Metric(
                icon: Icons.check_circle_outline_rounded,
                label: '可用',
                value: SizeFormatter.formatSize(available, 1),
                color: const Color(0xFF22C55E),
              ),
            ),
            _MetricDivider(),
            Expanded(
              child: _Metric(
                icon: Icons.storage_rounded,
                label: '总量',
                value: SizeFormatter.formatSize(total, 1),
                color: palette.coolAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterHint extends StatelessWidget {
  const _FooterHint({required this.configured, required this.hint});

  final bool configured;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      children: [
        Icon(
          configured ? Icons.link_rounded : Icons.link_off_rounded,
          size: 17,
          color: configured ? palette.coolAccent : palette.faintText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardPalette.of(context);
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
                  color: palette.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.bodyText,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: DashboardPalette.of(context).divider,
    );
  }
}

class _StorageStatePane extends StatelessWidget {
  const _StorageStatePane({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: palette.mutedText),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.titleText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedText,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

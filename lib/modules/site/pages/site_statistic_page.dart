import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_statistic_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_statistic_models.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';

class SiteStatisticPage extends StatefulWidget {
  const SiteStatisticPage({super.key});

  @override
  State<SiteStatisticPage> createState() => _SiteStatisticPageState();
}

class _SiteStatisticPageState extends State<SiteStatisticPage> {
  late final SiteStatisticController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SiteStatisticController>()
        ? Get.find<SiteStatisticController>()
        : Get.put(SiteStatisticController(), permanent: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.items.isEmpty) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.errorText.value != null &&
                    controller.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.errorText.value ?? '',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            onPressed: controller.load,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummary(context)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = controller.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StatisticItemTile(
                              item: item,
                              onInfoTap: () => _showNoteSheet(context, item),
                            ),
                          );
                        }, childCount: controller.items.length),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Text(
            '统计信息',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.xmark_circle_fill, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final primary = theme.colorScheme.primary;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _SummaryChip(
              value: '${controller.totalSites}',
              label: '总站点数',
              color: primary,
            ),
            const SizedBox(width: 12),
            _SummaryChip(
              value: '${controller.normalCount}',
              label: '正常站点',
              color: CupertinoColors.systemGreen,
            ),
            const SizedBox(width: 12),
            _SummaryChip(
              value: '${controller.failCount}',
              label: '失败站点',
              color: AppTheme.errorColor,
            ),
          ],
        ),
      );
    });
  }

  void _showNoteSheet(BuildContext context, SiteStatisticItem item) {
    if (item.note.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Material(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${item.domain} · 历史记录',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...item.note.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(e.key),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${e.value} s',
                              style: TextStyle(
                                fontSize: 13,
                                color: _stateColor(
                                  e.value,
                                  success: item.success > 0,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _stateLabel(e.value),
                              style: TextStyle(
                                fontSize: 13,
                                color: _stateColor(
                                  e.value,
                                  success: item.success > 0,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        tileColor: Theme.of(ctx).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _stateColor(
                              e.value,
                              success: true,
                            ).withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _stateLabel(int code) {
    switch (code) {
      case 0:
        return '正常';
      case 1:
        return '缓慢';
      case 2:
        return '失败';
      default:
        return '未知';
    }
  }

  Color _stateColor(int code, {bool success = false}) {
    if (!success) {
      return AppTheme.errorColor;
    }
    if (code < 0) {
      return CupertinoColors.systemGrey;
    }
    if (code < 2) {
      return CupertinoColors.systemGreen;
    }
    if (code < 10) {
      return CupertinoColors.systemOrange;
    }
    return AppTheme.errorColor;
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticItemTile extends StatelessWidget {
  const _StatisticItemTile({required this.item, required this.onInfoTap});

  final SiteStatisticItem item;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = item.state;
    final stateColor = state == SiteStatisticState.ok
        ? CupertinoColors.systemGreen
        : AppTheme.errorColor;
    final stateLabel = state == SiteStatisticState.ok ? '正常' : '失败';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stateColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.wifi, size: 28, color: stateColor),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  item.domain,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '平均耗时 ${item.seconds}s',
                style: TextStyle(
                  fontSize: 13,
                  color: stateColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '成功率 ${(item.successRate * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: item.note.isEmpty ? null : onInfoTap,
            child: Icon(
              CupertinoIcons.info_circle,
              size: 22,
              color: item.note.isEmpty
                  ? CupertinoColors.systemGrey4
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

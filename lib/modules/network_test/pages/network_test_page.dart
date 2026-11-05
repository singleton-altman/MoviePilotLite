import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/theme/section.dart';

import '../controllers/network_test_controller.dart';

class NetworkTestPage extends GetView<NetworkTestController> {
  const NetworkTestPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网速连通性测试'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.isTestingAll.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: CupertinoActivityIndicator(radius: 8),
              );
            }
            return IconButton(
              icon: const Icon(CupertinoIcons.refresh),
              onPressed: controller.runAll,
            );
          }),
        ],
      ),
      body: SafeArea(child: Obx(() => _buildBody(context, controller))),
    );
  }

  Widget _buildBody(BuildContext context, NetworkTestController controller) {
    final items = controller.items;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '暂无检测目标',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummary(controller);
        }
        return _buildItem(context, controller, items[index - 1]);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: items.length + 1,
    );
  }

  Widget _buildSummary(NetworkTestController controller) {
    final total = controller.items.length;
    final okCount = controller.items
        .where((item) => item.status == NetworkTestStatus.ok)
        .length;
    final errorCount = controller.items
        .where((item) => item.status == NetworkTestStatus.error)
        .length;
    final testingCount = controller.items
        .where((item) => item.status == NetworkTestStatus.testing)
        .length;
    final lastRunAt = controller.lastRunAt.value;
    final timeLabel = lastRunAt == null
        ? '尚未完成检测'
        : '最近检测 ${DateFormat('HH:mm:ss').format(lastRunAt)}';

    String summary;
    if (controller.isTestingAll.value || testingCount > 0) {
      summary = '检测中...';
    } else if (total == 0) {
      summary = '暂无目标';
    } else {
      summary = '正常 $okCount  |  异常 $errorCount';
    }

    return Section(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.wifi,
            size: 18,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          if (!controller.isTestingAll.value)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              color: CupertinoColors.systemBlue.withOpacity(0.12),
              onPressed: controller.runAll,
              child: const Text(
                '全部检测',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            )
          else
            const CupertinoActivityIndicator(radius: 8),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    NetworkTestController controller,
    NetworkTestItem item,
  ) {
    final statusColor = _statusColor(item);
    final statusText = _statusText(item);
    final detailText = _detailText(item);
    final errorText = _errorText(item);

    return Section(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (detailText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detailText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
                if (item.lastCheckedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '上次检测 ${DateFormat('HH:mm:ss').format(item.lastCheckedAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(context, controller, item),
        ],
      ),
    );
  }

  Widget _buildIcon(NetworkTestItem item) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: item.icon,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    NetworkTestController controller,
    NetworkTestItem item,
  ) {
    final isBusy = item.status == NetworkTestStatus.testing;
    final theme = Theme.of(context);
    final backgroundColor = isBusy
        ? CupertinoColors.systemGrey4
        : theme.colorScheme.primary;

    return InkWell(
      onTap: isBusy ? null : () => controller.testItem(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isBusy
              ? const CupertinoActivityIndicator(radius: 8)
              : const Icon(CupertinoIcons.bolt, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Color _statusColor(NetworkTestItem item) {
    if (item.status == NetworkTestStatus.testing) {
      return CupertinoColors.systemOrange;
    }
    if (item.status == NetworkTestStatus.ok) {
      final latency = item.latencyMs ?? 0;
      if (latency >= 2000) {
        return CupertinoColors.systemOrange;
      }
      return CupertinoColors.activeGreen;
    }
    if (item.status == NetworkTestStatus.error) {
      return CupertinoColors.systemRed;
    }
    return CupertinoColors.systemGrey;
  }

  String _statusText(NetworkTestItem item) {
    switch (item.status) {
      case NetworkTestStatus.testing:
        return '检测中';
      case NetworkTestStatus.ok:
        return (item.latencyMs ?? 0) >= 2000 ? '偏慢' : '正常';
      case NetworkTestStatus.error:
        return '异常';
      case NetworkTestStatus.idle:
        return '未检测';
    }
  }

  String _detailText(NetworkTestItem item) {
    if (item.status == NetworkTestStatus.ok && item.latencyMs != null) {
      return '${item.latencyMs} ms';
    }
    if (item.status == NetworkTestStatus.testing) {
      return '...';
    }
    if (item.status == NetworkTestStatus.error && item.statusCode != null) {
      return 'HTTP ${item.statusCode}';
    }
    return '';
  }

  String _errorText(NetworkTestItem item) {
    if (item.status != NetworkTestStatus.error) return '';
    return item.error ?? '';
  }
}

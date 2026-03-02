import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_header.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 存储空间组件
class StorageWidget extends StatelessWidget {
  const StorageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: '存储空间',
      icon: Icons.storage,
      onTapMore: () {
        Get.toNamed('/storage-list');
      },
      child: _buildInfo(context),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final storageData = controller.storageData;
      final totalStorage = storageData['total_storage'] ?? 0.0;
      final usedStorage = storageData['used_storage'] ?? 0.0;
      final progress = totalStorage > 0 ? usedStorage / totalStorage : 0.0;
      final usedPercentage = (progress * 100).toStringAsFixed(1);
      final freeStorage = totalStorage - usedStorage;

      return Skeletonizer(
        enabled: storageData.isEmpty,
        child: Column(
          children: [
            // 只显示存储使用信息，移除右侧图标
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStorageSize(usedStorage),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '已使用 $usedPercentage%',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.rocket_launch,
                      size: 14,
                      color: CupertinoColors.systemOrange,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(context, progress),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '总容量: ${_formatStorageSize(totalStorage)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                Text(
                  '可用: ${_formatStorageSize(freeStorage)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: CupertinoColors.systemGrey5,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        minHeight: 10,
      ),
    );
  }

  /// 格式化存储大小
  String _formatStorageSize(double bytes) {
    return SizeFormatter.formatSize(bytes, 2);
  }
}

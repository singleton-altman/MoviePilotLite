import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 存储空间组件
class StorageWidget extends StatelessWidget {
  const StorageWidget({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildInfo(context);
  }

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardMetricTile(
              label: '存储',
              value: _formatStorageSize(usedStorage),
              icon: Icons.storage_rounded,
              accentColor: palette.primary,
              trailing: Text(
                '$usedPercentage%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.mutedText,
                ),
              ),
              subtitle: '总容量 ${_formatStorageSize(totalStorage)}',
            ),
            const SizedBox(height: 16),
            DashboardProgressBar(
              value: progress,
              color: palette.primary,
              backgroundColor: palette.divider,
              height: 6,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardMiniStat(
                    label: '可用',
                    value: _formatStorageSize(freeStorage),
                  ),
                ),
                Expanded(
                  child: DashboardMiniStat(
                    label: '已用',
                    value: _formatStorageSize(usedStorage),
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompact(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final storageData = controller.storageData;
      final totalStorage = storageData['total_storage'] ?? 0.0;
      final usedStorage = storageData['used_storage'] ?? 0.0;
      final progress = totalStorage > 0 ? usedStorage / totalStorage : 0.0;

      return DashboardMetricTile(
        label: '存储',
        value: _formatStorageSize(totalStorage),
        icon: Icons.storage_rounded,
        accentColor: palette.primary,
        trailing: Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.mutedText,
          ),
        ),
        subtitle: '已用 ${_formatStorageSize(usedStorage)}',
      );
    });
  }

  /// 格式化存储大小
  String _formatStorageSize(double bytes) {
    return SizeFormatter.formatSize(bytes, 1);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 实时速率组件
class RealTimeSpeedWidget extends StatelessWidget {
  const RealTimeSpeedWidget({super.key, this.compact = false});

  final bool compact;

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final downloaderData = controller.downloaderData;
      final downloadSpeed = downloaderData['download_speed'] ?? 0.0;
      final uploadSpeed = downloaderData['upload_speed'] ?? 0.0;
      final downloadSize = downloaderData['download_size'] ?? 0.0;
      final uploadSize = downloaderData['upload_size'] ?? 0.0;
      final freeSpace = downloaderData['free_space'] ?? 0.0;

      return Skeletonizer(
        enabled: downloaderData.isEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardMetricTile(
                    label: '下载',
                    value: '${SizeFormatter.formatSize(downloadSpeed)}/s',
                    icon: CupertinoIcons.arrow_down,
                    accentColor: palette.coolAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardMetricTile(
                    label: '上传',
                    value: '${SizeFormatter.formatSize(uploadSpeed)}/s',
                    icon: CupertinoIcons.arrow_up,
                    accentColor: palette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    label: '上传总量',
                    value: SizeFormatter.formatSize(uploadSize),
                    icon: CupertinoIcons.cloud_upload,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    label: '下载总量',
                    value: SizeFormatter.formatSize(downloadSize),
                    icon: CupertinoIcons.cloud_download,
                    color: palette.warningAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              label: '可用空间',
              value: SizeFormatter.formatSize(freeSpace),
              icon: CupertinoIcons.folder,
              color: palette.successAccent,
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildInfo(context);
  }

  Widget _buildCompact(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final downloaderData = controller.downloaderData;
      final downloadSpeed = downloaderData['download_speed'] ?? 0.0;
      final uploadSpeed = downloaderData['upload_speed'] ?? 0.0;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.tileSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.speedometer,
                  size: 16,
                  color: palette.mutedText,
                ),
                const Spacer(),
                Text(
                  '网络',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: palette.faintText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildCompactRow(
              context: context,
              value: SizeFormatter.formatSize(uploadSpeed),
              unit: '/s',
              icon: CupertinoIcons.arrow_up,
              color: palette.primary,
            ),
            const SizedBox(height: 8),
            _buildCompactRow(
              context: context,
              value: SizeFormatter.formatSize(downloadSpeed),
              unit: '/s',
              icon: CupertinoIcons.arrow_down,
              color: palette.coolAccent,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactRow({
    required BuildContext? context,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final palette = DashboardPalette.of(context!);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.titleText,
          ),
        ),
        const SizedBox(width: 4),
        Text(unit, style: TextStyle(fontSize: 11, color: palette.faintText)),
      ],
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final palette = DashboardPalette.of(Get.context!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: palette.faintText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.titleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

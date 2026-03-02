import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 实时速率组件
class RealTimeSpeedWidget extends StatelessWidget {
  const RealTimeSpeedWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
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
          children: [
            // 第一行：上传/下载速度
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildDataCard(
                    '下载速度',
                    '${SizeFormatter.formatSize(downloadSpeed)}/s',
                    CupertinoIcons.arrow_down,
                    CupertinoColors.activeGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDataCard(
                    '上传速度',
                    '${SizeFormatter.formatSize(uploadSpeed)}/s',
                    CupertinoIcons.arrow_up,
                    CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第二行：上传量
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildDataRow(
                    '上传总量',
                    SizeFormatter.formatSize(uploadSize),
                    CupertinoIcons.cloud_upload,
                    CupertinoColors.systemIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第三行：下载量
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildDataRow(
                    '下载总量',
                    SizeFormatter.formatSize(downloadSize),
                    CupertinoIcons.cloud_download,
                    CupertinoColors.systemPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第四行：可用空间量
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildDataRow(
                    '可用空间',
                    SizeFormatter.formatSize(freeSpace),
                    CupertinoIcons.folder,
                    CupertinoColors.systemOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: '实时速率',
      icon: CupertinoIcons.speedometer,
      onTapMore: () {
        Get.toNamed('/downloader-config');
      },
      child: _buildInfo(context),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(width: 12),
        Text('$label: $value', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildDataCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

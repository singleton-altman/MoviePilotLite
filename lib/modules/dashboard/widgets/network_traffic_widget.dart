import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 网络流量组件
class NetworkTrafficWidget extends StatelessWidget {
  const NetworkTrafficWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final traffic = controller.networkTraffic;
      final upload = traffic.isNotEmpty ? traffic.first : 0;
      final download = traffic.length > 1 ? traffic.last : 0;
      final total = upload + download;
      final uploadRatio = total == 0 ? 0.0 : upload / total;
      final downloadRatio = total == 0 ? 0.0 : download / total;

      return Skeletonizer(
        enabled: traffic.isEmpty,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardMetricTile(
                    label: '上行',
                    value: '${SizeFormatter.formatSize(upload.toDouble())}/s',
                    icon: CupertinoIcons.arrow_up,
                    accentColor: palette.primary,
                    subtitle: '占比 ${(uploadRatio * 100).toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardMetricTile(
                    label: '下行',
                    value: '${SizeFormatter.formatSize(download.toDouble())}/s',
                    icon: CupertinoIcons.arrow_down,
                    accentColor: palette.coolAccent,
                    subtitle: '占比 ${(downloadRatio * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardProgressBar(
                    value: uploadRatio,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardProgressBar(
                    value: downloadRatio,
                    color: palette.coolAccent,
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
    return _buildInfo(context);
  }
}

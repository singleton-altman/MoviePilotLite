import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_header.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 网络流量组件
class NetworkTrafficWidget extends StatelessWidget {
  const NetworkTrafficWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final traffic = controller.networkTraffic;
      return Skeletonizer(
        enabled: traffic.isEmpty,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTrafficItem(
              '上行',
              '${SizeFormatter.formatSize(traffic.first)}ps',
              CupertinoIcons.arrow_up,
              Theme.of(context).colorScheme.secondary,
            ),
            _buildTrafficItem(
              '下行',
              '${SizeFormatter.formatSize(traffic.last)}ps',
              CupertinoIcons.arrow_down,
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: '网络流量',
      icon: CupertinoIcons.wifi,
      child: _buildInfo(context),
    );
  }

  Widget _buildTrafficItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 媒体统计组件
class MediaStatsWidget extends StatelessWidget {
  const MediaStatsWidget({super.key});
  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final statisticData = controller.statisticData.value;

      // 构建统计项列表，添加颜色
      final stats = [
        {
          'label': '电影',
          'value': statisticData?.movie_count ?? 0,
          'icon': CupertinoIcons.film,
          'color': CupertinoColors.systemPurple,
        },
        {
          'label': '电视剧',
          'value': statisticData?.tv_count ?? 0,
          'icon': CupertinoIcons.tv,
          'color': CupertinoColors.systemGreen,
        },
        {
          'label': '剧集',
          'value': statisticData?.episode_count ?? 0,
          'icon': CupertinoIcons.collections,
          'color': CupertinoColors.systemOrange,
        },
        {
          'label': '用户',
          'value': statisticData?.user_count ?? 0,
          'icon': CupertinoIcons.person,
          'color': CupertinoColors.systemBlue,
        },
      ];
      return Skeletonizer(
        enabled: statisticData == null,
        child: Row(
          children: stats.map((stat) {
            return Expanded(
              child: _buildStatItem(
                stat['label'] as String,
                (stat['value'] as int).toString(),
                stat['icon'] as IconData,
                stat['color'] as Color,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: '媒体统计',
      icon: CupertinoIcons.chart_bar,
      child: _buildInfo(context),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

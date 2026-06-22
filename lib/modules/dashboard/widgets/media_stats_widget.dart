import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 媒体统计组件
class MediaStatsWidget extends StatelessWidget {
  const MediaStatsWidget({super.key});
  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final statisticData = controller.statisticData.value;

      // 构建统计项列表，添加颜色
      final stats = [
        {
          'label': '电影',
          'value': statisticData?.movie_count ?? 0,
          'icon': CupertinoIcons.film,
          'color': palette.primary,
        },
        {
          'label': '电视剧',
          'value': statisticData?.tv_count ?? 0,
          'icon': CupertinoIcons.tv,
          'color': palette.coolAccent,
        },
        {
          'label': '剧集',
          'value': statisticData?.episode_count ?? 0,
          'icon': CupertinoIcons.collections,
          'color': palette.warningAccent,
        },
        {
          'label': '用户',
          'value': statisticData?.user_count ?? 0,
          'icon': CupertinoIcons.person,
          'color': palette.successAccent,
        },
      ];
      return Skeletonizer(
        enabled: statisticData == null,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((stat) {
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - 72) / 2,
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
    return _buildInfo(context);
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final palette = DashboardPalette.of(Get.context!);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: palette.titleText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

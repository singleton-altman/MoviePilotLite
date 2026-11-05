import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard_controller.dart';

/// 媒体统计组件：电影 / 电视剧 / 剧集 / 音乐（旧版服务端回退为用户）数量与本月新增
class MediaStatsWidget extends StatelessWidget {
  const MediaStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final statisticData = controller.statisticData.value;
      final musicCount = statisticData?.music_count;

      final stats = <_StatItem>[
        _StatItem(
          label: '电影',
          value: statisticData?.movie_count ?? 0,
          monthlyAddition: statisticData?.movie_count_month ?? 0,
          icon: CupertinoIcons.film,
          color: palette.primary,
        ),
        _StatItem(
          label: '电视剧',
          value: statisticData?.tv_count ?? 0,
          monthlyAddition: statisticData?.tv_count_month ?? 0,
          icon: CupertinoIcons.tv,
          color: palette.coolAccent,
        ),
        _StatItem(
          label: '剧集',
          value: statisticData?.episode_count ?? 0,
          monthlyAddition: statisticData?.episode_count_month ?? 0,
          icon: CupertinoIcons.collections,
          color: palette.warningAccent,
        ),
        if (musicCount != null)
          _StatItem(
            label: '音乐',
            value: musicCount,
            monthlyAddition: statisticData?.music_count_month ?? 0,
            icon: CupertinoIcons.music_note_2,
            color: palette.successAccent,
          )
        else
          _StatItem(
            label: '用户',
            value: statisticData?.user_count ?? 0,
            monthlyAddition: null,
            icon: CupertinoIcons.person,
            color: palette.successAccent,
          ),
      ];

      return Skeletonizer(
        enabled: statisticData == null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final tileWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final stat in stats)
                  SizedBox(width: tileWidth, child: _StatTile(stat: stat)),
              ],
            );
          },
        ),
      );
    });
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.monthlyAddition,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;

  /// 本月新增；为 null 的指标（如用户数）不显示增量
  final int? monthlyAddition;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final addition = stat.monthlyAddition;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, size: 20, color: stat.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCount(stat.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: palette.titleText,
                  ),
                ),
                if (addition != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${_formatCount(addition)} 本月新增',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: addition > 0
                          ? palette.successAccent
                          : palette.faintText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 千分位分隔，与 Web 端 toLocaleString 的展示一致
  static String _formatCount(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}

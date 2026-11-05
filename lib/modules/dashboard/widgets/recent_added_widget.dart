import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_skeletons.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../controllers/dashboard_controller.dart';

/// 入库统计组件：最近 7 天每日入库量柱图与汇总
class RecentAddedWidget extends StatelessWidget {
  const RecentAddedWidget({super.key});

  static const List<String> _weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final transferData = controller.transferData;
      final totalCount = transferData.fold(0, (sum, item) => sum + item);
      final peakCount = transferData.isEmpty
          ? 0
          : transferData.reduce((a, b) => a > b ? a : b);
      final avgCount = transferData.isEmpty
          ? 0.0
          : totalCount / transferData.length;
      final todayCount = transferData.isEmpty ? 0 : transferData.last;
      final chartData = _prepareChartData(transferData);

      if (transferData.isEmpty && controller.isWidgetLoading('最近入库')) {
        return const DashboardChartSkeleton();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DashboardInfoPill(
                text: '入库趋势',
                color: palette.warningAccent,
                icon: CupertinoIcons.chart_bar_alt_fill,
              ),
              const Spacer(),
              Text(
                '最近 7 天',
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 176,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.faintText,
                ),
              ),
              primaryYAxis: NumericAxis(
                isVisible: false,
                minimum: 0,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              series: <ColumnSeries<_DayCount, String>>[
                ColumnSeries<_DayCount, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.label,
                  yValueMapper: (data, _) => data.count,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  spacing: 0.32,
                  animationDuration: 500,
                  pointColorMapper: (data, _) {
                    if (data.isToday) return palette.primary;
                    return data.count == peakCount && peakCount > 0
                        ? palette.primary.withValues(alpha: 0.78)
                        : palette.primary.withValues(alpha: 0.42);
                  },
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    textStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: palette.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalCount',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: palette.titleText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '最近一周入库了 $totalCount 部影片',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: palette.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DashboardMiniStat(
                  label: '今日',
                  value: '$todayCount',
                  valueColor: palette.primary,
                ),
              ),
              Expanded(
                child: DashboardMiniStat(
                  label: '日均',
                  value: avgCount.toStringAsFixed(1),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: DashboardMiniStat(
                  label: '峰值',
                  value: '$peakCount',
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// 服务端按「最早 → 今天」返回每日入库量，这里补上对应的星期标签
  List<_DayCount> _prepareChartData(List<int> transferData) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final length = transferData.length;
    return [
      for (var index = 0; index < length; index++)
        _DayCount(
          label: index == length - 1
              ? '今天'
              : _weekdayLabels[today
                        .subtract(Duration(days: length - 1 - index))
                        .weekday -
                    1],
          count: transferData[index],
          isToday: index == length - 1,
        ),
    ];
  }
}

class _DayCount {
  const _DayCount({
    required this.label,
    required this.count,
    required this.isToday,
  });

  final String label;
  final int count;
  final bool isToday;
}

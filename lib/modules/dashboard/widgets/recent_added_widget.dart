import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../controllers/dashboard_controller.dart';

/// 最近入库组件
class RecentAddedWidget extends StatelessWidget {
  const RecentAddedWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final transferData = controller.transferData;
      final totalCount = transferData.fold(0, (sum, item) => sum + item);
      final peakCount = transferData.isEmpty
          ? 0
          : transferData.reduce((a, b) => a > b ? a : b);
      final avgCount = transferData.isEmpty
          ? 0
          : totalCount / transferData.length;
      final chartData = _prepareChartData(transferData);

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
          const SizedBox(height: 18),
          SizedBox(
            height: 172,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                isVisible: false,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              primaryYAxis: NumericAxis(
                isVisible: false,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              series: <ColumnSeries<Map<String, dynamic>, String>>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, index) => 'D$index',
                  yValueMapper: (data, _) => data['count'] as int,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  spacing: 0.28,
                  pointColorMapper: (data, _) {
                    final value = data['count'] as int;
                    return value == peakCount
                        ? palette.primary
                        : palette.primary.withValues(alpha: 0.48);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '7天前',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.faintText,
                ),
              ),
              const Spacer(),
              Text(
                '今天',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.faintText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DashboardMiniStat(
                  label: '总入库',
                  value: '$totalCount',
                  valueColor: palette.titleText,
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
                  valueColor: palette.primary,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }

  List<Map<String, dynamic>> _prepareChartData(List<int> transferData) {
    final data = List<int>.from(transferData);
    return data.asMap().entries.map((entry) {
      return {'day': entry.key, 'count': entry.value};
    }).toList();
  }
}

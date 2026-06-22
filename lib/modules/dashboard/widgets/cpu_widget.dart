import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../controllers/dashboard_controller.dart';

/// CPU 组件（纯 UI，数据由 DashboardController 提供）
class CpuWidget extends StatelessWidget {
  const CpuWidget({super.key, this.compact = false});

  final bool compact;

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);
    return Obx(() {
      final cpuUsage = controller.cpuUsage.value;
      final chartData = controller.cpuChartData;
      return Skeletonizer(
        enabled: chartData.isEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardMetricTile(
              label: 'CPU 负载',
              value: '${cpuUsage.toStringAsFixed(0)}%',
              icon: CupertinoIcons.speedometer,
              accentColor: palette.primary,
              subtitle: cpuUsage >= 80
                  ? '高负载运行中'
                  : cpuUsage >= 50
                  ? '负载平稳'
                  : '运行顺畅',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 132,
              child: chartData.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : SfCartesianChart(
                      margin: EdgeInsets.zero,
                      plotAreaBorderWidth: 0,
                      backgroundColor: Colors.transparent,
                      primaryXAxis: NumericAxis(
                        isVisible: false,
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 100,
                        isVisible: false,
                        majorGridLines: MajorGridLines(
                          width: 0.6,
                          color: palette.divider,
                        ),
                        axisLine: const AxisLine(width: 0),
                      ),
                      series: <CartesianSeries<ChartDataPoint, int>>[
                        AreaSeries<ChartDataPoint, int>(
                          dataSource: chartData,
                          xValueMapper: (ChartDataPoint data, _) => data.index,
                          yValueMapper: (ChartDataPoint data, _) => data.value,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              palette.primary.withValues(alpha: 0.28),
                              palette.primary.withValues(alpha: 0.02),
                            ],
                          ),
                          borderColor: palette.primary,
                          borderWidth: 2.2,
                          animationDuration: 250,
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                    ),
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
      final cpuUsage = controller.cpuUsage.value;
      final chartData = controller.cpuChartData;
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
            Text(
              'CPU 负载',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: palette.faintText,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${cpuUsage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.titleText,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCompactTrendChart(
              chartData: chartData,
              color: palette.primary,
              dividerColor: palette.divider,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactTrendChart({
    required List<ChartDataPoint> chartData,
    required Color color,
    required Color dividerColor,
  }) {
    final trendData = chartData.isEmpty
        ? List.generate(12, (index) => ChartDataPoint(index, 50))
        : chartData;

    return SizedBox(
      height: 40,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        backgroundColor: Colors.transparent,
        primaryXAxis: NumericAxis(
          isVisible: false,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          isVisible: true,
          minimum: 0,
          maximum: 100,
          majorGridLines: MajorGridLines(width: 0.5, color: dividerColor),
          axisLine: const AxisLine(width: 0),
        ),
        series: <CartesianSeries<ChartDataPoint, int>>[
          SplineSeries<ChartDataPoint, int>(
            dataSource: trendData,
            xValueMapper: (ChartDataPoint data, _) => data.index,
            yValueMapper: (ChartDataPoint data, _) => data.value,
            color: color.withValues(alpha: chartData.isEmpty ? 0.45 : 1),
            width: 2,
          ),
        ],
      ),
    );
  }
}

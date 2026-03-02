import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../controllers/dashboard_controller.dart';

/// CPU 组件（纯 UI，数据由 DashboardController 提供）
class CpuWidget extends StatelessWidget {
  const CpuWidget({super.key});
  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final cpuUsage = controller.cpuUsage.value;
      final chartData = controller.cpuChartData;
      return Skeletonizer(
        enabled: chartData.isEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: chartData.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : SfCartesianChart(
                      primaryXAxis: NumericAxis(
                        isVisible: false,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 100,
                        interval: 20,
                        majorGridLines: const MajorGridLines(
                          width: 1,
                          color: CupertinoColors.systemGrey5,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 10,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      series: <CartesianSeries<ChartDataPoint, int>>[
                        AreaSeries<ChartDataPoint, int>(
                          dataSource: chartData,
                          xValueMapper: (ChartDataPoint data, _) => data.index,
                          yValueMapper: (ChartDataPoint data, _) => data.value,
                          color: CupertinoColors.systemPurple.withAlpha(100),
                          borderColor: CupertinoColors.systemPurple,
                          borderWidth: 3,
                          animationDuration: 300,
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                    ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Text(
                '当前: ${cpuUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'CPU',
      icon: Icons.device_thermostat,
      child: _buildInfo(context),
    );
  }
}

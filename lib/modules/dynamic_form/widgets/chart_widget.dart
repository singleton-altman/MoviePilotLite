import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 图表区块：饼图/环形图，App 风格
class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key, required this.block});

  final ChartBlock block;

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (block.title != null && block.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                block.title!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.label,
                    context,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 220,
            child: _buildChart(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final labels = block.labels;
    final series = block.series;
    final chartType = block.chartType.toLowerCase();

    if (series.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel,
              context,
            ),
          ),
        ),
      );
    }

    final data = <_ChartPoint>[];
    for (var i = 0; i < series.length; i++) {
      final label = i < labels.length ? labels[i] : '项 ${i + 1}';
      data.add(_ChartPoint(label, series[i].toDouble()));
    }

    if (chartType == 'pie' || chartType == 'donut') {
      return SfCircularChart(
        legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
        series: <CircularSeries<_ChartPoint, String>>[
          PieSeries<_ChartPoint, String>(
            dataSource: data,
            xValueMapper: (_ChartPoint p, _) => p.label,
            yValueMapper: (_ChartPoint p, _) => p.value,
            dataLabelSettings: DataLabelSettings(isVisible: true),
          ),
        ],
      );
    }

    // 折线图 / 柱状图（趋势类数据）
    return SfCartesianChart(
      margin: const EdgeInsets.only(top: 8),
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<_ChartPoint, String>>[
        if (chartType == 'line')
          LineSeries<_ChartPoint, String>(
            dataSource: data,
            xValueMapper: (_ChartPoint p, _) => p.label,
            yValueMapper: (_ChartPoint p, _) => p.value,
            markerSettings: const MarkerSettings(isVisible: true),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          )
        else
          ColumnSeries<_ChartPoint, String>(
            dataSource: data,
            xValueMapper: (_ChartPoint p, _) => p.label,
            yValueMapper: (_ChartPoint p, _) => p.value,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
      ],
    );
  }
}

class _ChartPoint {
  _ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

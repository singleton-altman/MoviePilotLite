import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';

/// 后台任务列表组件
class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final scheduleList = controller.scheduleData.value;

      if (scheduleList.isEmpty) {
        return const DashboardEmptyState(
          icon: CupertinoIcons.calendar_badge_minus,
          title: '暂无后台任务',
          subtitle: '任务队列目前是空的',
        );
      }

      const maxDisplayCount = 5;
      final displayList = scheduleList.length > maxDisplayCount
          ? scheduleList.sublist(0, maxDisplayCount)
          : scheduleList;

      return Column(
        children: displayList.map((schedule) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: schedule == displayList.last ? 0 : 12,
            ),
            child: _buildScheduleItem(context, schedule),
          );
        }).toList(),
      );
    });
  }

  Widget _buildScheduleItem(BuildContext context, ScheduleModel schedule) {
    final palette = DashboardPalette.of(Get.context!);
    final theme = Theme.of(context);
    final primaryTextColor =
        theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant;
    final statusColor = _getStatusColor(schedule.status, palette);
    final progress = _getStatusProgress(schedule.status);

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(schedule.status),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  schedule.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              ),
              DashboardInfoPill(
                text: schedule.status.isEmpty ? '待机' : schedule.status,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardProgressBar(
            value: progress,
            color: statusColor,
            backgroundColor: palette.divider,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.provider.isEmpty ? '系统任务' : schedule.provider,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  schedule.next_run.isEmpty
                      ? '等待调度'
                      : '下次 ${schedule.next_run}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, DashboardPaletteData palette) {
    switch (status) {
      case '运行中':
        return palette.primary;
      case '等待':
        return palette.warningAccent;
      case '完成':
        return palette.successAccent;
      case '失败':
        return Colors.redAccent;
      default:
        return palette.mutedText;
    }
  }

  double _getStatusProgress(String status) {
    switch (status) {
      case '运行中':
        return 0.72;
      case '等待':
        return 0.36;
      case '完成':
        return 1;
      case '失败':
        return 0.18;
      default:
        return 0.12;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '运行中':
        return CupertinoIcons.time_solid;
      case '等待':
        return CupertinoIcons.hourglass;
      case '完成':
        return CupertinoIcons.check_mark_circled_solid;
      case '失败':
        return CupertinoIcons.exclamationmark_triangle_fill;
      default:
        return CupertinoIcons.circle_grid_3x3_fill;
    }
  }
}

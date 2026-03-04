import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
import 'package:moviepilot_mobile/theme/section.dart';

/// 后台任务列表组件
class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      title: '后台任务',
      icon: CupertinoIcons.calendar,
      onTapMore: () {
        Get.toNamed('/background-task-list');
      },
      child: _buildInfo(context),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final scheduleList = controller.scheduleData.value;

      if (scheduleList.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              '暂无后台任务数据',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ),
        );
      }

      // 限制显示数量为5个
      const maxDisplayCount = 5;
      final displayList = scheduleList.length > maxDisplayCount
          ? scheduleList.sublist(0, maxDisplayCount)
          : scheduleList;

      return Column(
        children: [
          ...displayList.map((schedule) {
            return _buildScheduleItem(
              schedule,
              context,
              schedule == displayList.last,
            );
          }),
        ],
      );
    });
  }

  /// 构建任务项
  Widget _buildScheduleItem(
    dynamic schedule,
    BuildContext context,
    bool isLast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  schedule.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Expanded(
                child: Text(
                  schedule.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(schedule.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  schedule.next_run,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
            height: 1,
          ),
      ],
    );
  }

  /// 根据状态获取颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case '运行中':
        return CupertinoColors.activeBlue;
      case '等待':
        return CupertinoColors.systemYellow;
      case '完成':
        return CupertinoColors.activeGreen;
      case '失败':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

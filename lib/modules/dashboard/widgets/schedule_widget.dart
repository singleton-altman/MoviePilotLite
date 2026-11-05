import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/transfer_queue_job.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_skeletons.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';

/// 后台任务列表组件：整理队列与运行中任务排在前面，运行中任务显示真实进度
class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({super.key, this.maxDisplayCount = 6});

  /// 仪表板上最多展示的条目数，更多内容由「查看全部」进入列表页
  final int maxDisplayCount;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final schedules = controller.scheduleData.value;
      final queue = controller.transferQueue;
      final error = controller.scheduleError.value;
      // 订阅进度变化，运行中任务的进度条随轮询刷新
      controller.scheduleProgress.length;

      final tasks = <_BackgroundTask>[
        for (final job in queue) _BackgroundTask.fromTransferJob(job),
        for (final schedule in schedules.where(
          DashboardController.isScheduleRunning,
        ))
          _BackgroundTask.fromSchedule(schedule, controller, running: true),
        for (final schedule in schedules.where(
          (item) => !DashboardController.isScheduleRunning(item),
        ))
          _BackgroundTask.fromSchedule(schedule, controller, running: false),
      ];

      if (tasks.isEmpty) {
        final isPermission =
            error == DashboardController.schedulePermissionMessage;
        if (isPermission) {
          return const DashboardEmptyState(
            icon: CupertinoIcons.lock_shield,
            title: DashboardController.schedulePermissionMessage,
            subtitle: '后台任务仅管理员账号可查看',
          );
        }
        if (error != null) {
          return DashboardEmptyState(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: '后台任务加载失败',
            subtitle: error,
          );
        }
        if (controller.isWidgetLoading('后台任务')) {
          return const DashboardListSkeleton(itemCount: 3, showPoster: false);
        }
        return const DashboardEmptyState(
          icon: CupertinoIcons.calendar_badge_minus,
          title: '没有后台服务',
          subtitle: '任务队列目前是空的',
        );
      }

      final displayList = tasks.length > maxDisplayCount
          ? tasks.sublist(0, maxDisplayCount)
          : tasks;

      return Column(
        children: [
          for (var index = 0; index < displayList.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == displayList.length - 1 ? 0 : 10,
              ),
              child: _BackgroundTaskTile(task: displayList[index]),
            ),
        ],
      );
    });
  }
}

/// 统一后的任务条目：定时服务与整理队列共用一套展示结构
class _BackgroundTask {
  const _BackgroundTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.color,
    this.progress,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;

  /// 运行中任务的百分比进度；null 表示未运行，不显示进度条
  final double? progress;

  bool get isRunning => progress != null;

  factory _BackgroundTask.fromSchedule(
    ScheduleModel schedule,
    DashboardController controller, {
    required bool running,
  }) {
    final visual = _SchedulerVisual.of(schedule);
    final name = _firstNonEmpty([schedule.name_i18n, schedule.name]);
    final provider = _firstNonEmpty([schedule.provider_i18n, schedule.provider]);
    final nextRun = _firstNonEmpty([schedule.next_run_i18n, schedule.next_run]);
    final statusText = _firstNonEmpty([schedule.status_i18n, schedule.status]);
    final progressText = running
        ? controller.scheduleProgressText(schedule)
        : '';

    return _BackgroundTask(
      id: 'schedule-${schedule.id}',
      title: name.isEmpty ? '后台任务' : name,
      subtitle: running && progressText.isNotEmpty
          ? progressText
          : provider.isNotEmpty
          ? provider
          : nextRun.isNotEmpty
          ? '下次 $nextRun'
          : '等待调度',
      status: running
          ? '进行中'
          : statusText.isNotEmpty
          ? statusText
          : '等待中',
      icon: visual.icon,
      color: visual.color,
      progress: running ? controller.scheduleProgressValue(schedule) : null,
    );
  }

  factory _BackgroundTask.fromTransferJob(TransferQueueJob job) {
    return _BackgroundTask(
      id: job.key,
      title: job.title,
      subtitle: '${job.completedTasks} / ${job.totalTasks} 个文件',
      status: job.isRunning ? '进行中' : '等待中',
      icon: Icons.drive_file_move_outlined,
      color: const Color(0xFFFFAD1F),
      progress: job.isRunning ? job.progress : null,
    );
  }

  static String _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final text = candidate?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class _BackgroundTaskTile extends StatelessWidget {
  const _BackgroundTaskTile({required this.task});

  final _BackgroundTask task;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final tone = task.color;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isRunning ? tone.withValues(alpha: 0.32) : palette.tileBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              task.isRunning ? 0 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tone.withValues(
                      alpha: palette.isDark ? 0.18 : 0.13,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(task.icon, color: tone, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: palette.titleText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: task.isRunning ? tone : palette.mutedText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (task.isRunning)
                      CupertinoActivityIndicator(radius: 6.5, color: tone)
                    else
                      Icon(
                        CupertinoIcons.clock,
                        size: 13,
                        color: palette.faintText,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (task.isRunning) ...[
            const SizedBox(height: 10),
            DashboardProgressBar(
              value: (task.progress ?? 0) / 100,
              color: tone,
              backgroundColor: palette.divider,
              height: 4,
            ),
          ],
        ],
      ),
    );
  }
}

/// 定时服务的图标与主题色，按任务 id / 名称 / 提供者匹配；与 Web 端规则保持一致
class _SchedulerVisual {
  const _SchedulerVisual(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _SchedulerVisual _fallback = _SchedulerVisual(
    Icons.timer_outlined,
    Color(0xFF25B6C8),
  );

  static const List<_SchedulerVisualRule> _rules = [
    _SchedulerVisualRule(
      ids: ['cookiecloud'],
      names: ['cookiecloud'],
      visual: _SchedulerVisual(Icons.cloud_sync_outlined, Color(0xFF3F8CFF)),
    ),
    _SchedulerVisualRule(
      ids: ['mediaserver_sync'],
      names: ['媒体服务器'],
      visual: _SchedulerVisual(Icons.live_tv_outlined, Color(0xFF42C336)),
    ),
    _SchedulerVisualRule(
      ids: ['new_subscribe_search', 'subscribe_search'],
      names: ['订阅搜索', '新增订阅搜索'],
      visual: _SchedulerVisual(Icons.search_rounded, Color(0xFFE91E63)),
    ),
    _SchedulerVisualRule(
      ids: ['subscribe_tmdb'],
      names: ['订阅元数据'],
      visual: _SchedulerVisual(Icons.manage_search_rounded, Color(0xFF9B6CF3)),
    ),
    _SchedulerVisualRule(
      ids: ['subscribe_refresh'],
      names: ['订阅刷新'],
      visual: _SchedulerVisual(Icons.refresh_rounded, Color(0xFF25B6C8)),
    ),
    _SchedulerVisualRule(
      ids: ['subscribe_follow'],
      names: ['订阅分享'],
      visual: _SchedulerVisual(Icons.share_outlined, Color(0xFFFF704D)),
    ),
    _SchedulerVisualRule(
      ids: ['transfer'],
      names: ['下载文件整理', '文件整理'],
      visual: _SchedulerVisual(
        Icons.drive_file_move_outlined,
        Color(0xFF3F8CFF),
      ),
    ),
    _SchedulerVisualRule(
      ids: ['random_wallpager'],
      names: ['壁纸'],
      visual: _SchedulerVisual(Icons.image_outlined, Color(0xFF9B6CF3)),
    ),
    _SchedulerVisualRule(
      ids: ['scheduler_job'],
      names: ['公共定时服务'],
      visual: _SchedulerVisual(Icons.schedule_outlined, Color(0xFF42C336)),
    ),
    _SchedulerVisualRule(
      ids: ['clear_cache'],
      names: ['缓存清理'],
      visual: _SchedulerVisual(
        Icons.cleaning_services_outlined,
        Color(0xFFFFAD1F),
      ),
    ),
    _SchedulerVisualRule(
      ids: ['data_cleanup'],
      names: ['数据表清理'],
      visual: _SchedulerVisual(Icons.delete_sweep_outlined, Color(0xFFFF704D)),
    ),
    _SchedulerVisualRule(
      ids: ['user_auth'],
      names: ['用户认证'],
      visual: _SchedulerVisual(
        Icons.verified_user_outlined,
        Color(0xFF9B6CF3),
      ),
    ),
    _SchedulerVisualRule(
      ids: ['sitedata_refresh'],
      names: ['站点数据'],
      visual: _SchedulerVisual(Icons.language_rounded, Color(0xFF25B6C8)),
    ),
    _SchedulerVisualRule(
      ids: ['recommend_refresh'],
      names: ['推荐缓存'],
      visual: _SchedulerVisual(Icons.star_outline_rounded, Color(0xFFFFAD1F)),
    ),
    _SchedulerVisualRule(
      ids: ['plugin_market_refresh'],
      names: ['插件市场'],
      visual: _SchedulerVisual(Icons.extension_outlined, Color(0xFFFF704D)),
    ),
    _SchedulerVisualRule(
      ids: ['subscribe_calendar_cache'],
      names: ['订阅日历'],
      visual: _SchedulerVisual(
        Icons.event_repeat_outlined,
        Color(0xFF3F8CFF),
      ),
    ),
    _SchedulerVisualRule(
      ids: ['full_gc'],
      names: ['内存回收'],
      visual: _SchedulerVisual(Icons.memory_outlined, Color(0xFF25B6C8)),
    ),
    _SchedulerVisualRule(
      ids: ['agent_heartbeat'],
      names: ['智能体'],
      visual: _SchedulerVisual(Icons.smart_toy_outlined, Color(0xFF9B6CF3)),
    ),
    _SchedulerVisualRule(
      ids: ['usage_report'],
      names: ['统计上报'],
      visual: _SchedulerVisual(Icons.show_chart_rounded, Color(0xFF42C336)),
    ),
    _SchedulerVisualRule(
      ids: ['workflow'],
      providers: ['工作流'],
      visual: _SchedulerVisual(
        Icons.account_tree_outlined,
        Color(0xFF3F8CFF),
      ),
    ),
    _SchedulerVisualRule(
      ids: ['plugin'],
      visual: _SchedulerVisual(Icons.extension_outlined, Color(0xFFFF704D)),
    ),
  ];

  static _SchedulerVisual of(ScheduleModel schedule) {
    final id = schedule.id.toLowerCase();
    final name = schedule.name.toLowerCase();
    final provider = schedule.provider.toLowerCase();
    for (final rule in _rules) {
      if (_matches(rule.ids, id) ||
          _matches(rule.names, name) ||
          _matches(rule.providers, provider)) {
        return rule.visual;
      }
    }
    return _fallback;
  }

  static bool _matches(List<String>? values, String target) {
    if (values == null || values.isEmpty || target.isEmpty) return false;
    return values.any((value) => target.contains(value.toLowerCase()));
  }
}

class _SchedulerVisualRule {
  const _SchedulerVisualRule({
    required this.visual,
    this.ids,
    this.names,
    this.providers,
  });

  final _SchedulerVisual visual;
  final List<String>? ids;
  final List<String>? names;
  final List<String>? providers;
}

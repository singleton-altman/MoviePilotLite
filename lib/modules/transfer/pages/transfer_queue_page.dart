import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/transfer/controllers/transfer_queue_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 整理队列监控页：查看整理中的媒体与任务,可移除单个任务。
class TransferQueuePage extends GetView<TransferQueueController> {
  const TransferQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('整理队列'),
        centerTitle: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: '刷新队列',
              onPressed: controller.isLoading.value ? null : controller.reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.jobs.isEmpty) {
          return Skeletonizer(
            enabled: true,
            child: _buildList(_skeletonJobs, theme),
          );
        }
        final error = controller.errorText.value;
        if (error != null && controller.jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: theme.colorScheme.error.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.reload,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (controller.jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 44,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '整理队列为空',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '下载完成的文件会先进入队列等待整理',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return _buildList(controller.jobs, theme);
      }),
    );
  }

  Widget _buildList(List<TransferQueueJob> jobs, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: controller.reload),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildJobCard(context, jobs[index], theme),
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    TransferQueueJob job,
    ThemeData theme,
  ) {
    final poster = job.poster?.trim() ?? '';
    final metaParts = <String>[
      if (job.year != null && job.year!.isNotEmpty) job.year!,
      if (job.season != null && job.season! > 0)
        'S${job.season.toString().padLeft(2, '0')}',
      '${job.tasks.length} 个任务',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 56,
                  child: poster.isEmpty
                      ? Container(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                          child: Icon(
                            Icons.movie_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                        )
                      : CachedImage(
                          imageUrl: ImageUtil.convertCacheImageUrl(poster),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (metaParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          metaParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          for (final task in job.tasks) _buildTaskRow(theme, job, task),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    ThemeData theme,
    TransferQueueJob job,
    TransferQueueTask task,
  ) {
    final stateLabel = _stateLabel(task.state);
    final subParts = <String>[
      if (task.downloader != null && task.downloader!.isNotEmpty)
        task.downloader!,
      if (stateLabel != null) stateLabel,
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName?.isNotEmpty == true ? task.fileName! : '未命名任务',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '移除',
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              size: 20,
              color: theme.colorScheme.error.withOpacity(0.8),
            ),
            onPressed: () => _confirmDelete(job, task),
          ),
        ],
      ),
    );
  }

  String? _stateLabel(String? state) {
    final s = state?.trim();
    if (s == null || s.isEmpty) return null;
    switch (s.toLowerCase()) {
      case 'waiting':
      case 'pending':
        return '等待中';
      case 'running':
      case 'transferring':
        return '整理中';
      case 'success':
      case 'done':
        return '已完成';
      case 'error':
      case 'failed':
        return '失败';
      default:
        return s;
    }
  }

  void _confirmDelete(TransferQueueJob job, TransferQueueTask task) {
    ToastUtil.warning(
      '将从整理队列移除「${task.fileName ?? '该任务'}」,确定继续吗?',
      title: '移除整理任务',
      onConfirm: () async {
        final error = await controller.deleteTask(job, task);
        if (error != null) {
          ToastUtil.error(error);
        } else {
          ToastUtil.success('已移除');
        }
      },
    );
  }

  static final List<TransferQueueJob> _skeletonJobs = List.generate(
    3,
    (i) => const TransferQueueJob(
      title: '加载中的媒体条目',
      year: '2026',
      season: 1,
      tasks: [
        TransferQueueTask(
          fileitem: {},
          fileName: '加载中的任务文件名.mkv',
          state: 'running',
        ),
      ],
    ),
  );
}

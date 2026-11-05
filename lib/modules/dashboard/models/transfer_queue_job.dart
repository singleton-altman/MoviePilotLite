/// 整理队列任务（API: GET /api/v1/transfer/queue → TransferJob[]）
///
/// 仪表板只关心展示标题与文件级进度，故不保留完整的 MediaInfo 与 FileItem。
class TransferQueueJob {
  const TransferQueueJob({
    required this.key,
    required this.title,
    required this.totalTasks,
    required this.completedTasks,
    required this.isRunning,
  });

  /// 用于列表 key 的稳定标识
  final String key;

  /// 展示标题（优先 title_year）
  final String title;

  /// 文件任务总数
  final int totalTasks;

  /// 已完成文件任务数
  final int completedTasks;

  /// 是否有文件任务处于 running 状态
  final bool isRunning;

  /// 完成百分比（0-100）
  double get progress =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks * 100).clamp(0, 100);

  factory TransferQueueJob.fromJson(Map<String, dynamic> json, int index) {
    final mediaRaw = json['media'];
    final media = mediaRaw is Map
        ? Map<String, dynamic>.from(mediaRaw)
        : const <String, dynamic>{};
    final tasksRaw = json['tasks'];
    final tasks = tasksRaw is List ? tasksRaw.whereType<Map>().toList() : const [];
    final completed = tasks
        .where((task) => task['state']?.toString() == 'completed')
        .length;
    final running = tasks.any((task) => task['state']?.toString() == 'running');

    final titleYear = media['title_year']?.toString();
    final title = media['title']?.toString();
    final season = json['season'];
    final mediaSource = media['media_source']?.toString() ?? 'unknown';
    final mediaId = media['media_id']?.toString() ?? '$index';

    return TransferQueueJob(
      key: 'transfer-$mediaSource-$mediaId-${season ?? ''}',
      title: (titleYear != null && titleYear.isNotEmpty)
          ? titleYear
          : (title != null && title.isNotEmpty ? title : '整理队列'),
      totalTasks: tasks.length,
      completedTasks: completed,
      isRunning: running,
    );
  }
}

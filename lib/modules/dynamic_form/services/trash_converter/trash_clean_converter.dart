import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// TrashClean 插件专用转换器：将自定义 API 原始 JSON 转换为 FormBlock 列表
class TrashCleanConverter {
  /// 展示页：status + latestCleanResult + cleanProgress + stats → FormBlock 列表（只读）
  static List<FormBlock> convertPage({
    required Map<String, dynamic> status,
    required Map<String, dynamic> latestCleanResult,
    required Map<String, dynamic> cleanProgress,
    List<Map<String, dynamic>> stats = const [],
    List<Map<String, dynamic>> downloaders = const [],
  }) {
    final blocks = <FormBlock>[];

    _buildStatusSection(blocks, status);
    _buildMonitorPathsSection(blocks, status);
    _buildStatsSection(blocks, stats);
    _buildExcludeDirsSection(blocks, status);
    _buildDownloaderSection(blocks, cleanProgress, downloaders);
    _buildCleanupRulesSection(blocks, status);
    _buildLatestCleanResultSection(blocks, latestCleanResult);
    _buildCleaningHistorySection(blocks, status);

    blocks.add(
      const FormBlock.alert(type: 'info', text: '点击右下角设置按钮可设置清理策略和监控目录。'),
    );

    return blocks;
  }

  /// 配置页：status → (FormBlock 列表, formModel)
  static (List<FormBlock>, Map<String, dynamic>) convertForm({
    required Map<String, dynamic> status,
  }) {
    final blocks = <FormBlock>[];
    final model = _buildFormModel(status);

    _buildBasicSettingsSection(blocks);
    _buildScheduleSection(blocks);
    _buildMonitorPathsFormSection(blocks);
    _buildCleanupRulesFormSection(blocks);
    _buildExcludeDirsFormSection(blocks);

    return (blocks, model);
  }

  // ---------------------------------------------------------------------------
  // 展示页各 Section（全部使用 InfoCardBlock）
  // ---------------------------------------------------------------------------

  static void _buildStatusSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final enabled = status['enabled'] == true;
    final cron = status['cron']?.toString() ?? '未设置';
    final nextRun = status['next_run_time']?.toString() ?? '未知';

    blocks.add(
      FormBlock.infoCard(
        title: '当前状态',
        iconName: 'mdi-information',
        iconColor: 'info',
        rows: [
          InfoCardRow(
            iconName: 'mdi-power',
            iconColor: enabled ? 'green' : 'grey',
            label: '插件状态',
            chipText: enabled ? '已启用' : '已禁用',
            chipColor: enabled ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-code-braces',
            label: 'CRON表达式',
            chipText: cron,
            chipColor: 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            label: '下次运行',
            value: nextRun,
          ),
        ],
      ),
    );
  }

  static void _buildStatsSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> stats,
  ) {
    if (stats.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '目录统计',
          iconName: 'mdi-chart-line-variant',
          iconColor: 'teal',
          emptyText: '暂无目录统计数据',
        ),
      );
      return;
    }

    final rows = <InfoCardRow>[];
    for (final item in stats) {
      final path = item['path']?.toString() ?? '';
      final exists = item['exists'] == true;
      final sizeMB = (item['total_size_mb'] as num?) ?? 0;
      final fileCount = item['file_count'] ?? 0;
      final dirCount = item['dir_count'] ?? 0;

      rows.add(
        InfoCardRow(
          iconName: 'mdi-folder-search',
          iconColor: exists ? 'blue' : 'red',
          label: path,
          value: '$fileCount 文件 · $dirCount 目录',
          chipText: _formatSize(sizeMB.toDouble()),
          chipColor: 'teal',
        ),
      );
    }

    blocks.add(
      FormBlock.infoCard(
        title: '目录统计',
        iconName: 'mdi-chart-line-variant',
        iconColor: 'teal',
        headerChipText: '${stats.length} 个目录',
        headerChipColor: 'blue',
        rows: rows,
      ),
    );
  }

  static String _formatSize(double mb) {
    if (mb >= 1024 * 1024) {
      return '${(mb / (1024 * 1024)).toStringAsFixed(2)} TB';
    } else if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    } else {
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  static void _buildMonitorPathsSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final paths = _toStringList(status['monitor_paths']);
    blocks.add(
      FormBlock.infoCard(
        title: '监控路径',
        iconName: 'mdi-folder-search',
        iconColor: 'info',
        headerChipText: '${paths.length} 个路径',
        headerChipColor: 'green',
        rows: paths
            .map((p) => InfoCardRow(iconName: 'mdi-folder-search', label: p))
            .toList(),
        emptyText: '未设置任何监控路径',
        emptyIconName: 'mdi-folder-off',
      ),
    );
  }

  static void _buildExcludeDirsSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final dirs = _toStringList(status['exclude_dirs']);
    blocks.add(
      FormBlock.infoCard(
        title: '排除目录',
        iconName: 'mdi-folder-remove',
        iconColor: 'warning',
        headerChipText: '${dirs.length} 个目录',
        headerChipColor: 'green',
        rows: dirs
            .map((d) => InfoCardRow(iconName: 'mdi-folder-remove', label: d))
            .toList(),
        emptyText: '未设置任何排除目录',
        emptyIconName: 'mdi-folder-off',
      ),
    );
  }

  static void _buildDownloaderSection(
    List<FormBlock> blocks,
    Map<String, dynamic> progress,
    List<Map<String, dynamic>> downloaders,
  ) {
    final running = progress['running'] == true;
    String? alertText;
    String? alertType;

    if (running) {
      final current = progress['current_dir']?.toString() ?? '';
      final percent = progress['percent'] ?? 0;
      alertText = '正在清理: $current（进度 $percent%）';
      alertType = 'warning';
    }

    if (downloaders.isEmpty) {
      blocks.add(
        FormBlock.infoCard(
          title: '下载器状态',
          iconName: 'mdi-download',
          iconColor: 'info',
          alertText: alertText,
          alertType: alertType,
          emptyText: '未找到可用的下载器',
          emptyIconName: 'mdi-download-off',
        ),
      );
      return;
    }

    final hasActive = downloaders.any((d) => d['hasActiveTasks'] == true);
    final rows = <InfoCardRow>[];
    for (final dl in downloaders) {
      final name = dl['name']?.toString() ?? '';
      final type = dl['type']?.toString() ?? '';
      final active = dl['hasActiveTasks'] == true;
      final count = dl['count'] ?? 0;

      rows.add(
        InfoCardRow(
          iconName: active ? 'mdi-download' : 'mdi-download-off',
          iconColor: active ? 'orange' : 'green',
          label: name,
          value: type,
          chipText: active ? '$count 活跃任务' : '空闲',
          chipColor: active ? 'orange' : 'green',
        ),
      );
    }

    blocks.add(
      FormBlock.infoCard(
        title: '下载器状态',
        iconName: 'mdi-download',
        iconColor: 'info',
        headerChipText: hasActive ? '有活跃任务' : '全部空闲',
        headerChipColor: hasActive ? 'orange' : 'green',
        alertText: alertText,
        alertType: alertType,
        rows: rows,
      ),
    );
  }

  static void _buildCleanupRulesSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final rules = status['cleanup_rules'] as Map<String, dynamic>? ?? {};

    final emptyDir = rules['empty_dir'] == true;
    final smallDir = rules['small_dir'] as Map<String, dynamic>? ?? {};
    final smallEnabled = smallDir['enabled'] == true;
    final maxSize = smallDir['max_size'] ?? 0;
    final sizeReduction =
        rules['size_reduction'] as Map<String, dynamic>? ?? {};
    final reductionEnabled = sizeReduction['enabled'] == true;

    blocks.add(
      FormBlock.infoCard(
        title: '清理规则',
        iconName: 'mdi-filter',
        iconColor: 'purple',
        rows: [
          InfoCardRow(
            iconName: 'mdi-folder-remove',
            iconColor: emptyDir ? 'green' : 'grey',
            label: '清理空目录',
            chipText: emptyDir ? '已启用' : '已禁用',
            chipColor: emptyDir ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-package-variant',
            iconColor: smallEnabled ? 'orange' : 'grey',
            label: '清理小体积目录',
            value: smallEnabled ? '最大体积 ${maxSize}MB' : null,
            chipText: smallEnabled ? '已启用' : '已禁用',
            chipColor: smallEnabled ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-chart-line-variant',
            iconColor: reductionEnabled ? 'green' : 'grey',
            label: '清理体积减少目录',
            chipText: reductionEnabled ? '已启用' : '已禁用',
            chipColor: reductionEnabled ? 'green' : 'grey',
          ),
        ],
      ),
    );
  }

  static void _buildLatestCleanResultSection(
    List<FormBlock> blocks,
    Map<String, dynamic> result,
  ) {
    final resultStatus = result['status']?.toString() ?? '';
    if (resultStatus.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '最近清理记录',
          iconName: 'mdi-history',
          iconColor: 'info',
          emptyText: '暂无清理记录',
        ),
      );
      return;
    }

    final removedDirs = _toStringList(result['removed_dirs']);
    final emptyCount = result['removed_empty_dirs_count'] ?? 0;
    final smallCount = result['removed_small_dirs_count'] ?? 0;
    final reductionCount = result['removed_size_reduction_dirs_count'] ?? 0;
    final totalDirs = emptyCount + smallCount + reductionCount;
    final freedSpace = result['total_freed_space'] ?? 0;
    final freedMB = (freedSpace is num)
        ? (freedSpace / (1024 * 1024)).toStringAsFixed(2)
        : '0.00';

    final isSuccess = resultStatus == 'success';
    blocks.add(
      FormBlock.infoCard(
        title: '最近清理记录',
        iconName: 'mdi-history',
        iconColor: 'info',
        alertText: isSuccess
            ? '清理成功，共删除 $totalDirs 个目录，释放 ${freedMB}MB 空间'
            : '清理失败: $resultStatus',
        alertType: isSuccess ? 'success' : 'error',
        rows: removedDirs
            .map((d) => InfoCardRow(iconName: 'mdi-folder-remove', label: d))
            .toList(),
        emptyText: removedDirs.isEmpty ? '没有符合清理条件的目录' : null,
      ),
    );
  }

  static void _buildCleaningHistorySection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final history = status['cleaning_history'] as List? ?? [];
    if (history.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '清理历史',
          iconName: 'mdi-history',
          iconColor: 'info',
          emptyText: '暂无清理历史记录',
        ),
      );
      return;
    }

    final rows = <InfoCardRow>[];
    final badgeColors = ['green', 'orange', 'red', 'grey', 'purple', 'teal'];
    var idx = 0;
    for (final item in history) {
      if (item is Map<String, dynamic>) {
        final time = item['time']?.toString() ?? '';
        final s = item['status']?.toString() ?? '';
        final count =
            (item['removed_empty_dirs_count'] ?? 0) +
            (item['removed_small_dirs_count'] ?? 0) +
            (item['removed_size_reduction_dirs_count'] ?? 0);
        final freedBytes = (item['total_freed_space'] as num?) ?? 0;
        final freedMB = freedBytes / (1024 * 1024);
        final sizeText = _formatSize(freedMB);
        final isOk = s == 'success';
        rows.add(
          InfoCardRow(
            iconName: 'mdi-check-circle',
            iconColor: badgeColors[idx % badgeColors.length],
            label: time,
            subtitle: '清理 $count 个目录 (释放 $sizeText)',
            chipText: '#${idx + 1}',
            chipColor: badgeColors[idx % badgeColors.length],
          ),
        );
        idx++;
      }
    }

    blocks.add(
      FormBlock.infoCard(
        title: '清理历史',
        iconName: 'mdi-history',
        iconColor: 'info',
        rows: rows,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 配置页各 Section
  // ---------------------------------------------------------------------------

  static void _buildBasicSettingsSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '基本设置'));
    blocks.add(const FormBlock.switchField(label: '启用插件', name: 'enable'));
    blocks.add(const FormBlock.switchField(label: '启用通知', name: 'notify'));
    blocks.add(
      const FormBlock.switchField(
        label: '仅在无下载任务时执行',
        name: 'only_when_no_download',
      ),
    );
  }

  static void _buildScheduleSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '定时任务设置'));
    blocks.add(
      const FormBlock.cronField(
        label: 'CRON表达式',
        name: 'cron',
        hint: '如：0 4 * * *（每天凌晨4点）',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '监控扫描间隔(小时)',
        name: 'scan_interval',
        hint: '目录大小监控的间隔时间，用于判断体积减少阈值',
      ),
    );
    blocks.add(
      const FormBlock.alert(
        type: 'info',
        text:
            '扫描间隔是系统记录目录大小变化的时间周期，对"体积减少目录"功能至关重要。'
            '建议设置为与清理任务执行时间相同或更长。',
      ),
    );
  }

  static void _buildMonitorPathsFormSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '监控路径设置'));
    blocks.add(
      const FormBlock.textArea(
        label: '监控路径',
        name: 'monitor_paths',
        hint: '每行一个路径',
        rows: 4,
      ),
    );
  }

  static void _buildCleanupRulesFormSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '清理规则'));
    blocks.add(
      const FormBlock.switchField(label: '清理空目录', name: 'empty_dir_cleanup'),
    );
    blocks.add(
      const FormBlock.switchField(label: '清理小体积目录', name: 'small_dir_cleanup'),
    );
    blocks.add(
      const FormBlock.textField(
        label: '小体积目录最大值(MB)',
        name: 'small_dir_max_size',
      ),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '清理体积减少目录',
        name: 'size_reduction_cleanup',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '体积减少阈值(%)',
        name: 'size_reduction_threshold',
      ),
    );
    blocks.add(
      const FormBlock.alert(
        type: 'info',
        text:
            '垃圾文件清理插件支持三种清理模式：空目录清理、小体积目录清理、体积减少目录清理。'
            '配置完成后，插件将按CRON设定定时执行。',
      ),
    );
  }

  static void _buildExcludeDirsFormSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '排除目录设置'));
    blocks.add(
      const FormBlock.textArea(
        label: '排除目录',
        name: 'exclude_dirs',
        hint: '每行一个目录路径',
        rows: 4,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // formModel 构建：status 嵌套结构 → config 扁平结构
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _buildFormModel(Map<String, dynamic> status) {
    final rules = status['cleanup_rules'] as Map<String, dynamic>? ?? {};
    final smallDir = rules['small_dir'] as Map<String, dynamic>? ?? {};
    final sizeReduction =
        rules['size_reduction'] as Map<String, dynamic>? ?? {};

    final monitorPaths = _toStringList(status['monitor_paths']);
    final excludeDirs = _toStringList(status['exclude_dirs']);

    return {
      'enable': status['enabled'] ?? false,
      'notify': true,
      'cron': status['cron'] ?? '0 4 * * *',
      'only_when_no_download': status['only_when_no_download'] ?? true,
      'monitor_paths': monitorPaths.join('\n'),
      'exclude_dirs': excludeDirs.join('\n'),
      'scan_interval': 24,
      'empty_dir_cleanup': rules['empty_dir'] ?? false,
      'small_dir_cleanup': smallDir['enabled'] ?? false,
      'small_dir_max_size': smallDir['max_size'] ?? 10,
      'size_reduction_cleanup': sizeReduction['enabled'] ?? false,
      'size_reduction_threshold': sizeReduction['threshold'] ?? 80,
    };
  }

  /// formModel → POST /config 的请求 body（字符串字段转回数组）
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    final body = Map<String, dynamic>.from(model);

    body['monitor_paths'] = _splitLines(body['monitor_paths']);
    body['exclude_dirs'] = _splitLines(body['exclude_dirs']);

    final scanInterval = body['scan_interval'];
    if (scanInterval is String) {
      body['scan_interval'] = int.tryParse(scanInterval) ?? 24;
    }
    final maxSize = body['small_dir_max_size'];
    if (maxSize is String) {
      body['small_dir_max_size'] = int.tryParse(maxSize) ?? 10;
    }
    final threshold = body['size_reduction_threshold'];
    if (threshold is String) {
      body['size_reduction_threshold'] = int.tryParse(threshold) ?? 80;
    }

    return body;
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<String> _splitLines(dynamic value) {
    if (value is String) {
      return value
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

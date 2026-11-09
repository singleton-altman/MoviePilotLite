import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

/// ProxmoxVEBackup 插件专用转换器：将 API 原始 JSON 转换为 FormBlock 列表
class ProxmoxVEBackupConverter {
  /// 展示页：pve_status + container_status + dashboard + backups + history → FormBlock 列表
  /// [useHeaderBlock] 为 true 时跳过 PVE 状态 InfoCard，由 ProxmoxVeBackupHeader 渲染
  static List<FormBlock> convertPage({
    required Map<String, dynamic> pveStatus,
    List<Map<String, dynamic>> containerStatusList = const [],
    List<Map<String, dynamic>> backups = const [],
    List<Map<String, dynamic>> backupHistory = const [],
    List<Map<String, dynamic>> restoreHistory = const [],
    Map<String, dynamic>? dashboard,
    Map<String, dynamic>? monitor,
    List<Map<String, dynamic>> templates = const [],
    bool useHeaderBlock = false,
    void Function(String type, String vmid, String action)? onContainerAction,
    void Function(String type, Map<String, dynamic> item)? onBackupAction,
  }) {
    final blocks = <FormBlock>[];
    if (!useHeaderBlock) {
      _buildPveStatusSection(blocks, pveStatus);
    }
    _buildDashboardSection(blocks, dashboard);
    _buildContainerStatusSection(
      blocks,
      containerStatusList,
      onContainerAction,
    );
    _buildAvailableBackupsSection(blocks, backups, onBackupAction);
    _buildHistorySection(
      blocks,
      title: '备份历史',
      iconName: 'mdi-history',
      iconColor: 'blue',
      records: backupHistory,
    );
    _buildHistorySection(
      blocks,
      title: '恢复历史',
      iconName: 'mdi-backup-restore',
      iconColor: 'orange',
      records: restoreHistory,
    );
    _buildMonitorSection(blocks, monitor);
    _buildTemplateSection(blocks, templates);

    blocks.add(
      const FormBlock.alert(type: 'info', text: '点击右下角设置按钮可配置 Proxmox VE 备份。'),
    );

    return blocks;
  }

  /// 配置页：config → (FormBlock 列表, formModel)
  ///
  /// 结构对齐 Web 端 Config.vue（v3.x）：基本设置 → 连接设置 → 备份存储
  /// （storage_targets 由原生编辑器渲染，插入在「备份存储」标题后）→
  /// WebDAV → 备份还原 → 系统设置。
  static (List<FormBlock>, Map<String, dynamic>) convertForm({
    required Map<String, dynamic> config,
  }) {
    final blocks = <FormBlock>[];
    final model = _normalizeConfig(config);

    _buildBasicSettingsSection(blocks);
    _buildPveConnectionSection(blocks);
    _buildStorageSection(blocks);
    _buildWebdavSection(blocks);
    _buildBackupRestoreSection(blocks);
    _buildCleanupSection(blocks);

    return (blocks, model);
  }

  /// 表单默认值，对齐 Web 端 Config.vue 的 reactive(config) 初始值。
  /// 服务端配置里缺失的字段用默认值回填，保证与 Web 端看到的表单一致。
  static const Map<String, dynamic> _formDefaults = {
    'enabled': false,
    'notify': false,
    'retry_count': 0,
    'retry_interval': 60,
    'notification_message_type': '插件',
    'onlyonce': false,
    'pve_host': '',
    'pve_api_port': '',
    'ssh_port': '22',
    'ssh_username': 'root',
    'ssh_password': '',
    'ssh_key_file': '',
    'enable_local_backup': false,
    'backup_path': '/config/plugins/ProxmoxVEBackup/actual_backups',
    'keep_backup_num': 0,
    'enable_webdav': false,
    'webdav_url': '',
    'webdav_username': '',
    'webdav_password': '',
    'webdav_path': '',
    'webdav_keep_backup_num': 0,
    'storage_backup_enable': true,
    'storage_name': 'local',
    'backup_vmid': '',
    'backup_mode': 'snapshot',
    'compress_mode': 'zstd',
    'auto_delete_after_download': true,
    'download_all_backups': true,
    'enable_restore': false,
    'restore_force': false,
    'restore_skip_existing': true,
    'restore_storage': '',
    'restore_vmid': '',
    'restore_now': false,
    'restore_file': '',
    'clear_history': false,
    'cron': '0 3 * * *',
    'auto_cleanup_tmp': true,
    'enable_log_cleanup': false,
    'log_journal_days': 0,
    'log_vzdump_keep': 0,
    'log_pve_keep': 0,
    'log_dpkg_keep': 0,
    'cleanup_template_images': false,
    'status_poll_interval': 30000,
    'container_poll_interval': 30000,
  };

  /// 对齐 Web 端 fetchConfig 的合并与归一化：
  /// 默认值打底 → 服务端配置覆盖 → 补齐派生字段（对齐 Config.vue 592-640 行）。
  static Map<String, dynamic> _normalizeConfig(Map<String, dynamic> config) {
    final model = Map<String, dynamic>.from(_formDefaults);
    model.addAll(config);

    // SSH 用户名缺省 root
    if ((model['ssh_username'] ?? '').toString().trim().isEmpty) {
      model['ssh_username'] = 'root';
    }
    // 备份存储目标：确保是数组且至少一行（本地行预填本地备份路径）
    final targets = model['storage_targets'];
    if (targets is! List || targets.isEmpty) {
      model['storage_targets'] = [
        {
          'type': 'local',
          'path': (model['backup_path'] ?? '').toString(),
          'keep_backup_num': 0,
        },
      ];
    } else {
      model['storage_targets'] = [
        for (final t in targets)
          t is Map ? Map<String, dynamic>.from(t) : <String, dynamic>{},
      ];
    }
    // 旧版「启用本地备份」迁移：转为存储目标中的本地磁盘行
    if (model['storage_backup_enable'] != true &&
        model['enable_local_backup'] == true) {
      model['storage_backup_enable'] = true;
      model['storage_targets'] = [
        {
          'type': 'local',
          'path': (model['backup_path'] ?? '').toString(),
          'keep_backup_num': _intOf(model['keep_backup_num']),
        },
      ];
    }
    if (model['mp_storages'] is! List) model['mp_storages'] = <dynamic>[];
    // 状态页轮询配置：归一化为数字，缺省/0 → 30000ms
    for (final key in const ['status_poll_interval', 'container_poll_interval']) {
      final n = int.tryParse('${model[key]}') ?? 0;
      model[key] = n <= 0 ? 30000 : n;
    }
    return model;
  }

  /// formModel → 请求 body。插件保存走 POST /config 且服务端做字段合并，
  /// 这里原样回传全部字段（含未在表单展示的 pve_api_port、restore_* 等），
  /// 避免漏字段被服务端清空。
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    return Map<String, dynamic>.from(model);
  }

  /// 时间戳（秒或毫秒）或时间字符串 → 可读时间
  static String formatTime(dynamic raw) {
    if (raw == null) return '';
    if (raw is num) {
      final millis = raw > 100000000000 ? raw.toInt() : (raw * 1000).toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return _formatDateTime(dt);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return '';
    final parsed = num.tryParse(text);
    if (parsed != null) return formatTime(parsed);
    return text;
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  static String _formatUptime(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${seconds ~/ 60} 分钟';
    if (seconds < 86400) return '${seconds ~/ 3600} 小时';
    return '${seconds ~/ 86400} 天';
  }

  static void _buildPveStatusSection(
    List<FormBlock> blocks,
    Map<String, dynamic> pveStatus,
  ) {
    final online = pveStatus['online'] == true;
    final error = pveStatus['error']?.toString() ?? '';
    final hostname = pveStatus['hostname']?.toString() ?? '未知';
    final ip = pveStatus['ip']?.toString() ?? '';
    final cpuUsage = numOf(pveStatus['cpu_usage']) ?? 0.0;
    final memUsage = numOf(pveStatus['mem_usage']) ?? 0.0;
    final diskUsage = numOf(pveStatus['disk_usage']) ?? 0.0;
    final loadAvg = pveStatus['load_avg'] as List? ?? [];
    final loadStr = loadAvg.map((e) => e?.toString() ?? '').join(' / ');
    final cpuTemp = numOf(pveStatus['cpu_temp']);
    final cpuModel = pveStatus['cpu_model']?.toString() ?? '';
    final cpuCores = pveStatus['cpu_cores']?.toString() ?? '';
    final kernel = pveStatus['kernel']?.toString() ?? '';
    final pveVersion = pveStatus['pve_version']?.toString() ?? '';
    final totalMem = numOf(pveStatus['mem_total']) ?? 0.0;
    final memUsed = numOf(pveStatus['mem_used']) ?? 0.0;
    final totalDisk = numOf(pveStatus['disk_total']) ?? 0.0;
    final diskUsed = numOf(pveStatus['disk_used']) ?? 0.0;
    final swapUsage = numOf(pveStatus['swap_usage']) ?? 0.0;
    final swapUsed = numOf(pveStatus['swap_used']) ?? 0.0;
    final swapTotal = numOf(pveStatus['swap_total']) ?? 0.0;
    final rows = <InfoCardRow>[
      InfoCardRow(
        iconName: 'mdi-server',
        iconColor: online ? 'green' : 'red',
        label: 'PVE 状态',
        chipText: online ? '在线' : '离线',
        chipColor: online ? 'green' : 'red',
      ),
      if (error.isNotEmpty)
        InfoCardRow(
          iconName: 'mdi-alert',
          iconColor: 'red',
          label: '错误',
          value: error,
        ),
      InfoCardRow(iconName: 'mdi-desktop-mac', label: '主机名', value: hostname),
      if (ip.isNotEmpty)
        InfoCardRow(iconName: 'mdi-ip', label: 'IP', value: ip),
      InfoCardRow.progress(
        iconName: 'mdi-chip',
        iconColor: 'blue',
        label: 'CPU 使用率',
        chipText:
            '${cpuUsage.toStringAsFixed(1)}%${cpuTemp != null ? ' / ${cpuTemp.toStringAsFixed(0)}°C' : ''}',
        chipColor: cpuUsage > 80 ? 'red' : 'blue',
        progressValue: (cpuUsage / 100.0).clamp(0.0, 1.0),
      ),
      InfoCardRow.progress(
        iconName: 'mdi-memory',
        iconColor: 'teal',
        label: '内存使用率',
        chipText:
            '${SizeFormatter.formatSizeFromMb(memUsed)}/${SizeFormatter.formatSizeFromMb(totalMem)}',
        chipColor: memUsage > 80 ? 'red' : 'teal',
        progressValue: (memUsage / 100.0).clamp(0.0, 1.0),
      ),
      InfoCardRow.progress(
        iconName: 'mdi-harddisk',
        iconColor: 'purple',
        label: '磁盘使用率',
        chipText:
            '${SizeFormatter.formatSizeFromMb(diskUsed)}/${SizeFormatter.formatSizeFromMb(totalDisk)}',
        chipColor: diskUsage > 80 ? 'red' : 'purple',
        progressValue: (diskUsage / 100.0).clamp(0.0, 1.0),
      ),
      if (loadStr.isNotEmpty)
        InfoCardRow(
          iconName: 'mdi-chart-line',
          iconColor: 'blue',
          label: '负载',
          value: loadStr,
        ),
      if (swapTotal > 0)
        InfoCardRow.progress(
          iconName: 'mdi-swap-horizontal',
          iconColor: 'orange',
          label: 'Swap 使用率',
          chipText:
              '${SizeFormatter.formatSizeFromMb(swapUsed)}/${SizeFormatter.formatSizeFromMb(swapTotal)}',
          chipColor: _usageColor(swapUsage),
          progressValue: (swapUsage / 100.0).clamp(0.0, 1.0),
        ),
      if (cpuModel.isNotEmpty)
        InfoCardRow(
          iconName: 'mdi-cpu-64-bit',
          label: 'CPU',
          value: cpuCores.isEmpty ? cpuModel : '$cpuModel ($cpuCores 核)',
        ),
      if (kernel.isNotEmpty)
        InfoCardRow(iconName: 'mdi-linux', label: '内核', value: kernel),
      if (pveVersion.isNotEmpty)
        InfoCardRow(
          iconName: 'mdi-information',
          label: 'PVE 版本',
          value: pveVersion,
        ),
    ];

    blocks.add(
      FormBlock.infoCard(
        title: 'Proxmox VE 主机状态',
        iconName: 'mdi-server',
        iconColor: online ? 'green' : 'grey',
        rows: rows,
      ),
    );
  }

  static String _usageColor(num usage) => usage > 80 ? 'red' : 'blue';

  static void _buildDashboardSection(
    List<FormBlock> blocks,
    Map<String, dynamic>? dashboard,
  ) {
    if (dashboard == null || dashboard.isEmpty) return;
    final backupStats = _asMap(dashboard['backup_stats']);
    final restoreStats = _asMap(dashboard['restore_stats']);
    final available = _asMap(dashboard['available_backups']);
    final status = _asMap(dashboard['status']);
    if (backupStats.isEmpty && available.isEmpty) return;

    final items = <(String, String, String, String)>[
      (
        'mdi-backup-restore',
        '备份成功',
        '${_intOf(backupStats['successful'])}',
        'green',
      ),
      ('mdi-alert-circle', '备份失败', '${_intOf(backupStats['failed'])}', 'red'),
      ('mdi-restore', '恢复成功', '${_intOf(restoreStats['successful'])}', 'teal'),
      ('mdi-file-archive', '可用备份', '${_intOf(available['total'])}', 'blue'),
    ];
    blocks.add(
      FormBlock.infoCard(
        title: '备份概览',
        iconName: 'mdi-chart-donut',
        iconColor: 'blue',
        headerChipText: status['running'] == true ? '运行中' : '空闲',
        headerChipColor: status['running'] == true ? 'orange' : 'green',
        rows: [
          for (final item in items)
            InfoCardRow(
              iconName: item.$1,
              iconColor: item.$4,
              label: item.$2,
              value: item.$3,
            ),
          if (available.isNotEmpty)
            InfoCardRow(
              iconName: 'mdi-cloud',
              iconColor: 'purple',
              label: '本地 / 网盘备份',
              value:
                  '${_intOf(available['local'])} / ${_intOf(available['webdav'])}',
            ),
          if ((status['backup_activity']?.toString() ?? '').isNotEmpty)
            InfoCardRow(
              iconName: 'mdi-progress-clock',
              iconColor: 'orange',
              label: '备份状态',
              value: status['backup_activity'].toString(),
            ),
          if ((status['restore_activity']?.toString() ?? '').isNotEmpty)
            InfoCardRow(
              iconName: 'mdi-progress-wrench',
              iconColor: 'orange',
              label: '恢复状态',
              value: status['restore_activity'].toString(),
            ),
        ],
      ),
    );
  }

  static void _buildContainerStatusSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> containerStatusList,
    void Function(String type, String vmid, String action)? onContainerAction,
  ) {
    if (containerStatusList.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '虚拟机 / 容器',
          iconName: 'mdi-docker',
          iconColor: 'info',
          emptyText: '暂无容器数据',
          emptyIconName: 'mdi-docker',
        ),
      );
      return;
    }

    final headers = ['名称', 'VMID', '状态', '类型', '运行时间', 'CPU', '内存'];
    final rows = <List<dynamic>>[];
    for (final c in containerStatusList) {
      final vmid = c['vmid']?.toString() ?? '';
      final name = c['displayName']?.toString() ?? c['name']?.toString() ?? '';
      final status = c['status']?.toString() ?? '';
      final type = c['type']?.toString() ?? '';
      final uptime = intOfNum(c['uptime']);
      final cpu = numOf(c['cpu']) ?? 0.0;
      final mem = numOf(c['mem']) ?? 0.0;
      final maxMem = numOf(c['maxmem']) ?? 0.0;
      rows.add([
        name,
        vmid,
        status,
        type,
        _formatUptime(uptime),
        '${(cpu * 100).toStringAsFixed(1)}%',
        maxMem > 0
            ? '${SizeFormatter.formatSizeFromMb(mem)}/${SizeFormatter.formatSizeFromMb(maxMem)}'
            : SizeFormatter.formatSizeFromMb(mem),
      ]);
    }

    blocks.add(
      FormBlock.table(
        onAction: (actionType, index) {
          final vmid = rows[index][1];
          final type = rows[index][3];
          onContainerAction?.call(type.toString(), vmid.toString(), actionType);
        },
        headers: headers,
        rows: rows,
        actions: [
          InfoCardRowMenuItem(
            label: '启动',
            iconName: 'mdi-play',
            iconColor: 'green',
            events: Map<String, dynamic>.from({'type': 'start'}),
          ),
          InfoCardRowMenuItem(
            label: '停止',
            iconName: 'mdi-stop',
            iconColor: 'red',
            events: Map<String, dynamic>.from({'type': 'stop'}),
          ),
          InfoCardRowMenuItem(
            label: '重启',
            iconName: 'mdi-restart',
            iconColor: 'blue',
            events: Map<String, dynamic>.from({'type': 'reboot'}),
          ),
          InfoCardRowMenuItem(
            label: '快照',
            iconName: 'mdi-camera',
            iconColor: 'blue',
            events: Map<String, dynamic>.from({'type': 'snapshot'}),
          ),
        ],
      ),
    );
  }

  static void _buildAvailableBackupsSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> backups,
    void Function(String type, Map<String, dynamic> item)? onBackupAction,
  ) {
    if (backups.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '备份文件',
          iconName: 'mdi-backup-restore',
          iconColor: 'teal',
          emptyText: '暂无备份文件',
          emptyIconName: 'mdi-backup-restore',
        ),
      );
      return;
    }

    final rows = <List<dynamic>>[];
    for (final b in backups) {
      rows.add([
        b['filename']?.toString() ?? '',
        b['source']?.toString() ?? '',
        '${(numOf(b['size_mb']) ?? 0).toStringAsFixed(1)} MB',
        b['time_str']?.toString() ?? formatTime(b['timestamp']),
      ]);
    }

    blocks.add(
      FormBlock.table(
        onAction: (actionType, index) {
          if (index < 0 || index >= backups.length) return;
          onBackupAction?.call(actionType, backups[index]);
        },
        headers: const ['文件名', '来源', '大小', '时间'],
        rows: rows,
        actions: [
          InfoCardRowMenuItem(
            label: '恢复',
            iconName: 'mdi-restore',
            iconColor: 'teal',
            events: Map<String, dynamic>.from({'type': 'restore'}),
          ),
          InfoCardRowMenuItem(
            label: '下载',
            iconName: 'mdi-download',
            iconColor: 'blue',
            events: Map<String, dynamic>.from({'type': 'download'}),
          ),
          InfoCardRowMenuItem(
            label: '删除',
            iconName: 'mdi-delete-outline',
            iconColor: 'red',
            events: Map<String, dynamic>.from({'type': 'delete'}),
          ),
        ],
      ),
    );
  }

  static void _buildHistorySection(
    List<FormBlock> blocks, {
    required String title,
    required String iconName,
    required String iconColor,
    required List<Map<String, dynamic>> records,
  }) {
    if (records.isEmpty) {
      blocks.add(
        FormBlock.infoCard(
          title: title,
          iconName: iconName,
          iconColor: iconColor,
          emptyText: '暂无记录',
          emptyIconName: iconName,
        ),
      );
      return;
    }
    final recent = records.reversed.take(10).toList();
    final rows = <InfoCardRow>[];
    for (final r in recent) {
      final success = r['success'] == true;
      final filename = r['filename']?.toString() ?? '';
      final message = r['message']?.toString() ?? '';
      final detail = [
        if (filename.isNotEmpty) filename,
        if (message.isNotEmpty) message,
      ].join(' · ');
      rows.add(
        InfoCardRow(
          iconName: success ? 'mdi-check-circle' : 'mdi-close-circle',
          iconColor: success ? 'green' : 'red',
          label: formatTime(r['timestamp']),
          subtitle: detail.isEmpty ? null : detail,
          chipText: success ? '成功' : '失败',
          chipColor: success ? 'green' : 'red',
        ),
      );
    }
    blocks.add(
      FormBlock.infoCard(
        title: title,
        iconName: iconName,
        iconColor: iconColor,
        headerChipText: '${records.length} 条',
        headerChipColor: 'blue',
        rows: rows,
      ),
    );
  }

  static void _buildMonitorSection(
    List<FormBlock> blocks,
    Map<String, dynamic>? monitor,
  ) {
    if (monitor == null || monitor.isEmpty) return;
    final error = monitor['error']?.toString() ?? '';
    if (error.isNotEmpty) {
      blocks.add(
        FormBlock.infoCard(
          title: '性能监控',
          iconName: 'mdi-chart-areaspline',
          iconColor: 'blue',
          alertText: error,
          alertType: 'warning',
          emptyText: '监控数据获取失败',
          emptyIconName: 'mdi-chart-areaspline',
        ),
      );
      return;
    }

    final rows = <InfoCardRow>[];
    final node = monitor['node']?.toString() ?? '';
    final uptime = intOfNum(monitor['uptime']);
    final loadavg = monitor['loadavg'] as List? ?? [];
    final cpuModel = monitor['cpu_model']?.toString() ?? '';
    if (node.isNotEmpty) {
      rows.add(
        InfoCardRow(
          iconName: 'mdi-server-network',
          iconColor: 'blue',
          label: '节点',
          value: node,
          subtitle: cpuModel.isEmpty ? null : cpuModel,
        ),
      );
    }
    if (uptime > 0) {
      rows.add(
        InfoCardRow(
          iconName: 'mdi-timer-outline',
          iconColor: 'teal',
          label: '运行时长',
          value: _formatUptime(uptime),
        ),
      );
    }
    if (loadavg.isNotEmpty) {
      rows.add(
        InfoCardRow(
          iconName: 'mdi-chart-line',
          iconColor: 'blue',
          label: '负载',
          value: loadavg.map((e) => e.toString()).join(' / '),
        ),
      );
    }

    final mem = _asMap(monitor['memory']);
    if (mem.isNotEmpty) {
      final used = numOf(mem['used']) ?? 0;
      final total = numOf(mem['total']) ?? 0;
      rows.add(
        InfoCardRow.progress(
          iconName: 'mdi-memory',
          iconColor: 'teal',
          label: '内存',
          chipText:
              '${SizeFormatter.formatSizeFromMb(used / 1024 / 1024)}/${SizeFormatter.formatSizeFromMb(total / 1024 / 1024)}',
          chipColor: 'teal',
          progressValue: total > 0 ? (used / total).clamp(0.0, 1.0) : 0,
        ),
      );
    }

    final rootfs = _asMap(monitor['rootfs']);
    if (rootfs.isNotEmpty) {
      final used = numOf(rootfs['used']) ?? 0;
      final total = numOf(rootfs['total']) ?? 0;
      rows.add(
        InfoCardRow.progress(
          iconName: 'mdi-harddisk',
          iconColor: 'purple',
          label: '根分区',
          chipText:
              '${SizeFormatter.formatSizeFromMb(used / 1024 / 1024)}/${SizeFormatter.formatSizeFromMb(total / 1024 / 1024)}',
          chipColor: 'purple',
          progressValue: total > 0 ? (used / total).clamp(0.0, 1.0) : 0,
        ),
      );
    }

    blocks.add(
      FormBlock.infoCard(
        title: '性能监控',
        iconName: 'mdi-chart-areaspline',
        iconColor: 'blue',
        rows: rows,
        emptyText: '暂无监控数据',
        emptyIconName: 'mdi-chart-areaspline',
      ),
    );

    final storages = monitor['storages'] as List? ?? [];
    if (storages.isNotEmpty) {
      final storageRows = <InfoCardRow>[];
      for (final s in storages) {
        if (s is! Map) continue;
        final map = Map<String, dynamic>.from(s);
        final name = map['storage']?.toString() ?? '';
        final used = numOf(map['used']) ?? 0;
        final total = numOf(map['total']) ?? 0;
        final fraction = numOf(map['used_fraction']) ?? 0;
        storageRows.add(
          InfoCardRow.progress(
            iconName: 'mdi-database',
            iconColor: 'cyan',
            label: name,
            subtitle: map['content']?.toString(),
            chipText:
                '${SizeFormatter.formatSizeFromMb(used / 1024 / 1024)}/${SizeFormatter.formatSizeFromMb(total / 1024 / 1024)}',
            chipColor: fraction > 0.85 ? 'red' : 'cyan',
            progressValue: fraction.clamp(0.0, 1.0),
          ),
        );
      }
      blocks.add(
        FormBlock.infoCard(
          title: '存储空间',
          iconName: 'mdi-database',
          iconColor: 'cyan',
          rows: storageRows,
        ),
      );
    }

    final tasks = monitor['tasks'] as List? ?? [];
    if (tasks.isNotEmpty) {
      final taskRows = <InfoCardRow>[];
      for (final t in tasks.take(8)) {
        if (t is! Map) continue;
        final map = Map<String, dynamic>.from(t);
        final running =
            (map['status']?.toString() ?? '').contains('running') ||
            map['endtime'] == null ||
            map['endtime'] == 0;
        final start = intOfNum(map['starttime']);
        taskRows.add(
          InfoCardRow(
            iconName: running ? 'mdi-progress-clock' : 'mdi-check-circle',
            iconColor: running ? 'orange' : 'green',
            label:
                '${map['desc'] ?? map['type'] ?? ''}'
                '${map['vmid'] != null ? ' #${map['vmid']}' : ''}',
            subtitle: start > 0 ? formatTime(start) : null,
            chipText: running ? '进行中' : '完成',
            chipColor: running ? 'orange' : 'green',
          ),
        );
      }
      blocks.add(
        FormBlock.infoCard(
          title: '最近任务',
          iconName: 'mdi-progress-clock',
          iconColor: 'orange',
          rows: taskRows,
        ),
      );
    }
  }

  static void _buildTemplateSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> templates,
  ) {
    if (templates.isEmpty) return;
    final rows = <InfoCardRow>[];
    for (final t in templates.take(20)) {
      final isIso = t['type']?.toString() == 'iso';
      rows.add(
        InfoCardRow(
          iconName: isIso ? 'mdi-disc' : 'mdi-package-variant-closed',
          iconColor: isIso ? 'blue' : 'teal',
          label: t['filename']?.toString() ?? '',
          subtitle: t['date']?.toString(),
          value: '${(numOf(t['size_mb']) ?? 0).toStringAsFixed(1)} MB',
        ),
      );
    }
    blocks.add(
      FormBlock.infoCard(
        title: '镜像模板',
        iconName: 'mdi-disc-multiple',
        iconColor: 'blue',
        headerChipText: '${templates.length} 个',
        headerChipColor: 'blue',
        rows: rows,
      ),
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  /// 安全数值读取：num 直接返回；字符串尝试解析（插件部分字段会序列化成
  /// 字符串，硬 `as num?` 会抛 TypeError 导致整页崩溃）。
  static double? numOf(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static int intOfNum(dynamic value) {
    if (value is num) return value.toInt();
    final text = '${value ?? ''}'.trim();
    return int.tryParse(text) ?? (double.tryParse(text)?.toInt() ?? 0);
  }

  static int _intOf(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static void _buildBasicSettingsSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '基本设置'));
    blocks.add(const FormBlock.switchField(label: '启用插件', name: 'enabled'));
    blocks.add(const FormBlock.switchField(label: '启用通知', name: 'notify'));
    blocks.add(const FormBlock.switchField(label: '仅执行一次', name: 'onlyonce'));
    blocks.add(
      const FormBlock.selectField(
        label: '消息类型',
        name: 'notification_message_type',
        items: [
          SelectOption(title: '插件', value: 'Plugin'),
          SelectOption(title: '系统', value: 'System'),
          SelectOption(title: '全部', value: 'All'),
        ],
      ),
    );
    blocks.add(
      const FormBlock.cronField(
        label: 'CRON表达式',
        name: 'cron',
        hint: '如：0 3 * * *（每天凌晨3点）',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '重试次数',
        name: 'retry_count',
        hint: '失败后重试次数',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '重试间隔(秒)',
        name: 'retry_interval',
        hint: '重试间隔秒数',
      ),
    );
  }

  /// 轮询间隔选项（对齐 Config.vue pollIntervalOptions）
  static const _pollIntervalOptions = [
    SelectOption(title: '5秒', value: 5000),
    SelectOption(title: '10秒', value: 10000),
    SelectOption(title: '15秒', value: 15000),
    SelectOption(title: '30秒（推荐）', value: 30000),
    SelectOption(title: '1分钟', value: 60000),
    SelectOption(title: '2分钟', value: 120000),
    SelectOption(title: '5分钟', value: 300000),
  ];

  static void _buildPveConnectionSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '连接设置'));
    blocks.add(
      const FormBlock.textField(
        label: 'PVE主机地址',
        name: 'pve_host',
        hint: '192.168.1.100',
      ),
    );
    blocks.add(
      const FormBlock.textField(label: 'SSH端口', name: 'ssh_port', hint: '22'),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH用户名',
        name: 'ssh_username',
        hint: '通常使用root用户以确保有足够权限',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH密码',
        name: 'ssh_password',
        hint: '留空则使用密钥',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH私钥文件路径',
        name: 'ssh_key_file',
        hint: '可选',
      ),
    );
    blocks.add(
      FormBlock.selectField(
        label: '状态轮询间隔',
        name: 'status_poll_interval',
        items: _pollIntervalOptions,
      ),
    );
    blocks.add(
      FormBlock.selectField(
        label: '容器状态轮询间隔',
        name: 'container_poll_interval',
        items: _pollIntervalOptions,
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'PVE API 端口',
        name: 'pve_api_port',
        hint: '默认 8006',
      ),
    );
  }

  /// 备份存储（本地磁盘 / MP 存储多目标）标题块，
  /// 多目标编辑器由渲染器插在该标题后（ProxmoxStorageTargetsEditor）。
  static void _buildStorageSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '备份存储'));
  }

  static void _buildWebdavSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: 'WebDAV 备份'));
    blocks.add(
      const FormBlock.switchField(label: '启用WebDAV备份', name: 'enable_webdav'),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV服务器地址',
        name: 'webdav_url',
        hint: 'http://host:port/dav',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV用户名',
        name: 'webdav_username',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV密码',
        name: 'webdav_password',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV备份路径',
        name: 'webdav_path',
        hint: '/dav/backup',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV备份保留数量',
        name: 'webdav_keep_backup_num',
        hint: '设置为0或留空表示保留全部备份',
      ),
    );
  }

  /// 备份还原（对齐 Config.vue backup-config 节点）
  static void _buildBackupRestoreSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '备份还原'));
    blocks.add(
      const FormBlock.switchField(
        label: '下载后自动删除PVE备份',
        name: 'auto_delete_after_download',
      ),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '下载所有备份文件（多VM时）',
        name: 'download_all_backups',
      ),
    );
    blocks.add(
      const FormBlock.switchField(label: '启用恢复系统', name: 'enable_restore'),
    );
    blocks.add(
      const FormBlock.switchField(label: '强制恢复容器', name: 'restore_force'),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '跳过已存在的VM',
        name: 'restore_skip_existing',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '存储名称',
        name: 'storage_name',
        hint: 'local',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '要备份的容器ID',
        name: 'backup_vmid',
        hint: '如 101，多个用逗号分隔',
      ),
    );
    blocks.add(
      const FormBlock.selectField(
        label: '备份模式',
        name: 'backup_mode',
        items: const [
          SelectOption(title: '快照（推荐）', value: 'snapshot'),
          SelectOption(title: '停止', value: 'stop'),
          SelectOption(title: '挂起', value: 'suspend'),
        ],
      ),
    );
    blocks.add(
      const FormBlock.selectField(
        label: '压缩模式',
        name: 'compress_mode',
        items: const [
          SelectOption(title: 'ZSTD（快又好）', value: 'zstd'),
          SelectOption(title: 'LZO', value: 'lzo'),
          SelectOption(title: 'GZIP', value: 'gzip'),
          SelectOption(title: '无压缩', value: 'none'),
        ],
      ),
    );
  }

  /// 系统设置（对齐 Config.vue cleanup 节点）
  static void _buildCleanupSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '系统设置'));
    blocks.add(
      const FormBlock.switchField(label: '启用临时空间', name: 'auto_cleanup_tmp'),
    );
    blocks.add(
      const FormBlock.switchField(label: '启用系统日志', name: 'enable_log_cleanup'),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '启用镜像模板',
        name: 'cleanup_template_images',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'journalctl保留天数',
        name: 'log_journal_days',
        hint: '留空或0为全部清理',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '/var/log/vzdump保留最新N个',
        name: 'log_vzdump_keep',
        hint: '0为全部清理',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '/var/log/pve保留最新N个',
        name: 'log_pve_keep',
        hint: '0为全部清理',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '/var/log/dpkg.log保留最新N个',
        name: 'log_dpkg_keep',
        hint: '0为全部清理',
      ),
    );
  }
}

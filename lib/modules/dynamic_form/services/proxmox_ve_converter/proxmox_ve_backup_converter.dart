import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// ProxmoxVEBackup 插件专用转换器：将 API 原始 JSON 转换为 FormBlock 列表
class ProxmoxVEBackupConverter {
  /// 展示页：pve_status + container_status + available_backups → FormBlock 列表
  /// [useHeaderBlock] 为 true 时跳过 PVE 状态 InfoCard，由 ProxmoxVeBackupHeader 渲染
  static List<FormBlock> convertPage({
    required Map<String, dynamic> pveStatus,
    List<Map<String, dynamic>> containerStatusList = const [],
    List<Map<String, dynamic>> backups = const [],
    bool useHeaderBlock = false,
  }) {
    final blocks = <FormBlock>[];
    _buildPveStatusSection(blocks, pveStatus);
    _buildContainerStatusSection(blocks, containerStatusList);
    _buildAvailableBackupsSection(blocks, backups);

    blocks.add(
      const FormBlock.alert(type: 'info', text: '点击右下角设置按钮可配置 Proxmox VE 备份。'),
    );

    return blocks;
  }

  /// 配置页：config → (FormBlock 列表, formModel)
  static (List<FormBlock>, Map<String, dynamic>) convertForm({
    required Map<String, dynamic> config,
  }) {
    final blocks = <FormBlock>[];
    final model = Map<String, dynamic>.from(config);

    _buildBasicSettingsSection(blocks);
    _buildPveConnectionSection(blocks);
    _buildBackupSettingsSection(blocks);
    _buildWebdavSection(blocks);
    _buildRestoreSection(blocks);
    _buildAdvancedSection(blocks);

    return (blocks, model);
  }

  /// formModel → PUT 请求 body（保持字段原样）
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    return Map<String, dynamic>.from(model);
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
    final cpuUsage = (pveStatus['cpu_usage'] as num?)?.toDouble() ?? 0.0;
    final memUsage = (pveStatus['mem_usage'] as num?)?.toDouble() ?? 0.0;
    final diskUsage = (pveStatus['disk_usage'] as num?)?.toDouble() ?? 0.0;
    final loadAvg = pveStatus['load_avg'] as List? ?? [];
    final loadStr = loadAvg.map((e) => e?.toString() ?? '').join(' / ');
    final cpuTemp = (pveStatus['cpu_temp'] as num?)?.toDouble();
    final pveVersion = pveStatus['pve_version']?.toString() ?? '';

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
      InfoCardRow(
        iconName: 'mdi-chip',
        iconColor: 'blue',
        label: 'CPU 使用率',
        chipText: '${cpuUsage.toStringAsFixed(1)}%',
        chipColor: cpuUsage > 80 ? 'red' : 'blue',
      ),
      InfoCardRow(
        iconName: 'mdi-memory',
        iconColor: 'teal',
        label: '内存使用率',
        chipText: '${memUsage.toStringAsFixed(1)}%',
        chipColor: memUsage > 80 ? 'red' : 'teal',
      ),
      InfoCardRow(
        iconName: 'mdi-harddisk',
        iconColor: 'purple',
        label: '磁盘使用率',
        chipText: '${diskUsage.toStringAsFixed(1)}%',
        chipColor: diskUsage > 80 ? 'red' : 'purple',
      ),
      if (loadStr.isNotEmpty)
        InfoCardRow(iconName: 'mdi-chart-line', label: '负载', value: loadStr),
      if (cpuTemp != null)
        InfoCardRow(
          iconName: 'mdi-thermometer',
          label: 'CPU 温度',
          chipText: '${cpuTemp.toStringAsFixed(0)}°C',
          chipColor: cpuTemp > 70 ? 'red' : 'grey',
        ),
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

  static void _buildContainerStatusSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> containerStatusList,
  ) {
    if (containerStatusList.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '容器状态',
          iconName: 'mdi-docker',
          iconColor: 'info',
          emptyText: '暂无容器数据',
          emptyIconName: 'mdi-docker',
        ),
      );
      return;
    }

    final headers = ['名称', 'VMID', '状态', '类型', '运行时间', '标签'];
    final rows = <List<dynamic>>[];
    for (final c in containerStatusList) {
      final vmid = c['vmid']?.toString() ?? '';
      final name = c['displayName']?.toString() ?? c['name']?.toString() ?? '';
      final status = c['status']?.toString() ?? '';
      final type = c['type']?.toString() ?? '';
      final uptime = (c['uptime'] as num?)?.toInt() ?? 0;
      final tags = c['tags']?.toString() ?? '';
      rows.add([name, vmid, status, type, _formatUptime(uptime), tags]);
    }

    blocks.add(FormBlock.table(headers: headers, rows: rows));
  }

  static void _buildAvailableBackupsSection(
    List<FormBlock> blocks,
    List<Map<String, dynamic>> backups,
  ) {
    if (backups.isEmpty) {
      blocks.add(
        const FormBlock.infoCard(
          title: '可用备份',
          iconName: 'mdi-backup-restore',
          iconColor: 'teal',
          emptyText: '暂无备份文件',
          emptyIconName: 'mdi-backup-restore',
        ),
      );
      return;
    }

    final rows = <InfoCardRow>[];
    for (final b in backups) {
      final filename = b['filename']?.toString() ?? '';
      final sizeMb = (b['size_mb'] as num?)?.toDouble() ?? 0.0;
      final timeStr = b['time_str']?.toString() ?? '';
      final source = b['source']?.toString() ?? '';
      rows.add(
        InfoCardRow(
          iconName: 'mdi-file-archive',
          iconColor: 'teal',
          label: filename,
          value: timeStr,
          chipText: _formatSize(sizeMb),
          chipColor: 'blue',
          subtitle: source.isNotEmpty ? '来源: $source' : null,
        ),
      );
    }

    blocks.add(
      FormBlock.infoCard(
        title: '可用备份',
        iconName: 'mdi-backup-restore',
        iconColor: 'teal',
        headerChipText: '${backups.length} 个',
        headerChipColor: 'blue',
        rows: rows,
      ),
    );
  }

  static void _buildBasicSettingsSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '基本设置'));
    blocks.add(const FormBlock.switchField(label: '启用插件', name: 'enabled'));
    blocks.add(const FormBlock.switchField(label: '启用通知', name: 'notify'));
    blocks.add(const FormBlock.switchField(label: '仅执行一次', name: 'onlyonce'));
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

  static void _buildPveConnectionSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: 'PVE 连接'));
    blocks.add(
      const FormBlock.textField(
        label: 'PVE 主机',
        name: 'pve_host',
        hint: '192.168.1.100',
      ),
    );
    blocks.add(
      const FormBlock.textField(label: 'SSH 端口', name: 'ssh_port', hint: '22'),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH 用户名',
        name: 'ssh_username',
        hint: 'root',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH 密码',
        name: 'ssh_password',
        hint: '留空则使用密钥',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'SSH 密钥文件路径',
        name: 'ssh_key_file',
        hint: '/path/to/key',
      ),
    );
  }

  static void _buildBackupSettingsSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '备份设置'));
    blocks.add(
      const FormBlock.textField(
        label: '存储名称',
        name: 'storage_name',
        hint: 'local',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '备份 VMID',
        name: 'backup_vmid',
        hint: '101',
      ),
    );
    blocks.add(
      const FormBlock.switchField(label: '启用本地备份', name: 'enable_local_backup'),
    );
    blocks.add(
      const FormBlock.textField(
        label: '备份路径',
        name: 'backup_path',
        hint: '/config/plugins/ProxmoxVEBackup',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '保留备份数量',
        name: 'keep_backup_num',
        hint: '0 为不限制',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '备份模式',
        name: 'backup_mode',
        hint: 'snapshot / stop',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '压缩模式',
        name: 'compress_mode',
        hint: 'zstd / gzip / lzo',
      ),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '下载后自动删除',
        name: 'auto_delete_after_download',
      ),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '下载所有备份',
        name: 'download_all_backups',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '状态轮询间隔(ms)',
        name: 'status_poll_interval',
        hint: '30000',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '容器轮询间隔(ms)',
        name: 'container_poll_interval',
        hint: '30000',
      ),
    );
  }

  static void _buildWebdavSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: 'WebDAV'));
    blocks.add(
      const FormBlock.switchField(label: '启用 WebDAV', name: 'enable_webdav'),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV URL',
        name: 'webdav_url',
        hint: 'http://host:port/dav',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV 用户名',
        name: 'webdav_username',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV 密码',
        name: 'webdav_password',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV 路径',
        name: 'webdav_path',
        hint: '/path',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'WebDAV 保留备份数',
        name: 'webdav_keep_backup_num',
        hint: '0 为不限制',
      ),
    );
  }

  static void _buildRestoreSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '恢复'));
    blocks.add(
      const FormBlock.switchField(label: '启用恢复', name: 'enable_restore'),
    );
    blocks.add(
      const FormBlock.textField(
        label: '恢复存储',
        name: 'restore_storage',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '恢复 VMID',
        name: 'restore_vmid',
        hint: '',
      ),
    );
    blocks.add(
      const FormBlock.switchField(label: '强制恢复', name: 'restore_force'),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '跳过已存在',
        name: 'restore_skip_existing',
      ),
    );
    blocks.add(
      const FormBlock.textField(label: '恢复文件', name: 'restore_file', hint: ''),
    );
  }

  static void _buildAdvancedSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '高级'));
    blocks.add(
      const FormBlock.switchField(label: '清除历史', name: 'clear_history'),
    );
    blocks.add(
      const FormBlock.switchField(label: '自动清理临时文件', name: 'auto_cleanup_tmp'),
    );
    blocks.add(
      const FormBlock.switchField(label: '启用日志清理', name: 'enable_log_cleanup'),
    );
    blocks.add(
      const FormBlock.switchField(
        label: '清理模板镜像',
        name: 'cleanup_template_images',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: '日志保留天数',
        name: 'log_journal_days',
        hint: '0',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'vzdump 日志保留',
        name: 'log_vzdump_keep',
        hint: '0',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'pve 日志保留',
        name: 'log_pve_keep',
        hint: '0',
      ),
    );
    blocks.add(
      const FormBlock.textField(
        label: 'dpkg 日志保留',
        name: 'log_dpkg_keep',
        hint: '0',
      ),
    );
  }
}

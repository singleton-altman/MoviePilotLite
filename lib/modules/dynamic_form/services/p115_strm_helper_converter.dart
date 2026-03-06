import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// P115StrmHelper 插件专用转换器：将 API 原始 JSON 转换为 FormBlock 列表
class P115StrmHelperConverter {
  /// 展示页：status + userStorage → FormBlock 列表（只读）
  static List<FormBlock> convertPage({
    required Map<String, dynamic> status,
    Map<String, dynamic>? userStorage,
    Map<String, dynamic>? config,
  }) {
    final blocks = <FormBlock>[];

    _buildPluginStatusSection(blocks, status);
    if (userStorage != null) {
      _buildUserStorageSection(blocks, userStorage);
    }

    if (config != null) {
      _buildFeatureSwitchesSection(blocks, config);
      _buildPathConfigSection(blocks, config);
    }

    blocks.add(
      const FormBlock.alert(type: 'info', text: '点击右下角设置按钮可配置 P115 转流助手。'),
    );

    return blocks;
  }

  static void _buildPluginStatusSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final enabled = status['enabled'] == true;
    final hasClient = status['has_client'] == true;
    final running = status['running'] == true;

    blocks.add(
      FormBlock.infoCard(
        title: '插件状态',
        iconName: 'mdi-cloud',
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
            iconName: 'mdi-client',
            iconColor: hasClient ? 'green' : 'grey',
            label: '115 客户端',
            chipText: hasClient ? '已连接' : '未连接',
            chipColor: hasClient ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-sync',
            iconColor: running ? 'yellow' : 'grey',
            label: '任务状态',
            chipText: running ? '运行中' : '未运行',
            chipColor: running ? 'yellow' : 'grey',
          ),
        ],
      ),
    );
  }

  static void _buildUserStorageSection(
    List<FormBlock> blocks,
    Map<String, dynamic> userStorage,
  ) {
    final userInfo = userStorage['user_info'];
    final storageInfo = userStorage['storage_info'];
    final Map<String, dynamic>? userMap = userInfo is Map<String, dynamic>
        ? userInfo
        : (userInfo is Map ? Map<String, dynamic>.from(userInfo) : null);
    final Map<String, dynamic>? storageMap = storageInfo is Map<String, dynamic>
        ? storageInfo
        : (storageInfo is Map ? Map<String, dynamic>.from(storageInfo) : null);

    final rows = <InfoCardRow>[];
    if (userMap != null) {
      final name = userMap['name']?.toString() ?? '未知';
      final isVip = userMap['is_vip'] == true;
      final vipExpire = userMap['vip_expire_date']?.toString() ?? '';
      rows.add(
        InfoCardRow(
          iconName: 'mdi-account',
          iconColor: 'blue',
          label: '用户名',
          value: name,
        ),
      );
      rows.add(
        InfoCardRow(
          iconName: 'mdi-crown',
          iconColor: isVip ? 'amber' : 'grey',
          label: '会员状态',
          chipText: isVip ? 'VIP' : '普通用户',
          chipColor: isVip ? 'amber' : 'grey',
        ),
      );
      if (vipExpire.isNotEmpty) {
        rows.add(
          InfoCardRow(
            iconName: 'mdi-calendar',
            label: 'VIP 到期',
            value: vipExpire,
          ),
        );
      }
    }
    if (storageMap != null) {
      final total = storageMap['total'];
      final used = storageMap['used'];
      if (total.isNotEmpty || used.isNotEmpty) {
        rows.add(
          InfoCardRow(
            iconName: 'mdi-harddisk',
            iconColor: 'teal',
            label: '存储空间',
            value: '$used / $total',
          ),
        );
      }
    }

    if (rows.isEmpty) return;

    blocks.add(
      FormBlock.infoCard(
        title: '115 账户信息',
        iconName: 'mdi-cloud',
        iconColor: 'teal',
        rows: rows,
      ),
    );
  }

  /// 配置页：config → (FormBlock 列表, formModel)
  static (List<FormBlock>, Map<String, dynamic>) convertForm({
    required Map<String, dynamic> config,
  }) {
    final blocks = <FormBlock>[];
    final model = _buildFormModel(config);

    _buildBasicSettingsSection(blocks, config);
    _buildFeatureSwitchesSection(blocks, config);
    _buildPathConfigSection(blocks, config);

    return (blocks, model);
  }

  static void _buildBasicSettingsSection(
    List<FormBlock> blocks,
    Map<String, dynamic> config,
  ) {
    blocks.add(const FormBlock.pageHeader(title: '基本设置'));
    blocks.add(
      FormBlock.switchField(
        label: '启用插件',
        name: 'enabled',
        value: config['enabled'] == true,
      ),
    );
    blocks.add(
      FormBlock.switchField(
        label: '启用通知',
        name: 'notify',
        value: config['notify'] == true,
      ),
    );
  }

  static void _buildFeatureSwitchesSection(
    List<FormBlock> blocks,
    Map<String, dynamic> config,
  ) {
    final mpSyncEnabled = config['transfer_monitor_enabled'] == true;
    final timingFullSyncEnabled = config['timing_full_sync_strm'] == true;
    final incrementSyncEnabled = config['increment_sync_strm_enabled'] == true;
    final monitorLifeEnabled = config['monitor_life_enabled'] == true;
    final panTransferEnabled = config['pan_transfer_enabled'] == true;
    final clearRecyclebinEnabled = config['clear_recyclebin_enabled'] == true;
    final syncDelEnabled = config['sync_del_enabled'] == true;
    final fuseEnabled = config['fuse_enabled'] == true;
    blocks.add(
      FormBlock.infoCard(
        title: '功能配置',
        iconName: 'mdi-settings',
        iconColor: 'teal',
        rows: [
          InfoCardRow(
            iconName: 'mdi-sync',
            iconColor: 'yellow',
            label: '监控MP整理',
            chipText: mpSyncEnabled ? '已启用' : '已禁用',
            chipColor: mpSyncEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'blue',
            label: '定期全量同步',
            chipText: timingFullSyncEnabled ? '已启用' : '已禁用',
            chipColor: timingFullSyncEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-sync',
            iconColor: 'blue',
            label: '定期增量同步',
            chipText: incrementSyncEnabled ? '已启用' : '已禁用',
            chipColor: incrementSyncEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'blue',
            label: '监控115生活事件',
            chipText: monitorLifeEnabled ? '已启用' : '已禁用',
            chipColor: monitorLifeEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'yellow',
            label: '网盘整理',
            chipText: panTransferEnabled ? '已启用' : '已禁用',
            chipColor: panTransferEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'yellow',
            label: '定期清理',
            chipText: clearRecyclebinEnabled ? '已启用' : '已禁用',
            chipColor: clearRecyclebinEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'yellow',
            label: '同步删除',
            chipText: syncDelEnabled ? '已启用' : '已禁用',
            chipColor: syncDelEnabled ? 'yellow' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            iconColor: 'yellow',
            label: 'FUSE 文件系统',
            chipText: fuseEnabled ? '已启用' : '已禁用',
            chipColor: fuseEnabled ? 'yellow' : 'grey',
          ),
        ],
      ),
    );
  }

  static void _buildPathConfigSection(
    List<FormBlock> blocks,
    Map<String, dynamic> config,
  ) {
    final transferMonitorPaths = config['transfer_monitor_paths']
        ?.toString()
        .split('\n');
    blocks.add(
      FormBlock.infoCard(
        title: '监控MP整理路径',
        iconName: 'mdi-folder-search',
        iconColor: 'info',
        rows:
            transferMonitorPaths?.map((path) {
              final paths = path.split('#');
              var from = '';
              var to = '';
              if (paths.length > 1) {
                from = paths[0];
                to = paths[1];
              } else {
                from = paths[0];
              }
              return InfoCardRow(
                iconName: 'mdi-folder-search',
                label: from,
                subtitle: to,
              );
            }).toList() ??
            [],
      ),
    );
    final transferMpMediaserverPaths = config['pan_transfer_paths']
        ?.toString()
        .split('\n');
    blocks.add(
      FormBlock.infoCard(
        title: '网盘整理目录',
        iconName: 'mdi-folder-search',
        iconColor: 'info',
        rows:
            transferMpMediaserverPaths
                ?.map((path) {
                  final paths = path.split('#');
                  var from = '';
                  var to = '';
                  if (paths.length > 1) {
                    from = paths[0];
                    to = paths[1];
                  } else {
                    from = paths[0];
                  }
                  return InfoCardRow(
                    iconName: 'mdi-folder-search',
                    label: from,
                    subtitle: to,
                  );
                })
                .whereType<InfoCardRow>()
                .toList() ??
            [],
      ),
    );
  }

  static Map<String, dynamic> _buildFormModel(Map<String, dynamic> config) {
    return {
      'enabled': config['enabled'] ?? false,
      'notify': config['notify'] ?? false,
      'transfer_monitor_enabled': config['transfer_monitor_enabled'] ?? false,
      'timing_full_sync_strm': config['timing_full_sync_strm'] ?? false,
      'increment_sync_strm_enabled':
          config['increment_sync_strm_enabled'] ?? false,
      'monitor_life_enabled': config['monitor_life_enabled'] ?? false,
      'pan_transfer_enabled': config['pan_transfer_enabled'] ?? false,
      'clear_recyclebin_enabled': config['clear_recyclebin_enabled'] ?? false,
      'sync_del_enabled': config['sync_del_enabled'] ?? false,
      'fuse_enabled': config['fuse_enabled'] ?? false,
      'transfer_monitor_paths':
          config['transfer_monitor_paths']?.toString() ?? '',
      'transfer_mp_mediaserver_paths':
          config['transfer_mp_mediaserver_paths']?.toString() ?? '',
      'pan_transfer_paths': config['pan_transfer_paths']?.toString() ?? '',
      'full_sync_strm_paths': config['full_sync_strm_paths']?.toString() ?? '',
      'increment_sync_strm_paths':
          config['increment_sync_strm_paths']?.toString() ?? '',
      'cron_full_sync_strm': config['cron_full_sync_strm']?.toString() ?? '',
      'cron_clear': config['cron_clear']?.toString() ?? '',
      'increment_sync_cron': config['increment_sync_cron']?.toString() ?? '',
    };
  }

  /// formModel → PUT 请求 body（暂不实现保存，返回空）
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    return Map<String, dynamic>.from(model);
  }
}

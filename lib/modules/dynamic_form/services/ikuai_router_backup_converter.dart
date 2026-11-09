import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// IkuaiRouterBackup（爱快路由时光机）配置转换器。
///
/// GET /config 返回完整配置（含 mp_storages 等附加只读字段），
/// 保存时与 Web 端一致提交整个配置对象：
/// - 密码字段（ikuai_password/webdav_password）GET 不回传，POST 留空=服务端保留旧值
/// - 数值/布尔字段统一做类型收敛，避免字符串提交后被 bool()/int() 误读
class IkuaiRouterBackupConverter {
  /// 配置页：config → FormBlock 列表
  static List<FormBlock> convertForm({
    required Map<String, dynamic> config,
  }) {
    bool boolOf(String key, [bool fallback = false]) {
      final value = config[key];
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is num) return value != 0;
      return fallback;
    }

    String stringOf(String key) => config[key]?.toString() ?? '';
    int intOf(String key, int fallback) {
      final value = config[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value.trim()) ?? fallback;
      }
      return fallback;
    }

    final mpStorages = <SelectOption>[];
    final storages = config['mp_storages'];
    if (storages is List) {
      for (final entry in storages.whereType<Map>()) {
        final type = entry['type']?.toString() ?? '';
        if (type.isEmpty) continue;
        final name = entry['name']?.toString() ?? type;
        mpStorages.add(SelectOption(title: name, value: type));
      }
    }

    return [
      const FormBlock.pageHeader(title: '基本设置'),
      FormBlock.switchField(
        label: '启用插件',
        name: 'enabled',
        value: boolOf('enabled'),
      ),
      FormBlock.textField(
        label: '定时备份（Cron）',
        name: 'cron',
        value: stringOf('cron').isEmpty ? '0 3 * * *' : stringOf('cron'),
        hint: '5 位 cron 表达式，默认每天 03:00',
      ),
      FormBlock.switchField(
        label: '消息通知',
        name: 'notify',
        value: boolOf('notify'),
      ),
      FormBlock.textField(
        label: '重试次数',
        name: 'retry_count',
        value: intOf('retry_count', 3).toString(),
        hint: '备份失败重试次数（0-10）',
      ),
      FormBlock.textField(
        label: '重试间隔（秒）',
        name: 'retry_interval',
        value: intOf('retry_interval', 60).toString(),
        hint: '两次重试之间的间隔秒数（≥10）',
      ),
      const FormBlock.pageHeader(title: '爱快连接'),
      FormBlock.textField(
        label: '路由器地址',
        name: 'ikuai_url',
        value: stringOf('ikuai_url'),
        hint: '如 https://192.168.9.1',
      ),
      FormBlock.textField(
        label: '用户名',
        name: 'ikuai_username',
        value:
            stringOf('ikuai_username').isEmpty
                ? 'admin'
                : stringOf('ikuai_username'),
      ),
      FormBlock.textField(
        label: '密码',
        name: 'ikuai_password',
        value: '',
        hint: '留空保留已保存的密码',
      ),
      FormBlock.selectField(
        label: '认证方式',
        name: 'ikuai_auth_mode',
        value: stringOf('ikuai_auth_mode').isEmpty
            ? 'auto'
            : stringOf('ikuai_auth_mode'),
        items: const [
          SelectOption(title: '自动识别', value: 'auto'),
          SelectOption(title: '密码登录', value: 'password'),
          SelectOption(title: 'API 令牌', value: 'token'),
        ],
      ),
      FormBlock.textField(
        label: '爱快 4.x API 令牌',
        name: 'ikuai_api_token',
        value: '',
        hint: '令牌方式登录时填写，留空保留旧值',
      ),
      const FormBlock.pageHeader(title: '备份目标'),
      FormBlock.switchField(
        label: '启用存储备份',
        name: 'storage_backup_enable',
        value: boolOf('storage_backup_enable', true),
      ),
      FormBlock.selectField(
        label: '存储类型',
        name: 'storage_type',
        value: stringOf('storage_type').isEmpty
            ? 'local'
            : stringOf('storage_type'),
        items: [
          const SelectOption(title: '本地磁盘', value: 'local'),
          ...mpStorages,
        ],
      ),
      FormBlock.textField(
        label: '备份路径',
        name: 'storage_path',
        value: stringOf('storage_path'),
        hint: '本地磁盘时为服务器上的目录，网盘时为远端目录',
      ),
      FormBlock.textField(
        label: '保留份数',
        name: 'storage_keep_backup_num',
        value: intOf('storage_keep_backup_num', 7).toString(),
      ),
      FormBlock.switchField(
        label: '备份后删除路由器文件',
        name: 'delete_after_backup',
        value: boolOf('delete_after_backup'),
      ),
      FormBlock.switchField(
        label: '无变化跳过备份',
        name: 'skip_unchanged_backup',
        value: boolOf('skip_unchanged_backup', true),
      ),
      FormBlock.switchField(
        label: '启用 WebDAV 备份',
        name: 'enable_webdav',
        value: boolOf('enable_webdav'),
      ),
      FormBlock.textField(
        label: 'WebDAV 地址',
        name: 'webdav_url',
        value: stringOf('webdav_url'),
      ),
      FormBlock.textField(
        label: 'WebDAV 用户名',
        name: 'webdav_username',
        value: stringOf('webdav_username'),
      ),
      FormBlock.textField(
        label: 'WebDAV 密码',
        name: 'webdav_password',
        value: '',
        hint: '留空保留已保存的密码',
      ),
      FormBlock.textField(
        label: 'WebDAV 路径',
        name: 'webdav_path',
        value: stringOf('webdav_path'),
      ),
      FormBlock.textField(
        label: 'WebDAV 保留份数',
        name: 'webdav_keep_backup_num',
        value: intOf('webdav_keep_backup_num', 7).toString(),
      ),
      const FormBlock.pageHeader(title: '恢复设置'),
      FormBlock.switchField(
        label: '启用恢复功能',
        name: 'enable_restore',
        value: boolOf('enable_restore'),
      ),
      FormBlock.switchField(
        label: '强制恢复',
        name: 'restore_force',
        value: boolOf('restore_force'),
      ),
      FormBlock.switchField(
        label: '恢复前创建恢复点',
        name: 'restore_point_enable',
        value: boolOf('restore_point_enable', true),
      ),
      const FormBlock.pageHeader(title: '监控与告警'),
      FormBlock.switchField(
        label: '启用监控仪表盘',
        name: 'monitor_enable',
        value: boolOf('monitor_enable', true),
      ),
      FormBlock.switchField(
        label: '启用负载告警',
        name: 'load_warn_enable',
        value: boolOf('load_warn_enable'),
      ),
      FormBlock.textField(
        label: 'CPU 阈值（%）',
        name: 'load_cpu_threshold',
        value: intOf('load_cpu_threshold', 90).toString(),
        hint: '50-100',
      ),
      FormBlock.textField(
        label: '内存阈值（%）',
        name: 'load_mem_threshold',
        value: intOf('load_mem_threshold', 90).toString(),
        hint: '50-100',
      ),
      FormBlock.textField(
        label: '连续超限次数',
        name: 'load_warn_times',
        value: intOf('load_warn_times', 3).toString(),
        hint: '1-36 次',
      ),
      const FormBlock.alert(
        type: 'info',
        text: '密码与令牌留空表示保留已保存的值；多目标备份（storage_targets）暂不支持在 App 内编辑，已有配置保存时原样保留。',
      ),
    ];
  }

  /// formModel → POST /config 请求体。
  ///
  /// 与 Web 端一致提交完整配置；数值字段做类型收敛，
  /// 密码字段仅在用户输入时包含（留空/未输入由服务端保留旧值）。
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    final body = Map<String, dynamic>.from(model);
    // 移除 GET /config 注入的只读扩展字段，避免写回配置
    body.remove('mp_storages');

    body['enabled'] = body['enabled'] == true;
    body['notify'] = body['notify'] == true;
    body['storage_backup_enable'] = body['storage_backup_enable'] == true;
    body['delete_after_backup'] = body['delete_after_backup'] == true;
    body['skip_unchanged_backup'] = body['skip_unchanged_backup'] == true;
    body['enable_webdav'] = body['enable_webdav'] == true;
    body['enable_restore'] = body['enable_restore'] == true;
    body['restore_force'] = body['restore_force'] == true;
    body['restore_point_enable'] = body['restore_point_enable'] == true;
    body['monitor_enable'] = body['monitor_enable'] == true;
    body['load_warn_enable'] = body['load_warn_enable'] == true;
    body['enable_ip_group'] = body['enable_ip_group'] == true;
    body['ip_group_address_pool'] = body['ip_group_address_pool'] == true;

    for (final key in const [
      'retry_count',
      'retry_interval',
      'storage_keep_backup_num',
      'webdav_keep_backup_num',
      'load_cpu_threshold',
      'load_mem_threshold',
      'load_warn_times',
      'notification_style',
    ]) {
      final value = body[key];
      if (value is String) {
        final parsed = num.tryParse(value.trim());
        body[key] = parsed ?? (value.trim().isEmpty ? 0 : value);
      }
    }

    // storage_targets 已有配置原样保留（App 内暂不支持编辑多目标）
    if (body['storage_targets'] is! List) {
      body.remove('storage_targets');
    }

    // 密码字段：空值删除 key，服务端按“留空=保留旧值”处理
    for (final key in const ['ikuai_password', 'webdav_password']) {
      final value = body[key]?.toString() ?? '';
      if (value.isEmpty) {
        body.remove(key);
      } else {
        body[key] = value;
      }
    }

    return body;
  }
}

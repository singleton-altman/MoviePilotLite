import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// VueQuarkDisk（夸克网盘存储）状态模型 + 转换器。
///
/// GET /api/v1/plugin/VueQuarkDisk/config 直接返回配置本体（无 success 外壳），
/// 除配置字段外还附带登录态与空间统计等只读扩展字段。
class VueQuarkDiskStatus {
  const VueQuarkDiskStatus({
    required this.enabled,
    required this.cookie,
    required this.pageSize,
    required this.sortField,
    required this.sortOrder,
    required this.permanentlyDelete,
    required this.loggedIn,
    required this.userName,
    required this.userId,
    required this.vipLevel,
    required this.svipExpAt,
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
  });

  factory VueQuarkDiskStatus.fromJson(Map<String, dynamic> json) {
    return VueQuarkDiskStatus(
      enabled: json['enabled'] == true,
      cookie: _stringOf(json['cookie']),
      pageSize: _intOf(json['page_size']) == 0 ? 50 : _intOf(json['page_size']),
      sortField: _stringOf(json['sort_field']).isEmpty
          ? 'file_name'
          : _stringOf(json['sort_field']),
      sortOrder: _stringOf(json['sort_order']).isEmpty
          ? 'asc'
          : _stringOf(json['sort_order']),
      permanentlyDelete: json['permanently_delete'] == true,
      loggedIn: json['logged_in'] == true,
      userName: _stringOf(json['user_name']),
      userId: _stringOf(json['user_id']),
      vipLevel: _stringOf(json['vip_level']),
      svipExpAt: _stringOf(json['svip_exp_at']),
      totalSpace: _intOf(json['total_space']),
      usedSpace: _intOf(json['used_space']),
      freeSpace: _intOf(json['free_space']),
    );
  }

  final bool enabled;
  final String cookie;
  final int pageSize;
  final String sortField;
  final String sortOrder;
  final bool permanentlyDelete;

  // ---- 以下为 GET /config 附带的只读扩展字段 ----
  final bool loggedIn;
  final String userName;
  final String userId;
  final String vipLevel;
  final String svipExpAt;
  final int totalSpace;
  final int usedSpace;
  final int freeSpace;

  static const sortFieldLabels = <String, String>{
    'file_name': '文件名',
    'updated_at': '更新时间',
    'size': '文件大小',
    'created_at': '创建时间',
  };

  String get sortFieldLabel => sortFieldLabels[sortField] ?? sortField;

  String get sortOrderLabel => sortOrder == 'desc' ? '降序' : '升序';

  String get vipLabel =>
      vipLevel.isEmpty ? '普通用户' : vipLevel;

  /// 已用空间占比（0-1），总空间未知时返回 null
  double? get usedRatio {
    if (totalSpace <= 0) return null;
    return (usedSpace / totalSpace).clamp(0.0, 1.0);
  }

  static String formatSpace(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final text = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text ${units[unit]}';
  }

  Map<String, dynamic> toFormModel() {
    return {
      'enabled': enabled,
      'cookie': cookie,
      'page_size': pageSize.toString(),
      'sort_field': sortField,
      'sort_order': sortOrder,
      'permanently_delete': permanentlyDelete,
    };
  }
}

/// VueQuarkDisk 插件转换器：配置表单 → FormBlock
class VueQuarkDiskConverter {
  /// 配置页：config → FormBlock 列表
  static List<FormBlock> convertForm({
    required VueQuarkDiskStatus status,
  }) {
    final blocks = <FormBlock>[
      const FormBlock.pageHeader(title: '基础设置'),
      FormBlock.switchField(
        label: '启用插件',
        name: 'enabled',
        value: status.enabled,
      ),
      FormBlock.switchField(
        label: '彻底删除（删除后从回收站二次清除，不可恢复）',
        name: 'permanently_delete',
        value: status.permanentlyDelete,
      ),
      FormBlock.textField(
        label: '分页大小',
        name: 'page_size',
        value: status.pageSize.toString(),
        hint: '文件列表分页大小（1-200）',
      ),
      FormBlock.selectField(
        label: '排序字段',
        name: 'sort_field',
        value: status.sortField,
        items: VueQuarkDiskStatus.sortFieldLabels.entries
            .map((entry) => SelectOption(title: entry.value, value: entry.key))
            .toList(),
      ),
      FormBlock.selectField(
        label: '排序方向',
        name: 'sort_order',
        value: status.sortOrder,
        items: const [
          SelectOption(title: '升序', value: 'asc'),
          SelectOption(title: '降序', value: 'desc'),
        ],
      ),
      const FormBlock.pageHeader(title: '认证信息'),
      FormBlock.textArea(
        label: '夸克 Cookie',
        name: 'cookie',
        value: status.cookie,
        hint: '扫码登录后自动填充，也可手动粘贴',
        rows: 3,
      ),
      const FormBlock.alert(
        type: 'info',
        text: '推荐使用「扫码登录」完成授权；Cookie 由服务端自动维护与续期。',
      ),
    ];
    return blocks;
  }

  /// formModel → POST /config 请求体（只提交服务端持久化字段）
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    final body = <String, dynamic>{
      'enabled': model['enabled'] == true,
      'cookie': _stringOf(model['cookie']),
      'page_size': _intOf(model['page_size']) == 0
          ? 50
          : _intOf(model['page_size']).clamp(1, 200),
      'sort_field': _stringOf(model['sort_field']).isEmpty
          ? 'file_name'
          : _stringOf(model['sort_field']),
      'sort_order': _stringOf(model['sort_order']) == 'desc'
          ? 'desc'
          : 'asc',
      'permanently_delete': model['permanently_delete'] == true,
    };
    return body;
  }
}

String _stringOf(Object? value) {
  if (value == null) return '';
  return value.toString();
}

int _intOf(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

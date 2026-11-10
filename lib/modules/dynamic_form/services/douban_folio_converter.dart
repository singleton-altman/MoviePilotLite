import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// DoubanFolio（豆瓣档案）模型与转换器。
///
/// GET /api/v1/plugin/DoubanFolio/config 除配置字段外附带
/// logged_in / nickname / uid / avatar 等只读扩展字段。
class DoubanFolioStatus {
  const DoubanFolioStatus({
    required this.loggedIn,
    required this.nickname,
    required this.uid,
    required this.avatar,
    required this.enabled,
    required this.notify,
    required this.processedCount,
    required this.waitCount,
  });

  factory DoubanFolioStatus.fromJson(Map<String, dynamic> json) {
    return DoubanFolioStatus(
      loggedIn: json['logged_in'] == true,
      nickname: _stringOf(json['nickname']),
      uid: _stringOf(json['uid']),
      avatar: _stringOf(json['avatar']),
      enabled: json['enabled'] == true,
      notify: json['notify'] == true,
      processedCount: _intOf(json['processed_count']),
      waitCount: _intOf(json['wait_count']),
    );
  }

  final bool loggedIn;
  final String nickname;
  final String uid;
  final String avatar;
  final bool enabled;
  final bool notify;
  final int processedCount;
  final int waitCount;
}

/// 同步记录（GET /logs 的 data 数组元素）
class DoubanFolioLog {
  const DoubanFolioLog({
    required this.time,
    required this.title,
    required this.result,
    required this.message,
    required this.type,
    required this.poster,
  });

  factory DoubanFolioLog.fromJson(Map<String, dynamic> json) {
    return DoubanFolioLog(
      time: _stringOf(json['time']),
      title: _stringOf(json['title']),
      result: _stringOf(json['result']),
      message: _stringOf(json['message']),
      type: _stringOf(json['type']),
      poster: _stringOf(json['poster']),
    );
  }

  final String time;
  final String title;
  final String result;
  final String message;
  final String type;
  final String poster;

  /// success / fail / not_found → 展示文案与颜色
  String get resultLabel {
    switch (result) {
      case 'success':
        return '成功';
      case 'fail':
        return '失败';
      case 'not_found':
        return '豆瓣未收录';
      default:
        return result;
    }
  }

  bool get isFail => result == 'fail';
  bool get isNotFound => result == 'not_found';
}

/// DoubanFolio 插件转换器：配置表单 → FormBlock
class DoubanFolioConverter {
  /// 配置页：config → FormBlock 列表
  static List<FormBlock> convertForm({
    required Map<String, dynamic> config,
  }) {
    bool boolOf(String key) => config[key] == true;
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

    return [
      const FormBlock.pageHeader(title: '基础设置'),
      FormBlock.switchField(
        label: '启用插件',
        name: 'enabled',
        value: boolOf('enabled'),
      ),
      FormBlock.switchField(
        label: '豆瓣标记仅自己可见',
        name: 'private',
        value: boolOf('private'),
      ),
      FormBlock.switchField(
        label: '首集同步（播放第 1 集也同步到豆瓣）',
        name: 'first',
        value: boolOf('first'),
      ),
      FormBlock.switchField(
        label: 'Cookie 失效通知',
        name: 'notify',
        value: boolOf('notify'),
      ),
      const FormBlock.pageHeader(title: '想看自动订阅'),
      FormBlock.switchField(
        label: '豆瓣想看自动订阅到 MoviePilot',
        name: 'auto_subscribe',
        value: boolOf('auto_subscribe'),
      ),
      FormBlock.switchField(
        label: '已有想看也订阅（关闭时首轮只建立基线）',
        name: 'auto_subscribe_existing',
        value: boolOf('auto_subscribe_existing'),
      ),
      FormBlock.textField(
        label: '检查间隔（分钟）',
        name: 'auto_subscribe_interval',
        value: intOf('auto_subscribe_interval', 5).toString(),
        hint: '1-59 分钟，服务端会自动收敛到合法范围',
      ),
      const FormBlock.pageHeader(title: '同步范围'),
      FormBlock.textField(
        label: '只同步的用户名',
        name: 'user',
        value: stringOf('user'),
        hint: '英文逗号分隔，留空同步全部',
      ),
      FormBlock.textField(
        label: '排除关键词',
        name: 'exclude',
        value: stringOf('exclude'),
        hint: '逗号分隔，标题或路径命中即跳过',
      ),
      const FormBlock.pageHeader(title: '豆瓣账号'),
      FormBlock.textArea(
        label: '豆瓣 Cookie',
        name: 'cookie',
        value: stringOf('cookie'),
        hint: '扫码登录后自动填充，也可手动粘贴',
        rows: 3,
      ),
      const FormBlock.alert(
        type: 'info',
        text: '推荐使用「扫码登录」绑定豆瓣账号；标记数据由播放事件自动同步。',
      ),
    ];
  }

  /// formModel → POST /config 请求体
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    String stringOf(String key) => model[key]?.toString() ?? '';
    int intOf(String key, int fallback) {
      final value = model[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value.trim()) ?? fallback;
      }
      return fallback;
    }

    return {
      'enabled': model['enabled'] == true,
      'private': model['private'] == true,
      'first': model['first'] == true,
      'notify': model['notify'] == true,
      'auto_subscribe': model['auto_subscribe'] == true,
      'auto_subscribe_existing': model['auto_subscribe_existing'] == true,
      'auto_subscribe_interval': intOf('auto_subscribe_interval', 5),
      'user': stringOf('user'),
      'exclude': stringOf('exclude'),
      'cookie': stringOf('cookie'),
      'pc_month': intOf('pc_month', 3),
      'pc_num': intOf('pc_num', 50),
      'mobile_month': intOf('mobile_month', 2),
      'mobile_num': intOf('mobile_num', 15),
    };
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
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

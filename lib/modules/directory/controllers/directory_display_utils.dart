import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';

enum OverwriteMode { always, never, size, latest }

extension OverwriteModeX on OverwriteMode {
  String get displayName {
    switch (this) {
      case OverwriteMode.always:
        return '总是覆盖';
      case OverwriteMode.never:
        return '从不覆盖';
      case OverwriteMode.size:
        return '按照大小覆盖';
      case OverwriteMode.latest:
        return '按照最新时间覆盖';
      default:
        return '未知';
    }
  }
}

enum MonitorType { monitor, downloader, manual, none }

extension MonitorTypeX on MonitorType {
  String get displayName {
    switch (this) {
      case MonitorType.monitor:
        return '目录监控';
      case MonitorType.downloader:
        return '下载器监控';
      case MonitorType.manual:
        return '手动监控';
      default:
        return '不整理';
    }
  }
}

enum TransferType { copy, move, softlink, link }

extension TransferTypeX on TransferType {
  String get displayName {
    switch (this) {
      case TransferType.copy:
        return '复制';
      case TransferType.move:
        return '移动';
      case TransferType.softlink:
        return '软链接';
      case TransferType.link:
        return '硬链接';
    }
  }
}

class DirectoryDisplayUtils {
  static String formatDirectoryName(DirectorySetting directory) {
    final name = directory.name;
    if (name.isEmpty) return '(未命名)';
    if (name.length > 10) return '${name.substring(0, 10)}...';
    return name;
  }

  static String formatStorageName(DirectorySetting directory) {
    final storage = directory.storage;
    if (storage.isEmpty) return '全部';
    switch (storage) {
      case 'local':
        return '本地';
      case 'u115':
        return '115网盘';
      case 'alipan':
        return '阿里云盘';
      case 'rclone':
        return 'RClone';
      case 'alist':
        return 'Openlist';
      case 'smb':
        return 'SMB';
      case 'custom7':
        return '自定义';
      default:
        return storage;
    }
  }

  static String formatTransferType(DirectorySetting directory) {
    final transferType = TransferType.values.firstWhere(
      (e) => e.name == directory.transferType,
      orElse: () => TransferType.copy,
    );
    return transferType.displayName;
  }

  static String formatMonitorType(DirectorySetting directory) {
    final monitorType = MonitorType.values.firstWhere(
      (e) => e.name == directory.monitorType,
      orElse: () => MonitorType.none,
    );
    return monitorType.displayName;
  }

  static String formatOverwriteMode(DirectorySetting directory) {
    final overwriteMode = OverwriteMode.values.firstWhere(
      (e) => e.name == directory.overwriteMode,
      orElse: () => OverwriteMode.never,
    );
    return overwriteMode.displayName;
  }
}

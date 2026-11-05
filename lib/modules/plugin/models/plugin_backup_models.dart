import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';

class PluginBackupFile {
  const PluginBackupFile({
    required this.version,
    required this.createdAt,
    required this.scopeKey,
    required this.plugins,
    this.fileName = '',
    this.filePath = '',
    this.imported = false,
    this.auto = false,
  });

  final int version;
  final DateTime createdAt;
  final String scopeKey;
  final List<PluginItem> plugins;
  final String fileName;
  final String filePath;
  final bool imported;
  final bool auto;

  static const int currentVersion = 1;

  Map<String, dynamic> toJson() => {
    'version': version,
    'created_at': createdAt.toUtc().toIso8601String(),
    'scope_key': scopeKey,
    'imported': imported,
    'auto': auto,
    'plugins': plugins.map(_pluginToBackupJson).toList(),
  };

  factory PluginBackupFile.fromJson(
    Map<String, dynamic> json, {
    String fileName = '',
    String filePath = '',
  }) {
    final rawPlugins = json['plugins'];
    final plugins = <PluginItem>[];
    if (rawPlugins is List) {
      for (final item in rawPlugins) {
        if (item is! Map) continue;
        try {
          plugins.add(
            PluginItem.fromJson(Map<String, dynamic>.from(item)).copyWith(
              installed: false,
              state: false,
              hasUpdate: false,
            ),
          );
        } catch (_) {}
      }
    }
    final createdRaw = json['created_at']?.toString();
    final importedFlag = json['imported'] == true;
    final autoFlag = json['auto'] == true;
    final importedByName = fileName.startsWith('plugins_import_');
    final autoByName = fileName.startsWith('plugins_auto_');
    return PluginBackupFile(
      version: _asInt(json['version'], fallback: currentVersion),
      createdAt:
          DateTime.tryParse(createdRaw ?? '')?.toLocal() ?? DateTime.now(),
      scopeKey: json['scope_key']?.toString() ?? '',
      plugins: plugins,
      fileName: fileName,
      filePath: filePath,
      imported: importedFlag || importedByName,
      auto: autoFlag || autoByName,
    );
  }

  static Map<String, dynamic> _pluginToBackupJson(PluginItem item) {
    return {
      'id': item.id,
      'plugin_name': item.pluginName,
      'plugin_desc': item.pluginDesc,
      'plugin_icon': item.pluginIcon,
      'plugin_version': item.pluginVersion,
      'plugin_label': item.pluginLabel,
      'plugin_author': item.pluginAuthor,
      'author_url': item.authorUrl,
      'plugin_config_prefix': item.pluginConfigPrefix,
      'plugin_order': item.pluginOrder,
      'auth_level': item.authLevel,
      'repo_url': item.repoUrl,
      'is_local': item.isLocal,
      'plugin_public_key': item.pluginPublicKey,
      'add_time': item.addTime,
    };
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class PluginBackupListItem {
  const PluginBackupListItem({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.pluginCount,
    this.imported = false,
    this.auto = false,
  });

  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int pluginCount;
  final bool imported;
  final bool auto;
}

class PluginBatchInstallProgress {
  const PluginBatchInstallProgress({
    required this.total,
    required this.currentIndex,
    required this.currentName,
    required this.successCount,
    required this.failedCount,
    this.currentId = '',
    this.done = false,
  });

  final int total;
  final int currentIndex;
  final String currentId;
  final String currentName;
  final int successCount;
  final int failedCount;
  final bool done;

  double get ratio {
    if (done) return 1;
    if (total <= 0) return 0;
    final completed = successCount + failedCount;
    return (completed / total).clamp(0, 1);
  }
}

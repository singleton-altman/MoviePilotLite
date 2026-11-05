import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_backup_models.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:path_provider/path_provider.dart';

class PluginBackupService {
  static const _rootDirName = 'plugin_backups';

  Future<Directory> _scopeDir(String scopeKey) async {
    final support = await getApplicationSupportDirectory();
    final safeScope = _sanitizeScope(scopeKey);
    final dir = Directory('${support.path}/$_rootDirName/$safeScope');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _sanitizeScope(String scopeKey) {
    final trimmed = scopeKey.trim();
    if (trimmed.isEmpty) return '_default';
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<PluginBackupFile> saveBackup({
    required String scopeKey,
    required List<PluginItem> plugins,
    bool auto = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 暂不支持插件备份');
    }
    final now = DateTime.now();
    final backup = PluginBackupFile(
      version: PluginBackupFile.currentVersion,
      createdAt: now,
      scopeKey: scopeKey,
      plugins: plugins,
      auto: auto,
    );
    final dir = await _scopeDir(scopeKey);
    final stamp = _formatStamp(now);
    final fileName = auto ? 'plugins_auto_$stamp.json' : 'plugins_$stamp.json';
    final file = File('${dir.path}/$fileName');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(backup.toJson()), flush: true);
    return PluginBackupFile(
      version: backup.version,
      createdAt: backup.createdAt,
      scopeKey: backup.scopeKey,
      plugins: backup.plugins,
      fileName: fileName,
      filePath: file.path,
      auto: auto,
    );
  }

  Future<List<PluginBackupListItem>> listBackups(String scopeKey) async {
    if (kIsWeb) return const [];
    final dir = await _scopeDir(scopeKey);
    if (!await dir.exists()) return const [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        files.add(entity);
      }
    }
    final items = <PluginBackupListItem>[];
    for (final file in files) {
      final name = file.uri.pathSegments.isEmpty
          ? file.path
          : file.uri.pathSegments.last;
      try {
        final backup = await readBackupFile(file.path);
        items.add(
          PluginBackupListItem(
            fileName: backup.fileName.isNotEmpty ? backup.fileName : name,
            filePath: file.path,
            createdAt: backup.createdAt,
            pluginCount: backup.plugins.length,
            imported: backup.imported,
            auto: backup.auto,
          ),
        );
      } catch (_) {
        final stat = await file.stat();
        items.add(
          PluginBackupListItem(
            fileName: name,
            filePath: file.path,
            createdAt: stat.modified,
            pluginCount: 0,
            imported: name.startsWith('plugins_import_'),
            auto: name.startsWith('plugins_auto_'),
          ),
        );
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  bool hasAutoBackupOnDate(List<PluginBackupListItem> items, DateTime day) {
    final y = day.year;
    final m = day.month;
    final d = day.day;
    for (final item in items) {
      if (!item.auto) continue;
      final t = item.createdAt;
      if (t.year == y && t.month == m && t.day == d) return true;
    }
    return false;
  }

  Future<PluginBackupFile> readBackupFile(String path) async {
    final file = File(path);
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('备份文件格式无效');
    }
    return PluginBackupFile.fromJson(
      Map<String, dynamic>.from(decoded),
      fileName: file.uri.pathSegments.isEmpty
          ? file.path
          : file.uri.pathSegments.last,
      filePath: file.path,
    );
  }

  Future<PluginBackupFile> readBackupBytes(
    List<int> bytes, {
    String fileName = '',
  }) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('备份文件格式无效');
    }
    return PluginBackupFile.fromJson(
      Map<String, dynamic>.from(decoded),
      fileName: fileName,
    );
  }

  Future<PluginBackupFile> importBackup({
    required String scopeKey,
    required PluginBackupFile source,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 暂不支持插件备份');
    }
    if (source.plugins.isEmpty) {
      throw StateError('备份中没有可导入的插件');
    }
    final dir = await _scopeDir(scopeKey);
    if (source.filePath.isNotEmpty) {
      final existing = File(source.filePath);
      final normalizedDir = dir.path.endsWith('/')
          ? dir.path
          : '${dir.path}/';
      if (existing.path.startsWith(normalizedDir) && await existing.exists()) {
        return source;
      }
    }
    final now = DateTime.now();
    final backup = PluginBackupFile(
      version: source.version <= 0
          ? PluginBackupFile.currentVersion
          : source.version,
      createdAt: source.createdAt,
      scopeKey: scopeKey,
      plugins: source.plugins,
      imported: true,
    );
    final stamp = _formatStamp(now);
    final fileName = 'plugins_import_$stamp.json';
    final file = File('${dir.path}/$fileName');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(backup.toJson()), flush: true);
    return PluginBackupFile(
      version: backup.version,
      createdAt: backup.createdAt,
      scopeKey: backup.scopeKey,
      plugins: backup.plugins,
      fileName: fileName,
      filePath: file.path,
      imported: true,
    );
  }

  Future<void> deleteBackup(String path) async {
    if (kIsWeb) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<({String fileName, List<int> bytes})> readBackupExportPayload(
    String path,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 暂不支持导出备份');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('备份文件不存在');
    }
    final bytes = await file.readAsBytes();
    final name = file.uri.pathSegments.isEmpty
        ? 'plugins_backup.json'
        : file.uri.pathSegments.last;
    return (fileName: name, bytes: bytes);
  }

  String _formatStamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}

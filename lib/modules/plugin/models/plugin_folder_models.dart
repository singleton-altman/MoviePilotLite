import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Both V2 and V3 accept legacy arrays and objects with a `plugins` array.
/// Keep the entire JSON document so edits never discard presentation metadata.
class PluginFolders {
  PluginFolders._(this._data);

  factory PluginFolders.fromJson(Object? raw) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw const FormatException('插件文件夹响应格式无效');
    }
    final data = _copy(Map<String, dynamic>.from(raw));
    for (final value in data.values) {
      if (value is! List && value is! Map) {
        throw const FormatException('插件文件夹配置格式无效');
      }
      final plugins = value is Map ? value['plugins'] : value;
      // Object-format folders may omit plugins (the V3 schema defaults to []).
      if ((value is Map && value.containsKey('plugins') && plugins == null) ||
          (plugins != null &&
              (plugins is! List || plugins.any((id) => id is! String)))) {
        throw const FormatException('插件文件夹成员格式无效');
      }
    }
    return PluginFolders._(data);
  }

  final Map<String, dynamic> _data;

  List<String> get names => List.unmodifiable(_data.keys);
  bool get isEmpty => _data.isEmpty;

  List<String> pluginsIn(String name) {
    final value = _data[name];
    final plugins = value is Map ? value['plugins'] : value;
    return plugins is List ? List<String>.unmodifiable(plugins) : const [];
  }

  Map<String, dynamic> toJson() => _copy(_data);

  bool sameAs(PluginFolders other) =>
      listEquals(names, other.names) &&
      mapEquals(_canonical(_data), _canonical(other._data));

  // Canonical JSON compares nested metadata independent of object key order.
  static Map<String, String> _canonical(Map<String, dynamic> data) =>
      data.map((key, value) => MapEntry(key, jsonEncode(_sorted(value))));

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _sorted(value[key])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }

  PluginFolders create(String name) {
    _validateNewName(name);
    return PluginFolders.fromJson({..._data, name: <String>[]});
  }

  PluginFolders rename(String oldName, String newName) {
    _requireFolder(oldName);
    if (oldName == newName) return this;
    _validateNewName(newName);
    return PluginFolders.fromJson({
      for (final entry in _data.entries)
        (entry.key == oldName ? newName : entry.key): entry.value,
    });
  }

  PluginFolders delete(String name) {
    _requireFolder(name);
    final data = toJson()..remove(name);
    return PluginFolders.fromJson(data);
  }

  PluginFolders withPlugins(String name, Iterable<String> pluginIds) {
    _requireFolder(name);
    final data = toJson();
    final value = data[name];
    final plugins = pluginIds.toSet().toList();
    data[name] = value is Map ? {...value, 'plugins': plugins} : plugins;
    return PluginFolders.fromJson(data);
  }

  void _requireFolder(String name) {
    if (!_data.containsKey(name)) throw StateError('文件夹已不存在，请刷新后重试');
  }

  void _validateNewName(String name) {
    if (name.trim().isEmpty || name != name.trim() || name.length > 128) {
      throw const FormatException('请输入 1–128 个字符的文件夹名称');
    }
    if (_data.containsKey(name)) throw const FormatException('文件夹已存在');
  }

  static Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
}

class PluginRemote {
  const PluginRemote({
    required this.id,
    required this.name,
    required this.url,
    this.sourcePluginId,
  });

  factory PluginRemote.fromJson(Map raw) {
    if (raw['id'] is! String ||
        raw['name'] is! String ||
        raw['url'] is! String) {
      throw const FormatException('插件联邦组件响应格式无效');
    }
    return PluginRemote(
      id: raw['id'] as String,
      name: raw['name'] as String,
      url: raw['url'] as String,
      sourcePluginId: raw['source_plugin_id'] as String?,
    );
  }

  final String id;
  final String name;
  final String url;
  final String? sourcePluginId;
}

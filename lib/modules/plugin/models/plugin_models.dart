import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_models.freezed.dart';
part 'plugin_models.g.dart';

/// 插件项（API: /api/v1/plugin/?state=installed）
@freezed
class PluginItem with _$PluginItem {
  const factory PluginItem({
    required String id,
    @JsonKey(name: 'plugin_name') required String pluginName,
    @JsonKey(name: 'plugin_desc') String? pluginDesc,
    @JsonKey(name: 'plugin_icon') String? pluginIcon,
    @JsonKey(name: 'plugin_version') String? pluginVersion,
    @JsonKey(name: 'plugin_label') String? pluginLabel,
    @JsonKey(name: 'plugin_author') String? pluginAuthor,
    @JsonKey(name: 'author_url') String? authorUrl,
    @JsonKey(name: 'plugin_config_prefix') String? pluginConfigPrefix,
    @JsonKey(name: 'plugin_order', fromJson: _intFromJson) @Default(0) int pluginOrder,
    @JsonKey(name: 'auth_level', fromJson: _intFromJson) @Default(1) int authLevel,
    @Default(true) bool installed,
    @Default(false) bool state,
    @JsonKey(name: 'has_page') @Default(false) bool hasPage,
    @JsonKey(name: 'has_update') @Default(false) bool hasUpdate,
    @JsonKey(name: 'is_local') @Default(false) bool isLocal,
    @JsonKey(name: 'repo_url') String? repoUrl,
    @JsonKey(name: 'install_count', fromJson: _intFromJson) @Default(0) int installCount,
    @Default({}) Map<String, dynamic> history,
    @JsonKey(name: 'add_time', fromJson: _intFromJson) @Default(0) int addTime,
    @JsonKey(name: 'plugin_public_key') String? pluginPublicKey,
  }) = _PluginItem;

  factory PluginItem.fromJson(Map<String, dynamic> json) =>
      _$PluginItemFromJson(_normalizePluginJson(json));
}

Map<String, dynamic> _normalizePluginJson(Map<String, dynamic> json) {
  final id = json['id']?.toString() ?? '';
  final name = json['plugin_name']?.toString().trim();
  final history = json['history'];
  return {
    ...json,
    'id': id,
    'plugin_name': (name == null || name.isEmpty) ? id : name,
    'history': history is Map
        ? Map<String, dynamic>.from(history)
        : <String, dynamic>{},
  };
}

List<dynamic> unwrapPluginList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map) {
    final data = raw['data'];
    if (data is List) return data;
  }
  return const [];
}

int _intFromJson(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, int> parsePluginInstallCountMap(dynamic data) {
  if (data is! Map) return {};
  final result = <String, int>{};
  for (final entry in data.entries) {
    final key = entry.key?.toString().trim() ?? '';
    if (key.isEmpty) continue;
    result[key] = _intFromJson(entry.value);
  }
  return result;
}

int lookupPluginInstallCount(Map<String, int> counts, Object? id) {
  final key = id?.toString().trim() ?? '';
  if (key.isEmpty) return 0;
  final direct = counts[key];
  if (direct != null) return direct;
  final lower = key.toLowerCase();
  for (final entry in counts.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return 0;
}

class PluginAvailability {
  const PluginAvailability({
    this.unavailable = false,
    this.label = '不可用',
  });

  final bool unavailable;
  final String label;
}

PluginAvailability pluginAvailabilityFromJson(Map<String, dynamic> json) {
  final compatible = json['system_version_compatible'] != false;
  if (!compatible) {
    final message = json['system_version_message']?.toString().trim();
    return PluginAvailability(
      unavailable: true,
      label: (message != null && message.isNotEmpty) ? message : '不兼容',
    );
  }
  final binding = json['source_binding_status']?.toString();
  switch (binding) {
    case 'binding_required':
    case 'unbound':
    case 'missing':
      return const PluginAvailability(unavailable: true, label: '不可用');
  }
  final runtime = json['runtime_status']?.toString();
  switch (runtime) {
    case 'error':
    case 'failed':
    case 'crashed':
      return const PluginAvailability(unavailable: true, label: '异常');
  }
  return const PluginAvailability();
}
